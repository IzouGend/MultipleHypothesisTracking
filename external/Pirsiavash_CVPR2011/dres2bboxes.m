function bboxes = dres2bboxes(dres, fnum)

if ~isempty(dres.x)
    for i = 1:fnum
      bboxes(i).bbox = [];
    end

    for i = 1:length(dres.x)
    %   bbox = [dres.x(i) dres.y(i) dres.w(i) dres.h(i) dres.r(i)];
      %bbox = [dres.x(i) dres.y(i) dres.x(i)+dres.w(i) dres.y(i)+dres.h(i) dres.id(i) dres.det_type(i)];
      bbox = [dres.x_hat(i) dres.y_hat(i) dres.x_hat(i)+dres.w(i) dres.y_hat(i)+dres.h(i) dres.id(i)];
      bboxes(dres.fr(i)).bbox = [bboxes(dres.fr(i)).bbox; bbox];
    end
else
    bboxes = [];
end
