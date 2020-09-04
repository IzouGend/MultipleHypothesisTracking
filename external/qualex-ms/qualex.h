/***********************************************************************
!! QUALEX-MS: a QUick ALmost EXact Motzkin-Straus maximum weight      !!
!! clique/independent set solver.                                     !!
!!                                                                    !!
!! Copyright (c) Stanislav Busygin, 2000-2007. All rights reserved.   !!
!!                                                                    !!
!! Qualex header                                                      !!
***********************************************************************/

#ifndef QUALEX_H
#define QUALEX_H

#include "graph.h"

bool qualex_ms(MaxCliqueInfo& graph_info, double* a);

#endif  // QUALEX_H
