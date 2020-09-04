function jac = computeJacobian(format,stateCart)
% 计算Jacobian矩阵
% 输入:format:数据格式;stateSph:状态(笛卡尔坐标系)
% Author:X.W.Cui; Date:2020-6-13

GTRACK_STATE_VECTORS_2D = 0;
GTRACK_STATE_VECTORS_2DA = 1;

jac = zeros(3,4);

posx = stateCart(1); 
posy = stateCart(2); 
velx = stateCart(3); 
vely = stateCart(4);

range2 = (posx*posx + posy*posy);
range = sqrt(range2);
range3 = range*range2;

switch format
    case GTRACK_STATE_VECTORS_2D	        
        jac(1,1) = posx / range;  % dx
        jac(1,2) = posy / range;  % dy
        jac(1,3) = 0; % dx'
        jac(1,4) = 0; % dy'
        jac(2,1) = posy / range2; % dx
        jac(2,2) = -posx / range2;  % dy
        jac(2,3) = 0;  % dx'
        jac(2,4) = 0;  % dy'
        % dR'
        jac(3,1) = (posy*(velx*posy - vely*posx))/range3;  % dx
        jac(3,2) = (posx*(vely*posx - velx*posy))/range3; % dy
        jac(3,3) = posx / range; % dx'
        jac(3,4) = posy / range; % dy'

    case GTRACK_STATE_VECTORS_2DA
        % cart = [posx posy velx vely accx accy] 
        % jacobian is 3x6
        % dR
        jac(1) = posx / range; % dx
        jac(2) = posy / range; % dy
        jac(3) = 0; % dx'
        jac(4) = 0; % dy'
        jac(5) = 0; % dx''
        jac(6) = 0; % dy''
         % dPhi
        jac(7) = posy / range2; % dx
        jac(8) = -posx / range2; % dy
        jac(9) = 0; % dx'
        jac(10) = 0; % dy'
        jac(11) = 0; % dx''
        jac(12) = 0; % dy''
        % dR'
        jac(13) = (posy*(velx*posy - vely*posx))/range3; % dx
        jac(14) = (posx*(vely*posx - velx*posy))/range3; % dy
        jac(15) = posx / range; % dx'
        jac(16) = posy / range; % dy'
        jac(17) = 0; % dx''
        jac(18) = 0; % dy''
end

end

