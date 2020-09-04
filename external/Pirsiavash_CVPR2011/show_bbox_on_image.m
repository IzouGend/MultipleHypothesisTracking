% drawss bbox on an image (im1) and returns the image file
% bbox: a matrix of size n*5
% default line width (lw) is 2
function im1 = show_bbox_on_image(im1, bbox, bws, col, lw)

if ~exist('lw')
  lw = 4;
end
% 
% bbox_type = bbox(:,end);
% bbox = bbox(:,1:end-1);

m1 = floor((lw-1)/2);   %% reduce 1 for the pixel itself
m2 = ceil((lw-1)/2);

[sz1 sz2 sz3] = size(im1);
sz = size(bbox, 1);

bbox = round(bbox);

for j = floor(size(bbox,2)/4):-1:1 %%for all parts
  for i = 1:sz
    x1 = bbox(i, (j-1)*4+1);
    y1 = bbox(i, (j-1)*4+2);
    x2 = bbox(i, (j-1)*4+3);
    y2 = bbox(i, (j-1)*4+4);
    
    %if bbox_type(i) == 1
    for k = 1:3  %% RGB channels
      im1(max(1,y1-m1):min(sz1,y1+m2),  max(1,x1):min(sz2,x2),        k) = col(k, bbox(i,end));
      im1(max(1,y2-m1):min(sz1,y2+m2),  max(1,x1):min(sz2,x2),        k) = col(k, bbox(i,end));
      im1(max(1,y1):min(sz1,y2),        max(1,x1-m1):min(sz2,x1+m2),  k) = col(k, bbox(i,end));
      im1(max(1,y1):min(sz1,y2),        max(1,x2-m1):min(sz2,x2+m2),  k) = col(k, bbox(i,end));
    end
    %else
%     col_hdet = [255 255 0];
%     for k = 1:3  %% RGB channels
%       im1(max(1,y1-m1):min(sz1,y1+m2),  max(1,x1):min(sz2,x2),        k) = col_hdet(k);
%       im1(max(1,y2-m1):min(sz1,y2+m2),  max(1,x1):min(sz2,x2),        k) = col_hdet(k);
%       im1(max(1,y1):min(sz1,y2),        max(1,x1-m1):min(sz2,x1+m2),  k) = col_hdet(k);
%       im1(max(1,y1):min(sz1,y2),        max(1,x2-m1):min(sz2,x2+m2),  k) = col_hdet(k);
%     end
%     end
    if ~isempty(bws)  %% add text if needed
      col1  = col(:, bbox(i, end));
      % chanho added for resizing
      height = y2-y1;
      im1 = show_text_on_image(im1, num2str(bbox(i,end)), col1, min(max(x1-10,1),sz2), min(max(y1-20,1),sz1), 20, bws(bbox(i,end)).bw, height);
    end
  end
end

function im = show_text_on_image(im, txt, col, x, y, h, bw, height)
[sz11 sz22 sz33] =size(im);

% original
% [sz1 sz2] = size(bw);
% y2 = min(y+sz1-1, sz11);
% x2 = min(x+sz2-1, sz22);
% 
% for k = 1:3 %% RGB channels
%   im(y2-sz1+1:y2, x2-sz2+1:x2, k) = (1-bw) * col(k);
% end

% chanho edited for resizing labeling
resize_factor = height*0.0045;
resize_factor = min(max(resize_factor,1),2);
bw = imresize(bw,resize_factor);
[sz1 sz2] = size(bw);
y2 = min(y+sz1-1, sz11);
x2 = min(x+sz2-1, sz22);

margin_control = 0;
if resize_factor >= 1.5
    margin_control = 15;
elseif resize_factor > 1.4
    margin_control = 12;
elseif resize_factor > 1.3
    margin_control = 9;
elseif resize_factor > 1.2
    margin_control = 6;
elseif resize_factor > 1.1
    margin_control = 3;
end

    margin_y = 0;
    if y2-sz1+1-margin_control <= 0
        margin_y = -(y2-sz1+1-margin_control)+1;
    end

    margin_x = 0;
    if x2-sz2+1 <= 0;
       margin_x = -(x2-sz2+1);
    end
    
   for k = 1:3 %% RGB channels
       im(y2-sz1+1-margin_control+margin_y:y2-margin_control+margin_y, x2-sz2+1+margin_x:x2+margin_x, k) = (1-bw) * col(k);
   end

