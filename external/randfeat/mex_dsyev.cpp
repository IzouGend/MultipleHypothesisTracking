#include <mex.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <string>
#include "mkl_lapack.h"
#include "omp.h"
#include "mkl.h"
#include "mat.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray *mat;
	MKL_INT D1,D2, lwork, info;
	double objdim;
	double *hesmat;
	double wkopt;
	double *work;
	if (nrhs < 1)
	{
		mexPrintf("mex_dsyev expects a symmetric matrix as input.");
		return;
	}
	mat = prhs[0];
	D1 = mxGetN(mat);
	D2 = mxGetM(mat);
	if (D1 != D2)
	{
		mexPrintf("mex_dsyev only works on symmetric matrices.");
		return;
	}
	if (mxGetClassID(mat) != mxDOUBLE_CLASS)
	{
		mexPrintf("To use the mex_dsyev, the matrix must be double.");
		return;
	}

	plhs[0] = mxDuplicateArray(mat);
	double *eigmat = mxGetPr(plhs[0]);

	plhs[1] = mxCreateDoubleMatrix(D1,1,mxREAL);
	double *eigvalmat = mxGetPr(plhs[1]);

	lwork = -1;	

	dsyev("Vectors", "Upper", &D1, eigmat, &D2, eigvalmat, &wkopt, &lwork, &info);

	lwork = (int)wkopt;
	work = (double *) malloc(lwork * sizeof(double));
	if (!work)
	{
		mexPrintf("Out of memory. Unable to allocate working space for eigenvalues");
		return;
	}

	dsyev("Vectors", "Upper", &D1, eigmat, &D2, eigvalmat, work, &lwork, &info);

	eigmat = 0;
	if (nlhs > 1)
		eigvalmat = 0;
	hesmat = 0;
	mat = 0;
	free(work);
	work = 0;
}
