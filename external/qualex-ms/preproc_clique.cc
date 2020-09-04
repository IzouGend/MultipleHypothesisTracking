/***********************************************************************
!! preproc_clique() preprocesses a graph for maximum weight clique    !!
!! finding.                                                           !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2001, 2002. All rights reserved.  !!
!!                                                                    !!
!! preproc_clique() implementation                                    !!
***********************************************************************/

#include <float.h>

#include "bool_vector.h"
#include "graph.h"
#include "greedy_clique.h"
#include "preproc_clique.h"
#include "vec_del.h"

// preproc_clique() preprocesses a graph for maximum weight clique finding.
// Each vertex disconnected only with a subset weighting not more than it
// becomes preselected. On the base of MIN heuristic result, too low
// connected vertices are removed.
// It returns in the corresponding parameters: the residual set of graph
// vertices to submit to a next maximum weight clique routine, the
// preselected vertex set, the discovered lower bound of maximum weight
// clique and a clique giving this bound itself. The function result is
// the total weight of preselected vertices.
double preproc_clique (
  Graph& g, vector<int>& residual, list<int>& preselected,
  double& known_bound, list<int>& clique
) {
  int& n=g.n;
  double* w = new double[n];
  neighborhood_weights(g,&(g.weights[0]),w);
  residual.resize(n);
  int i,j;
  for(i=0;i<n;i++) residual[i] = i;
  bool_vector remove_flag(n);

  double result = 0.0;
  list<int> consider;
  bool_vector considered_flag(n);
  bool reduction_flag;
  list<int>::iterator pc;
  known_bound = 0.0;
  do {
    reduction_flag = false;
    clique.erase(clique.begin(),clique.end());
    greedy_clique(g,residual,&(g.weights[0]),w,clique);
    double clique_weight = 0.0;
    for(pc=clique.begin();pc!=clique.end();pc++)
      clique_weight += g.weights[*pc];
    if(clique_weight <= known_bound) break;
    known_bound = clique_weight;
    vector<int>::iterator ii;
    for(ii=residual.begin();ii<residual.end();ii++) {
      i = *ii;
      considered_flag.clear(i);
      consider.push_front(i);
    }
    while(!consider.empty()) {
      do {
        i = consider.front();
        consider.pop_front();
        considered_flag.put(i);
        if(w[i] < known_bound*(1.0-DBL_EPSILON)) {
          vec_del(residual,i);
          remove_flag.put(i);
          bit_iterator bi(g.mates[i]);
          while((j=bi.next())>-1) {
            if(!remove_flag.at(j)) {
              w[j] -= g.weights[i];
              if(considered_flag.at(j)) {
                considered_flag.clear(j);
                consider.push_back(j);
              }
            }
          }
          reduction_flag = true;
        }
      } while(!consider.empty());
      double total_weight = 0.0;
      for(ii=residual.begin();ii<residual.end();ii++)
        total_weight += g.weights[*ii];
      for(ii=residual.end()-1;ii>=residual.begin();ii--) {
        i = *ii;
        double weight_i = g.weights[i];
        if(g.weights[i]*(1.0+3.0*DBL_EPSILON) >= total_weight - w[i]) {
          known_bound -= weight_i;
          if(known_bound < 0.0) known_bound = 0.0;
          vector<bool_vector>::iterator mates_i = g.mates.begin()+i;
          vector<int>::iterator jj;
          for(jj=residual.begin();jj<residual.end();jj++) {
            j = *jj;
            if(!mates_i->at(j) && considered_flag.at(j)) {
              w[j] = -1.0;
              considered_flag.clear(j);
              consider.push_back(j);
            }
          }
          clique.erase(clique.begin(),clique.end());
          preselected.push_back(i);
          result += weight_i;
        }
      }
    }
  } while(reduction_flag && !residual.empty());
  delete[] w;
  for(i=n-1;i>=0;i--) if(remove_flag.at(i)) g.remove_vertex(i);
  return result;
}
