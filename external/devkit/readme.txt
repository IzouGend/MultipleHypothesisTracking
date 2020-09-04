Multiple Object Tracking Challenge
==================================
---- http://motchallenge.net -----
----------------------------------

This development kit provides scripts to evaluate tracking results.
Please report bugs to anton.milan@adelaide.edu.au


Requirements
============
- MATLAB
- Benchmark data 
  e.g. 2DMOT2015, available here: http://motchallenge.net/data/2D_MOT_2015/
  
  

Usage
=====

To compute the evaluation for the included demo, which corresponds to 
the results of the CEM tracker (continuous energy minimization) on the 
training set of the '2015 MOT 2DMark', start MATLAB and run

	benchmarkDir = '../data/2DMOT2015/train/';
	allMets = evaluateTracking('c2-train.txt', 'res/data/', benchmarkDir);

Replace the value for benchmarkDir accordingly.

You should see the following output (be patient, it may take a minute):

Sequences: 
    'TUD-Stadtmitte'
    'TUD-Campus'
    'PETS09-S2L1'
    'ETH-Bahnhof'
    'ETH-Sunnyday'
    'ETH-Pedcross2'
    'ADL-Rundle-6'
    'ADL-Rundle-8'
    'KITTI-13'
    'KITTI-17'
    'Venice-2'
Evaluating ... 
	... TUD-Stadtmitte
*** 2D (Bounding Box overlap) ***
 Rcll  Prcn   FAR| GT  MT  PT  ML|   FP    FN  IDs   FM|  MOTA  MOTP MOTAL 
 75.3  94.0  0.31| 10   7   3   0|   56   285   11    9|  69.6  69.8  70.4 
..................
..................
..................

 ********************* Your Benchmark Results (2D) ***********************
 Rcll  Prcn   FAR| GT  MT  PT  ML|   FP    FN  IDs   FM|  MOTA  MOTP MOTAL 
 52.2  67.9  1.93|570 108 207 255|10633 20631  467  527|  26.4  73.0  27.5 



Details
=======
The evaluation script accepts 3 arguments:

1)
sequence map (e.g. `c2-train.txt` contains a list of all sequences to be 
evaluated in a single run. These files are inside the ./seqmaps folder.

2)
The folder containing the tracking results. Each one should be saved in a
separate .txt file with the name of the respective sequence (see ./res/data)

3)
The folder containing the benchmark sequences.

The results will be shown for each individual sequence, as well as for the
entire benchmark.




Directory structure
===================
	

./res
----------
This directory contains 
  - the tracking results for each sequence in a subfolder data  
  - eval.txt, which shows all metrics for this demo
  
  
  
./utils
-------
Various scripts and functions used for evaluation.


./seqmaps
---------
Sequence lists for different benchmarks




Version history
===============

1.01 - Feb. 06, 2015
  - Fixes in 3D evaluation (thanks Michael)

1.0 - Jan. 23, 2015
  - initial release