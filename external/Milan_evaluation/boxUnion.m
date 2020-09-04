function union=boxUnion(bboxleft1, bboxright1, bboxbottom1, bboxup1, bboxleft2, bboxright2, bboxbottom2, bboxup2,isect)
% 
% (C) Anton Andriyenko, 2012
%
% The code may be used free of charge for non-commercial and
% educational purposes, the only requirement is that this text is
% preserved within the derivative work. For any other purpose you
% must contact the authors for permission. This code may not be
% redistributed without written permission from the authors.

a1=bboxright1-bboxleft1;
b1=bboxbottom1-bboxup1;
a2=bboxright2-bboxleft2;
b2=bboxbottom2-bboxup2;
union=a1*b1+a2*b2;
if nargin>8
    bisect=isect;
else
    bisect=boxIntersect(bboxleft1, bboxright1, bboxbottom1, bboxup1, bboxleft2, bboxright2, bboxbottom2, bboxup2);
end
union=union-bisect;


end
