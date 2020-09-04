#ifndef VEC_DEL_H
#define VEC_DEL_H

#include <vector>
#include <algorithm>

using namespace std;

template<class T>
inline void vec_del(vector<T>& x, T value){
  x.erase(lower_bound(x.begin(),x.end(),value));
}

#endif  // VEC_DEL_H
