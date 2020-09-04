/***********************************************************************
!! refine_clique() provides a maximal clique by a vertex "appealing"  !!
!! vector.                                                            !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! refine_clique() implementation                                     !!
***********************************************************************/

#include <string.h>
#include <algorithm>

#include "bool_vector.h"
#include "greedy_clique.h"
#include "refiner.h"

#include "comp_double.h"
#include "vec_del.h"

using namespace std;

// refine_clique_VO() provides a maximal clique by a vertex
// "appealing" vector x using Vetex Order procedure.
// Returns true if the known clique was improved
bool refine_clique_VO(MaxCliqueInfo& graph_info, double* x) {
  int& n = graph_info.g.n;
  list<int> clique;
  int* sort_nos=new int[n];
  int i;
  for(i=0;i<n;i++) sort_nos[i]=i;
  sort(sort_nos, sort_nos+n, greater_double(x));
  for(int j=0;j<n;j++){
    i=sort_nos[j];
    vector<bool_vector>::iterator mates = graph_info.g.mates.begin()+i;
    for(list<int>::iterator jj=clique.begin();jj!=clique.end();jj++)
      if(!mates->at(*jj)) goto L1;
    clique.push_back(i);
    L1:;
  }
  delete[] sort_nos;
  return graph_info.receive_clique(clique);
}

// refine_clique_MIN() provides a maximal clique of by a vertex
// "appealing" vector x using MIN procedure.
// Returns true if the known clique was improved
bool refine_clique_MIN(MaxCliqueInfo& graph_info, double* x) {
  int& n = graph_info.g.n;
  double* w = new double[n];
  neighborhood_weights(graph_info.g,x,w);
  vector<int> active_vertices(n);
  for(int i=0;i<n;i++) active_vertices[i] = i;
  list<int> clique;
  greedy_clique(graph_info.g,active_vertices,x,w,clique);
  delete[] w;
  return graph_info.receive_clique(clique);
}
