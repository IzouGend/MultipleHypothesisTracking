function activeTreeSet = activateTrackBranch(scoreTreeSet,obsTreeSet,activeTreeSet,other_param,cur_time)

treeInd = findleaves(scoreTreeSet);
tabuList = zeros(1,length(treeInd));
score = [];            
for j = 1:length(treeInd)
    obsSel = obsTreeSet.get(treeInd(j));
               
    % ?
    if obsSel(3) ~= cur_time
        tabuList(j) = treeInd(j);
        continue;
    end
    scoreSel = scoreTreeSet.get(treeInd(j));               
    score = [score scoreSel(1)];               
%     if scoreSel(2) == 0
%         error('error in the confidence score of the current observation');
%     end
        
end
     
% NOTE: assumed that treeInd is always sorted. otherwise, treeInd and score will not be synced anymore.
treeInd = setdiff(treeInd, tabuList);

% error check
if length(treeInd) ~= length(score)
    error('something wrong happened in the track tree branch pruning'); 
end
            
if length(treeInd) > other_param.maxActiveTrackPerTree
    [~, indexSorted] = sort(score,'descend');                                                                              
    indexSorted = indexSorted(1:other_param.maxActiveTrackPerTree);
                
    for j = 1:length(indexSorted)
        activeTreeSet = activeTreeSet.set(treeInd(indexSorted(j)),1);
    end
else
    % if the number of track branches is smaller than the threshold, activate all track branches
    for j = 1:length(treeInd)
        activeTreeSet = activeTreeSet.set(treeInd(j),1);
    end
end
            
end