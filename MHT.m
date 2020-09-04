function track = MHT(observation, initTrack, kalman_param, other_param)

initTrackNum = length(initTrack); % 前一帧航迹数
setVariables;
%% init variables with given track info
initTrackFimaly;
% init the incompability list
[incompabilityListTreeSet incompabilityListTreeNodeIDSet]= updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);
% init the clusters
[clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, other_param);
% init the global hypothesis
mergeFlag = 0;
% [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs] = generateGlobalHypothesis(scoreTreeSet,obsTreeSet,stateTreeSet,idTreeSet, incompabilityListTreeSet, clusters, ICL_clusters, selectedTrackIDs, other_param, mergeFlag);    


%% start MHT
for k = firstFrame:lastFrame
    
    % observation at time k
    idx = find(observation.fr == k);
    cur_observation.x = observation.x(idx);
    cur_observation.y = observation.y(idx);
    cur_observation.fr = observation.fr(idx);  
    cur_observation.pointNum = observation.pointNum(idx); % for TI Kalman-filter
    if k >= 670
        watchFlag = 1;
    end
    % 构建和更新轨迹家族
    disp(sprintf('\nUpdating track trees at time %d',k));
    [obsTreeSet stateTreeSet scoreTreeSet idTreeSet activeTreeSet obsTreeSetConfirmed ...
        stateTreeSetConfirmed scoreTreeSetConfirmed activeTreeSetConfirmed familyID trackID treeDel treeConfirmed obsMembership] = formTrackFamily(obsTreeSet,...
        stateTreeSet, scoreTreeSet, idTreeSet, activeTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed,...
        selectedTrackIDs, cur_observation, kalman_param, other_param, familyID, trackID, k);       
                                                                                                                                                                                                                               
    if length(obsTreeSet) < 3
        watchFlag = 1;
    end                                                                                                                                                                                                                    
    % update the incompability list
    disp(sprintf('\nUpdating the incompability list at time %d',k));
    [incompabilityListTreeSet incompabilityListTreeNodeIDSet]= updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, cur_observation, obsMembership);
    
    if length(incompabilityListTreeNodeIDSet) < 3
        watchFlag = 1;
    end
    % update the clusters
    disp(sprintf('\nUpdating clusters at time %d',k));
    [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, other_param);
    
    % generate the global hypothesis
    disp(sprintf('\nGenerating the global hypothesis at time %d',k));
    if k == lastFrame
        mergeFlag = 1;
    else
        mergeFlag = 0;
    end
    [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs] = ...
        generateGlobalHypothesis(scoreTreeSet, obsTreeSet, stateTreeSet, idTreeSet, incompabilityListTreeSet, clusters, ICL_clusters, selectedTrackIDs, other_param);    
    
    % save the output
    if k == lastFrame
        track = getTracksFromHypothesis(bestHypothesis, bestScore, trackIndexInTrees, obsTreeSet, stateTreeSet, scoreTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed, treeConfirmed, clusters, other_param);
%         track = getFinalTracks(track, kalman_param, other_param);
%         printTracks(track, length(obsTreeSet));
        watchFlag = 1;
    else
        
        % N scan pruning
    %     disp(sprintf('\nRunning N scan pruning at time %d',k));
        [obsTreeSet, stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, familyID, trackFamilyPrev] = nScanPruning(bestHypothesis, trackIndexInTrees, obsTreeSet, ...
                                                                                                                                                stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeSet, ...
                                                                                                                                                incompabilityListTreeNodeIDSet, activeTreeSet, familyID, treeDel, treeConfirmed, trackFamilyPrev, other_param, k - firstFrame + 1);          
    end       
    if length(incompabilityListTreeNodeIDSet) < 3
        watchFlag = 1;
    end
end

