%% Parameter settings
frmNum = 200;         % frame numbers
T = 0.05;                % frame peroid
MC_number = 1;             % monte carlo simulation number
initNumTarget = 3;        

Pd = 1;                % detection probability
Pg = 0.99;             % probability of correct measures falling into gates
g_sigma = 9.21;        % gate
lambda = 3;
gamma = lambda*10^(-6);    % generate 3 clusters per unit area
target_delta = [0.2 0.2 0.2];  % measure stand deviation                   
P = zeros(4,4,initNumTarget);          % covriance matrices
P1 = [target_delta(1)^2   0               0               0;
        0           target_delta(2)^2     0               0;
        0                 0              0.01             0;
        0                 0               0              0.01]; 

    
%% Simulate existing tracks.
% three tracks
hTrack(1).tid = 1;
% initial position and velocity [x y vx vy].
hTrack(1).S_hat = [0.0 4.0 0.8 0.4];
hTrack(1).H_s = [2.8 1.1 -0.3];
hTrack(1).P_hat = P1;
hTrack(1).fr = 1;

hTrack(2).tid = 2;
hTrack(2).S_hat = [0.0 8.0 0.8 -0.4];
hTrack(2).H_s = [3.7 0.6 -0.5];
hTrack(2).P_hat = P1;
hTrack(2).fr = 1;

hTrack(3).tid = 3;
hTrack(3).S_hat = [4.0 4.0 0 0.4];
hTrack(3).H_s = [4.5 0.5 -0.6];
hTrack(3).P_hat = P1;
hTrack(3).fr = 1;


%% Simulate measures.
% state transiation matrix
F = [1  0  T  0;
     0  1  0  T;
     0  0  1  0;
     0  0  0  1];
% measure matrix
H = [1  0  0  0;
     0  1  0  0];    
% measure coviance matrix
R = [target_delta(1)^2     0;
      0            target_delta(2)^2];      
% system process noise coviance matrix
Q = [0.04  0;
     0    0.01];  
% process noise matrix
G = [T^2/2  0;
      T   0;
      0  T^2/2;
      0   T];  
  
xFilter = zeros(4,initNumTarget,frmNum);    % filter value
xFilter1 = zeros(4,initNumTarget,frmNum,MC_number);          % filter value of all frames
dataMeasurement = zeros(initNumTarget,2,frmNum);             % measure matrix
dataMeasurement1 = zeros(initNumTarget,4,frmNum);            % ground truth  


%% generate ground truth of targets
for ii = 1:3
    dataMeasurement1(ii,:,1) = hTrack(ii).S_hat;  
end
% initialize ground truth 
for i = 1:initNumTarget
    for ii = 2:frmNum      
        % ground truth 
        dataMeasurement1(i,:,ii) = (F*dataMeasurement1(i,:,ii-1)')'+ (G*sqrt(Q)*(randn(2,1)))';        
    end
end

% generate measures
for ii = 1:frmNum
    for jj = 1:initNumTarget
        dataMeasurement(jj,1,ii) = dataMeasurement1(jj,1,ii) + rand(1)*target_delta(jj);
        dataMeasurement(jj,2,ii) = dataMeasurement1(jj,2,ii) + rand(1)*target_delta(jj);
    end
end

% generate clusters
S = zeros(2,2,initNumTarget);
zPredict = zeros(2,initNumTarget);    
xPredict = zeros(4,initNumTarget); 
ellipseVolume = zeros(1,initNumTarget);
noiseSum = cell(initNumTarget,frmNum);
% for ii = 1:initNumTarget
%     for jj = 1:frmNum
%         noiseSum(ii,jj) = [];   % store cluster
%     end
% end

for t = 1:frmNum
    noise = [];
    NOISE = [];
    for ii = 1:initNumTarget
        if t ~= 1
            % kalman predict
            xPredict(:,ii) = F*xFilter(:,ii,t-1);                                       
        else
            % use ground truth
            xPredict(:,ii) = hTrack(ii).S_hat';                                        
        end
        % update covriance matrix 
        P_predict = F*hTrack(ii).P_hat*F'+ G*Q*G';
        zPredict(:,ii) = H * xPredict(:,ii);                                                 
        R = [target_delta(ii)^2 0; 0 target_delta(ii)^2];
        S(:,:,ii) = H*P_predict*H' + R;       
        % calculate area of tracking gate of each traget
        ellipseVolume(ii) = pi*g_sigma*sqrt(det(S(:,:,ii))); 
        % number of false returns
        numReturns = floor(ellipseVolume(ii)*gamma + 1);    
        side = sqrt((ellipseVolume(ii)*gamma+1)/gamma) / 2;     
        % generate clusters around predicted position
        noiseX = xPredict(1,i) + side - 2*rand(1,numReturns)*side;                                                                                                                              %注意：当某一次number_returns小于等于0时会出错，再运行一次即可。
        noiseY = xPredict(2,i) + side - 2*rand(1,numReturns)*side;    
        noise = [noiseX;noiseY];
        NOISE = [NOISE noise];
        noiseSum{ii,t} = [noiseSum{ii,t} noise];
    end
end


%% generate block
numBlock = 0;
for ii = 1:frmNum
    for jj = 1:initNumTarget
        numBlock = numBlock + 1;
        block(numBlock).x = dataMeasurement(jj,1,ii);
        block(numBlock).y = dataMeasurement(jj,2,ii);
        block(numBlock).frame = ii;
        block(numBlock).pointNum = rand(1);
        block(numBlock).snr = 20*randn(1);
        
        for kk = 1:size(noiseSum{jj,ii},2)
            numBlock = numBlock + 1;
            block(numBlock).x = noiseSum{jj,ii}(1,kk);
            block(numBlock).y = noiseSum{jj,ii}(2,kk);
            block(numBlock).frame = ii;
            block(numBlock).pointNum = rand(1);
            block(numBlock).snr = 20*randn(1);
        end
    end
end
    
        

