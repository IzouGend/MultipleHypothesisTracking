% 根据前一帧航迹信息初始化变量

if initTrackNum ~= 0
    cur_observation.x = zeros(1, initTrackNum);
    cur_observation.y = zeros(1, initTrackNum);
    cur_observation.fr = zeros(1, initTrackNum);
    obsMembership = cell(initTrackNum, 1); 
    for i = 1 : initTrackNum   
        cur_observation.x(i) = initTrack(i).S_hat(1);
        cur_observation.y(i) = initTrack(i).S_hat(2);
        cur_observation.fr(i) = initTrack(i).fr;
        obsTreeSet(i, 1) = tree([cur_observation.x(i) cur_observation.y(i) cur_observation.fr(i) 1 0 0 0]);       % last four elements : (1) the number of observation nodes (2) the number of dummy nodes (3) the number of total dummy nodes (4) a dummy node indicator, 1--real, NaN--dummy
        stateEstimate = [initTrack(i).S_hat' reshape(initTrack(i).P_hat,[4 4])];
        stateTreeSet(i, 1) = tree(stateEstimate);
        scoreTreeSet(i, 1) = tree(8 / other_param.const); % zy,注意，已有轨迹概率初始值可能需要调整
        idTreeSet(i, 1) = tree([familyID trackID]);  % [familyID trackID];
        activeTreeSet(i, 1) = tree(1);   
        obsMembership{i} = [obsMembership{i}; [familyID 1 trackID]]; % [familyID branchIndex trackID] 
        familyID = familyID + 1;
        trackID = trackID + uint64(1);
    end
else
    obsMembership = []; 
end

