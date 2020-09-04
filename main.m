close all;
clear;
clc;

addpath(genpath('external'));

% prepare parameters
setKalmanParameters; 
setOtherParameters;
% 进入边界
zone(:,1) = [other_param.leftWall, other_param.rightWall, 0.5 ,other_param.upperEntrance - 0.15];

%% load test Data
% load('S_hat_158.mat');
% load('block_159_230_selected.mat');

% load('S_hat_228(blkm_loose).mat');
% load('block_229_268(blkm_loose).mat');

% load('S_hat_538(blkm_loose).mat');
% load('block_539_756(blkm_loose).mat');

simulateData1;

initTrack = hTrack;
initTrackNum = length(initTrack);

stFrm = block(1).frame;
edFrm = block(end).frame;
step = other_param.step;
cnt = 0;
cycNum = floor((edFrm - stFrm) / step);
idx1 = 1;
allTrack = [];
figFlag = 1;
while cnt < cycNum
    cnt = cnt + 1;
    % 取step帧量测数据
    for k = idx1 + 1 : length(block)
        if (block(k).frame >= block(idx1).frame + step)
            idx2 = k - 1;
            break;
        end
    end   
    curCycPntNum = (idx2 - idx1 + 1);
    observation.x = zeros(1, curCycPntNum);    
    observation.y = zeros(1, curCycPntNum);  
    observation.fr = zeros(1, curCycPntNum);  
    observation.pntNum = zeros(1, curCycPntNum);  
    tmpIdx = 1;
    for k = idx1 : idx2
        observation.x(tmpIdx) = block(k).x;    
        observation.y(tmpIdx) = block(k).y; 
        observation.fr(tmpIdx) = block(k).frame;
        observation.pointNum(tmpIdx) = block(k).pointNum;
        tmpIdx = (tmpIdx) + 1;
    end
    idx1 = idx2 + 1;
    
    % run MHT
    track = MHT(observation, initTrack, kalman_param, other_param);
    allTrack = [allTrack track];
    % save tracking output into images
%     visTracks(track, other_param, img_input_path{i}, img_output_path{i}, max(det.fr));         
    % init initTrack with last state of each track in current MHT-process,
    initTrackNum = sum(diff(track.id)) + 1;
    disp(track.fr(end));
    for k = 1 : initTrackNum
        initTrack(k).tid = k;
        tmpIdx = (k) * (step + 1) - 1; % 取倒数第三帧数据作为下一周期的初始值
        if isnan(track.isdummy(tmpIdx)) % 如果此帧漏警
            if (tmpIdx + 1) <= k * (step + 1) % 检查下一帧
                if isnan(track.isdummy(tmpIdx + 1)) 
                    stIdx = (k - 1) * (step + 1) + 1; % 取上一周期预测位置
                    initTrack(k).S_hat = [track.x_hat(stIdx), track.y_hat(stIdx), track.xv(stIdx), track.yv(stIdx)]; 
%                     initTrack(k).P_hat = track.p_hat(stIdx, :); 
                else
                    initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)]; 
%                     initTrack(k).P_hat = track.p_hat(tmpIdx, :);
%                     initTrack(k).S_hat = [track.x_hat(tmpIdx + 1), track.y_hat(tmpIdx + 1), track.xv(tmpIdx  + 1), track.yv(tmpIdx + 1)]; 
                end
            elseif (tmpIdx - 1) > (k - 1) * (step + 1) % 检查上一帧
                if isnan(track.isdummy(tmpIdx - 1)) 
                    stIdx = (k - 1) * (step + 1) + 1; % 取上一周期预测位置
                    initTrack(k).S_hat = [track.x_hat(stIdx), track.y_hat(stIdx), track.xv(stIdx), track.yv(stIdx)]; 
%                     initTrack(k).P_hat = track.p_hat(stIdx, :);
                else
                    initTrack(k).S_hat = [track.x_hat(tmpIdx - 1), track.y_hat(tmpIdx - 1), track.xv(tmpIdx - 1), track.yv(tmpIdx - 1)]; 
%                     initTrack(k).P_hat = track.p_hat(tmpIdx - 1, :);
                end
            else
                initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)];
%                 initTrack(k).P_hat = track.p_hat(tmpIdx, :);
            end
        else
            initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)]; 
%             initTrack(k).P_hat = track.p_hat(tmpIdx, :);
        end        
        initTrack(k).fr = track.fr(end);
        % print result
        curRes = [k initTrack(k).S_hat];
        disp(curRes);
    end

    if figFlag == 1 % figure
        figure(1);
        clrType = 'mcrgbkmcrgbkmcrgbkmc';
        tmpObs_xy = zeros(initTrackNum, 2); % observations:[x, y]
        tmpSta_xy = zeros(initTrackNum, 2);  
        tmpIsDummy = zeros(initTrackNum, 1);  % 漏警判断
        
        for m = 1 : step
            plot([zone(1),zone(2),zone(2),zone(1),zone(1)],[zone(3),zone(3),zone(4),zone(4),zone(3)],'b','LineWidth',1);
            axis([0 10 0 10]);
            hold on;
            grid on;
            for k = 1 : initTrackNum
                tmpIdx = (k - 1) * (step + 1) + m + 1; % step + 1, 不包含初始track
                tmpTid = track.id(tmpIdx);
                tmpObs_xy(k, :) = [track.x(tmpIdx), track.y(tmpIdx)]; 
                tmpSta_xy(k, :) = [track.x_hat(tmpIdx), track.y_hat(tmpIdx)];
                tmpIsDummy(k) = isnan(track.isdummy(tmpIdx));
                tmpFrmNo = track.fr(tmpIdx);
                scatter(tmpSta_xy(k, 1), tmpSta_xy(k, 2), 100, clrType(k)); % statements
                hold on;
            end
             
            title(['frmNO.', num2str(tmpFrmNo)]);
            tmpIdx = (observation.fr == tmpFrmNo);
            curObs = [observation.x(tmpIdx)', observation.y(tmpIdx)'];
            scatter(curObs(:, 1), curObs(:, 2), 20, 'b'); % obsversations
            hold on;
            watchMat = zeros(size(curObs, 1), 6);
            watchMat(:, 1:2) = curObs;
            watchMat(1 : size(tmpObs_xy, 1), 3:4) = tmpObs_xy;
            watchMat(1 : size(tmpSta_xy, 1), 5:6) = tmpSta_xy;
            for k = 1 : initTrackNum
                if(tmpIsDummy(k) ~= 1)
                    scatter(tmpObs_xy(k, 1), tmpObs_xy(k, 2), 20, clrType(k), 'filled'); % associated observations
                else
                    scatter(tmpObs_xy(k, 1), tmpObs_xy(k, 2), 5, clrType(k), 'filled'); % parent observations
                end    
            end
            if tmpFrmNo >= 1
                watchFlag = 1; 
            end
            hold off;        
        end
    end
end