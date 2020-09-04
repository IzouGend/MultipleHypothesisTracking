function [Xi Yi]=projectToImage(X,Y,camPar)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

Z=zeros(size(X));
[mR mT]=getRotTrans(camPar);
[Xi Yi]=allWorldToImage_mex(X,Y,Z, ...
    camPar.mGeo.mDpx, camPar.mGeo.mDpy, ...
    camPar.mInt.mSx, camPar.mInt.mCx, camPar.mInt.mCy, camPar.mInt.mFocal, camPar.mInt.mKappa1,...
    mR,mT);

end