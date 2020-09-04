
% 不采用表观模型
other_param.isAppModel = 0;

%% declare variables
obsTreeSetConfirmed = [];
stateTreeSetConfirmed = [];
scoreTreeSetConfirmed = [];
activeTreeSetConfirmed = [];    

incompabilityListTreeSet = [];   
incompabilityListTreeNodeIDSet = [];  
selectedTrackIDs = [];
trackFamilyPrev = [];
firstFrame = min(observation.fr);
lastFrame = max(observation.fr);  
familyID = 1;
trackID = uint64(1);  

if initTrackNum ~= 0
    obsTreeSet(initTrackNum,1) = tree;
    stateTreeSet(initTrackNum,1) = tree;
    scoreTreeSet(initTrackNum,1) = tree;
    idTreeSet(initTrackNum,1) = tree;
    activeTreeSet(initTrackNum,1) = tree;   
    obsMembership = cell(initTrackNum,1);  
else
    obsTreeSet = [];
    stateTreeSet = [];
    scoreTreeSet = [];
    idTreeSet = [];
    activeTreeSet = [];    
    obsMembership = [];  
end

