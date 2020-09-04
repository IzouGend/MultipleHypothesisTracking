CC = gcc
CFLAGS = -O3 -march=nocona -ffast-math -fomit-frame-pointer -fPIC 
#OMPFLAGS = -fopenmp

#CC=icc
#CFLAGS = -xP -fast
#OMPFLAGS = -openmp

MATLABDIR= /usr/local/MATLAB/R2010b
MKLROOT = /opt/intel
MKLPATH = $(MKLROOT)/mkl/lib/intel64
INCLUDES=-I$(MATLABDIR)/extern/include -I$(MKLROOT)/mkl/include -DATL_USEPTHREADS -DMKL_ILP64
LDIRS= -L$(MATLABDIR)/bin/glnxa64 -L$(MKLPATH) -L$(MKLROOT)/lib/intel64
MEX_EXT = mexa64

MKLLIBS = $(MKLPATH)/libmkl_solver_ilp64.a -Wl,--start-group $(MKLPATH)/libmkl_intel_ilp64.a $(MKLPATH)/libmkl_intel_thread.a $(MKLPATH)/libmkl_core.a -Wl,--end-group -liomp5 
MATH_LIB = $(MKLLIBS)
#MATH_LIB = -latlas -lptcblas -liomp5 -lpthread


all:	mex_featurize.$(MEX_EXT) mex_dsyev.$(MEX_EXT)
mex_featurize.o:	mex_featurize.cpp
	$(CC) $(CFLAGS) -c $(INCLUDES) -o mex_featurize.o mex_featurize.cpp 

mex_dsyev.o:	mex_dsyev.cpp
	$(CC) $(CFLAGS) -c $(INCLUDES) -o mex_dsyev.o mex_dsyev.cpp

mex_featurize.$(MEX_EXT):	mex_featurize.o
	$(CC) mex_featurize.o $(LDIRS) -lmex -shared $(MATH_LIB) -fPIC -o mex_featurize.$(MEX_EXT)

mex_dsyev.$(MEX_EXT):	mex_dsyev.o
	$(CC) mex_dsyev.o $(LDIRS) -lmex -shared $(MATH_LIB) -fPIC -o mex_dsyev.$(MEX_EXT)

# default installation of libomp cannot be opened using dlopen() as would be required e.g. for Python
clean:
	rm -f *.o *.$(MEX_EXT)


