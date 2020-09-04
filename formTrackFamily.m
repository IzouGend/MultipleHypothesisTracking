function [obsTreeSetNew stateTreeSetNew scoreTreeSetNew idTreeSetNew activeTreeSetNew obsTreeSetConfirmed stateTreeSetConfirmed scoreTreeSetConfirmed activeTreeSetConfirmed familyID trackID treeDel treeConfirmed obsMembership] = formTrackFamily(obsTreeSetPrev, stateTreeSetPrev, scoreTreeSetPrev, idTreeSetPrev, activeTreeSetPrev, ...
                                                                                                                                                                                                        obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, activeTreeSetConfirmed,...
                                                                                                                                                                                                        selectedTrackIDs, cur_observation, kalman_param, other_param, familyID, trackID, cur_time) 
    observationNo = length(cur_observation.x);
    familyNo = length(obsTreeSetPrev);
    
    if observationNo ~= 0
        obsTreeSet(observationNo,1) = tree;
        stateTreeSet(observationNo,1) = tree;
        scoreTreeSet(observationNo,1) = tree;
        idTreeSet(observationNo,1) = tree;
        activeTreeSet(observationNo,1) = tree;   
        obsMembership = cell(length(cur_observation.x),1);  
    else
        obsTreeSet = [];
        stateTreeSet = [];
        scoreTreeSet = [];
        idTreeSet = [];
        activeTreeSet = [];    
        obsMembership = [];  
    end
    

    kalman_Q_adjusted = kalman_param.Q_adjusted;
    % 起始新的航迹
%     ct = 1;       
%     for i = 1:observationNo                             
%             % initialize track score
%             loglik = 1*(1/other_param.const);
% %             loglik = log(cur_observation.sc(i)/(1-cur_observation.sc(i)+eps));
% 
% %             if other_param.isAppModel                                                           
% %                 % initialize an appearance model          
% %                 indSel = setdiff(1:observationNo,i);  
% %                 appModel = LinearRegressor_Data([cur_observation.app(i,:) ; cur_observation.app(indSel,:)], [1; -1*ones(length(indSel),1)]); 
% %             else
% %                 appModel = [];
% %             end
%             
%             % set the initial error cov by the width of the bounding box 
%             if ~other_param.is3Dtracking
%                 kalman_initV_adjusted = (kalman_param.covWeight1*cur_observation.w(i))^2*eye(kalman_param.ss);
%                 kalman_initV_adjusted(3,3) = kalman_param.covWeight2*cur_observation.w(i);
%                 kalman_initV_adjusted(4,4) = kalman_param.covWeight2*cur_observation.w(i);             
%             else
%                 kalman_initV_adjusted = kalman_param.initV;
%             end
%                  
%             % 新航迹状态估计值(x,y,0,0)
%             stateEstimate = [cur_observation.x(i); cur_observation.y(i); 0; 0];
%             obsTreeSet(ct) = tree([cur_observation.x(i) cur_observation.y(i) cur_observation.fr(i) 1 0 0 1]);       % last four elements : (1) the number of observation nodes (2) the number of dummy nodes (3) the number of total dummy nodes (4) a dummy node indicator        
%             stateTreeSet(ct) = tree([stateEstimate kalman_initV_adjusted]);      
%             scoreTreeSet(ct) = tree(loglik); 
%             idTreeSet(ct) = tree([familyID trackID]);  % [familyID trackID]
%             activeTreeSet(ct) = tree(1);
% 
%             obsMembership{i} = [obsMembership{i}; [familyID 1 trackID]]; % [familyID branchIndex trackID]   
%             
%             familyID = familyID + 1;       
%             trackID = trackID + uint64(1);
%             ct = ct+1;
%     end
    
    % 用新的观测或者隐观测来更新轨迹
    treeDel = [];   
    treeConfirmed = [];
    for i = 1:familyNo
        treeInd = findleaves(obsTreeSetPrev(i));
        tabuList = zeros(1,length(treeInd));
        ct1 = 0; 
        ct2 = 0;
        
        for j = 1:length(treeInd)                      
            
           % 检测航迹是否有效
           if activeTreeSetPrev(i).get(treeInd(j)) == 0
               tabuList(j) = treeInd(j);
               continue;
           end
            
           % 采用隐节点更新
           previousObservation = obsTreeSetPrev(i).get(treeInd(j));
           stateEstimate = stateTreeSetPrev(i).get(treeInd(j));    
           
           % 没有目标,kalman更新
           statePredict_missOBS = kalman_param.F*stateEstimate(:,1);       
           scoreSel = scoreTreeSetPrev(i).get(treeInd(j));      
           loglik = scoreSel(1);
           
           ID_tmp = idTreeSetPrev(i).get(treeInd(j));
           familyID_tmp = ID_tmp(1);
           trackID_tmp = ID_tmp(2);
           obsNo = previousObservation(4);
           dummyNo = previousObservation(5)+1;
           totalDummyNo = previousObservation(6)+1;  
           
           % 航迹未被确认
           if dummyNo < other_param.dummyNumberTH               
               % 增加惩罚项 ************是否合理？
%                loglik = max(loglik + (1/other_param.const)*log(1-other_param.pDetection),1*(1/other_param.const)); 
               loglik =max(loglik + (1/other_param.const)*log(1-other_param.pDetection), 0); % zy, 200618, 设下限为0

               %    误差协方差矩阵更新
               vPredict = kalman_param.F*stateEstimate(:,2:5)*kalman_param.F' + ((other_param.dummyNumberTH-dummyNo)/other_param.dummyNumberTH)*kalman_Q_adjusted;       
               statePredict = statePredict_missOBS;                             
           else               
               statePredict = statePredict_missOBS;
               vPredict = stateEstimate(:,2:5); 
           end
           % 加入隐节点
           obsTreeSetPrev(i) = obsTreeSetPrev(i).addnode(treeInd(j),[previousObservation(1) previousObservation(2) cur_time obsNo dummyNo totalDummyNo NaN]); 
           stateTreeSetPrev(i) = stateTreeSetPrev(i).addnode(treeInd(j),[statePredict vPredict]);
           scoreTreeSetPrev(i) = scoreTreeSetPrev(i).addnode(treeInd(j),loglik); 
           idTreeSetPrev(i) = idTreeSetPrev(i).addnode(treeInd(j),[familyID_tmp trackID_tmp]);          
           
           if sum(selectedTrackIDs == trackID_tmp) ~= 1
               activeTreeSetPrev(i) = activeTreeSetPrev(i).addnode(treeInd(j), 0);
           else
               activeTreeSetPrev(i) = activeTreeSetPrev(i).addnode(treeInd(j), 1);
           end                      
           
           if observationNo ~= 0
           % update with a new observation if a track is not confirmed yet
           if dummyNo < other_param.dummyNumberTH               
               [obsTreeSetPrev(i), stateTreeSetPrev(i), scoreTreeSetPrev(i), idTreeSetPrev(i) activeTreeSetPrev(i) trackID obsUsed] = updateNewObservation(obsTreeSetPrev(i),stateTreeSetPrev(i),scoreTreeSetPrev(i),idTreeSetPrev(i),activeTreeSetPrev(i), ...
                                                                                                            treeInd(j),cur_observation,kalman_param,other_param,familyID_tmp,trackID); 
               
               
               % save observation memberships for speeding up the updateICL function
               tryInd = find(obsUsed(:,1));
               for k = 1:length(tryInd)
                   obsMembership{tryInd(k)} = [obsMembership{tryInd(k)}; [i obsUsed(tryInd(k),2:3)]]; % [familyID branchIndex trackID]
               end                              
               
           elseif 0 || (totalDummyNo-dummyNo)/(obsNo+totalDummyNo-dummyNo) >= other_param.dummyRatioTH
               ct1 = ct1+1;
           else
               ct2 = ct2+1; % count good tracks that have been confirmed
           end
                               
           end         
        end

        
        % tree deletion 
%         tabuList = tabuList(tabuList ~= 0);        
%         if ct1 == length(treeInd) - length(tabuList)  
%             % tree deletion when all tree branches are dead
%             treeDel = [treeDel; i]; 
%         % tree confirmation
%         elseif ct2 == length(treeInd) - length(tabuList) && ct2 == 1            
%             treeConfirmed = [treeConfirmed; i];
        if ct2 == length(treeInd) - length(tabuList) && ct2 == 1            
            treeConfirmed = [treeConfirmed; i];
        % branch pruning
        else 
            % prune track branches based on its score
            activeTreeSetPrev(i) = activateTrackBranch(scoreTreeSetPrev(i),obsTreeSetPrev(i),activeTreeSetPrev(i),other_param,cur_time);            
        end
    end       
    
    obsTreeSetConfirmed = [obsTreeSetPrev(treeConfirmed); obsTreeSetConfirmed];
    stateTreeSetConfirmed = [stateTreeSetPrev(treeConfirmed); stateTreeSetConfirmed];       
    scoreTreeSetConfirmed = [scoreTreeSetPrev(treeConfirmed); scoreTreeSetConfirmed];    
    activeTreeSetConfirmed = [activeTreeSetPrev(treeConfirmed); activeTreeSetConfirmed];
    
    % 不用新起航迹，树的规模不必增加
%     obsTreeSetNew = [obsTreeSetPrev; obsTreeSet];
%     stateTreeSetNew = [stateTreeSetPrev; stateTreeSet];       
%     scoreTreeSetNew = [scoreTreeSetPrev; scoreTreeSet];    
%     idTreeSetNew = [idTreeSetPrev; idTreeSet];
%     activeTreeSetNew = [activeTreeSetPrev; activeTreeSet];
    obsTreeSetNew = obsTreeSetPrev;
    stateTreeSetNew = stateTreeSetPrev;       
    scoreTreeSetNew = scoreTreeSetPrev;    
    idTreeSetNew = idTreeSetPrev;
    activeTreeSetNew = activeTreeSetPrev;
    
end

