/***********************************************************************
!! Auxiliary one-dimensional numerical templates                      !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000, 2001. All rights reserved.  !!
***********************************************************************/

#ifndef _1D_MATH_H
#define _1D_MATH_H

#include <float.h>
#include <math.h>

// root() finds a root of a monotone function f(x) on interval [a; b]
// f should have double operator()
template<class Function>
double root(double a,double b,Function& f){
  double c=a;
  double fa=f(a);
  double fb=f(b);
  double fc=fa;
  do{
    double d1=b-a;
    if(fabs(fc)<fabs(fb)){
      a=b;b=c;c=a;
      fa=fb;fb=fc;fc=fa;
    }
    double d2=(c-b)/2.0;
    double eps=DBL_EPSILON*(2.0*fabs(b)+0.5);
    if(fabs(d2)<=eps||!fb)return b;
    if(fabs(d1)>=eps&&fabs(fa)>fabs(fb)){
      double p,q;
      double cb=c-b;
      double t1=fb/fa;
      if(a==c){
        p=cb*t1;
        q=1.0-t1;
      }else{
        double t2=fb/fc;
        q=fa/fc;
        p=t1*(cb*q*(q-t2)-(b-a)*(t2-1.0));
        q=(q-1.0)*(t1-1.0)*(t2-1.0);
      }
      if(p>0.0)q=-q;
      else p=-p;
      if(2.0*p<1.5*cb*q-fabs(eps*q)&&2.0*p<fabs(d1))d2=p/q;
    }
    if(fabs(d2)<eps)d2=(d2>0.0?eps:-eps);
    a=b;
    fa=fb;
    b+=d2;
    fb=f(b);
    if(fb>0.0&&fc>0.0||fb<0.0&&fc<0.0){
      c=a;
      fc=fa;
    }
  }while(true);
}

const double fi=(3.0-sqrt(5.0))/2.0;
const double sqrt_eps=sqrt(DBL_EPSILON);

// minimum() finds the minimum of a unimodal function f(x) on interval [a; b]
// f should have double operator()
// returns the value of argument providing the minimum
// fx will be the minimum value itself
template<class Function>
double minimum(double a,double b,Function& f,double& fx){
  double v=a+fi*(b-a);
  double fv=f(v);
  double x=v;
  fx=fv;
  double w=v;
  double fw=fv;
  do{
    double range=b-a;
    double midpoint=(a+b)/2.0;
    double eps=sqrt_eps*fabs(x)+DBL_EPSILON/3.0;
    if(2.0*fabs(x-midpoint)+range<=4.0*eps)return x;
    double d=fi*(x<midpoint?b-x:a-x);
    if(fabs(x-w)>=eps){
      double t=(x-w)*(fx-fv);
      double q=(x-v)*(fx-fw);
      double p=(x-v)*q-(x-w)*t;
      q=2.0*(q-t);
      if(q>0.0)p=-p;
      else q=-q;
      if(fabs(p)<fabs(d*q)&&p>q*(a-x+2.0*eps)&&p<q*(b-x-2.0*eps))d=p/q;
    }
    if(fabs(d)<eps)d=(d>0?eps:-eps);
    double t=x+d;
    double ft=f(t);
    if(ft<=fx){
      (t<x?b:a)=x;
      v=w;w=x;x=t;
      fv=fw;fw=fx;fx=ft;
    }else{
      (t<x?a:b)=t;
      if(ft<=fw||w==x){
        v=w;w=t;
        fv=fw;fw=ft;
      }else if(ft<=fv||v==x||v==w){
        v=t;fv=ft;
      }
    }
  }while(true);
}

#endif  // _1D_MATH_H
