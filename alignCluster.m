function iclCluster = alignCluster(cluster,iclCluster,idTreeSet)
%

[row,~] = size(cluster);
for ii = 1:row
    familyID = cluster(ii,1);
    branchID = cluster(ii,2);
    IDsel = idTreeSet(familyID).get(branchID);
    trackID = IDsel(2);
    
    iclCluster(ii) = trackID;
end

