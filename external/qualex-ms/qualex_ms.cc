#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <math.h>

#include "mex.h"
#include "graph.h"
#include "greedy_clique.h"
#include "preproc_clique.h"
#include "qualex.h"

/* Output Arguments */
#define OUTPUT 	plhs[0]

/*
 * The MATLAB arguments are as follows:
 *     prhs[0]      mtxAdj         The input adjacency matrix.  
 *     prhs[1]      mtxWeight      The input weight vector.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Ensure that an appropriate number of arguments were provided and that an
     * an appropriate number of return variables were requested. */
    if (nrhs != 2)
        mexErrMsgTxt("Exactly two input arguments are required.");
    else if (nlhs > 1)
        mexErrMsgTxt("Too many output arguments were requested.");

    /* Retrieve and store the size of the input adjacency matrix for size
     * checking and later use. */
    mwSize iRows = mxGetM(prhs[0]);
    mwSize iCols = mxGetN(prhs[0]);

    mwSize iCols_weightMtx = mxGetN(prhs[1]);


    /* Perform size- and type-checking on the input values. */
    if ((iRows != iCols) || !mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]))
        mexErrMsgTxt("The first argument must be an integer-valued square matrix.");
    else if (iCols != iCols_weightMtx)
        mexErrMsgTxt("The size of the weight matrix is not matched with the size of the adjacency matrix.");

    bool for_clique=true;
    unsigned char from1 = '\0';

    Graph g((int)iRows);
 
    // add edges with weights
    double *adjac_mtx_ptr = mxGetPr(prhs[0]);
    double *weight_mtx_ptr =  mxGetPr(prhs[1]);
    int iGraphOrder = iCols;
    int i,j,idx;

    for (j = 1; j < iGraphOrder; j++)
        for (i = 0; i < j; i++)
        {
            if(j==i)
                continue;

            /* The matrix adj_mtx is stored as a 1-dimensional array, so
             * we must convert the coordinate (i, j) to the corresponding
             * 1-dimensional index. */
            idx = j + i * iGraphOrder;

            /* If the entry of the adjacency matrix is a 1, we want to add
             * an edge to our graph. */
            if(adjac_mtx_ptr[idx] == 1){
                g.add_edge(j, i);
                g.weights[i] =  weight_mtx_ptr[i];
                g.weights[j] =  weight_mtx_ptr[j];
            }
        }


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

    /* Create the output matrix, which will have one row for each clique and
     * one column for each node of the graph. */
    double   *ptrOutputMatrix;
    plhs[0] = mxCreateDoubleMatrix(1, iCols, mxREAL);
    ptrOutputMatrix = mxGetPr(plhs[0]);

    for(list<int>::iterator i=clique.begin();i!=clique.end();i++)
        ptrOutputMatrix[*i + from1] = 1;

    return;

}
