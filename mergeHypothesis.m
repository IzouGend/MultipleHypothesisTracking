function [adjMatNew,weightMatNew,indMerge] = mergeHypothesis(adjMat,weightMat,trkIndInTrees,obsTreeSet,stateTreeSet)

indMerge = [];

trackNo = length(weightMat) - 1;
obsTotal = zeros(trackNo,4);
stateTotal = zeros(trackNo,2);
stateDifThre = 0.2;

% Get two recent observation of tracks
for ii = 1:length(weightMat)-1
    if length(weightMat) == 2
        familyID = trkIndInTrees(1);
        leafNodeInd = trkIndInTrees(2);
    else
        familyID = trkIndInTrees(ii,1);
        leafNodeInd = trkIndInTrees(ii,2);
    end
    
    curObs = obsTreeSet(familyID).get(leafNodeInd);
    obsTotal(ii,1:2) = curObs(1:2);
    
    curState = stateTreeSet(familyID).get(leafNodeInd);
    stateTotal(ii,:) = curState(1:2);
    
    parentNodeInd = obsTreeSet(familyID).getparent(leafNodeInd);
    preObs = obsTreeSet(familyID).get(parentNodeInd);
    obsTotal(ii,3:4) = preObs(1:2);
end

% If two tracks have the same observations, then merge.
delta = 0.005;
isMergedFlag = zeros(1,trackNo);
mergedInd = cell(trackNo,1);
mergedNum = 0;
for ii = 1:trackNo
    if isMergedFlag(ii) ~= 0
        continue;
    else
        isMergedFlag(ii) = 1;
        mergedNum = mergedNum + 1;
        mergedInd{mergedNum,1} = [mergedInd{mergedNum,1},ii];
        for jj = ii+1:trackNo
            if isMergedFlag(jj) ~= 0
                continue;
            end
            if (norm(obsTotal(ii,:)-obsTotal(jj,:))<delta) && (norm(stateTotal(ii,:)-stateTotal(jj,:))<stateDifThre)
                isMergedFlag(jj) = 1;
                mergedInd{mergedNum,1} = [mergedInd{mergedNum,1},jj];
            end
        end
    end
end

% Select the index with max probablity in a merge
for ii = 1:mergedNum
    curWeight = weightMat(mergedInd{ii,1});
    [~,mergCurInd] = max(curWeight);
    mergInd = mergedInd{ii,1}(mergCurInd);
    indMerge = [indMerge mergInd];
end

indNotSel = setdiff(1:trackNo,indMerge);
indMerge = setdiff(1:trackNo,indNotSel);

weightMat(indNotSel) = [];
weightMatNew = weightMat;
adjMat(indNotSel,:) = [];
adjMat(:,indNotSel) = []; 
adjMatNew = adjMat;

end

