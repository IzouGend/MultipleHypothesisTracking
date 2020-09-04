/***********************************************************************
!! Graph holds an undirected graph, its fundamental properties, and   !!
!! provides methods operating with them.                              !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! Graph header                                                       !!
***********************************************************************/

#ifndef GRAPH_H
#define GRAPH_H

#include <stdio.h>
#include <vector>
#include <list>

#include "bool_vector.h"

using namespace std;

struct Graph {
  char* header; // a text describing the graph
  int n;  // number of vertices
  vector<double> weights; // vector of vertex weights
  vector<bool_vector> mates;  // adjacency matrix

  // Graph constructor by a given number of vertices: creates edgeless graph
  Graph(int _n): header(NULL), n(_n), weights(_n, 1.0), mates(_n, _n){}

  // Graph loading constructor:
  // name -- a DIMACS graph file name
  // weights_name -- a name of file containing a list of vertex weights
  //    (all weights will be 1 if NULL)
  // complement -- a flag pointing if the original or the complementary graph is needed
  Graph(const char* name, const char* weights_name, bool complement);

  // Graph destructor
  ~Graph() { if(header!=NULL) delete[] header; }

  // method add_vertex() inserts vertex with number u and with a given weight
  void add_vertex(int u, double weight);

  // method remove_vertex() removes vertex with number u
  void remove_vertex(int u);

  // method add_edge() adds an edge between vertex u and vertex v
  void add_edge(int u, int v) {
    mates[u].put(v);
    mates[v].put(u);
  }

  // method remove_edge() removes an edge between vertex u and vertex v
  void remove_edge(int u, int v) {
    mates[u].clear(v);
    mates[v].clear(u);
  }

  // method get_vertex_mates(int, vector<int>&) provides the neighborhood set
  // of vertex u in the whole graph
  void get_vertex_mates(int u, vector<int>& vertex_mates);

  // method get_vertex_mates(vector<int>&, int, vector<int>&) provides
  // the neighborhood set of vertex u in the subgraph induced by
  // an active vertex set (must be sorted)
  void get_vertex_mates(vector<int>& active, int u, vector<int>& vertex_mates);

  // method create_subgraph() constructs the subgraph induced by
  // an active vertex set (must be sorted)
  Graph* create_subgraph(vector<int>& active);
};

struct MaxCliqueInfo {
  Graph& g;  // the considered graph
  bool for_clique;  // shows if we are looking for omega_w or alpha_w of the complementary graph

  double lower_clique_bound;  // omega_w(G) >= lower_clique_bound
  list<int> clique;  // the heaviest known clique

  double w_min;   // the smallest vertex weight present in the graph
  double W;       // the total weight of all vertices
  double* sqrtw;  // square roots of the vertex weights
  double* shift;  // the point sqrtw/W

  // MaxCliqueInfo constructor:
  // _g -- the graph to find a maximum weight clique
  // _for_clique -- omega_w vs alpha_w of the complementary graph
  MaxCliqueInfo(Graph& _g, bool _for_clique);

  // MaxCliqueInfo destructor
  ~MaxCliqueInfo() {
    delete[] sqrtw;
    delete[] shift;
  }

  // method print_update() outputs obtained info on max-weight clique
  void print_update() {
    printf("%s_w >= %lg\r", for_clique?"omega":"alpha", lower_clique_bound);
  }

  // method receive_clique() calculates the total weight of a provided
  // maximal clique and stores it if the weight is greater than
  // the currently known (returning true at that)
  bool receive_clique(list<int>& new_clique);
};

#endif  // GRAPH_H
