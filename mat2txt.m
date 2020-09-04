load('S_hat_158.mat');
load('block_159_230_selected.mat');

% load('S_hat_228(blkm_loose).mat');
% load('block_229_268(blkm_loose).mat');

% load('S_hat_538(blkm_loose).mat');
% load('block_539_756(blkm_loose).mat');

numTrack = size(hTrack,2);
fid=fopen('mhtInput158.txt','w+');
for ii = 1:numTrack
    fprintf(fid,"%.4f ",hTrack(ii).tid);
    for jj = 1:4
        fprintf(fid,"%.4f ",hTrack(ii).S_hat(jj));
    end
    fprintf(fid,"%.4f ",hTrack(ii).fr);
    for jj = 1:16
        fprintf(fid,"%.4f ",hTrack(ii).P_hat(jj));
    end
    fprintf(fid,"\n");
end

fprintf(fid,"*\n");
numBlock = size(block,2);
for ii = 1:numBlock
    fprintf(fid,"%.4f %.4f %.4f %.4f %.4f \n",block(ii).x,block(ii).y,block(ii).frame,block(ii).pointNum,...
        block(ii).snr);
end
fclose(fid);

