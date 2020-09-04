/***********************************************************************
!! bool_vector is a simple manager of bit strings allowing a set of   !!
!! basic bitwise operations and optimized iterating through           !!
!! true entries.                                                      !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! bool_vector header                                                 !!
***********************************************************************/

#ifndef BOOL_VECTOR_H
#define BOOL_VECTOR_H

#include <stdlib.h>
#include <stdio.h>
#include <memory.h>

// a shortcut for unsigned long
#ifndef u_long
typedef unsigned long u_long;
#endif

// b_size is the number of bits contained in u_long
#define b_size (8*sizeof(u_long))

// last_bit is u_long constant whose highest bit is 1 and all others are 0
#define last_bit (1UL<<(b_size-1))

// bool_vector is the object holding a bit string and providing
// bitwise access and operations
struct bool_vector{
  u_long* data;   // the bool_vector data storage                       
  int size;       // the vector dimension (i.e. number of contained bits)
  int data_size;  // the number of u_long`s allocated to hold the vector

  // bool_vector default constructor
  bool_vector():data(NULL),size(0),data_size(0){}

  // bool_vector constructor by a given size: all entries are initially false
  bool_vector(int i_size):size(i_size),data_size((i_size+b_size-1)/b_size){
    data=(u_long*)calloc(data_size,sizeof(u_long));
  }

  // bool_vector copy constructor
  bool_vector(const bool_vector& x):size(x.size),data_size(x.data_size){
    if(data_size){
      data=(u_long*)calloc(data_size,sizeof(u_long));
      memcpy(data,x.data,data_size*sizeof(u_long));
    }else data=NULL;
  }

  // bool_vector loading constructor (file must be open)
  bool_vector(FILE* file);

  // bool_vector destructor
  ~bool_vector(){if(data)free(data);}

  // bool_vector identity operator: true iff sizes and data are the same
  bool operator==(const bool_vector& x)const{
    return size==x.size&&!memcmp(data,x.data,data_size*sizeof(u_long));
  }

  // bool_vector assignment
  bool_vector& operator=(const bool_vector& x);

  // i-th entry
  bool at(int i){return bool((*(data+i/b_size))&(1UL<<(i%b_size)));}

  // set i-th entry to true
  void put(int i){*(data+i/b_size)|=1UL<<(i%b_size);}

  // set i-th entry to false
  void clear(int i){*(data+i/b_size)&=~(1UL<<(i%b_size));}

  // set all entries to false
  void zero(){for(int i=0;i<data_size;i++)data[i]=0;}

  // insert new i-th entry (will be initially false)
  void insert(int i);

  // erase i-th entry
  void erase(int i);

  // perform bitwise AND operation with vector x
  void _and(const bool_vector& x);

  // perform bitwise OR operation with vector x
  void _or(const bool_vector& x);

  // perform bitwise AND-NOT operation with vector x
  void and_not(const bool_vector& x);

  // perform bitwise OR-NOT operation with vector x
  void or_not(const bool_vector& x);

  // store bool_vector in a file (should be open)
  void save(FILE* file);
};

// compare two vectors; return -1 if x<y, 0 if x=y, and 1 if x>y
int cmp(const bool_vector& x,const bool_vector& y);

// bit_iterator is an iterator through bool_vector true entries
struct bit_iterator{
  int size;
  u_long* jj;
  u_long mask;
  int j;
  int j1;
  int current;

  bit_iterator(){}

  // bit_iterator may be associated with a bool_vector during construction
  bit_iterator(bool_vector& base):
    size(base.size),jj(base.data),j(0),j1(0),current(-1){mask=*jj;}

  // or afterwards by init() method (as well as reassigned to another instance)
  void init(bool_vector& base){
    size=base.size;
    jj=base.data;
    mask=*jj;
    j=0;
    j1=0;
    current=-1;
  }

  // method next() returns the index of next true entry
  // or -1 when there are no more true entries
  int next();
};

#endif  // BOOL_VECTOR_H
