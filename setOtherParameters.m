
%% MHT parameters                        % notation in the paper                              % comment 
other_param.step = 5; % zy, 200612, mht帧步长
other_param.pDetection = 0.90;           % P_D 
other_param.pFalseAlarm = 0.05; % 0.000001;      % measurement likelihood under the null hypthesis    Please refer to adjustOtherParameters.m or the paper to see how to set this parameter for different videos.
other_param.maxActiveTrackPerTree = 100; % B_{th} 
other_param.dummyNumberTH = other_param.step;  % 注意，如果比other_param.step小，可能引起某个mht周期的某个全dummy节点轨迹的节点数比other_param.step少二者之差，在可视化数据时需注意不是所有轨迹的节点数都一样       % N_{miss}                                           the number of consecutive missing observation
other_param.N = 1;                       % N (N scan)
other_param.MahalanobisDist = 300;        % d_{th}                                             set this parameter to 6 for motion-based tracking and 12 for motion+appearance-based tracking.
         

%% additional parameters
other_param.is3Dtracking = 0;            % set this parameter to 0 for 2D tracking (e.g. MOT) and 1 for 3D tracking (e.g. PETS)
% other_param.minDetScore = 0;             % detection pruning. Detections whose confidence score is lower than this threshold are ignored.
% other_param.confscTH = 5;                % confirmed track pruning (MOT). Confirmed tracks whose average detection confidence score is lower than this threshold are ignored.
% other_param.confscTH = 0.2;            % confirmed track pruning (PETS)
other_param.dummyRatioTH = 0.5;          % confirmed track pruning based on a ratio of the # of dummy observations to the # of total observations
other_param.minLegnthTH = 4;             % confirmed track pruning based on a track length
% other_param.maxScaleDiff = 1.4;          % allowed bounding box scale difference between consecutive frames in each track. Set this parameter to > 1. For example, 1.4 means 40% scale change is allowed.

%% graph solver
other_param.const = 0.125; % 0.05;
%% scenery
other_param.leftWall = -20;
other_param.rightWall = 20;
other_param.upperEntrance = 20;
