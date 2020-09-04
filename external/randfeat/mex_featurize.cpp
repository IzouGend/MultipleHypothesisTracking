#include <mex.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <string>
#include "mkl_cblas.h"
#include "omp.h"
#include "mkl.h"
#include "mat.h"

/* Don't do the sqrt */
const double SQRT2 = 1.414213562373095;
const double PI = 3.1415926535897932384626;
const int INIT_NPERDIM = 200;

/* This computes sqrt(2) * sqrt(sech) */
inline double sqrtsech(double x)
{
	return 1.0 / sqrt(exp(x) + exp(-x));
}

inline void compute_vedaldi(double *seriesmat, double x, int length, double period, double *objomega, int D)
{
	bool cos_sin_flag = false;
	double periodx = sqrt(period * x);
	double lgx = log(x);
	*seriesmat = periodx;
	seriesmat++;
	length--;
	while(length > 0)
	{
		if (!cos_sin_flag)
			*seriesmat = cos((*objomega) * lgx) * periodx * 2 * sqrtsech(PI * (*objomega));
		else
			*seriesmat = sin((*objomega) * lgx) * periodx * 2 * sqrtsech(PI * (*objomega));
		length--;
		cos_sin_flag = !cos_sin_flag;
		seriesmat++;
		objomega+= D;
	}
}

inline void compute_cseries(double *seriesmat, double x, int length)
{
	double lgxpi = log(x) / PI;
	int odd_even;
	int i;
	*seriesmat = 2.0 * x / (x+1.0);
//	seriesmat[0] = 2.0 * x / (x + 1.0);
	seriesmat[1] = - lgxpi * SQRT2 * seriesmat[0];
	seriesmat += 2;
	for(i=2;i<length;i++,seriesmat++)
	{
		odd_even = (i % 2 == 0)?1:-1;
		*seriesmat =  (odd_even * 2.0 * lgxpi * seriesmat[-1] + (i-2) * seriesmat[-2])/ (double)(i);
	}
}

inline void compute_abseries(double *seriesmat, double x, int length)
{
// Make sure lena + lenb = length
	int lena = floor(float(length)/2.0);
	int lenb = ceil(float(length)/2.0);
	int i;
	double lgx = log(x);
	double sqrtx = sqrt(x);
// Log^2(x)/ Pi^2
	double lgxpi = lgx / PI;
// Log(x) / 4 Pi
	double lgx2 = lgx / (4 * PI);
// 4 * sqrt(2) * sqrt(x) * Log(x) / Pi^2
	double lgxpi2 = 4.0 * SQRT2 * sqrtx * lgxpi / PI;
	lgxpi *= lgxpi;
// Do a series first
	*seriesmat = 2.0 * x / (x + 1.0);
	seriesmat++;
	if (lena > 1)
	{
		*seriesmat = - lgxpi * seriesmat[-1] * SQRT2;
		seriesmat++;
// Use the recurrence relation from k=1
		for(i=1;i+1<lena;i++,seriesmat++)
		{
			int denom = (2 * i + 1) * (i + 1);
			*seriesmat = ((-lgxpi * 2.0 + 4.0 * i * i) * seriesmat[-1] - (2 * i - 1) * (i - 1) * seriesmat[-2])/(double)denom;
		}
	}
// Do b series now, compute b_0
	double b_0 = 0;
	for (i=0;i<100;i++)
		b_0 += (i + 0.5) / ((i + 0.25) * (i+0.25) + lgx2 * lgx2) / ((i + 0.75) * (i+0.75) + lgx2 * lgx2);
	*seriesmat = - b_0 * lgx2 / PI * sqrtx;
	seriesmat++;
	if (lenb > 1)
	{
		*seriesmat = -lgxpi * seriesmat[-1] * SQRT2 - lgxpi2 / 2.0;
		seriesmat++;
		for(i=1;i+1<lenb;i++,seriesmat++)
		{
			int denom = (2 * i + 1) * (i + 1);
			int odd_even = (i % 2 == 0)?1:-1;
			*seriesmat = ((-lgxpi * 2.0 + 4.0 * i * i) * seriesmat[-1] - (2 * i - 1) * (i - 1) * seriesmat[-2] - lgxpi2 * odd_even)/(double)denom;
		}
	}
}

void rf_featurize(double *featmat, double *omegamat, double *beta, double *mat, const char *objname, const char *objmethod, int N, int D, int Napp, double kernel_param, int Nperdim = 0, double period=0.0, double *signalomega = 0)
{
	int i,j;
	clock_t clk1,clk2,clk3,clk4;
	if (!strcmp(objname, "chi2_skewed"))
	{
		double *tempmat = (double *) malloc(sizeof(double)*N*D);
		/* Logit first */
//		clk1 = clock();
		for(i=0;i<D;i++)
			for(j=0;j<N;j++)
				tempmat[i*N+j] = 0.5 * log(featmat[i*N+j] + kernel_param);
//		clk2 = clock();
		/* Tile beta into mat */
		for(i=0;i<Napp;i++)
			for(j=0;j<N;j++)
				mat[i*N+j] = beta[i] * 2.0 * PI;
//		clk3 = clock();
                mkl_set_num_threads(4);
                mkl_set_dynamic(1);
		/* ATLAS matrix multiplication */
		cblas_dgemm(CblasColMajor,CblasNoTrans,CblasNoTrans,N,Napp,D,1,tempmat,N,omegamat,D,1,mat,N);
//		clk4 = clock();
		/* Final cosine and sqrt(2) */
		for(i=0;i<Napp;i++)
			for(j=0;j<N;j++)
				mat[i*N+j] = SQRT2 * cos(mat[i*N+j]);
//		clk5 = clock();
/*		mexPrintf("Time elapsed in phase 1: %.4lf seconds.", (double)(clk2 - clk1)/ CLOCKS_PER_SEC);
		mexPrintf("Time elapsed in phase 2: %.4lf seconds.", (double)(clk3 - clk2)/ CLOCKS_PER_SEC);
		mexPrintf("Time elapsed in phase 3: %.4lf seconds.", (double)(clk4 - clk3)/ CLOCKS_PER_SEC);
		mexPrintf("Time elapsed in phase 4: %.4lf seconds.", (double)(clk5 - clk4)/ CLOCKS_PER_SEC);
*/		free(tempmat);
	}
	else if (!strcmp(objname, "chi2") || !strcmp(objname, "exp_chi2"))
	{
			double *tempmat = (double *) malloc(Nperdim * N * sizeof(double));
			double *temp2 = (double *) malloc(INIT_NPERDIM * N * sizeof(double));
			MATFile *vf;
			mxArray *plhs, *prhs;
			char *path;
			double *vp;
			std::string mex_path;
			int pos;
/* Use N * Napp instead of Napp * N for better referencing, coming back in the end */
/* Tile beta into mat first as initialization (no need to initialize to 0) */
		clk1 = clock();
			for(j=0;j<N;j++)
				for(i=0;i<Napp;i++)
					mat[j*Napp+i] = beta[i] * 2.0 * PI;
		clk2 = clock();
			vf = 0;
			prhs = mxCreateString("mex_featurize");
// Get the directory of the .mexa64 file, which is the same as the V.mat file
			mexCallMATLAB(1,&plhs, 1, &prhs,"which");
			path = mxArrayToString(plhs);
			mex_path = path;
// Linux style, need to work to make this work on windows
			pos = mex_path.find_last_of('/');
			mex_path = mex_path.substr(0,pos+1) + "V.mat";
			mexPrintf((mex_path+"\n").c_str());
			vf = matOpen(mex_path.c_str(),"r");
			if (vf == 0)
			{
				mexPrintf("V.mat not exist! Not using PCA.");
				vp = 0;
			}
			else
				vp = mxGetPr(matGetVariable(vf,"V"));
			for(i=0;i<D;i++)
			{
				for(j=0;j<N;j++)
				{
/* If 0, everything is 0 because there's a sqrt(x) in the fourier feature, so no need to do anything */
					if (featmat[i*N+j])
					{
						if(!strcmp(objmethod,"chebyshev"))
							if (vp)
								compute_cseries(&temp2[j*INIT_NPERDIM], featmat[i*N+j], INIT_NPERDIM);
							else
								compute_cseries(&tempmat[j*Nperdim], featmat[i*N+j], Nperdim);
						else if(!strcmp(objmethod,"signals"))
							compute_vedaldi(&tempmat[j*Nperdim], featmat[i*N+j], Nperdim, period, &signalomega[i], D);
						else
						{
							mexPrintf("Unknown approximation method.");
							return;
						}
					}
					else
					{
						if(!strcmp(objmethod,"chebyshev") && vp)
							memset(&temp2[j*INIT_NPERDIM],0,sizeof(double) * INIT_NPERDIM);
						else
							memset(&tempmat[j*Nperdim],0,sizeof(double) * Nperdim);
					}
				}
				if(!strcmp(objmethod,"chebyshev") && vp)
					cblas_dgemm(CblasColMajor, CblasTrans, CblasNoTrans, Nperdim, N, INIT_NPERDIM, 1.0, vp, INIT_NPERDIM, temp2, INIT_NPERDIM, 0, tempmat, Nperdim);
				cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, Napp,N,Nperdim, 1.0, &omegamat[i*Nperdim*Napp], Napp, tempmat, Nperdim, 1.0, mat, Napp);
			}
		clk3 = clock();
			/* Final cosine and sqrt(2) */
			for(i=0;i<Napp * N;i++)
				mat[i] = SQRT2 * cos(mat[i]);
		clk4 = clock();
		mexPrintf("CPU Time elapsed in phase 1: %.4lf seconds.\n", (double)(clk2 - clk1)/ CLOCKS_PER_SEC);
		mexPrintf("CPU Time elapsed in phase 2: %.4lf seconds.\n", (double)(clk3 - clk2)/ CLOCKS_PER_SEC);
		mexPrintf("CPU Time elapsed in phase 3: %.4lf seconds.\n", (double)(clk4 - clk3)/ CLOCKS_PER_SEC);
		if(tempmat)
			free(tempmat);
		if(temp2)
			free(temp2);
		tempmat = 0;
		temp2 = 0;
	}
	else
	{
		mexPrintf("Unknown kernel approximation scheme.");
		return;
	}
}
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mxArray *obj, *features, *omega;
	int Napp;
	int N, D;
	double objdim;
	double *featmat, *omegamat;
	clock_t clk1,clk2,clk3,clk4,clk5;
	if (nrhs < 2)
	{
		mexPrintf("rf_featurize expects at least two arguments, the RF object and the input features.");
		return;
	}
	obj = prhs[0];
	features = prhs[1];
	if (mxGetClassID(features) != mxDOUBLE_CLASS)
	{
		mexPrintf("To use the MEX version of rf_featurize, the input features must be double.");
		return;
	}
	featmat = mxGetPr(features);
	D = mxGetN(features);
	N = mxGetM(features);
	if (nrhs >= 3)
		Napp = (int)(mxGetPr(prhs[2])[0]);

	char objname[255];
	char objmethod[255];
	if (mxGetString(mxGetField(obj,0,"name"),objname,255))
	{
		mexPrintf("Unknown kernel approximation scheme.");
		return;
	}
	if (mxGetString(mxGetField(obj,0,"method"),objmethod,255))
	{
		mexPrintf("Unknown approximation method.");
		return;
	}
/* If not period, look for omega */
	if (strcmp(objmethod,"signals"))
	{
		if (!strcmp(objname,"exp_chi2"))
			omega = mxGetField(obj,0,"omega2");
		else
			omega = mxGetField(obj,0,"omega");
		if (nrhs >= 3 && Napp > mxGetM(omega))
		{
			mexPrintf("Warning: selected number of random features %d more than built-in number of random features %d",Napp, int(mxGetN(omega)));
			Napp = mxGetM(omega);
		}
		if (nrhs < 3)
			Napp = mxGetM(omega);
	}
	else
	{
		mxArray *temp;
		double *t1;
		temp = mxGetField(obj,0,"Napp");
		if (nrhs < 3)
			Napp = (int)(mxGetPr(temp)[0]);
		if (!strcmp(objname,"exp_chi2"))
			omega = mxGetField(obj,0,"omega2");
	}
	objdim = mxGetPr(mxGetField(obj,0,"dim"))[0];
	if (objdim != D)
	{
		mexPrintf("Dimension in the RF object mismatch with the features.");
		return;
	}
	
	omegamat = mxGetPr(omega);

	plhs[0] = mxCreateDoubleMatrix(Napp,N,mxREAL);
	double *mat = mxGetPr(plhs[0]);
	
	double kernel_param, Nperdim, period;
	double *signalomega;
	
	if (mxGetField(obj,0,"kernel_param") == 0)
		kernel_param = 0;
	else
		kernel_param = *mxGetPr(mxGetField(obj,0,"kernel_param"));
/* If not sampling, we need Nperdim */
	if (strcmp(objmethod,"sampling") && mxGetField(obj,0,"Nperdim"))
		Nperdim = *mxGetPr(mxGetField(obj,0,"Nperdim"));
	else
		Nperdim = 0;
/* If it's signals, we need Period */
	if (!strcmp(objmethod,"signals"))
	{
		period = *mxGetPr(mxGetField(obj,0,"period"));
		signalomega = mxGetPr(mxGetField(obj,0,"omega"));
	}
	else
		period = 0;
	double *beta = mxGetPr(mxGetField(obj,0,"beta"));

	rf_featurize(featmat, omegamat, beta, mat, objname, objmethod, N, D, Napp, kernel_param, Nperdim, period, signalomega);
	featmat = 0;
	omegamat = 0;
	beta = 0;
	signalomega = 0;
	mat = 0;
	obj = 0;
	features = 0;
	omega = 0;
}
