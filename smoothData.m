function data = smoothData(data,kalman_param)

F = kalman_param.F; 
H = kalman_param.H;

Q_pos = kalman_param.Q/4;
R_pos = kalman_param.R/4;
initV_pos = kalman_param.initV/4;

Q_sz = 5*eye(4);
R_sz = 5*eye(2);
initV_sz = 10*eye(4);

for i = 1:max(data.id)

    idx = find(data.id==i);
    
    if isempty(idx)
        continue;
    end
          
    x_tmp = data.x(idx);
    y_tmp = data.y(idx);
%     w_tmp = data.w(idx);
%     h_tmp = data.h(idx);
    idx2 = isnan(data.isdummy(idx));
    
    diffInd = diff(idx2);
    idx2_pos_one = find(diffInd == 1);
    idx2_neg_one = find(diffInd == -1);
    
    if length(idx2_neg_one) ~= length(idx2_pos_one)
        error('error');
    end
    
    for j = 1:length(idx2_neg_one)
        x_st = x_tmp(idx2_pos_one(j));
        x_ed = x_tmp(idx2_neg_one(j)+1);
        y_st = y_tmp(idx2_pos_one(j));
        y_ed = y_tmp(idx2_neg_one(j)+1);
%         w_st = w_tmp(idx2_pos_one(j));
%         w_ed = w_tmp(idx2_neg_one(j)+1);
%         h_st = h_tmp(idx2_pos_one(j));
%         h_ed = h_tmp(idx2_neg_one(j)+1);
        step_sz = idx2_neg_one(j)+1-idx2_pos_one(j);
        
        ct = 1;
        x_increment = (x_ed-x_st)/step_sz;
        y_increment = (y_ed-y_st)/step_sz;
        w_increment = (w_ed-w_st)/step_sz;
        h_increment = (h_ed-h_st)/step_sz;
        for k = idx2_pos_one(j)+1:idx2_neg_one(j)
            x_tmp(k) = x_st+x_increment*ct;
            y_tmp(k) = y_st+y_increment*ct;
%             w_tmp(k) = w_st+w_increment*ct;
%             h_tmp(k) = h_st+h_increment*ct;
            ct = ct+1;
        end
    end
        
    [xy_out, Vsmooth] = kalman_smoother([x_tmp y_tmp]', F, H, Q_pos, R_pos, [x_tmp(1) y_tmp(1) 0 0]', initV_pos);    
%     [sz_out, Vsmooth] = kalman_smoother([w_tmp h_tmp]', F, H, Q_sz, R_sz, [w_tmp(1) h_tmp(1) 0 0]', initV_sz);

    data.x(idx) = xy_out(1,:)';
    data.y(idx) = xy_out(2,:)';
%     data.w(idx) = sz_out(1,:)';
%     data.h(idx) = sz_out(2,:)';
    
end

end