/***************************************************************************
 *   cameraModel.cpp   - description
 *
 *   This program is part of the Etiseo project.
 *
 *   See http://www.etiseo.net  http://www.silogic.fr
 *
 *   (C) Silogic - Etiseo Consortium
 *   Modified by Anton Andriyenko
 ***************************************************************************/

#include "mex.h"
#include <math.h>

void undistortedToDistortedSensorCoord(double Xu, double Yu, double *Xd, double *Yd, double mKappa1) {
    double Ru;
    double Rd;
    double lambda;
    double c;
    double d;
    double Q;
    double R;
    double D;
    double S;
    double T;
    double sinT;
    double cosT;
    
    if (((Xu == 0) && (Yu == 0)) || (mKappa1 == 0)) {
        *Xd = Xu;
        *Yd = Yu;
    }
    else {
        Ru = sqrt(Xu*Xu + Yu*Yu);
        
        c = 1.0 / mKappa1;
        d = -c * Ru;
        
        Q = c / 3;
        R = -d / 2;
        D = Q*Q*Q + R*R;
        
        if (D >= 0) {
            /* one real root */
            D = sqrt(D);
            if (R + D > 0) {
                S = pow(R + D, 1.0/3.0);
            }
            else {
                S = -pow(-R - D, 1.0/3.0);
            }
            
            if (R - D > 0) {
                T = pow(R - D, 1.0/3.0);
            }
            else {
                T = -pow(D - R, 1.0/3.0);
            }
            
            Rd = S + T;
            
            if (Rd < 0) {
                Rd = sqrt(-1.0 / (3 * mKappa1));
                /*fprintf (stderr, "\nWarning: undistorted image point to distorted image point mapping limited by\n");
                 * fprintf (stderr, "         maximum barrel distortion radius of %lf\n", Rd);
                 * fprintf (stderr, "         (Xu = %lf, Yu = %lf) -> (Xd = %lf, Yd = %lf)\n\n", Xu, Yu, Xu * Rd / Ru, Yu * Rd / Ru);*/
            }
        }
        else {
            /* three real roots */
            D = sqrt(-D);
            S = pow( sqrt(R*R + D*D) , 1.0/3.0 );
            T = atan2(D, R) / 3;
            sinT = sin(T);
            cosT = cos(T);
            
            /* the larger positive root is    2*S*cos(T)                   */
            /* the smaller positive root is   -S*cos(T) + SQRT(3)*S*sin(T) */
            /* the negative root is           -S*cos(T) - SQRT(3)*S*sin(T) */
            
            Rd = -S * cosT + sqrt(3.0) * S * sinT;	/* use the smaller positive root */
        }
        
        lambda = Rd / Ru;
        
        Xd[0] = Xu * lambda;
        Yd[0] = Yu * lambda;
    }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    
    /* /Declarations */
    const mxArray *Dpxdata, *Dpydata, *Sxdata, *Cxdata, *Cydata, *Xwdata, *Ywdata, *Zwdata, *focaldata, *kappadata, \
            *mRdata, *mTdata;
    
    double mDpx, mDpy, mSx, *Xw, *Yw, *Zw, focal, kappa, \
            mR11, mR12, mR13, mR21, mR22, mR23, mR31, mR32, mR33, \
            mTx, mTy, mTz, mCx, mCy;
    
    double xc;
    double yc;
    double zc;
    double Xu;
    double Yu;
    double Xd[1];
    double Yd[1];
    double xw, yw, zw;
    int F, N;
    
    double *Xi, *Yi;
    int i, j, ind;
        
    double *mR, *mT;
    
    /* //Copy input pointer x */
    Xwdata = prhs[0];
    Ywdata = prhs[1];
    Zwdata = prhs[2];
    Dpxdata = prhs[3];
    Dpydata = prhs[4];
    Sxdata = prhs[5];
    Cxdata = prhs[6];
    Cydata = prhs[7];
    focaldata = prhs[8];
    kappadata = prhs[9];
    mRdata = prhs[10];
    mTdata = prhs[11];
    
    mDpx = (double)(mxGetScalar(Dpxdata));
    mDpy = (double)(mxGetScalar(Dpydata));
    mSx = (double)(mxGetScalar(Sxdata));
    Xw = mxGetPr(Xwdata);
    Yw = mxGetPr(Ywdata);
    Zw = mxGetPr(Zwdata);
    focal = (double)(mxGetScalar(focaldata));
    kappa = (double)(mxGetScalar(kappadata));
    mCx = (double)(mxGetScalar(Cxdata));
    mCy = (double)(mxGetScalar(Cydata));
    

    mR = mxGetPr(mRdata);
    mT = mxGetPr(mTdata);
    
    mR11 = mR[0];
    mR12 = mR[3];
    mR13 = mR[6];
    mR21 = mR[1];
    mR22 = mR[4];
    mR23 = mR[7];
    mR31 = mR[2];
    mR32 = mR[5];
    mR33 = mR[8];
    mTx = mT[0];
    mTy = mT[1];
    mTz = mT[2];
    
    /* //Get number of frames and targets */
    F = mxGetN(Xwdata);
    N = mxGetM(Xwdata);
    
    
    /* Allocate memory and assign output pointer */
    plhs[0] = mxCreateDoubleMatrix(N, F, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(N, F, mxREAL);
    
    /*//Get a pointer to the data space in our newly allocated memory */
    Xi = mxGetPr(plhs[0]);
    Yi = mxGetPr(plhs[1]);
    
    /* */
    for(i=0;i<F;i++) {
        for(j=0;j<N;j++) {
            ind=(i*N)+j;
            if (Xw[ind] != 0){
                xw=Xw[ind];yw=Yw[ind];zw=Zw[ind];
                /* convert from world coordinates to camera coordinates */
                xc = mR11 * xw + mR12 * yw + mR13 * zw + mTx;
                yc = mR21 * xw + mR22 * yw + mR23 * zw + mTy;
                zc = mR31 * xw + mR32 * yw + mR33 * zw + mTz;
                
                /* convert from camera coordinates to undistorted sensor plane coordinates */
                Xu = focal * xc / zc;
                Yu = focal * yc / zc;
                
                /* convert from undistorted to distorted sensor plane coordinates */
                undistortedToDistortedSensorCoord(Xu, Yu, Xd, Yd, kappa);
                
                /* convert from distorted sensor plane coordinates to image coordinates */
                Xi[ind] = Xd[0] * mSx / mDpx + mCx;
                Yi[ind] = Yd[0] / mDpy + mCy;
                
            }
            
        }
    }
    
    return;
}