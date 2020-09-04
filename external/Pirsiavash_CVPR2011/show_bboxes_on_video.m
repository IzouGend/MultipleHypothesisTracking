% it shows bboxes on frames of a video (bunch of frames in "input_frames") and outputs a video "video_fname"
% bboxes(i).bbox is an n*5 matrix: detections on the i'th frame
% "thr" is used to prune detection results: default: -inf
% if you don't pass "output_frames", it will make a temporary one and then delete it in the end.
% "bws" is track numbers in image format (used as label for the boxes)

function show_bboxes_on_video(input_frames, bboxes, video_fname, bws, frame_rate, thr, output_frames, other_param)

offset = 0; 

if ~exist('frame_rate')
  frame_rate = 20;
end
if ~exist('thr')
  thr = -inf;
end
if exist('output_frames')
  if ~isempty(output_frames)
    flag1 = 0;
    unix(['rm -r ' output_frames]);
  else
    flag1 = 1;
  end
else
  flag1 = 1;
end
if flag1 == 1
  output_frames = tempname;   %% A temporary folder name
  output_frames = [output_frames(end-9:end) '/'];
end

mkdir (output_frames);

col = round((rand(3,5e5)/2+.5)*255);  %% we assume number of tracks is less than 1e4.

dirlist = dir([input_frames '*.jpg']);  %%list of images
if isempty(dirlist)
  dirlist = dir([input_frames '*.png']);
end
  
disp('writing output images...');
len1 = length(bboxes);
time1 = tic;
for i = 1:len1
  if toc(time1) > 2
    fprintf('%0.1f%%\n', 100*i/len1);
    time1 = tic;
  end
  bbox = bboxes(i).bbox;
  try
    if strcmp(other_param.seq,'PETS2009') || strcmp(other_param.seq,'KITTI_train') || strcmp(other_param.seq,'KITTI_test')
        im1 = imread(sprintf(input_frames, i-1+offset)); %% read an image
    else
        im1 = imread(sprintf(input_frames, i+offset)); %% read an image
    end
  catch
    break
  end
  if ~isempty(bbox)
    % hack by chanho
    inds = find(bbox(:,end) > thr);
    %inds = find(bbox(:,end-1) > thr);
    im1 = show_bbox_on_image(im1, bbox(inds, :), bws, col);
  end
  imwrite(im1, [output_frames sprintf('%0.8d', i) '.jpg']); %%write the output image
end

% frames_to_video(output_frames, video_fname, frame_rate);  %%convert frames to video
% 
% if flag1
%   unix(['rm -r ' output_frames]); %%remove temporary output folder
% end
