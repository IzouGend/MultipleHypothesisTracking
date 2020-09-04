function track = getFinalTracks(track, kalman_param, other_param)

% remove dummy observations that were added after track confirmation
del_idx = [];
for i = 1:max(track.id)
    
    idx = find(track.id == i);
    
    idx1 = isnan(track.isdummy(idx));
    
    % 当前树最后一条轨迹是漏检，则删除这棵树中所有处于漏检状态的轨迹
    if isnan(track.isdummy(idx(end)))
    
    idx2 = ~isnan(track.isdummy(idx));
    idx3 = find(idx2 == 1);
    
    if ~isempty(idx3)  
        idx3 = idx3(end);
        idx1(1:idx3) = 0;
        del_idx = [del_idx; idx(idx1)];
    end
    end

end
track.x(del_idx) = [];
track.y(del_idx) = [];
track.fr(del_idx) = [];
track.id(del_idx) = [];
track.isdummy(del_idx) = [];


% remove unconfirmed tracks whose score is lower than the threshold
del_idx = [];
for i = 1:max(track.id)
       
    idx = find(track.id == i);
    
    idx1 = isnan(track.isdummy(idx));
    
    if sum(idx1)/length(idx) > other_param.dummyRatioTH  
        del_idx = [del_idx; idx];          
%     elseif track.sc(idx(end))/(length(idx)-sum(idx1)) < other_param.confscTH
%         del_idx = [del_idx; idx];  
    % ********需要调整？
    elseif length(idx) <= other_param.minLegnthTH
        del_idx = [del_idx; idx];     
    end    

end
track.x(del_idx) = [];
track.y(del_idx) = [];
track.fr(del_idx) = [];
track.id(del_idx) = [];
track.isdummy(del_idx) = [];

% smooth tracks
track = smoothData(track,kalman_param);

% % map 3D detections to the image plane in the case of 3D tracking
% if other_param.is3Dtracking
%     [track.x_hat track.y_hat]=projectToImage(track.x,track.y,other_param.camParam); 
% end

% % set x and y as the upper left corner of the bounding box
% if other_param.is3Dtracking && strcmp(other_param.seq,'PETS2009')
%     track.x_hat = track.x_hat-track.w/2;
%     track.y_hat = track.y_hat-track.h/2;
% elseif ~other_param.is3Dtracking 
%     track.x_hat = track.x-track.w/2;
%     track.y_hat = track.y-track.h/2;
% end