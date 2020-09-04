function track = collectTrack(obsTreeSet, familyID, nodeID)

track.x = [];
track.y = [];
parentNodeID = 1;

while parentNodeID ~= 0
    
    xy = obsTreeSet(familyID).get(nodeID);
    track.x = [xy(end:-1:1,1); track.x];
    track.y = [xy(end:-1:1,2); track.y];
    
    parentNodeID = obsTreeSet(familyID).getparent(nodeID);
    nodeID = parentNodeID;

end