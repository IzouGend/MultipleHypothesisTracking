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

% ������������������������Ϣ�洢������
treeIndCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
trackIDCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
ICLCache = cell(length(incompabilityListTreeNodeIDSetPrev),1);
indexMapping = cell(length(incompabilityListTreeNodeIDSetPrev),1);
familyIdMapping = zeros(familyNo, 1); %zy, 200615
for i = 1:length(incompabilityListTreeNodeIDSetPrev)
   tmpVal = (idTreeSet(i).get(1));
   familyIdMapping(i) = tmpVal(1); % ȡfamilyID
   treeInd = findleaves(incompabilityListTreeNodeIDSetPrev(i));
   treeIndCache{i} = cell(length(treeInd),1); % ÿ��ǰһ֡��������i��Ҷ�ӽڵ�j�ڵ�ǰ֡������k���ӽڵ���Ϣ[familyID branchInd]�б�
   trackIDCache{i} = cell(length(treeInd),1); % ÿ��ǰһ֡��������i��Ҷ�ӽڵ�j�ڵ�ǰ֡������k���ӽڵ���Ϣ[familyID trackID]�б�
   ICLCache{i}     = cell(length(treeInd),1); % ÿ��ǰһ֡��������i��Ҷ�ӽڵ�j������,��[familyID branchInd]�б�
   indexMapping{i} = zeros(treeInd(end),1); % ÿ��ǰһ֡��������i��Ҷ�ӽڵ�j��branchInd��ICLCache{i}������j��ӳ���ϵ
   for j = 1:length(treeInd)       
       ICLCache{i}{j} = incompabilityListTreeNodeIDSetPrev(i).get(treeInd(j)); % incompabilityListTreeNodeIDSetPrevҶ�ڵ����ݣ�[familyID branchInd]�б�
       indexMapping{i}(treeInd(j)) = j;
       
       childList = idTreeSet(i).getchildren(treeInd(j)); % ��Ӧ��ǰ֡��Ҷ�ӽڵ�
       
       if ~isempty(childList)
           % 1.�ȴ��ӵ��ͬһ�����ڵ������Ҷ�ڵ㣨ͬһ�����ϻ������ݣ�
           treeIndCache{i}{j} = zeros(length(childList),2);  % [familyID branchInd]
           trackIDCache{i}{j} = zeros(length(childList),2);  % [familyID trackID]
           for k = 1:length(childList)
               if activeTreeSet(i).get(childList(k)) ~= 1
                   continue;
               end
               treeIndCache{i}{j}(k,:) = [i childList(k)];
               trackIDCache{i}{j}(k,:) = idTreeSet(i).get(childList(k));
           end
           % ɾ��non-active nodes��Ӧ����
           idx = (trackIDCache{i}{j}(:,2)==0);
           trackIDCache{i}{j}(idx,:) = [];
           treeIndCache{i}{j}(idx,:) = [];
       end       
   end
end

% delete nonactive tracks 
% ɾ��obsMembership��nonactive nodes��Ӧ����Ϣ
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

% Ѱ�Ҳ����ݵĹ켣
for i = 1:familyNo
   treeInd = findleaves(obsTreeSet(i));    
   % ���ڵ�ǰ�۲����ϵ�ÿ��Ҷ�ڵ������䲻���ݵ�Ҷ�ڵ㣨������
   for j = 1:length(treeInd) 
       
       if activeTreeSet(i).get(treeInd(j)) ~= 1
           continue;
       end
       
       idTemp = idTreeSet(i).getparent(treeInd(j)); % ��ǰ֡������/id��Ҷ�ӽڵ�ĸ��ڵ��branchIdx
       % Ѱ����ͬ����Ĳ����ݹ켣������������µļ��崴��ʱ���
       % �������
       if idTemp == 0        
           incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),idTreeSet(i).get(treeInd(j)));   
           incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j), [i treeInd(j)]);
           
       % ���Ǹ��ڵ�
       % �Ӹ��ڵ���Ѱ�Ҳ����ݵĹ켣 
       else    
            % ��һ֡���������Ľڵ�ֵ
            % ?????
            iclParentTemp = ICLCache{i}{indexMapping{i}(idTemp)}; % ��ǰ�ڵ�ĸ��ڵ�����в����ݽڵ�,��[familyID branchInd]�б�
            incompabilityListSet = [];
            incompabilityNodeIDListSet = [];
            % 2.�ټ����뵱ǰ�ڵ�ĸ��ڵ㴦��ͬһ����Ҳ����ݵĽڵ���ӽڵ㣨�������ϵĵ�ǰ���Ҷ�ڵ㣩
            % ע�⣬iclParentTemp�б��п��ܰ�����ǰ�ڵ�ĸ��ڵ���ͬһ�������ֵܽڵ�
            for k = 1:size(iclParentTemp,1)
                familyIDTemp = find(familyIdMapping == iclParentTemp(k,1));
%                 familyIDTemp = iclParentTemp(k,1);
                branchIndTemp = iclParentTemp(k,2);
                trackSelInd = indexMapping{familyIDTemp}(branchIndTemp);          
                if trackSelInd == 0 % ��ʾǰһ֡��������familyIDTemp��brancIndTemp�ڵ��Ѿ��������ˡ���ʲôʱ�򽫸ýڵ�ɾ�����أ���֦��ʱ��
                    iclTrackListTemp = [];
                    iclIndListTemp = [];
                else
                    % �뵱ǰ�ڵ㴦��ͬһ����Ҳ����ݵ�ĳ������ĳ���ڵ�Ĳ����ݽڵ㣨��ĳ���ڵ�ͬһ�����ڵ������Ҷ�ڵ㣩
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
       
       % 3.����ҳ����õ�ǰ����ֵ�����нڵ㣨�����ݣ����˴ο��ܲ�������
       % find incompatible tracks from other families
       sel_observation1 = obsTreeSet(i).get(treeInd(j));              
       
       % ����miss�ڵ㲻�����������ж�
       if ~isnan(sel_observation1(end))     
           ind1 = cur_observation.x == sel_observation1(1);
           ind2 = cur_observation.y == sel_observation1(2);
           % �ҳ����õ�ǰ����ֵ�����и��ٹ켣�����������⣩
           iclSel = cell2mat(obsMembership(ind1 & ind2)); % [familyID branchIndex trackID]
           if ~isempty(iclSel)                        
               incompatibleTrackList = [incompabilityListTreeSet(i).get(treeInd(j)); iclSel(:,[1 3])];
               incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),incompatibleTrackList);   
       
               incompatibleTrackList = [incompabilityListTreeNodeIDSet(i).get(treeInd(j)); iclSel(:,1:2)];
               incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j),incompatibleTrackList);   
           end
       end
       % ȥ����
       % remove redundant tracks from the list
       incompabilityListSet = incompabilityListTreeSet(i).get(treeInd(j));
       [incompabilityListSet index] = unique(incompabilityListSet,'rows');
       incompabilityListTreeSet(i) = incompabilityListTreeSet(i).set(treeInd(j),incompabilityListSet);
       
       incompabilityListSet = incompabilityListTreeNodeIDSet(i).get(treeInd(j));
       incompabilityListTreeNodeIDSet(i) = incompabilityListTreeNodeIDSet(i).set(treeInd(j),incompabilityListSet(index,:));
   end        
end

end


