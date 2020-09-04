#include <stdlib.h>

extern void dsyevr_(char*,char*,char*,int*,double*,int*,double*,double*,int*,int*,double*,int*,double*,double*,int*,int*,double*,int*,int*,int*,int*);

// a C wrapper of the LAPACK routine DSYEVR constructing
// the eigendecomposition of a real symmetric matrix.
// This routine involves Relatively Robust Representations (RRR)
// to compute eigenpairs after the matrix is reduced to a tridiagonal
// form. For more details, see "A new O(n^2) algorithm for the symmetric
// tridiagonal eigenvalue/eigenvector problem", by Inderjit Dhillon,
//  Computer Science Division Technical Report No. UCB//CSD-97-971,
//  UC Berkeley, May 1997.
int symmetric_eigen(int n,double* a,double* lambda,double* q) {
  char jobz = 'V';
  char range = 'A';
  char uplo = 'U';
  double vl=0.0, vu=0.0;
  int il=0, iu=0;
  double abstol=0.0;
  int m;
  int* isuppz = (int*)calloc(2*n,sizeof(int));
  int lwork = -1;
  double work_size;
  int liwork = -1;
  int iwork_size;
  int info;
  double* work;
  int* iwork;

  dsyevr_(&jobz,&range,&uplo,&n,a,&n,&vl,&vu,&il,&iu,&abstol,&m,lambda,q,&n,isuppz,&work_size,&lwork,&iwork_size,&liwork,&info);
  lwork = work_size;
  liwork = iwork_size;
  work = (double*)calloc(lwork,sizeof(double));
  iwork = (int*)calloc(liwork,sizeof(int));
  dsyevr_(&jobz,&range,&uplo,&n,a,&n,&vl,&vu,&il,&iu,&abstol,&m,lambda,q,&n,isuppz,work,&lwork,iwork,&liwork,&info);

  free(iwork);
  free(work);
  free(isuppz);

  return info;
}
