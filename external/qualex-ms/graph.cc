/***********************************************************************
!! Graph holds an undirected graph, its fundamental properties, and   !!
!! provides methods operating with them.                              !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! Graph implementation                                               !!
***********************************************************************/

#include <math.h>
#include <string.h>
#include <algorithm>

#include "graph.h"

#define ADDRESS(I) ((I>>3)+1)*((I>>3)*4+(I&7L))

// dimacs_get_params() reads DIMACS header to set
// the number of vertices and number of edges
void dimacs_get_params(char* preamble, int& n, int& m) {
  char c;
  char *pp = preamble;
  int stop = 0;
  char *tmp = new char[64];

  n = m = 0;

  while (!stop && (c = *pp++) != '\0'){
    switch (c)
      {
      case 'c':
        while ((c = *pp++) != '\n' && c != '\0');
        break;

      case 'p':
        sscanf(pp, "%s %d %d\n", tmp, &n, &m);
        stop = 1;
        break;

      default:
        break;
      }
  }

  delete[] tmp;
}

// dimacs_get_edge() checks is there edge (i,j) (i>j) in a DIMACS bitmap.
// Returns true if yes and false otherwise
inline bool dimacs_get_edge(const unsigned char* bitmap, int i, int j) {
  return bitmap[ADDRESS(i) + (j>>3)] & (1U << (7-(j&7)));
}

// Graph loading constructor:
// name -- a DIMACS graph file name
// weights_name -- a name of file containing a list of vertex weights
//    (all weights will be 1 if NULL)
// complement -- a flag pointing is an original or the complementary graph needed
Graph::Graph(const char* name, const char* weights_name, bool complement) {
  FILE* graph_file = fopen(name,"rb");
  if(graph_file==NULL) {
    printf("ERROR: Cannot open infile %s\n", name);
    throw(0);
  }

  int pr_len;
  if(!fscanf(graph_file, "%d\n", &pr_len)) {
    printf("ERROR: Corrupted preamble %s\n", name);
    throw(1);
  }

  header = new char[pr_len+1];
  fread(header, 1, pr_len, graph_file);
  header[pr_len] = '\0';
  int m;
  dimacs_get_params(header, n, m);
  if(n==0) {
    printf("ERROR: Corrupted preamble %s\n", name);
    throw(2);
  }

  int bmp_size = ADDRESS(n);
  unsigned char* bitmap = new unsigned char[bmp_size];
  fread(bitmap, 1, bmp_size, graph_file);
  fclose(graph_file);

  int i;
  weights.resize(n,1.0);
  if(weights_name!=NULL) {
    FILE* weight_file = fopen(weights_name,"r");
    for(i=0;i<n;i++) {
      if(fscanf(weight_file,"%lg",&weights[i])<=0) break;
    }
    fclose(weight_file);
  }

  mates.resize(n,n);
  for(i=1;i<n;i++) for(int j=0;j<i;j++)
    if(dimacs_get_edge(bitmap,i,j)!=complement) add_edge(i,j);
  delete[] bitmap;
}

// method add_vertex() inserts vertex with number u and with a given weight
void Graph::add_vertex(int u, double weight) {
  n++;
  weights.insert(weights.begin()+u, weight);
  vector<bool_vector>::iterator i;
  for(i=mates.begin(); i<mates.end(); i++) i->insert(u);
  mates.insert(mates.begin()+u, n);
}

// method remove_vertex() removes vertex with number u
void Graph::remove_vertex(int u) {
  n--;
  weights.erase(weights.begin()+u);
  mates.erase(mates.begin()+u);
  vector<bool_vector>::iterator i;
  for(i=mates.begin(); i<mates.end(); i++) i->erase(u);
}

// method get_vertex_mates(int, vector<int>&) provides the neighborhood set
// of vertex u in the whole graph
void Graph::get_vertex_mates(int u, vector<int>& vertex_mates) {
  vector<bool_vector>::iterator ii=mates.begin()+u;
  bit_iterator i(*ii);
  int j;
  while((j=i.next())>-1)vertex_mates.push_back(j);
}

// method get_vertex_mates(vector<int>&, int, vector<int>&) provides
// the neighborhood set of vertex u in the subgraph induced by
// an active vertex set (must be sorted)
void Graph::get_vertex_mates(vector<int>& active, int u, vector<int>& vertex_mates) {
  vector<bool_vector>::iterator ii=mates.begin()+u;
  bit_iterator i(*ii);
  int j;
  while((j=i.next())>-1) {
    vector<int>::iterator p=lower_bound(active.begin(), active.end(), j);
    if(p<active.end() && *p == j) vertex_mates.push_back(j);
  }
}

// method create_subgraph() constructs the subgraph induced by
// an active vertex set (must be sorted)
Graph* Graph::create_subgraph(vector<int>& active){
  int k=active.size();
  Graph* subgraph=new Graph(k);
  for(int ii=0; ii<k; ii++) {
    int i=active[ii];
    subgraph->weights[ii]=weights[i];
    vector<bool_vector>::iterator bi=mates.begin()+i;
    for(int jj=0; jj<ii; jj++) {
      if(bi->at(active[jj]))subgraph->add_edge(ii,jj);
    }
  }
  return subgraph;
}

// MaxCliqueInfo constructor:
// _g -- the graph to find a maximum weight clique
// _for_clique -- omega_w vs alpha_w of the complementary graph
MaxCliqueInfo::MaxCliqueInfo(Graph& _g, bool _for_clique): g(_g), for_clique(_for_clique) {
  int& n=g.n;

  sqrtw = new double[n];
  shift = new double[n];
  w_min = g.weights[0];
  W = 0.0;
  int i;
  for(i=0;i<n;i++) {
    double& weight_i = g.weights[i];
    sqrtw[i] = sqrt(weight_i);
    if(weight_i<w_min) w_min = weight_i;
    W += weight_i;
  }
  for(i=0;i<n;i++) shift[i] = sqrtw[i]/W;

  lower_clique_bound = g.weights[0];
  clique.push_back(0);
}

// method receive_clique() calculates the total weight of a provided
// maximal clique and stores it if the weight is greater than
// the currently known (returning true at that)
bool MaxCliqueInfo::receive_clique(list<int>& new_clique) {
  double new_lower_clique_bound = 0.0;
  for(list<int>::iterator ii=new_clique.begin();ii!=new_clique.end();ii++)
    new_lower_clique_bound += g.weights[*ii];
  if(new_lower_clique_bound>lower_clique_bound) {
    lower_clique_bound = new_lower_clique_bound;
    clique = new_clique;
    print_update();
    return true;
  } else return false;
}
