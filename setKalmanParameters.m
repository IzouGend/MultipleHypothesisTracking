kalman_param.ss = 4; % state size
kalman_param.os = 2; % observation size
dt = 0.05;     % 帧周期
std = 0.289;
kalman_param.F = [1 0 dt 0; 0 1 0 dt; 0 0 1 0; 0 0 0 1];
kalman_param.H = [1 0 0 0; 0 1 0 0];
% 设置状态误差协方差矩阵
dt2 = dt^2;    
dt3 = dt^3;
dt4 = dt^4;
kalman_param.Q_adjusted = [...
dt4/4    0    dt3/2   0;...
0	  dt4/4    0	dt3/2;...
dt3/2	0	  dt2	 0;...
0	  dt3/2	   0	dt2];
kalman_param.Q = kalman_param.Q_adjusted;
kalman_param.initV = kalman_param.Q_adjusted;
std2 = std^2;
kalman_param.R_adjusted = 0.1 * [std2 0;0 std2];
kalman_param.R = kalman_param.R_adjusted;
% TI kalman滤波参数
kalman_param.Q_TI = [...
    dt4/4    0     dt3/2    0;
    0      dt4/4     0    dt3/2;
    dt3/2	 0      dt2     0;
    0	   dt3/2     0     dt2];
kalman_param.processVar = 2.5 * 2.5;
% 量测方差参数
kalman_param.lengthStd = 0.289;
kalman_param.widthStd = 0.289;
kalman_param.dopplerStd = 1.0;

%% 2D tracking parameters (used for MOT). Q, R and initV are automatically set. 
% kalman_param.covWeight1 = 1/10;
% kalman_param.covWeight2 = 0.0125;


