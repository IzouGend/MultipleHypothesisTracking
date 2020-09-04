function [bestHypothesis bestScore trackIndexInTrees selectedTrackIDs] = ...
    generateGlobalHypothesis(scoreTreeSet, obsTreeSet, stateTreeSet, idTreeSet, incompabilityListTreeSet, clusters, ICL_clusters, selectedTrackIDsPrev, other_param)

clustersNo = length(clusters);
bestHypothesis = cell(clustersNo,1);
bestScore = cell(clustersNo,1);
trackIndexInTrees = cell(clustersNo,1);
selectedTrackIDs = [];

if clustersNo == 0    
    return
end

% graph density threshold setting (emprically found) for switching between Qualex and Cliquer
y0 = 0.7:-0.2/100:0.5;
y1 = 0.50:-0.05/99:0.45;
y2 = 0.45*ones(1,100);
y3 = 0.45:-0.25/499:0.2;
thLineFunc = [y0 y1 y2 y3];

for i = 1:clustersNo
    
   adjacencyMat = zeros(other_param.currentTrackNo(i)+1, other_param.currentTrackNo(i)+1);  % the last row and column for the dummy node
   weightMat = zeros(1, other_param.currentTrackNo(i)+1);    % the last element for the dummy node
   trackIndexInTrees{i,1} = zeros(other_param.currentTrackNo(i),2);   
   nodesNo = size(clusters{i},1);
   ICL_clusters{i} = alignCluster(clusters{i},ICL_clusters{i},idTreeSet);
   for j = 1:nodesNo            
      familyID1 = clusters{i}(j,1);
      leafNodeInd1 = clusters{i}(j,2);
      IDsel = idTreeSet(familyID1).get(leafNodeInd1);
      trackID = IDsel(2);
      index1 = find(ICL_clusters{i} == trackID);
      trackIndexInTrees{i,1}(index1,:) = [familyID1 leafNodeInd1];
          
      % assign a node weight    
      if weightMat(index1) ~= 0
          error('something wrong happend in the weight matrix');
      end
      scoreSel = scoreTreeSet(familyID1).get(leafNodeInd1);
      
      % score bug fixed
      if scoreSel(1) > 1.1*(1/other_param.const)
           weightMat(index1) = scoreSel(1);
      else
           weightMat(index1) = 1.1*(1/other_param.const);
      end      
      
      ICL = incompabilityListTreeSet(familyID1).get(leafNodeInd1);  
      if size(ICL,1) == 1 
           index2 = find(ICL_clusters{i} == ICL(2));           
           compatibleTracksID = ICL_clusters{i}(ICL_clusters{i} ~= ICL(2));
           
           if index1 ~= index2
              error('error happened in the ICL of the confirmed track'); 
           end
           
      else         
           [compatibleTracksID index2] = setdiff(ICL_clusters{i},ICL(:,2),'rows');
           index2 = index2';
      end
      
      if isempty(compatibleTracksID)
          continue;
      end
      
      % assign 1 if two tracks are compatible
      adjacencyMat(index1,index2) = 1;
   end
   
   edge_num = (sum(sum(adjacencyMat)) - sum(adjacencyMat(logical(eye(size(adjacencyMat))))))/2;  
   graph_density = edge_num/(other_param.currentTrackNo(i)*(other_param.currentTrackNo(i)-1)/2);
   
   % multipy a constant to the weights as the weights will be converted into integers in the graph solver
   weightMat = other_param.const*weightMat;

   % connect an isolated node to a dummy node. 
   % NOTE : A single node is not considered as a clique in Cliquer.      
   weightMat(end) = 1.1; 
     
   index = find(sum(adjacencyMat(1:end-1,1:end-1)') == 0);
   for k = index
       adjacencyMat(k,end) = 1;
       adjacencyMat(end,k) = 1;
   end

   % set the diagonal terms to zero
   adjacencyMat(logical(eye(size(adjacencyMat)))) = 0;
   
   % error check
   if ~isequal(adjacencyMat,adjacencyMat')
       error('the adjacency matrix is not symmetric');
   end

   edge_num = sum(sum(adjacencyMat))/2;  
   graph_density = edge_num/(size(weightMat,2)*(size(weightMat,2)-1)/2);        % *********ºı“ª
   disp(sprintf('The number of the vertices is %d and the graph density is %f in cluster %d',size(weightMat,2),graph_density,i));

   
   % generate the global hypothesis.   
   % NOTE1 :  Negative weights cause an error.
   % NOTE2 :  If the max number of clique is less than the actual number of maximum weighted cliques, the clique results are not correct. (Cliquer)
   maxCliqueNo = 1000;   

   if 0 % thLineFunc(max(200,min(1000,size(weightMat,2)))-199) < graph_density && size(weightMat,2) > 80   
       % Qualex-ms
       disp(sprintf('Qualex-ms is running to find the maximum weighted cliques in the graph'));
       bestHypothesis_tmp = qualex_ms(adjacencyMat, weightMat);                
   else
       % Cliquer
       disp(sprintf('Cliquer is running to find the maximum weighted cliques in the graph'));
       [maxCliqueNo_tmp, bestHypothesis_tmp] = Cliquer.FindSingle(adjacencyMat, 0, 0, true, maxCliqueNo, weightMat);   

       % check error
       if maxCliqueNo == maxCliqueNo_tmp
           error('The Cliquer might not be working correctly. Increase the maximum number of cliques');
       end            
   end
   bestHypothesis_tmp = bestHypothesis_tmp(:,1:end-1);
   weightMat = weightMat(1:end-1);
   disp(sprintf('The maximum weighted cliques have been found'));     
      
   % update the selected track list
   if size(bestHypothesis_tmp,1) > 1
        bestTracks = ~~sum(bestHypothesis_tmp);
   else
        bestTracks = bestHypothesis_tmp;
   end
   
   index = find(bestTracks == 1);
   selectedTrackIDs_tmp = zeros(length(index),1);
   for k = 1:length(index)
       IndSel = trackIndexInTrees{i,1}(index(k),:);
       IDSel = idTreeSet(IndSel(1)).get(IndSel(2));
       selectedTrackIDs_tmp(k) = IDSel(2);
   end
   selectedTrackIDs = [selectedTrackIDs; selectedTrackIDs_tmp];
   
   % keep only one clique (option 1)
   score = zeros(size(bestHypothesis_tmp,1),1);
   for k = 1:size(bestHypothesis_tmp,1)
        score(k) = sum(weightMat(logical(bestHypothesis_tmp(k,:))));
   end
   [~, index_tmp] = max(score);   
   bestHypothesis{i,1} = bestHypothesis_tmp(index_tmp,:);
   
%    % keep all cliques found (option 2). Currently, this option doesn't work. I need to change the code a bit to deep copy the appearance models in the case of tree splitting.
%    bestHypothesis{i,1} = bestHypothesis_tmp;

   bestScore{i,1} = weightMat;
end


