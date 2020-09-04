/***********************************************************************
!! bool_vector is a simple manager of bit strings allowing a set of   !!
!! basic bitwise operations and optimized iterating through           !!
!! true entries.                                                      !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! bool_vector implementation                                         !!
***********************************************************************/

#include "bool_vector.h"

// bool_vector loading constructor (file must be open)
bool_vector::bool_vector(FILE* file){
  fread(&size,sizeof(int),1,file);
  data_size=(size+b_size-1)/b_size;
  data=(u_long*)calloc(data_size,sizeof(u_long));
  fread(data,sizeof(u_long),data_size,file);
}

// bool_vector assignment
bool_vector& bool_vector::operator=(const bool_vector& x){
  size=x.size;
  data_size=x.data_size;
  if(data)free(data);
  if(data_size){
    data=(u_long*)calloc(data_size,sizeof(u_long));
    memcpy(data,x.data,data_size*sizeof(u_long));
  }else data=NULL;
  return *this;
}

// insert new i-th entry (will be initially false)
void bool_vector::insert(int i){
  if(!data){
    data=(u_long*)calloc(1,sizeof(u_long));
    size=1;
    data_size=1;
    return;
  }
  if(!(size%b_size)){
    data_size++;
    data=(u_long*)realloc(data,sizeof(u_long)*data_size);
    data[data_size-1]=0;
  }
  size++;
  int k=i/b_size;
  int b=i%b_size;
  u_long* v=data+k;
  u_long c=(*v)&last_bit;
  u_long mask=(1UL<<b)-1;
  u_long l=(*v)&mask;
  (*v)^=l;
  (*v)<<=1;
  (*v)|=l;
  for(v++;v<data+data_size;v++){
    u_long bit=(*v)&last_bit;
    (*v)<<=1;
    (*v)|=c>>(b_size-1);
    c=bit;
  }
}

// erase i-th entry
void bool_vector::erase(int i){
  int k=i/b_size;
  int b=i%b_size;
  u_long* v=data+k;
  u_long mask=(1UL<<b)-1;
  u_long l=(*v)&mask;
  (*v)>>=1;
  (*v)&=~mask;
  (*v)|=l;
  for(v++;v<data+data_size;v++){
    u_long bit=(*v)&1;
    (*(v-1))|=bit<<(b_size-1);
    (*v)>>=1;
  }
  size--;
  if(!size){
    free(data);
    data=0;
    data_size=0;
  }
  if(!(size%b_size)){
    data_size--;
    data=(u_long*)realloc(data,sizeof(u_long)*data_size);
  }
}

// perform bitwise AND operation with vector x
void bool_vector::_and(const bool_vector& x){
  u_long* w=x.data;
  for(u_long* v=data;v<data+data_size;v++,w++)(*v)&=(*w);
}

// perform bitwise OR operation with vector x
void bool_vector::_or(const bool_vector& x){
  u_long* w=x.data;
  for(u_long* v=data;v<data+data_size;v++,w++)(*v)|=(*w);
}

// perform bitwise AND-NOT operation with vector x
void bool_vector::and_not(const bool_vector& x){
  u_long* w=x.data;
  for(u_long* v=data;v<data+data_size;v++,w++)(*v)&=~(*w);
}

// perform bitwise OR-NOT operation with vector x
void bool_vector::or_not(const bool_vector& x){
  u_long* w=x.data;
  u_long* v;
  for(v=data;v<data+data_size-1;v++,w++)(*v)|=~(*w);
  (*v)|=~(*w)&((1UL<<(size%b_size))-1);
}

// store bool_vector in a file (should be open)
void bool_vector::save(FILE* file){
  fwrite(&size,sizeof(int),1,file);
  fwrite(data,sizeof(u_long),data_size,file);
}

// compare two vectors; return -1 if x<y, 0 if x=y, and 1 if x>y
int cmp(const bool_vector& x,const bool_vector& y){
  if(x.size<y.size)return -1;
  if(x.size>y.size)return 1;
  return memcmp(x.data,y.data,x.data_size*sizeof(u_long));
}

// method next() returns the index of next true entry
// or -1 when there are no more true entries
int bit_iterator::next(){
  if(j1>=size){
    current=-1;
    goto L1;
  }
  while(!mask){
    j+=b_size;
    if(j>=size){
      current=-1;
      goto L1;
    }
    j1=j;
    jj++;
    mask=*jj;
  }
  while(!(mask&1)){
    j1++;
    mask>>=1;
  }
  current=j1;
  j1++;
  mask>>=1;
  L1:return current;
}
