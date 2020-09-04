function det = loadDet(det_input_path, other_param)

load(det_input_path);

if strcmp(other_param.seq,'PETS2009')
    % change the detection variable name
    det = dres;
    if ~other_param.is3Dtracking
        det.x = det.bx+det.w/2;
        det.y = det.by+det.h/2;
    end
elseif ~other_param.is3Dtracking
    det.x = det.x + det.w/2;
    det.y = det.y + det.h/2;
end

% if there is no detection score field, creat it
if ~isfield(det,'r')
    det.r = ones(length(det.x),1);
end