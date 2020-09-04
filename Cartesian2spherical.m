function stateSph = Cartesian2spherical(format,stateCart)
% 笛卡尔坐标系到球坐标系的状态转换
% 输入;format:数据格式，默认为1;stateCart:笛卡尔坐标系状态:[x y vx vy]
% 输出:stateSph:球坐标系状态:[range angle doppler]
% Author:X.W.Cui; Date:2020-6-13

posx = 0.0;
posy = 0.0; 
velx = 0.0; 
vely = 0.0;

switch (format)
    case 0
        
    case 1
        posx = stateCart(1); 
        posy = stateCart(2); 
        velx = stateCart(3); 
        vely = stateCart(4);

        stateSph(1) = sqrt(posx*posx + posy*posy); 

        if posy == 0
            stateSph(2) = pi/2;
        elseif posy > 0
            stateSph(2) = atan(posx/posy);
        else
            stateSph(2) = atan(posx/posy) + pi;
        end

        stateSph(3) = (posx*velx+posy*vely)/stateSph(1);	
end

end

