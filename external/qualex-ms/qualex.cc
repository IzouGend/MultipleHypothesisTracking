/***********************************************************************
!! QUALEX-MS: a QUick ALmost EXact Motzkin-Straus maximum weight      !!
!! clique/independent set solver.                                     !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! Qualex implementation                                              !!
***********************************************************************/

#include <string.h>
#include <math.h>
#include <float.h>
#include <algorithm>
#include <functional>

#include "1d_math.h"
#include "qualex.h"
#include "refiner.h"

inline double sqr(double x) { return x*x; }

// BLAS/LAPACK routines
extern "C" {
  double norm2(int,double*);
  int symmetric_eigen(int,double*,double*,double*);
  double dot_product(int,double*,double*);
  void matrix_dot_vector(int,int,double*,char,double*,double*);
}

// EigenCluster hold information about one full cluster of equal eigenvalues
struct EigenCluster {
  double lambda;  // the eigenvalue
  double c2;  // the square sum of the corresponding linear form coefficients
  int first, last;  // the eigenvalue range
  EigenCluster() {}
  EigenCluster(double _lambda, double _c2, int _first, int _last) :
    lambda(_lambda), c2(_c2), first(_first), last(_last) {}
};

// Equation holds an expression \sum_i (c_i / (x - lambda_i))^2 - RHS
// (which is discrepancy of an equation \sum_i (c_i / (x - lambda_i))^2 = RHS)
// and provides double operator() to compute it as a function of x
struct Equation: public unary_function<double,double> {
  vector<EigenCluster>& lambda_clusters; // whence lambda and c2 are taken
  double rhs; // RHS value
  Equation(vector<EigenCluster>& _lambda_clusters, double _rhs) :
    lambda_clusters(_lambda_clusters), rhs(_rhs) {}
  double operator()(const double x);  // \sum_i (c_i / (x - lambda_i))^2 - RHS
};

// \sum_i (c_i / (x - lambda_i))^2 - RHS
double Equation::operator()(const double x) {
  double lhs = 0.0;
  vector<EigenCluster>::iterator i;
  for(i=lambda_clusters.begin();i<lambda_clusters.end();i++)
    lhs += i->c2/sqr(x-i->lambda);
  return lhs-rhs;
}

void init_projected_matrices (
  MaxCliqueInfo& graph_info, double* a, double* hatb
) {
  int& n = graph_info.g.n;
  double* delta = new double[n];
  matrix_dot_vector(n,n,a,'T',graph_info.sqrtw,delta);
  double D = dot_product(n,graph_info.sqrtw,delta);
  for(int j=0;j<n;j++) {
    for(int i=0;i<=j;i++) {
      a[j*n+i] += graph_info.shift[i]*graph_info.shift[j]*D -
        graph_info.shift[i]*delta[j] - graph_info.shift[j]*delta[i];
      a[i*n+j] = a[j*n+i];
    }
    hatb[j] = (delta[j]-graph_info.shift[j]*D)/graph_info.W;
  }
  delete[] delta;
}

struct QualexInfo {
  int k;  // the eigenvector space dimensionality, k<=n-1
  double* lambda; // eigenvalues of the projected feasible matrix
  double* q;  // eigenvector matrix of the projected feasible matrix
  double* c;  // linear form coefficients in the eigenvector basis

  vector<EigenCluster> active_clusters;  // the eigenvalue clusters where c2!=0
  vector<EigenCluster> degenerative_clusters;  // the clusters with c2=0

  QualexInfo(): k(0), lambda(NULL), q(NULL), c(NULL) {}
  ~QualexInfo() {
    if(lambda!=NULL) delete[] lambda;
    if(q!=NULL) delete[] q;
    if(c!=NULL) delete[] c;
  }

  void install_eigenvalues (
    int n, double* lambda1, int& n_neg_eigens, int& n_pos_eigens
  );

  inline void install_eigenvectors (
    int n, double* q1, int n_neg_eigens, int n_pos_eigens
  );

  inline void init_c(int n, double* hatb);

  void init_eigenclusters();
};

void QualexInfo::install_eigenvalues (
  int n, double* lambda1, int& n_neg_eigens, int& n_pos_eigens
) {
  double* first_zero_lambda = lower_bound(lambda1,lambda1+n,-1e-5);
  double* last_zero_lambda = first_zero_lambda+1;
  while(*last_zero_lambda<1e-5) last_zero_lambda++;
  n_neg_eigens = first_zero_lambda-lambda1;
  n_pos_eigens = n - (last_zero_lambda-lambda1);
  k = n_neg_eigens + n_pos_eigens;
  lambda = new double[k];
  memcpy(lambda,lambda1,sizeof(double)*n_neg_eigens);
  memcpy(lambda+n_neg_eigens,last_zero_lambda,sizeof(double)*n_pos_eigens);
}

void QualexInfo::install_eigenvectors (
  int n, double* q1, int n_neg_eigens, int n_pos_eigens
) {
  q = new double[n*k];
  memcpy(q,q1,sizeof(double)*n_neg_eigens*n);
  memcpy(q+(n_neg_eigens*n),q1+((n-n_pos_eigens)*n),sizeof(double)*n_pos_eigens*n);
}

void QualexInfo::init_c(int n, double* hatb) {
  c = new double[k];
  matrix_dot_vector(n,k,q,'T',hatb,c);
}

void QualexInfo::init_eigenclusters() {
  int first_index = 0;
  double lambda_sum = lambda[0];
  double c2 = sqr(c[0]);
  double last_lambda = lambda[0];
  int i;
  for(i=1;i<k;i++) {
    if(lambda[i]-last_lambda<1e-5) {
      lambda_sum += lambda[i];
      c2 += sqr(c[i]);
    } else {
      vector<EigenCluster>& clusters = (
        fabs(c2)<1e-5 ? degenerative_clusters : active_clusters );
      clusters.push_back (
        EigenCluster(lambda_sum/(i-first_index), c2, first_index, i) );
      first_index = i;
      lambda_sum = lambda[i];
      c2 = sqr(c[i]);
    }
    last_lambda = lambda[i];
  }
  vector<EigenCluster>& clusters = (
    fabs(c2)<1e-5 ? degenerative_clusters : active_clusters );
  clusters.push_back (
    EigenCluster(lambda_sum/(i-first_index), c2, first_index, i) );
}

bool init_projected_formulation (
  MaxCliqueInfo& graph_info, double* a, QualexInfo& solver_info
) {
  int& n = graph_info.g.n;
  double* hatb = new double[n];
  init_projected_matrices(graph_info,a,hatb);

  double* lambda1 = new double[n];
  double* q1 = new double[n*n];
  symmetric_eigen(n,a,lambda1,q1);

  if(lambda1[n-1]<1e-5) {
    delete[] hatb; delete[] lambda1; delete[] q1;
    return false;
  }

  int n_neg_eigens, n_pos_eigens;
  solver_info.install_eigenvalues(n,lambda1,n_neg_eigens,n_pos_eigens);
  delete[] lambda1;
  solver_info.install_eigenvectors(n,q1,n_neg_eigens,n_pos_eigens);
  delete[] q1;
  solver_info.init_c(n,hatb);
  delete[] hatb;
  solver_info.init_eigenclusters();

  return true;
}

bool try_stat_point (
  MaxCliqueInfo& graph_info, QualexInfo& solver_info,
  double mu, double* x, double* y
) {
  vector<EigenCluster>::iterator ii;
  int i;
  for(ii=solver_info.active_clusters.begin();ii<solver_info.active_clusters.end();ii++) {
    for(i=ii->first;i<ii->last;i++) y[i] = solver_info.c[i]/(mu-solver_info.lambda[i]);
  }
  matrix_dot_vector(graph_info.g.n,solver_info.k,solver_info.q,'N',y,x);
  for(i=0;i<graph_info.g.n;i++) x[i] = (x[i]+graph_info.shift[i])*graph_info.sqrtw[i];
  return refine_clique_MIN(graph_info,x);
}

bool try_nondeg_points (
  MaxCliqueInfo& graph_info, QualexInfo& solver_info, Equation& equ,
  double* x, double* y
) {
  double mu_max = solver_info.active_clusters.back().lambda;
  double mu_min = mu_max*(1.0+3.0*DBL_EPSILON);
  mu_max += norm2(solver_info.k,solver_info.c)/sqrt(equ.rhs);
  double mu = root(mu_min,mu_max,equ);
  bool result = try_stat_point(graph_info,solver_info,mu,x,y);
  vector<EigenCluster>::reverse_iterator ri;
  for(ri=solver_info.active_clusters.rbegin();ri<solver_info.active_clusters.rend();ri++) {
    if(ri->lambda<graph_info.w_min/2.0) break;
    mu_max = ri->lambda*(1.0-3.0*DBL_EPSILON);
    vector<EigenCluster>::reverse_iterator ri1 = ri+1;
    if(ri1==solver_info.active_clusters.rend()) mu_min = 0.0;
    else {
      mu_min = ri1->lambda*(1.0+3.0*DBL_EPSILON);
      if(mu_min<0.0) mu_min = 0.0;
    }
    if(mu_min<mu_max) {
      double fx;
      mu=minimum(mu_min,mu_max,equ,fx);
      if(try_stat_point(graph_info,solver_info,mu,x,y)) result = true;
      if(fx<0.0) {
        if(try_stat_point(graph_info,solver_info,root(mu_min,mu,equ),x,y))
          result = true;

        if(try_stat_point(graph_info,solver_info,root(mu,mu_max,equ),x,y))
          result = true;
      }
    }
  }
  return result;
}

bool try_deg_points (
  MaxCliqueInfo& graph_info, QualexInfo& solver_info, Equation& equ,
  double* x, double* y
) {
  bool result = false;
  int& n = graph_info.g.n;
  double* x1 = new double[n];
  vector<EigenCluster>::reverse_iterator ri;
  for(ri=solver_info.degenerative_clusters.rbegin();ri<solver_info.degenerative_clusters.rend();ri++) {
    double mu = ri->lambda;
    if(mu<graph_info.w_min/2.0) break;
    double r2 = equ.rhs;
    vector<EigenCluster>::iterator ii;
    int i;
    for(ii=solver_info.active_clusters.begin();ii<solver_info.active_clusters.end();ii++) {
      for(i=ii->first;i<ii->last;i++) r2 -= sqr(y[i] = solver_info.c[i]/(mu-solver_info.lambda[i]));
    }
    if(r2>0.0) {
      r2 = sqrt(r2);
      matrix_dot_vector(n,solver_info.k,solver_info.q,'N',y,x1);
      for(int j=ri->first;j<ri->last;j++) {
        double* qj = solver_info.q+(j*n);
        for(i=0;i<n;i++) x[i] = (x1[i]+qj[i]*r2+graph_info.shift[i])*graph_info.sqrtw[i];
        if(refine_clique_MIN(graph_info,x)) result = true;

        for(i=0;i<n;i++) x[i] = (x1[i]-qj[i]*r2+graph_info.shift[i])*graph_info.sqrtw[i];
        if(refine_clique_MIN(graph_info,x)) result = true;
      }
    }
  }
  delete[] x1;
  return result;
}

bool qualex_ms(MaxCliqueInfo& graph_info, double* a) {
  QualexInfo solver_info;
  if(!init_projected_formulation(graph_info,a,solver_info)) return false;
  Equation equ (
    solver_info.active_clusters,
    1.0/(graph_info.lower_clique_bound+graph_info.w_min)-1.0/graph_info.W );
  double* x = new double[graph_info.g.n];
  double* y = new double[solver_info.k];
  memset(y,0,sizeof(double)*solver_info.k);
  bool result = (solver_info.active_clusters.empty() ? false :
    try_nondeg_points(graph_info, solver_info, equ, x, y) );
  result |= try_deg_points(graph_info, solver_info, equ, x, y);
  delete[] y;
  delete[] x;
  return result;
}
