function [Xgp Ygp]=projectToGroundPlane(Xi, Yi, sceneInfo)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

[F N]=size(Xi);
Xgp=zeros(size(Xi));
Ygp=zeros(size(Xi));

if length(sceneInfo.camPar)==1
    for t=1:F
        extar=find(Xi(t,:));
        for id=extar
            [Xgp(t,id) Ygp(t,id) zw]=imageToWorld(Xi(t,id), Yi(t,id), sceneInfo.camPar);
        end
    end
else
    for t=1:F
        extar=find(Xi(t,:));
        for id=extar
            [Xgp(t,id) Ygp(t,id) zw]=imageToWorld(Xi(t,id), Yi(t,id), sceneInfo.camPar(t));
        end
    end

end
end
