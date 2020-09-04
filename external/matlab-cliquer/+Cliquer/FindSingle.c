#include <math.h>
#include "mex.h"
#include <stdio.h>
#include "cliquer.h"

/* Output Arguments */
#define OUTPUT 	plhs[0]

#if !defined(MAX)
#define MAX(A, B) 	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define MIN(A, B) 	((A) < (B) ? (A) : (B))
#endif

graph_t* MatrixToGraph(double *adjac_mtx_ptr, double *weight_mtx_ptr, int iGraphOrder)
{
    int i, j, idx;
    graph_t *ptrGraph;
    
    /* Initialize the graph that we want to return. */
    ptrGraph = graph_new(iGraphOrder);
    
    /* Loop through the adjacency matrix to create the graph.  We assume
     * that the adjacency matrix is symmetric and only consider the super-
     * diagonals of the matrix. */
    /* The indexing here seems flipped, but it's due to the translation
     * between MATLAB and C element ordering. */
    for (j = 0; j < iGraphOrder; j++)
        for (i = j + 1; i < iGraphOrder; i++)       
        {
            /* The matrix adj_mtx is stored as a 1-dimensional array, so
             * we must convert the coordinate (i, j) to the corresponding
             * 1-dimensional index. */
            idx = j + i * iGraphOrder;
            
            /* If the entry of the adjacency matrix is a 1, we want to add
             * an edge to our graph. */            
            if(adjac_mtx_ptr[idx] == 1){
                GRAPH_ADD_EDGE(ptrGraph, i, j);
                ptrGraph->weights[i] = weight_mtx_ptr[i];
                ptrGraph->weights[j] = weight_mtx_ptr[j]; 
            }
        }
        
    /* Just to be cautios, ensure that we've produced a valid graph. */
    ASSERT(graph_test(ptrGraph, NULL)); 
  
    return ptrGraph;
}


set_t FindCliques(graph_t *ptrGraph, int iMinWeight, int iMaxWeight,
		int bOnlyMaximal, int iMaxNumCliques, 
		int iCliqueListLength)
{
    int            iNumCliques;
    clique_options localopts;
    
    /* Set the clique_options.  These fields should all be null except
     * 'clique_list' and 'clique_list_length', which store the list of
     * cliques and the maximum length of the list of cliques, respectively. */
    localopts.time_function      = NULL;
    localopts.reorder_function   = NULL;
    localopts.reorder_map        = NULL;
    localopts.clique_list        = NULL;
    localopts.clique_list_length = NULL;
    localopts.user_function      = NULL;
    localopts.user_data          = NULL;
       
    /* Find a single maximal clique in this graph of
     * minimum size 1 (argument 2) and no maximum size (argument 3). */

    set_t maxWeightedClique;
    maxWeightedClique = clique_find_single(ptrGraph, iMinWeight, iMaxWeight, bOnlyMaximal,
				  &localopts);              
    
    return maxWeightedClique;
}

/**
 * Find all of the maximal cliques in the provided matlab matrix, which
 * should represent an adjacency matrix.  Most of this function just
 * translates from MATLAB input for processing with Cliquer and then
 * translates the output of Cliquer back into MATLAB data.
 * 
 * The MATLAB arguments are as follows:
 *     prhs[0]      mtxAdj          The input adjacency matrix.  Only the upper-
 *                                  triangular part of this is used.
 *     prhs[1]      iMinWeight      The minimum weight of cliques to find.
 *     prhs[2]      iMaxWeight      The maximum weight of cliques to find.
 *     prhs[3]      bOnlyMaximal    If `false` (i.e., zero), return all cliques;
 *                                  otherwise, return only maximal cliques.
 *     prhs[4]      iMaxNumCliques  The maximum number of cliques to be returned
 *                                  (due to a [perceived] limitation of Cliquer).
 *     prhs[5]      mtxWeight       The input weight vector. Chanho Kim added.
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /* Ensure that an appropriate number of arguments were provided and that an
     * an appropriate number of return variables were requested. */
    if (nrhs != 6)
        mexErrMsgTxt("Exactly five input arguments are required.");
    else if (nlhs > 2)
        mexErrMsgTxt("Too many output arguments were requested.");
    
    /* Retrieve and store the size of the input adjacency matrix for size
     * checking and later use. */
	int iRows = mxGetM(prhs[0]);
    int iCols = mxGetN(prhs[0]);
    
    int iCols_weightMtx = mxGetN(prhs[5]); 
    
	//mwSize iRows = mxGetM(prhs[0]);
    //mwSize iCols = mxGetN(prhs[0]);
    
    //mwSize iCols_weightMtx = mxGetN(prhs[5]);
    
    
    /* Perform size- and type-checking on the input values. */
    if ((iRows != iCols) || !mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]))
        mexErrMsgTxt("The first argument must be an integer-valued square matrix.");
    else if (mxGetM(prhs[1]) != 1 || mxGetN(prhs[1]) != 1 || !mxIsNumeric(prhs[1]))
        mexErrMsgTxt("The second argument must be an integer.");
    else if (mxGetM(prhs[2]) != 1 || mxGetN(prhs[2]) != 1 || !mxIsNumeric(prhs[2]))
        mexErrMsgTxt("The third argument must be an integer.");
    else if (mxGetM(prhs[3]) != 1 || mxGetN(prhs[3]) != 1 || !mxIsLogical(prhs[3]))
        mexErrMsgTxt("The fourth argument must be a logical scalar.");
    else if (mxGetM(prhs[4]) != 1 || mxGetN(prhs[4]) != 1 || !mxIsNumeric(prhs[4]))
        mexErrMsgTxt("The fifth argument must be an integer.");
    else if (iCols != iCols_weightMtx)
        mexErrMsgTxt("The size of the weight matrix is not matched with the size of the adjacency matrix.");
    
    /* Declare variables to hold the input arguments (except the first).  Each
     * of these can be retrieved by indexing `prhs`. */
    int iMinWeight     = MAX(0, (int) mxGetScalar(prhs[1]));
    int iMaxWeight     = MIN(iCols, (int) mxGetScalar(prhs[2]));
    int bOnlyMaximal   = (mxGetScalar(prhs[3]) == 0) ? FALSE : TRUE;
    int iMaxNumCliques = (int) mxGetScalar(prhs[4]);
    
    /* These variables are for storing the graph corresponding to the input
     * adjacency matrix, the list of cliques found in that graph, and the return
     * value for this MATLAB function. */
    graph_t  *ptrGraph;
    set_t    arrCliqueList;
    double   *ptrOutputMatrix;
    
    /* Miscellaneous variable declarations. */
    int i, j, idx, iNumCliques, iNumCliquesReturned;       
    
    /* Create a graph from the adjacency matrix `prhs[0]`. */
    ptrGraph = MatrixToGraph(mxGetPr(prhs[0]), mxGetPr(prhs[5]), iCols);
        
    /* Find the cliques in the associated graph. */
    arrCliqueList = FindCliques(ptrGraph, iMinWeight, iMaxWeight, bOnlyMaximal,
			      iMaxNumCliques, iMaxNumCliques);
    
    /* We are done with the graph.  Free the memory used to store it. */
    graph_free(ptrGraph);
     
    /* Retrieve the number of cliques returned by the function, which is bounded
     * above by `iMaxNumCliques`. */
    iNumCliquesReturned = 1;
    
    /* Output the total number of cliques found. */
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    mxGetPr(plhs[0])[0] = iNumCliquesReturned;
       
    /* Create the output matrix, which will have one row for each clique and
     * one column for each node of the graph. */
    plhs[1] = mxCreateDoubleMatrix(iNumCliquesReturned, iCols, mxREAL);
    ptrOutputMatrix = mxGetPr(plhs[1]);
        

    /* Fill in the entries of this row by looping through the corresponding
     * clique to find the vertices contained in the clique. */              
    for (j = 0; j < SET_MAX_SIZE(arrCliqueList); j++)
    {
        /* The entries of the output matrix are initialized to zeros.  If
         * the vertex 'j' is in clique 'i', place a 1 in the (i, j) entry
         * of the output matrix. */
        if (SET_CONTAINS(arrCliqueList, j))
        {
            /* Matrices in Matlab are stored column-wise (i.e., the columns
             * of the matrix are stacked and stored as a column vector); so,
             * we must access the output as a 1-dimensional array.  The index
             * of the entry corresponding to the (i, j) position in this
             * matrix is calculated in 'idx' below. */
            idx = j * iNumCliquesReturned + i; /* bug fixed by chanho */
            ptrOutputMatrix[idx] = 1;
        }
    }

    /* Now that we've stored this clique as a row in a matrix, we can free
     * the memory used to store the clique. */
    set_free(arrCliqueList);
                    
    return;
}
