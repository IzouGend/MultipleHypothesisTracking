function [obsTreeSetPrev, stateTreeSetPrev, scoreTreeSetPrev, idTreeSetPrev, activeTreeSetPrev, trackID, obsUsed] = updateNewObservation(obsTreeSetPrev, stateTreeSetPrev, scoreTreeSetPrev, idTreeSetPrev, activeTreeSetPrev, ...
                                                                                                                                    treeInd, cur_observation, kalman_param, other_param, familyID, trackID)
        
    % update the number of observations in the current track   
    obsPrev = obsTreeSetPrev.get(treeInd);
    obsNo = obsPrev(4)+1;  
    totalDummyNo = obsPrev(6);
    isDummyNode = obsPrev(7);
    
    kalman_Q_adjusted = kalman_param.Q_adjusted;
    kalman_R_adjusted = kalman_param.R_adjusted;
%     if ~other_param.is3Dtracking
%         % set error covariance by the width of bounding box
%         kalman_Q_adjusted = (kalman_param.covWeight1*obsPrev(3))^2*eye(kalman_param.ss);
%         kalman_R_adjusted = (kalman_param.covWeight1*obsPrev(3))^2*eye(kalman_param.os);
%         kalman_Q_adjusted(3,3) = kalman_param.covWeight2*obsPrev(3);
%         kalman_Q_adjusted(4,4) = kalman_param.covWeight2*obsPrev(3);
%     else
%         kalman_Q_adjusted = kalman_param.Q;
%         kalman_R_adjusted = kalman_param.R;
%     end
        
    stateEstimate = stateTreeSetPrev.get(treeInd);
    statePredict = kalman_param.F*stateEstimate(:,1);
    vPredict = kalman_param.F*stateEstimate(:,2:5)*kalman_param.F' + kalman_Q_adjusted;
    errorCov = kalman_param.H*vPredict*kalman_param.H' + kalman_R_adjusted;
    
    statePredictMat = repmat(statePredict',length(cur_observation.x),1);
    observations = [cur_observation.x' cur_observation.y'];
    
    distance = ((observations - statePredictMat(:,1:2))/errorCov)*(observations - statePredictMat(:,1:2))';
    
    % find observation within the gating area
    obsInd1 = diag(distance) <= other_param.MahalanobisDist;
    
    obsInd = find(obsInd1);
    
    if isempty(obsInd)
        obsInd1 = diag(distance) <= 1.5*other_param.MahalanobisDist;

        obsInd = find(obsInd1);
    end
    
    obsUsed = zeros(length(obsInd1),3);  % [Indicator BranchIndex TrackID]
    
    scoreSel = scoreTreeSetPrev.get(treeInd);    
    loglikPrev = scoreSel(1);
    for i = 1:length(obsInd) 
       [stateEstimateTmp, V, LL, W] = kalman_update(kalman_param.F, kalman_param.H, kalman_Q_adjusted, kalman_R_adjusted, ...
                                                [cur_observation.x(obsInd(i)); cur_observation.y(obsInd(i))], stateEstimate(:,1), stateEstimate(:,2:5), 'initial', 0);

       LL = LL-log(other_param.pFalseAlarm);
       loglik = loglikPrev + LL;                                    

       [obsTreeSetPrev branchInd] = obsTreeSetPrev.addnode(treeInd, [cur_observation.x(obsInd(i)) cur_observation.y(obsInd(i)) cur_observation.fr(obsInd(i)) obsNo 0 totalDummyNo 0]);                                 
       stateTreeSetPrev = stateTreeSetPrev.addnode(treeInd, [stateEstimateTmp V]);
       scoreTreeSetPrev = scoreTreeSetPrev.addnode(treeInd, loglik);
       idTreeSetPrev = idTreeSetPrev.addnode(treeInd, [familyID trackID]);
       activeTreeSetPrev = activeTreeSetPrev.addnode(treeInd, 0);        
       obsUsed(obsInd(i),:) = [1 branchInd trackID];           

       trackID = trackID + uint64(1);                      
    end
    
end 