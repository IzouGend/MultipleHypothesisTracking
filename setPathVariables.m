Sequences = {'PETS2009','MOT_Challenge_train','KITTI_train','MOT_Challenge_test','KITTI_test'};

det_input_dir = {'input/PETS2009/','input/MOT_Challenge/train/','input/KITTI/train/','input/MOT_Challenge/test/','input/KITTI/test/'};
                    
% set your output directory here
img_output_dir = {'/media/chanho/Extra_Drive/temp_img/','/media/chanho/Extra_Drive/temp_img/',...
                        '/media/chanho/Extra_Drive/temp_img/','/media/chanho/Extra_Drive/temp_img/',...
                            '/media/chanho/Extra_Drive/temp_img/'};

% set your dataset directory here                       
img_input_dir = {'/home/chanho/Research/tracking/Dataset/Crowd_PETS09/', '/home/chanho/Research/tracking/2015_ICCV/MOT_Challenge/2DMOT2015/train/',...
                        '/media/chanho/Extra_Drive/Research/Dataset/devkit_tracking/original_files/data_tracking_image_2/training/image_02/','/home/chanho/Research/tracking/2015_ICCV/MOT_Challenge/2DMOT2015/test/',...
                        '/media/chanho/Extra_Drive/Research/Dataset/devkit_tracking/original_files/data_tracking_image_2/testing/image_02/'};

% set your image path here. The entire image path should be [img_input_dir img_input_subdir].                   
img_input_subdir = {'S2/L1/Time_12-34/View_001/frame_%04d.jpg', 'S2/L2/Time_14-55/View_001/frame_%04d.jpg', 'S2/L3/Time_14-41/View_001/frame_%04d.jpg',...
                        'S1/L1/Time_13-59/View_001/frame_%04d.jpg', 'S1/L2/Time_14-06/View_001/frame_%04d.jpg',...
                        'ADL-Rundle-6/img1/%06d.jpg', 'ADL-Rundle-8/img1/%06d.jpg', 'ETH-Bahnhof/img1/%06d.jpg', 'ETH-Pedcross2/img1/%06d.jpg',...
                        'ETH-Sunnyday/img1/%06d.jpg', 'KITTI-13/img1/%06d.jpg', 'KITTI-17/img1/%06d.jpg', 'PETS09-S2L1/img1/%06d.jpg', 'TUD-Campus/img1/%06d.jpg', 'TUD-Stadtmitte/img1/%06d.jpg', 'Venice-2/img1/%06d.jpg',...
                        '0000/%06d.png','0001/%06d.png','0002/%06d.png','0003/%06d.png','0004/%06d.png','0005/%06d.png','0006/%06d.png','0007/%06d.png','0008/%06d.png','0009/%06d.png','0010/%06d.png','0011/%06d.png',...
                        '0012/%06d.png','0013/%06d.png','0014/%06d.png','0015/%06d.png','0016/%06d.png','0017/%06d.png','0018/%06d.png','0019/%06d.png','0020/%06d.png',...
                        'ADL-Rundle-1/img1/%06d.jpg','ADL-Rundle-3/img1/%06d.jpg','AVG-TownCentre/img1/%06d.jpg','ETH-Crossing/img1/%06d.jpg','ETH-Jelmoli/img1/%06d.jpg','ETH-Linthescher/img1/%06d.jpg',...
                        'KITTI-16/img1/%06d.jpg','KITTI-19/img1/%06d.jpg','PETS09-S2L2/img1/%06d.jpg','TUD-Crossing/img1/%06d.jpg','Venice-1/img1/%06d.jpg',...
                        '0000/%06d.png','0001/%06d.png','0002/%06d.png','0003/%06d.png','0004/%06d.png','0005/%06d.png','0006/%06d.png','0007/%06d.png','0008/%06d.png','0009/%06d.png','0010/%06d.png','0011/%06d.png',...
                        '0012/%06d.png','0013/%06d.png','0014/%06d.png','0015/%06d.png','0016/%06d.png','0017/%06d.png','0018/%06d.png','0019/%06d.png','0020/%06d.png',...
                        '0021/%06d.png','0022/%06d.png','0023/%06d.png','0024/%06d.png','0025/%06d.png','0026/%06d.png','0027/%06d.png','0028/%06d.png'};
                    
det_input_name = {'PETS2009-S2L1-c1-app_pca','PETS2009-S2L2-c1-app_pca','PETS2009-S2L3-c1-app_pca','PETS2009-S1L1-2-c1-app_pca','PETS2009-S1L2-1-c1-app_pca',...
                    'ADL-Rundle-6', 'ADL-Rundle-8', 'ETH-Bahnhof', 'ETH-Pedcross2', 'ETH-Sunnyday', 'KITTI-13', 'KITTI-17', 'PETS09-S2L1', 'TUD-Campus', 'TUD-Stadtmitte', 'Venice-2',...
                    '0000','0001','0002','0003','0004','0005','0006','0007','0008','0009','0010','0011','0012','0013','0014','0015','0016','0017','0018','0019','0020',...
                    'ADL-Rundle-1','ADL-Rundle-3','AVG-TownCentre','ETH-Crossing','ETH-Jelmoli','ETH-Linthescher','KITTI-16','KITTI-19','PETS09-S2L2','TUD-Crossing','Venice-1',...
                    '0000','0001','0002','0003','0004','0005','0006','0007','0008','0009','0010','0011','0012','0013','0014','0015','0016','0017','0018','0019','0020',...
                    '0021','0022','0023','0024','0025','0026','0027','0028'};         


% find an index of the query sequence
seq_idx = 1;
while 1 
    if strcmp(other_param.seq,Sequences{seq_idx})        
        break;
    end
    seq_idx = seq_idx + 1;
end

% select input image indices based on the query sequence
input_idx = 0;
switch seq_idx
    case 1       
        input_idx = 1:5;
    case 2
        input_idx = 6:16;
    case 3
        input_idx = 17:37;
    case 4
        input_idx = 38:48;
    case 5
        input_idx = 49:77;
    otherwise
        error('unexpected sequence index');    
end

% set the input detection path 
det_input_path = cell(1,length(input_idx));
for i = 1:length(input_idx)
    det_input_path{i} = [det_input_dir{seq_idx} det_input_name{input_idx(i)} '.mat'];
end

% set the input/output imgage path 
img_output_path = cell(1,length(input_idx));
img_input_path = cell(1,length(input_idx));
for i = 1:length(input_idx)
    if isempty(other_param.appSel)        
        img_output_path{i} = [img_output_dir{seq_idx} Sequences{seq_idx} '/' det_input_name{input_idx(i)} '/mot/'];
    else
        img_output_path{i} = [img_output_dir{seq_idx} Sequences{seq_idx} '/' det_input_name{input_idx(i)} '/app/'];
    end        
    img_input_path{i} = [img_input_dir{seq_idx} img_input_subdir{input_idx(i)}];
end

% load camera parameters when PETS is selected
if strcmp(other_param.seq,'PETS2009')
    % get the camera parameters
    load input/PETS2009/PETS2009_S2L1_camera_parameters.mat;    
    other_param.camParam = camParam;
end