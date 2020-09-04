#ifndef COMP_DOUBLE_H
#define COMP_DOUBLE_H

#include <functional>

using namespace std;

struct less_double:public binary_function<int,int,bool> {
  double* x;
  less_double(double* _x): x(_x) {}
  bool operator()(const int i, const int j) const { return x[i]<x[j]; }
};

struct greater_double:public binary_function<int,int,bool> {
  double* x;
  greater_double(double* _x): x(_x) {}
  bool operator()(const int i, const int j) const { return x[i]>x[j]; }
};

#endif	// COMP_DOUBLE_H
