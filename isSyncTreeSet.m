function result = isSyncTreeSet(obsTreeSet, stateTreeSet, scoreTreeSet, idTreeSet, incompabilityListTreeSet, incompabilityListTreeNodeIDSet, activeTreeSet, appTreeSet)

result = 0;
obsTreeSize = length(obsTreeSet);
stateTreeSize = length(stateTreeSet);
scoreTreeSize = length(scoreTreeSet);
idTreeSize = length(idTreeSet);
iclTreeSize = length(incompabilityListTreeSet);
iclNodeTreeSize = length(incompabilityListTreeNodeIDSet);
activeTreeSize = length(activeTreeSet);
appTreeSize = length(appTreeSet);

if (obsTreeSize ~= stateTreeSize || stateTreeSize ~=scoreTreeSize || scoreTreeSize ~= idTreeSize || idTreeSize ~= iclTreeSize || iclTreeSize ~= iclNodeTreeSize || iclNodeTreeSize ~= activeTreeSize || activeTreeSize ~= appTreeSize)
    result = 0;
    return
end

for i = 1:obsTreeSize
    
if (~obsTreeSet(i).issync(stateTreeSet(i)) || ~stateTreeSet(i).issync(scoreTreeSet(i)) || ~scoreTreeSet(i).issync(idTreeSet(i)) || ~idTreeSet(i).issync(incompabilityListTreeSet(i)) || ~incompabilityListTreeSet(i).issync(incompabilityListTreeNodeIDSet(i)) || ~incompabilityListTreeNodeIDSet(i).issync(activeTreeSet(i)) || ~activeTreeSet(i).issync(appTreeSet(i)))
    result = 0;
    return    
end

end

result = 1;

end