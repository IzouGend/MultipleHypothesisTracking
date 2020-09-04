  QUALEX-MS: QUick ALmost EXact maximum weight clique solver
             based on a generalized Motzkin-Straus formulation,
             ver 1.2

  Copyright (c) Stanislav Busygin, 2000-2009. All rights reserved.


1. INTRODUCTION

This software is to solve maximum weight clique/independent set problem.
It is well-known that this problem is NP-hard, so an exact efficient
algorithm for it probably does not exist. However, QUALEX-MS has shown
the ability to solve this problem exactly in many cases, including
test instances considered hard for all existing algorithms. Complexity
of the routine is O(n^3), where n is the number of graph vertices.

The algorithm uses a trust region technique for a generalization
of the Motzkin-Straus formulation for maximum clique problem. The
generalization allows to consider vertex weights. The RAM requirement is
mainly determined by usage of DSYEVR routine of LAPACK for
eigendecomposition of an nxn double precision matrix. That is,
the available memory should be enough for, at least, two nxn double
matrices.

The solver may be used free of charge for research and educational
purposes.

COMMERCIAL usage of the solver is PROHIBITED without a written
permission from the copyright holder. To get the permission, please
email an inquiry to <busygin@gmail.com>.

This software is distributed AS IS. NO WARRANTY is expressed or implied.


2. USAGE

QUALEX-MS uses some linear algebraic routines from the standard
packages BLAS and LAPACK. Please install them if you want to build
the executable file. They can be gotten at NetLib website:

http://www.netlib.org

Unless your hardware platform is very specific, it is suggested to
use the so-called ATLAS implementation of BLAS. There are ATLAS
prebuilts for almost all hardware platforms available for free and
compiled with full possible optimization.

Then, if you use the GNU environment, put correct values for
BLASLIB and LAPACKLIB in Makefile and just type `make`.

To use the solver, issue the command:

qualex-ms [<flag>] <dimacs_binary_file> [-w<weights_file>]

Flags:

+c: looking for maximum clique (default)
-c: looking for maximum independent set
+1: vertex numbers in solution file go from 1
-1: vertex numbers in solution file go from 0 (default)
weights_file: a text file for list of vertex weights (reals >= 1.0)

An obtained solution will be stored in a corresponding .sol file
(the vertex numbering is from 0 there). For example, you can find
the maximum clique of an instance coded in probe.clq.b file by
the command

qualex-ms probe.clq.b

File probe.sol will be created to store the result.

File probe.w contains a sample list of weights for this instance,
so the command

qualex-ms probe.clq.b -wprobe.w

will take into accout the given weights.


3. What is new?

version 1.1:
- the preliminary greedy heuristic is now MIN starting n times
(i.e. from each vertex);
- the quadratic programming formulation is scaled by square roots
of the vertex weights.

version 1.1.1:
- minor code optimization for the degenerative case.

version 1.1.2:
- an empty graph bug fixed.

version 1.2:
- code redesigned to improve readability;
- bool_vector is now 64-bit compliant (many thanks to "Max" <relf@rambler.ru>);
- a new parameter allows numbering of vertices from 1 (not 0) in solution files;
- Windows executable is recompiled with newest MinGW gcc and LAPACK 3.1.1.
