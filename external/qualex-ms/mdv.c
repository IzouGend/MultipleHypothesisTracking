extern double dnrm2_(int*,double*,int*);
extern void dscal_(int*,double*,double*,int*);
extern double ddot_(int*,double*,int*,double*,int*);
extern void dgemv_(char*,int*,int*,double*,double*,int*,double*,int*,double*,double*,int*);
extern void dgemm_(char*,char*,int*,int*,int*,double*,double*,int*,double*,int*,double*,double*,int*);

double norm2(int n, double* x) {
  int inc = 1;
  return dnrm2_(&n,x,&inc);
}

void scaling(int n, double* x, double c) {
  int inc = 1;
  dscal_(&n,&c,x,&inc);
}

double dot_product(int n, double* x, double* y) {
  int inc = 1;
  return ddot_(&n,x,&inc,y,&inc);
}

// a C wrapper for the optimized matrix-vector multiplication by BLAS
// if trans=='N' then y:=A*x; if trans=='T' then y:=A'*x
void matrix_dot_vector(int m,int n,double* a,char trans,double* x,double* y) {
  double alpha=1.0;
  int inc=1;
  double beta=0.0;
  dgemv_(&trans,&m,&n,&alpha,a,&m,x,&inc,&beta,y,&inc);
}

// a C wrapper for the optimized matrix-matrix multiplication by BLAS
// C = transa(A)*transb(B)
void matrix_dot_matrix(int m,int n,int k,double* a,char transa,double* b,char transb,double* c) {
  double alpha=1.0;
  double beta=0.0;
  dgemm_(&transa,&transb,&m,&n,&k,&alpha,a,(transa=='N'?&m:&k),b,(transb=='N'?&k:&n),&beta,c,&m);
}
