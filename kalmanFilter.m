function [stateFilter,stateCovPost,loglik,VVnew] = kalmanFilter(statePrev,obsCur,numPoints,kalmanParam,stateCovPrev)
% kalman�˲�(TI�汾)
% ����:stetePrev:ǰһ֡״̬�˲�ֵ;obsCur:��ǰ�۲�ֵ(�ѿ�������ϵ);numPoints:���е���;kalmanParam:kalman����;
% ���:stateFilter:��ǰ֡�˲�ֵ;kalmanParam:kalman����;handle:��������

%% Ԥ�ⲽ��
% ״̬Ԥ��
statePredict = kalmanParam.F * statePrev;

% ״̬����Э�������
stateCovPredict = kalmanParam.F * stateCovPrev *kalmanParam.F';
stateCovPredict = stateCovPredict + kalmanParam.Q_TI * kalmanParam.processVar;
stateCovPredict = (stateCovPredict+stateCovPredict') / 2;

% �ѿ������굽������ת��
statePredictSph = Cartesian2spherical(1, statePredict);


%% ���²���
% �۲�ֵת��Ϊ������ϵ
obsCurSph = Cartesian2spherical(1,[obsCur;0;0]);

% ��Ϣ����
innovation = obsCurSph - statePredictSph;

% ����Jacobian����
J = computeJacobian(0,statePredict);

% ����Rg����������Э�������
R = zeros(3,3);
dRangeVar = kalmanParam.lengthStd * kalmanParam.lengthStd;
dDopplerVar = kalmanParam.dopplerStd * kalmanParam.dopplerStd;

R(1,1) = dRangeVar / numPoints;
angleStd = 2*atan(0.5*kalmanParam.widthStd/statePredictSph(1));	
R(2,2) = angleStd*angleStd / numPoints;
R(3,3) = dDopplerVar / numPoints;

% ������ϢЭ����
innoCov = J * stateCovPredict * J' + R;

% ����kalman����
K = stateCovPredict * J' * innoCov;

% �����˲���״̬
statePost = statePredict + K*innovation';

% ����������Э����
stateCovPost = stateCovPredict - K*J*stateCovPredict;

stateFilter = statePost;

% ���������Ȼ����
loglik = gaussian_prob(innovation, zeros(1,length(innovation)), innoCov, 1);

ss = length(stateCovPrev);
VVnew = (eye(ss) - K*[kalmanParam.H;[0 0 1 0]])*kalmanParam.F*stateCovPrev;

end

