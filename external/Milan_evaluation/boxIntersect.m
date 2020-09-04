function isect=boxIntersect(bboxleft1, bboxright1, bboxbottom1, bboxup1, bboxleft2, bboxright2, bboxbottom2, bboxup2)
% A=[bboxleft1 bboxbottom1 abs(bboxright1-bboxleft1) abs(bboxbottom1-bboxup1)];
% B=[bboxleft2 bboxbottom2 abs(bboxright2-bboxleft2) abs(bboxbottom2-bboxup2)];
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

% isect=rectint(A,B);        
isect=0;

hor= max(0,min(bboxright1,bboxright2) - max(bboxleft1,bboxleft2));

if ~hor, return; end
ver= max(0,min(bboxbottom1,bboxbottom2) - max(bboxup1,bboxup2));
if ~ver, return; end

isect = hor*ver;

end