/***********************************************************************
!! preproc_clique() preprocesses a graph for maximum weight clique    !!
!! finding.                                                           !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2001, 2002. All rights reserved.  !!
!!                                                                    !!
!! preproc_clique() header                                            !!
***********************************************************************/

#ifndef PREPROC_CLIQUE_H
#define PREPROC_CLIQUE_H

#include <vector>
#include <list>

#include "graph.h"

using namespace std;

// preproc_clique() preprocesses a graph for maximum weight clique finding.
// Each vertex disconnected only with a subset weighting not more than it
// becomes preselected. On the base of MIN heuristic result, too low
// connected vertices are removed.
// It returns in the corresponding parameters: the residual set of graph
// vertices to submit to a next maximum weight clique routine, the
// preselected vertex set, the discovered lower bound of maximum weight
// clique and a clique giving this bound itself. The function result is
// the total weight of preselected vertices.
double preproc_clique (
  Graph& g, vector<int>& residual, list<int>& preselected,
  double& known_bound, list<int>& clique
);

#endif  // PREPROC_CLIQUE_H
