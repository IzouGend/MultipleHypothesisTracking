function [obsTreeSet, stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, familyID, trackFamilyNew] = nScanPruning(bestHypothesis, trackIndexInTrees, obsTreeSetPrev, ...
                                                                                                                             stateTreeSetPrev, scoreTreeSetPrev, idTreeSetPrev, incompabilityListTreeSetPrev, incompabilityListTreeNodeIDSetPrev, activeTreeSetPrev, ...
                                                                                                                             familyID, treeDel, treeConfirmed, trackFamilyPrev, other_param, cur_time)
    
familyNo = length(obsTreeSetPrev);
                                                                                                                         
% if cur_time <= other_param.N + 1  || familyNo == 0 
if cur_time <= other_param.N || familyNo == 0 % zy, 200619, pruning one frame in advance
    
    % select unconfirmed trees only
    idSel = setdiff(1:familyNo,treeConfirmed);
    
    obsTreeSet = obsTreeSetPrev(idSel);
    stateTreeSet = stateTreeSetPrev(idSel);
    scoreTreeSet = scoreTreeSetPrev(idSel);
    idTreeSet = idTreeSetPrev(idSel);
    incompabilityListTreeNodeIDSet = incompabilityListTreeNodeIDSetPrev(idSel);
    activeTreeSet = activeTreeSetPrev(idSel);
%--zy, 200706, trackFamily未使用，C代码中忽略  
    if ~isempty(trackFamilyPrev)
        trackFamilyNew = trackFamilyPrev(idSel);
    else
        trackFamilyNew = trackFamilyPrev;
    end
%--    
    return;
end

trackFamilyNew = zeros(length(obsTreeSetPrev),4);
hypoNo = length(bestHypothesis);
familyID = 1;


% select the trees in the best hypothesis
treeIDselected = [];
currentTrackList = [];
currentTrackIndList = [];
for i = 1:hypoNo
    
    if size(bestHypothesis{i},1) > 1
        % ********这是什么意思？
        bestTracks = ~~sum(bestHypothesis{i});
    else
        bestTracks = bestHypothesis{i};
    end
    
    ind = find(bestTracks == 1);       

    for k = 1:length(ind)          
        treeInd = trackIndexInTrees{i}(ind(k),:);        
        familyIDPrev = treeInd(1);
        parentInd = treeInd(2);
        parentIndPrev = 1;      
        
        % delete bad trees
        if sum(treeDel == familyIDPrev) == 1
            continue;
        elseif sum(treeDel == familyIDPrev) > 1
            error('something wrong happened in selecting bad trees');
        end
        
        % skip confirmed trees
        if sum(treeConfirmed == familyIDPrev) == 1
            continue;
        elseif sum(treeConfirmed == familyIDPrev) > 1
            error('something wrong happened in selecting confirmed trees');
        end
        
        for w = 1:other_param.N
            parentInd = obsTreeSetPrev(familyIDPrev).getparent(parentInd);                  
           
            if parentInd == 0
                break;
            end
            
            parentIndPrev = parentInd;
        end
        
        % check if a new track shares the same root node of any new selected trees. If so, skip the track.
        redundancyCheck = unique([treeIDselected; [familyIDPrev parentIndPrev]],'rows');
        if size(redundancyCheck,1) == size(treeIDselected,1)
            continue;
        end
        
        treeIDselected = [treeIDselected; [familyIDPrev parentIndPrev]];        
                
        familyID = familyIDPrev; %--zy, 200723, 与C代码一致
        if parentInd == 0 
            obsTreeSet(familyID,1) = obsTreeSetPrev(familyIDPrev);
            stateTreeSet(familyID,1) = stateTreeSetPrev(familyIDPrev);
            scoreTreeSet(familyID,1) = scoreTreeSetPrev(familyIDPrev);
            idTreeSet(familyID,1) = idTreeSetPrev(familyIDPrev);
            incompabilityListTreeSet(familyID,1) = incompabilityListTreeSetPrev(familyIDPrev);
            incompabilityListTreeNodeIDSet(familyID,1) = incompabilityListTreeNodeIDSetPrev(familyIDPrev);
            activeTreeSet(familyID,1) = activeTreeSetPrev(familyIDPrev);
        else
            % define a new root node at k-N scan
            % [appTreeSet(familyID,1),~,iterator] = appTreeSetPrev(familyIDPrev).subtree(parentIndPrev);  % iterator is computed once and reused for other calls
            [obsTreeSet(familyID,1),~,iterator] = obsTreeSetPrev(familyIDPrev).subtree(parentIndPrev);  % iterator is computed once and reused for other calls
             obsTreeSet(familyID,1) = obsTreeSetPrev(familyIDPrev).subtree2(iterator);
            stateTreeSet(familyID,1) = stateTreeSetPrev(familyIDPrev).subtree2(iterator);
            scoreTreeSet(familyID,1) = scoreTreeSetPrev(familyIDPrev).subtree2(iterator);
            idTreeSet(familyID,1) = idTreeSetPrev(familyIDPrev).subtree2(iterator);
            incompabilityListTreeSet(familyID,1) = incompabilityListTreeSetPrev(familyIDPrev).subtree2(iterator);
            incompabilityListTreeNodeIDSet(familyID,1) = incompabilityListTreeNodeIDSetPrev(familyIDPrev).subtree2(iterator);
            activeTreeSet(familyID,1) = activeTreeSetPrev(familyIDPrev).subtree2(iterator);

            % include the hard-decisioned part of the track in the root node
            parentInd = parentIndPrev;
            observations = obsTreeSetPrev(familyIDPrev).get(parentInd);
            states = stateTreeSetPrev(familyIDPrev).get(parentInd);
            while parentInd ~= 0
                parentInd = obsTreeSetPrev(familyIDPrev).getparent(parentInd);                

                if parentInd == 0
                    break;
                end

                observation_tmp = obsTreeSetPrev(familyIDPrev).get(parentInd);
                observations = [observations; observation_tmp];   

                state_tmp = stateTreeSetPrev(familyIDPrev).get(parentInd);
                states = [states state_tmp];                
            end
            obsTreeSet(familyID) = obsTreeSet(familyID).set(1, observations);
            stateTreeSet(familyID) = stateTreeSet(familyID).set(1, states);
        end
            
        % reset the track ID and tree index
        %--zy, 200616, adding root node reset
        nodeVal = idTreeSet(familyID).get(1); 
        idTreeSet(familyID) = idTreeSet(familyID).set(1, [familyID nodeVal(2)]);
        %--
        index = findleaves(idTreeSet(familyID));
        currentTrackList_tmp = zeros(length(index),2);
        currentTrackIndList_tmp = zeros(length(index),2);
        iterNo = length(index);
        w = 1;
        while w < iterNo+1
            
            if activeTreeSet(familyID).get(index(w)) ~= 1
                w = w+1;
                continue;
            end
            
            nodeVal = idTreeSet(familyID).get(index(w));            
            
            idTreeSet(familyID) = idTreeSet(familyID).set(index(w), [familyID nodeVal(2)]);
            currentTrackList_tmp(w,:) = [familyID nodeVal(2)];
            currentTrackIndList_tmp(w,:) = [familyID index(w)];
            w = w+1;
        end
        
        indSel = currentTrackList_tmp(:,1) ~= 0;        
        
        currentTrackList = [currentTrackList; currentTrackList_tmp(indSel,:)];
        currentTrackIndList = [currentTrackIndList; currentTrackIndList_tmp(indSel,:)];                        
        
        familyID = familyID + 1;
    end       
end

% reset the incompability list
familyNo = length(idTreeSet);
for i = 1:familyNo
    
    index = findleaves(incompabilityListTreeSet(i));
           
    for w = index               
        
        if activeTreeSet(i).get(w) ~= 1
            continue;
        end
        
        icl = incompabilityListTreeSet(i).get(w);
                
        [~, indSel] = intersect(currentTrackList(:,2), icl(:,2));        
        
        % remove pruned tracks from ICL
        icl = currentTrackList(indSel,:);
        iclInd = currentTrackIndList(indSel,:);
                               
        % update the ICL trees                  
        incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(w, iclInd);
    end            
end

end                                                                                                                     