clear;
close all;

addpath(genpath('external'));

adjacencyMat1 = zeros(91,91);
weightMat1 = zeros(1,91);

adjacencyMat1(:,91) = 1;
adjacencyMat1(91,:) = 1;
adjacencyMat1(91,91) = 0;
weightMat1(1) = 1.1000;
weightMat1(2) = -3.0466;
weightMat1(3) = 2.5636;
weightMat1(4) = 3.0011;
weightMat1(5) = 6.0103;
weightMat1(6) = 5.2641;
weightMat1(7) = 1.1000;
weightMat1(8) = 4.0000;
weightMat1(9) = 2.1380;
weightMat1(10) = 1.1000; 
weightMat1(11:end) = 1.1000;

bestHypothesis_tmp = zeros(1,91);
maxCliqueNo = 1000;
[maxCliqueNo_tmp, bestHypothesis_tmp] = Cliquer.FindSingle(adjacencyMat1, 0, 0, true, maxCliqueNo, weightMat1);