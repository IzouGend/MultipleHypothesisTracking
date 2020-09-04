function [incompabilityListTreeSet incompabilityListTreeNodeIDSet] = updateICL(obsTreeSet, idTreeSet, incompabilityListTreeNodeIDSetPrev,activeTreeSet, cur_observation, obsMembership)

familyNo = length(obsTreeSet);
if familyNo ~= 0
    incompabilityListTreeSet(familyNo,1) = tree;
    incompabilityListTreeNodeIDSet(familyNo,1) = tree;
else
    incompabilityListTreeSet = [];
    incompabilityListTreeNodeIDSet = [];
    return
end


% initialize the incompability lists
for i = 1:familyNo        
    incompabilityListTreeSet(i) = tree(idTreeSet(i), 'clear');
    incompabilityListTreeNodeIDSet(i) = tree(idTreeSet(i), 'clear');
end

% 由于树操作较慢，将树的信息存储到表中
treeIndCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
trackIDCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
ICLCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
indexMapping = cell(length(incompabilityListTreeNodeIDSetPrev),1);
familyIdMapping = zeros(familyNo, 1); %zy, 200615
for i = 1:length(incompabilityListTreeNodeIDSetPrev)
   tmpVal = (idTreeSet(i).get(1));
   familyIdMapping(i) = tmpVal(1); % 取familyID
   treeInd = findleaves(incompabilityListTreeNodeIDSetPrev(i));
   treeIndCache{i} = cell(length(treeInd),1); % 每棵前一帧不兼容树i的叶子节点j在当前帧的所有k个子节点信息[familyID branchInd]列表
   trackIDCache{i} = cell(length(treeInd),1); % 每棵前一帧不兼容树i的叶子节点j在当前帧的所有k个子节点信息[familyID trackID]列表
   ICLCache{i}     = cell(length(treeInd),1); % 每棵前一帧不兼容树i的叶子节点j的内容,即[familyID branchInd]列表
   indexMapping{i} = zeros(treeInd(end),1); % 每棵前一帧不兼容树i的叶子节点j的branchInd与ICLCache{i}中索引j的映射关系
   for j = 1:length(treeInd)       
       ICLCache{i}{j} = incompabilityListTreeNodeIDSetPrev(i).get(treeInd(j)); % incompabilityListTreeNodeIDSetPrev叶节点内容：[familyID branchInd]列表
       indexMapping{i}(treeInd(j)) = j;
       
       childList = idTreeSet(i).getchildren(treeInd(j)); % 对应当前帧的叶子节点
       
       if ~isempty(childList)
           % 1.先存放拥有同一个父节点的所有叶节点（同一棵树上互不兼容）
           treeIndCache{i}{j} = zeros(length(childList),2);  % [familyID branchInd]
           trackIDCache{i}{j} = zeros(length(childList),2);  % [familyID trackID]
           for k = 1:length(childList)
               if activeTreeSet(i).get(childList(k)) ~= 1
                   continue;
               end
               treeIndCache{i}{j}(k,:) = [i childList(k)];
               trackIDCache{i}{j}(k,:) = idTreeSet(i).get(childList(k));
           end
           % 删除non-active nodes对应的行
           idx = (trackIDCache{i}{j}(:,2)==0);
           trackIDCache{i}{j}(idx,:) = [];
           treeIndCache{i}{j}(idx,:) = [];
       end       
   end
end

% delete nonactive tracks 
% 删除obsMembership中nonactive nodes对应的信息
for i = 1:length(obsMembership)
   if ~isempty(obsMembership{i})
       obsInd = zeros(size(obsMembership{i},1),1);
       for j = 1:size(obsMembership{i},1)
           if activeTreeSet(obsMembership{i}(j,1)).get(obsMembership{i}(j,2)) ~= 1
               obsInd(j) = 1;
           end
       end
       obsInd = ~~obsInd;
       obsMembership{i}(obsInd,:) = [];
   end
end

% 寻找不兼容的轨迹
for i = 1:familyNo
   treeInd = findleaves(obsTreeSet(i));    
   % 对于当前观察树上的每个叶节点求与其不兼容的叶节点（跨树）
   for j = 1:length(treeInd) 
       
       if activeTreeSet(i).get(treeInd(j)) ~= 1
           continue;
       end
       
       idTemp = idTreeSet(i).getparent(treeInd(j)); % 当前帧量测树/id树叶子节点的父节点的branchIdx
       % 寻找相同家族的不兼容轨迹。这个操作在新的家族创建时完成
       % 新起的树
       if idTemp == 0        
           incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),idTreeSet(i).get(treeInd(j)));   
           incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j), [i treeInd(j)]);
           
       % 不是根节点
       % 从父节点中寻找不兼容的轨迹 
       else    
            % 上一帧不兼容树的节点值
            % ?????
            iclParentTemp = ICLCache{i}{indexMapping{i}(idTemp)}; % 当前节点的父节点的所有不兼容节点,即[familyID branchInd]列表
            incompabilityListSet = [];
            incompabilityNodeIDListSet = [];
            % 2.再加入与当前节点的父节点处于同一层次且不兼容的节点的子节点（其他树上的当前层次叶节点）
            % 注意，iclParentTemp列表中可能包括当前节点的父节点在同一棵树的兄弟节点
            for k = 1:size(iclParentTemp,1)
                familyIDTemp = find(familyIdMapping == iclParentTemp(k,1));
%                 familyIDTemp = iclParentTemp(k,1);
                branchIndTemp = iclParentTemp(k,2);
                trackSelInd = indexMapping{familyIDTemp}(branchIndTemp);          
                if trackSelInd == 0 % 表示前一帧不兼容树familyIDTemp中brancIndTemp节点已经不存在了。那什么时候将该节点删除的呢？剪枝的时候。
                    iclTrackListTemp = [];
                    iclIndListTemp = [];
                else
                    % 与当前节点处于同一层次且不兼容的某棵树的某个节点的不兼容节点（仅某个节点同一个父节点的所有叶节点）
                    iclTrackListTemp = trackIDCache{familyIDTemp}{trackSelInd}; 
                    iclIndListTemp = treeIndCache{familyIDTemp}{trackSelInd};
                end
                
        
                if ~isempty(iclTrackListTemp)                     
                    incompabilityListSet = [incompabilityListSet; iclTrackListTemp];
                    incompabilityNodeIDListSet = [incompabilityNodeIDListSet; iclIndListTemp];                    
                end
            end
            incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j), incompabilityListSet); 
            incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j), incompabilityNodeIDListSet);             
       end
       
       % 3.最后找出共用当前量测值的所有节点（不兼容），此次可能产生冗余
       % find incompatible tracks from other families
       sel_observation1 = obsTreeSet(i).get(treeInd(j));              
       
       % 对于miss节点不作共用量测判断
       if ~isnan(sel_observation1(end))     
           ind1 = cur_observation.x == sel_observation1(1);
           ind2 = cur_observation.y == sel_observation1(2);
           % 找出共用当前量测值的所有跟踪轨迹（包括树内外）
           iclSel = cell2mat(obsMembership(ind1 & ind2)); % [familyID branchIndex trackID]
           if ~isempty(iclSel)                        
               incompatibleTrackList = [incompabilityListTreeSet(i).get(treeInd(j)); iclSel(:,[1 3])];
               incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),incompatibleTrackList);   
       
               incompatibleTrackList = [incompabilityListTreeNodeIDSet(i).get(treeInd(j)); iclSel(:,1:2)];
               incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j),incompatibleTrackList);   
           end
       end
       % 去冗余
       % remove redundant tracks from the list
       incompabilityListSet = incompabilityListTreeSet(i).get(treeInd(j));
       [incompabilityListSet index] = unique(incompabilityListSet,'rows');
       incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),incompabilityListSet);
       
       incompabilityListSet = incompabilityListTreeNodeIDSet(i).get(treeInd(j));
       incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j),incompabilityListSet(index,:));
   end        
end

end


