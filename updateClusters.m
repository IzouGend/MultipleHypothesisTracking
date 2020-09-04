function [clusters ICL_clusters other_param] = updateClusters(incompabilityListTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, other_param)

% Each tree node can be accessed by its familyID and trackID

familyNo = length(incompabilityListTreeSet);
other_param.currentTrackNo = 0;

if familyNo == 0
    clusters = [];
    ICL_clusters = [];
    return
end

clusterFamilyList = cell(familyNo,1);
clusterFamilyIndex = cell(familyNo,1);
familyClusters = zeros(familyNo,1);

for i = 1:familyNo            
    treeInd = findleaves(incompabilityListTreeSet(i));   
    ICL_sel = [];
    for j = treeInd
    
        if activeTreeSet(i).get(j) ~= 1
            continue;
        end
        
        ICL_sel_tmp = incompabilityListTreeNodeIDSet(i).get(j);
        ICL_sel = [ICL_sel; ICL_sel_tmp(:,1)]; %         
    end
    
    ICL_sel = unique(ICL_sel);        
    clusterFamilyList{i} = ICL_sel; % 存放与当前树叶节点共用量测的所有树编号   
end
% 两棵树的不兼容树簇中，如果含有相同的其他树，则把其中一棵序号大的树加入另一棵序号小的树的不兼容树簇
for i = 1:length(clusterFamilyList)
   ICL_sel = clusterFamilyList{i};
   clusterFamilyIndex{i} = i;
   if i ~= length(clusterFamilyList)
   for j = i+1:length(clusterFamilyList)                  
        
        ICL_sel2 = clusterFamilyList{j};
        for k = 1:length(ICL_sel2)
            if sum(ICL_sel == ICL_sel2(k)) ~= 0
                clusterFamilyIndex{i} = [clusterFamilyIndex{i}; j];
                break;
            end
        end               
   end
   end
end

w = 0; % 树簇编号
todolist = 1:familyNo;
while ~isempty(todolist)
    w = w+1;
    i = todolist(1); % 当前树序号
    cl_index = clusterFamilyIndex{i};% 每棵树的不兼容树簇
    cl_index = cl_index';
    for j = cl_index
        if i == j
            continue;
        end        
        % 将当前树的不兼容树簇中的其他树的不兼容树簇也加入到当前树的不兼容树簇中，并将其他树的不兼容树簇清空
        clusterFamilyIndex{i} = [clusterFamilyIndex{i}; clusterFamilyIndex{j}];  
        clusterFamilyIndex{j} = [];
    end
    clusterFamilyIndex{i} = unique(clusterFamilyIndex{i});
    todolist = setdiff(todolist,cl_index');  
    if sum(familyClusters(clusterFamilyIndex{i})) == 0
        familyClusters(clusterFamilyIndex{i}) = w; % 当前树的不兼容树簇中所有树都还没有被分配已知的簇号时，分配新簇号w
    else 
        % 
        cl_parent = find(familyClusters(clusterFamilyIndex{i})~=0); % 找出其中已被分配的簇号
        clusterNums = unique(familyClusters(clusterFamilyIndex{i}(cl_parent)));
        for k = 1:length(clusterNums)
            indSel = find(familyClusters==clusterNums(k));
            familyClusters(indSel) = w;  % 对已被分配簇号的树重新分配新簇号w       
        end
        familyClusters(clusterFamilyIndex{i}) = w; % 其中未被分配的树，分配簇号w
    end
end

%--zhouYang, 200724, 使簇号与其中的最小树序号尽可能差异小，与C代码一致
familyClustersSort = zeros(size(familyClusters));
m = 1;
for k = 1 : length(familyClusters)
    if familyClustersSort(k) ~= 0
        continue;
    end
    indSel = find(familyClusters == familyClusters(k));
    if isempty(indSel)
        continue;
    end
    for i = indSel
        familyClustersSort(i) = m;
    end
    m = m + 1;
end
familyClusters = familyClustersSort;
%--
ICL_clusters = cell(w,1);
clusters = cell(w,1);
for k = 1:max(familyClusters)
    ICL_sel = [];    
    ICL_Ind_sel = [];
    indSel = find(familyClusters == k);
    indSel = indSel';
    % 取簇号相同的树的叶节点ID
    for i = indSel
        treeInd = findleaves(incompabilityListTreeSet(i));    
                
        for j = treeInd
            if activeTreeSet(i).get(j) ~= 1
                continue;
            end
        
            ICL_sel_tmp = incompabilityListTreeSet(i).get(j);
            ICL_sel = [ICL_sel; ICL_sel_tmp(:,2)]; % TrackId
            ICL_Ind_sel = [ICL_Ind_sel; [i j]]; 
        end
    end
    
    ICL_sel = unique(ICL_sel);
    ICL_clusters{k} = ICL_sel; % 每个簇包含的TrackId
    clusters{k} = ICL_Ind_sel; % 每个簇包含的[familyId branchId]列表
end
          
ICL_clusters(cellfun('isempty',ICL_clusters)) = [];  
clusters(cellfun('isempty',clusters)) = [];         

% count the number of tracks in each cluster
other_param.currentTrackNo = zeros(length(clusters),1);
for i = 1:length(clusters)
    
%     % print the track number information
%     for k = min(clusters{i}(:,1)):max(clusters{i}(:,1))
%         idx = clusters{i}(:,1) == k;        
%         if sum(idx) == 0
%             continue;
%         end        
%         disp(sprintf('the number of tracks in tree %d of cluster %d is %d.',k, i, sum(idx)));
%     end
    
    other_param.currentTrackNo(i) = size(clusters{i},1);
    
    if size(clusters{i},1) ~= size(ICL_clusters{i},1)
        error('error');
    end
end
