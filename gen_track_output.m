function resFile = gen_track_output(track_sel, track_output_root, track_output_path, sequence_name, other_param)

if strcmp(other_param.seq,'MOT_Challenge_train') || strcmp(other_param.seq,'MOT_Challenge_test')
    
    id = 1;
    track_sel_tmp = track_sel;
    for i = 1:max(track_sel.id)

        idx = find(track_sel.id == i);

        if isempty(idx)
           continue; 
        end

        track_sel_tmp.id(idx) = id;
        id = id+1;        

    end

    track_sel = track_sel_tmp;

    result = [];
    for i = 1:max(track_sel.fr)

        idx = find(track_sel.fr == i);

        if isempty(idx)
            continue;
        end

        padding = -1*ones(length(idx),4);    
        x = track_sel.x_hat(idx);
        y = track_sel.y_hat(idx);
        w = track_sel.w(idx);
        h = track_sel.h(idx);
        fr = track_sel.fr(idx);
        id = track_sel.id(idx);
        result = [result; fr id x y w h padding];
    end

    resFile = [track_output_path sequence_name '.txt'];
    if ~exist(track_output_path)
        mkdir(track_output_path);
    end  

    csvwrite(resFile,result);

    if ~exist(track_output_root)
        mkdir(track_output_root);
    end  
    resFile = [track_output_root sequence_name '.txt'];

    csvwrite(resFile,result);
    
elseif strcmp(other_param.seq,'KITTI_train') || strcmp(other_param.seq,'KITTI_test')
    
    % reset ID numbers
    if ~isempty(track_sel{1}.x) && ~isempty(track_sel{2}.x)
        track_sel{2}.id = track_sel{2}.id + max(track_sel{1}.id);
    end
    
    track_out.x = [track_sel{1}.x; track_sel{2}.x];
    track_out.y = [track_sel{1}.y; track_sel{2}.y];
    track_out.x_hat = [track_sel{1}.x_hat; track_sel{2}.x_hat];
    track_out.y_hat = [track_sel{1}.y_hat; track_sel{2}.y_hat];
    track_out.w = [track_sel{1}.w; track_sel{2}.w];
    track_out.h = [track_sel{1}.h; track_sel{2}.h];
    track_out.fr = [track_sel{1}.fr; track_sel{2}.fr];
    track_out.id = [track_sel{1}.id; track_sel{2}.id];
    track_out.sc = [track_sel{1}.sc; track_sel{2}.sc];
    track_out.isdummy = [track_sel{1}.isdummy; track_sel{2}.isdummy];
    track_out.type = [repmat({'Pedestrian'},length(track_sel{1}.x),1); repmat({'Car'},length(track_sel{2}.x),1)];
    
    % set to the 0-based ID number
    id = 0;
    track_out_tmp = track_out;
    for i = 1:max(track_out.id)

        idx = find(track_out.id == i);

        if isempty(idx)
           continue; 
        end

        track_out_tmp.id(idx) = id;
        id = id+1;        

    end

    track_out = track_out_tmp;
    
    if ~exist(track_output_path)
        mkdir(track_output_path);
    end 
    
    % write the output file
    resFile = [track_output_path sequence_name '.txt'];    
    fid = fopen(resFile,'w');
    
    % set to the 0-based frame number
    track_out.fr = track_out.fr-1;
    for i = 0:max(track_out.fr)
        
        idx = find(track_out.fr == i);
        for j = 1:length(idx)
        
            fprintf(fid,'%d ',track_out.fr(idx(j))); % frame
            fprintf(fid,'%d ',track_out.id(idx(j))); % ID
            fprintf(fid,'%s ',track_out.type{idx(j)}); % type
            fprintf(fid,'-1 '); % truncation
            fprintf(fid,'-1 '); % occlusion
            fprintf(fid,'-10 '); % alpha
            fprintf(fid,'%.2f ', track_out.x(idx(j))-track_out.w(idx(j))/2); % upper left x
            fprintf(fid,'%.2f ', track_out.y(idx(j))-track_out.h(idx(j))/2); % upper left y
            fprintf(fid,'%.2f ', track_out.x(idx(j))+track_out.w(idx(j))/2); % bottom right x
            fprintf(fid,'%.2f ', track_out.y(idx(j))+track_out.h(idx(j))/2); % bottom right y
            fprintf(fid,'-1 '); % 3D bounding box (h)
            fprintf(fid,'-1 '); % 3D bounding box (w)
            fprintf(fid,'-1 '); % 3D bounding box (l)
            fprintf(fid,'-1000 -1000 -1000 '); % 3D bounding box (t)
            fprintf(fid,'-10 '); % 3D bounding box (ry)            
            fprintf(fid,'%.2f ',1); % option : score
            
            fprintf(fid,'\n');
            
        end
    end
    
    fclose(fid);   
    
    % write the same file in a different path
    if ~exist(track_output_root)
        mkdir(track_output_root);
    end  
    
    resFile = [track_output_root sequence_name '.txt'];
    fid = fopen(resFile,'w');
    
    % set to the 0-based frame number
    for i = 0:max(track_out.fr)
        
        idx = find(track_out.fr == i);
        for j = 1:length(idx)
        
            fprintf(fid,'%d ',track_out.fr(idx(j))); % frame
            fprintf(fid,'%d ',track_out.id(idx(j))); % ID
            fprintf(fid,'%s ',track_out.type{idx(j)}); % type
            fprintf(fid,'-1 '); % truncation
            fprintf(fid,'-1 '); % occlusion
            fprintf(fid,'-10 '); % alpha
            fprintf(fid,'%.2f ', track_out.x(idx(j))-track_out.w(idx(j))/2); % upper left x
            fprintf(fid,'%.2f ', track_out.y(idx(j))-track_out.h(idx(j))/2); % upper left y
            fprintf(fid,'%.2f ', track_out.x(idx(j))+track_out.w(idx(j))/2); % bottom right x
            fprintf(fid,'%.2f ', track_out.y(idx(j))+track_out.h(idx(j))/2); % bottom right y
            fprintf(fid,'-1 '); % 3D bounding box (h)
            fprintf(fid,'-1 '); % 3D bounding box (w)
            fprintf(fid,'-1 '); % 3D bounding box (l)
            fprintf(fid,'-1000 -1000 -1000 '); % 3D bounding box (t)
            fprintf(fid,'-10 '); % 3D bounding box (ry)            
            fprintf(fid,'%.2f ',1); % option : score
            
            fprintf(fid,'\n');
            
        end
    end
    
    fclose(fid);       
end
