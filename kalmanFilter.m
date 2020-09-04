function [stateFilter,stateCovPost,loglik,VVnew] = kalmanFilter(statePrev,obsCur,numPoints,kalmanParam,stateCovPrev)
% kalman滤波(TI版本)
% 输入:stetePrev:前一帧状态滤波值;obsCur:当前观测值(笛卡尔坐标系);numPoints:堆中点数;kalmanParam:kalman参数;
% 输出:stateFilter:当前帧滤波值;kalmanParam:kalman参数;handle:航迹参数

%% 预测步骤
% 状态预测
statePredict = kalmanParam.F * statePrev;

% 状态向量协方差矩阵
stateCovPredict = kalmanParam.F * stateCovPrev *kalmanParam.F';
stateCovPredict = stateCovPredict + kalmanParam.Q_TI * kalmanParam.processVar;
stateCovPredict = (stateCovPredict+stateCovPredict') / 2;

% 笛卡尔坐标到球坐标转换
statePredictSph = Cartesian2spherical(1, statePredict);


%% 更新步骤
% 观察值转换为球坐标系
obsCurSph = Cartesian2spherical(1,[obsCur;0;0]);

% 新息计算
innovation = obsCurSph - statePredictSph;

% 计算Jacobian矩阵
J = computeJacobian(0,statePredict);

% 计算Rg，量测噪声协方差矩阵
R = zeros(3,3);
dRangeVar = kalmanParam.lengthStd * kalmanParam.lengthStd;
dDopplerVar = kalmanParam.dopplerStd * kalmanParam.dopplerStd;

R(1,1) = dRangeVar / numPoints;
angleStd = 2*atan(0.5*kalmanParam.widthStd/statePredictSph(1));	
R(2,2) = angleStd*angleStd / numPoints;
R(3,3) = dDopplerVar / numPoints;

% 计算新息协方差
innoCov = J * stateCovPredict * J' + R;

% 计算kalman增益
K = stateCovPredict * J' * innoCov;

% 计算滤波后状态
statePost = statePredict + K*innovation';

% 计算后验误差协方差
stateCovPost = stateCovPredict - K*J*stateCovPredict;

stateFilter = statePost;

% 计算对数似然概率
loglik = gaussian_prob(innovation, zeros(1,length(innovation)), innoCov, 1);

ss = length(stateCovPrev);
VVnew = (eye(ss) - K*[kalmanParam.H;[0 0 1 0]])*kalmanParam.F*stateCovPrev;

end

