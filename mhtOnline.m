close all;
clear;

addpath(genpath('external'));

% prepare parameters
setKalmanParameters; % Kalman初始参数
setOtherParameters;
step = other_param.step;


%% 第一帧进行初始化
if rem(cur_observation.fr,step) == 1
    if cur_observation.fr == 1
        initTrack = hTrack;
    end
    initTrackNum = length(initTrack);

    setVariables;
    initTrackFimaly;
    
    [incompabilityListTreeSet incompabilityListTreeNodeIDSet]= updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);
    [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, other_param);

    mergeFlag = 0;
    % 构建和更新轨迹家族
    [obsTreeSet stateTreeSet scoreTreeSet idTreeSet activeTreeSet obsTreeSetConfirmed ...
        stateTreeSetConfirmed scoreTreeSetConfirmed activeTreeSetConfirmed familyID trackID treeDel treeConfirmed obsMembership] = formTrackFamily(obsTreeSet,...
        stateTreeSet, scoreTreeSet, idTreeSet, activeTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed,...
        selectedTrackIDs, cur_observation, kalman_param, other_param, familyID, trackID, cur_observation.fr);

    [incompabilityListTreeSet incompabilityListTreeNodeIDSet] = ...
        updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);

    [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, ...
        incompabilityListTreeNodeIDSet, activeTreeSet, other_param);

    [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs flagSelPercent idxMerge] = ...
        generateGlobalHypothesis(scoreTreeSet, obsTreeSet, stateTreeSet, idTreeSet, incompabilityListTreeSet,...
        clusters, ICL_clusters, selectedTrackIDs, other_param, mergeFlag); 
    
    [obsTreeSet, stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, familyID, trackFamilyPrev] = ...
        nScanPruning(bestHypothesis, trackIndexInTrees, obsTreeSet, ...
        stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeSet, ...
        incompabilityListTreeNodeIDSet, activeTreeSet, familyID, treeDel,...
        treeConfirmed, trackFamilyPrev, other_param, rem(cur_observation.fr,step)); 
%% 一个MHT周期内最后一帧
elseif rem(cur_observation.fr,step) == 0
    mergeFlag = 1;

   % 构建和更新轨迹家族
    [obsTreeSet stateTreeSet scoreTreeSet idTreeSet activeTreeSet obsTreeSetConfirmed ...
        stateTreeSetConfirmed scoreTreeSetConfirmed activeTreeSetConfirmed familyID trackID treeDel treeConfirmed obsMembership] = formTrackFamily(obsTreeSet,...
        stateTreeSet, scoreTreeSet, idTreeSet, activeTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed,...
        selectedTrackIDs, cur_observation, kalman_param, other_param, familyID, trackID, cur_observation.fr);

    [incompabilityListTreeSet incompabilityListTreeNodeIDSet] = ...
        updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);

    [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, ...
        incompabilityListTreeNodeIDSet, activeTreeSet, other_param);

    [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs flagSelPercent idxMerge] = ...
        generateGlobalHypothesis(scoreTreeSet, obsTreeSet, stateTreeSet, idTreeSet, incompabilityListTreeSet,...
        clusters, ICL_clusters, selectedTrackIDs, other_param, mergeFlag); 

    track = getTracksFromHypothesis(bestHypothesis, bestScore, trackIndexInTrees, obsTreeSet, stateTreeSet, scoreTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed, treeConfirmed, clusters,flagSelPercent,idxMerge, other_param, mergeFlag);

    initTrackNum = sum(diff(track.id)) + 1;
    for k = 1 : initTrackNum
        initTrack(k).tid = k;
        tmpIdx = (k) * (step + 1) - 1; % 取倒数第三帧数据作为下一周期的初始值
        if isnan(track.isdummy(tmpIdx)) % 如果此帧漏警
            if (tmpIdx + 1) <= k * (step + 1) % 检查下一帧
                if isnan(track.isdummy(tmpIdx + 1)) 
                    stIdx = (k - 1) * (step + 1) + 1; % 取上一周期预测位置
                    initTrack(k).S_hat = [track.x_hat(stIdx), track.y_hat(stIdx), track.xv(stIdx), track.yv(stIdx)]; 
                else
                    initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)];  
                end
            elseif (tmpIdx - 1) > (k - 1) * (step + 1) % 检查上一帧
                if isnan(track.isdummy(tmpIdx - 1)) 
                    stIdx = (k - 1) * (step + 1) + 1; % 取上一周期预测位置
                    initTrack(k).S_hat = [track.x_hat(stIdx), track.y_hat(stIdx), track.xv(stIdx), track.yv(stIdx)]; 
                else
                    initTrack(k).S_hat = [track.x_hat(tmpIdx - 1), track.y_hat(tmpIdx - 1), track.xv(tmpIdx - 1), track.yv(tmpIdx - 1)]; 
                end
            else
                initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)];
            end
        else
            initTrack(k).S_hat = [track.x_hat(tmpIdx), track.y_hat(tmpIdx), track.xv(tmpIdx), track.yv(tmpIdx)]; 
        end        
        initTrack(k).fr = track.fr(end);
    end
%% 一个MHT周期内中间帧
else
    mergeFlag = 0;
    % 构建和更新轨迹家族
    [obsTreeSet stateTreeSet scoreTreeSet idTreeSet activeTreeSet obsTreeSetConfirmed ...
        stateTreeSetConfirmed scoreTreeSetConfirmed activeTreeSetConfirmed familyID trackID treeDel treeConfirmed obsMembership] = formTrackFamily(obsTreeSet,...
        stateTreeSet, scoreTreeSet, idTreeSet, activeTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed,...
        selectedTrackIDs, cur_observation, kalman_param, other_param, familyID, trackID, cur_observation.fr);

    [incompabilityListTreeSet incompabilityListTreeNodeIDSet] = ...
        updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);

    [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, ...
        incompabilityListTreeNodeIDSet, activeTreeSet, other_param);

    [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs flagSelPercent idxMerge] = ...
        generateGlobalHypothesis(scoreTreeSet, obsTreeSet, stateTreeSet, idTreeSet, incompabilityListTreeSet,...
        clusters, ICL_clusters, selectedTrackIDs, other_param, mergeFlag); 
    
    [obsTreeSet, stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, familyID, trackFamilyPrev] = ...
        nScanPruning(bestHypothesis, trackIndexInTrees, obsTreeSet, ...
        stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeSet, ...
        incompabilityListTreeNodeIDSet, activeTreeSet, familyID, treeDel,...
        treeConfirmed, trackFamilyPrev, other_param, rem(cur_observation.fr,step)); 
end