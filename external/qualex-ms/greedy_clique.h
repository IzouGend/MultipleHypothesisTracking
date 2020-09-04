/***********************************************************************
!! greedy_clique.cc contains the implementation of basic greedy       !!
!! algorithms for maximum weight clique finding.                      !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2001-2007. All rights reserved.   !!
!!                                                                    !!
!! This is greedy_clique header.                                      !!
***********************************************************************/

#ifndef GREEDY_CLIQUE_H
#define GREEDY_CLIQUE_H

#include <vector>
#include <list>
#include "graph.h"

using namespace std;

void neighborhood_weights(Graph& g, double* vert_weights, double* neigh_weights);

void greedy_clique (
  Graph& g, vector<int> act_verts, double* vert_weights,
  double* neigh_weights, list<int>& clique
);

bool meta_greedy_clique(MaxCliqueInfo& graph_info);

bool meta_greedy_clique(MaxCliqueInfo& graph_info, double* a);

#endif  // GREEDY_CLIQUE_H
