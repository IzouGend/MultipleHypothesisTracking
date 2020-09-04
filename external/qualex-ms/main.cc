/*****************************************************************************
!!  This is the main() function of QUALEX-MS solver                         !!
!!  Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.        !!
!!                                                                          !!
!! This software is distributed AS IS. NO WARRANTY is expressed or implied. !!
!! The author grants a permission for everyone to use and distribute this   !!
!! software free of charge for research and educational purposes.           !!
!! Any COMMERCIAL usage of this software is PROHIBITED without a written    !!
!! permission of the copyright holder.                                      !!
!!                                                                          !!
!! Please send any inquiry to <busygin@gmail.com> and visit                 !!
!! Stas Busygin's NP-completeness page: <http://www.busygin.dp.ua/npc.html> !!
*****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <math.h>

#include "graph.h"
#include "greedy_clique.h"
#include "preproc_clique.h"
#include "qualex.h"

// print_clique() prints a provided clique and its total weight
// in a file along with the graph header
void print_clique (
  const char* filename, const char* header,
  list<int>& clique, double clique_weight, unsigned char from1
) {
  FILE* file=fopen(filename,"w");
  fputs(header,file);
  fprintf(file,"s %lg\n",clique_weight);
  for(list<int>::iterator i=clique.begin();i!=clique.end();i++)
    fprintf(file, "v%11d\n", *i + from1);
  fclose(file);
}

int main(int argc,char** argv) {
  puts(
    "QUick ALmost EXact maximum weight clique solver, ver. 1.2-MS\n\n"
    "Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.\n\n"
    "This software is distributed AS IS. NO WARRANTY is expressed or implied.\n"
    "The author grants a permission for everyone to use and distribute this\n"
    "software free of charge for research and educational purposes.\n"
    "Any COMMERCIAL usage of this software is PROHIBITED without a written\n"
    "permission of the copyright holder.\n\n"
    "Please send any inquiry to <busygin@gmail.com> and visit\n"
    "Stas Busygin's NP-completeness page: <http://www.busygin.dp.ua/npc.html>\n"
  );

  char* name=NULL;
  char* weights_name=NULL;
  bool for_clique=true;
  unsigned char from1 = '\0';
  char* p;

  // get running parameters
  while(argc-->=2) {
    p=*++argv;
    switch(p[0]) {
      case '-':
        switch(p[1]) {
          case 'c':
            for_clique=false;
            break;
          case '1':
            from1 = '\0';
            break;
          case 'w':
            weights_name=p+2;
        }
        break;
      case '+':
        switch(p[1]) {
          case 'c':
            for_clique=true;
            break;
          case '1':
            from1 = '\1';
        }
        break;
      default:
        name=p;
    }
  }

  if(name!=NULL) {  // parameters are valid
    printf("%s mode.\n", for_clique?"CLIQUE":"MIS");

    // load the graph from a DIMACS file
    Graph g(name,weights_name,!for_clique);

    // note the start time
    time_t time1,time2;
    time(&time1);

    // preprocess
    vector<int> residual;
    list<int> preselected, clique;
    double clique_weight;
    double preselected_weight = preproc_clique (
      g,residual,preselected,clique_weight,clique
    );

    // if the instance is not reduced completely, apply QUALEX-MS
    if(!residual.empty()) {
      MaxCliqueInfo info(g,for_clique);
      meta_greedy_clique(info);

      int& n=g.n;
      double* a = new double[n*n];
      memset(a,0,sizeof(double)*n*n);
      int i,j;

      for(i=0;i<n;i++) {
        a[i*(n+1)] = g.weights[i]-info.w_min;
        bit_iterator bi(g.mates[i]);
        while((j=bi.next())>-1) {
          if(j>i) break;
          a[i*n+j] = a[j*n+i] = info.sqrtw[i]*info.sqrtw[j];
        }
      }

      qualex_ms(info,a);

      delete[] a;

      if(info.lower_clique_bound>clique_weight) {
        clique_weight = info.lower_clique_bound;
        clique.erase(clique.begin(),clique.end());
        for(list<int>::iterator i=info.clique.begin();i!=info.clique.end();i++)
          clique.push_back(residual[*i]);
      }
    }

    // join with the earlier preselected vertices
    clique.splice(clique.begin(),preselected);
    clique_weight += preselected_weight;

    // note the finish time
    time(&time2);

    // print results
    printf (
      "%s: %s_w >= %lg, time=%lg sec.\n",
      name, for_clique?"omega":"alpha", clique_weight, difftime(time2,time1)
    );

    int length=strlen(name);
    char* sol_filename=new char[length+5];
    memcpy(sol_filename, name, length+1);
    char* p=strstr(sol_filename,for_clique?".clq":".mis");
    if(!p)p=sol_filename+length;
    strcpy(p,".sol");
    print_clique(sol_filename,g.header,clique,clique_weight,from1);
    delete[] sol_filename;
  } else puts(
    "Syntax: qualex-ms [<flag>] <dimacs_binary_file> [-w<weights_file>]\n"
    "Flags:\n"
    "+c: look for maximum clique (default)\n"
    "-c: look for maximum independent set\n"
    "+1: vertex numbers in solution file go from 1\n"
    "-1: vertex numbers in solution file go from 0 (default)\n"
    "weights_file: a text file for list of vertex weights (reals)\n"
  );

  return 0;
}
