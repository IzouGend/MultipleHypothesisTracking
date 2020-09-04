function iou=boxiou(x1,y1,w1,h1,x2,y2,w2,h2)    
% compute intersection over union of two bboxes
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

    bisect=boxIntersect(x1,x1+w1,y1+h1,y1,x2,x2+w2,y2+h2,y2);
    iou=0;
    if ~bisect, return; end
    
    bunion=boxUnion(x1,x1+w1,y1+h1,y1,x2,x2+w2,y2+h2,y2,bisect);
    
    assert(bunion>0,'something wrong with union computation');
    iou=bisect/bunion;

end