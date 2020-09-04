function tracks = getTracksFromHypothesis(bestHypothesis, bestScore, trackIndexInTrees, obsTreeSet, ...
    stateTreeSet, scoreTreeSet, obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, ...
    activeTreeSetConfirmed, treeConfirmed, clusters,other_param)

id = 1;
tracks.x = [];
tracks.y = [];
tracks.x_hat = [];
tracks.y_hat = [];
tracks.fr = [];
tracks.id = [];
tracks.isdummy = [];
%--zy, 200612, kalman-filtered velocity 
tracks.xv = []; 
tracks.yv = [];
%--
%--zy, 200707, P_hat 
tracks.p_hat = [];
%--
% collect confirmed tracks
for i = 1:length(obsTreeSetConfirmed)
    
    treeInd = findleaves(obsTreeSetConfirmed(i));
    
    IndSel = 0;
    ct = 0;
    for j = 1:length(treeInd)
        if activeTreeSetConfirmed(i).get(treeInd(j)) == 1
           IndSel = treeInd(j);
           ct = ct+1;           
        end
    end
    
    % a confirmed tree has only one track branch
    if ct ~= 1
       error('error in a confirmed tree');       
    end
    
    tracks_tmp = collectTrack(obsTreeSetConfirmed, stateTreeSetConfirmed, scoreTreeSetConfirmed, i, IndSel, id, other_param);
    tracks.x = [tracks.x; tracks_tmp.x];
    tracks.y = [tracks.y; tracks_tmp.y];
    tracks.x_hat = [tracks.x_hat; tracks_tmp.x_hat];
    tracks.y_hat = [tracks.y_hat; tracks_tmp.y_hat];
    tracks.fr = [tracks.fr; tracks_tmp.fr];
    tracks.id = [tracks.id; tracks_tmp.id];
    tracks.isdummy = [tracks.isdummy; tracks_tmp.isdummy];
    tracks.xv = [tracks.xv; tracks_tmp.xv]; 
    tracks.yv = [tracks.yv; tracks_tmp.yv]; 
    tracks.p_hat = [tracks.p_hat; tracks_tmp.p_hat];
    id = id+1;

end
bestHypoSortLists = []; %--zhouYang, 200724, 按照树的序号升序存放最佳假设，跟C代码一致
for i = 1:length(clusters)
     scoreTmp = bestScore{i};
     curBestScore = 0;
     idxSel = 1;
     for j = 1:size(bestHypothesis{i},1)        
        if curBestScore < sum(scoreTmp(~~bestHypothesis{i}(j,:)))
            idxSel = j;
            curBestScore = sum(scoreTmp(~~bestHypothesis{i}(j,:)));
        end
     end

     ind = find(bestHypothesis{i}(idxSel,:) == 1);      
     for k = 1:length(ind)          
         treeInd = trackIndexInTrees{i}(ind(k),:);      
         
         % skip confirmed trees
         if sum(treeConfirmed == treeInd(1)) == 1
             continue;
         end
         bestHypoSortLists = [bestHypoSortLists; treeInd(1), treeInd(2)]; % [familyId, branchId]
         
%          tracks_tmp = collectTrack(obsTreeSet, stateTreeSet, scoreTreeSet, treeInd(1),treeInd(2), id, other_param);
%          tracks.x = [tracks.x; tracks_tmp.x];
%          tracks.y = [tracks.y; tracks_tmp.y];
%          tracks.x_hat = [tracks.x_hat; tracks_tmp.x_hat];
%          tracks.y_hat = [tracks.y_hat; tracks_tmp.y_hat];
%          tracks.fr = [tracks.fr; tracks_tmp.fr];
%          tracks.id = [tracks.id; tracks_tmp.id];
%          tracks.isdummy = [tracks.isdummy; tracks_tmp.isdummy];
%          tracks.xv = [tracks.xv; tracks_tmp.xv]; 
%          tracks.yv = [tracks.yv; tracks_tmp.yv]; 
%          tracks.p_hat = [tracks.p_hat; tracks_tmp.p_hat];
%          id = id+1;
     end        
   
end
bestHypoSortLists = sortrows(bestHypoSortLists, 1); 
for k = 1 : size(bestHypoSortLists, 1)
     tracks_tmp = collectTrack(obsTreeSet, stateTreeSet, scoreTreeSet, bestHypoSortLists(k, 1),bestHypoSortLists(k, 2), id, other_param);
     tracks.x = [tracks.x; tracks_tmp.x];
     tracks.y = [tracks.y; tracks_tmp.y];
     tracks.x_hat = [tracks.x_hat; tracks_tmp.x_hat];
     tracks.y_hat = [tracks.y_hat; tracks_tmp.y_hat];
     tracks.fr = [tracks.fr; tracks_tmp.fr];
     tracks.id = [tracks.id; tracks_tmp.id];
     tracks.isdummy = [tracks.isdummy; tracks_tmp.isdummy];
     tracks.xv = [tracks.xv; tracks_tmp.xv]; 
     tracks.yv = [tracks.yv; tracks_tmp.yv]; 
     tracks.p_hat = [tracks.p_hat; tracks_tmp.p_hat];
     id = id+1;    
end
end

function track = collectTrack(obsTreeSet, stateTreeSet, scoreTreeSet, familyID, nodeID, id, other_param)

track.x = [];
track.y = [];
track.x_hat = [];
track.y_hat = [];
track.fr = [];
track.id = [];
track.isdummy = [];
%--zy, 200612, kalman-filtered velocity 
track.xv = []; 
track.yv = [];
track.p_hat = [];
%--

parentNodeID = 1;

while parentNodeID ~= 0
    
    xy = obsTreeSet(familyID).get(nodeID);    
    state = stateTreeSet(familyID).get(nodeID);
    % 量测树和状态树节点可能包含祖先信息
    p_hat = [];
    for k = 1 : floor(size(state,2) / 5)
        tmp = state(:, (k - 1) * 5 + 2 : k * 5);
        p_hat = [p_hat; reshape(tmp, [1 16])];
    end
    % *******
    xy_state = state(:,1:5:end)';
    
%     if parentNodeID == 1
%        score = scoreTreeSet(familyID).get(nodeID); 
%        score = score(2);
%     end
    
    if other_param.is3Dtracking
        [x_state y_state]=projectToImage(xy_state(:,1),xy_state(:,2),other_param.camParam);  
        track.x = [xy(end:-1:1,1); track.x];
        track.y = [xy(end:-1:1,2); track.y];
        track.x_hat = [x_state(end:-1:1); track.x_hat];
        track.y_hat = [y_state(end:-1:1); track.y_hat];
        track.fr = [xy(end:-1:1,3); track.fr];
        track.id = [id*ones(length(xy(end:-1:1,3)),1); track.id];
        track.isdummy = [xy(end:-1:1,7); track.isdummy];        
    else
        track.x = [xy(end:-1:1,1); track.x];
        track.y = [xy(end:-1:1,2); track.y];
        track.x_hat = [xy_state(end:-1:1,1); track.x_hat];
        track.y_hat = [xy_state(end:-1:1,2); track.y_hat];
        track.fr = [xy(end:-1:1,3); track.fr];
        track.id = [id*ones(length(xy(end:-1:1,3)),1); track.id];
        track.isdummy = [xy(end:-1:1,7); track.isdummy];
        track.xv = [xy_state(end:-1:1,3); track.xv]; 
        track.yv = [xy_state(end:-1:1,4); track.yv];
        track.p_hat = [p_hat(end:-1:1, :); track.p_hat];
    end
    
    parentNodeID = obsTreeSet(familyID).getparent(nodeID);
    nodeID = parentNodeID;

end

end





