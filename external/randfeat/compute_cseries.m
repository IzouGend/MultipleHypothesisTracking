function cs = compute_cseries(x,len)
    if size(x,2) > size(x,1)
        xx = x';
    else
        xx = x;
    end
    if issparse(x)
        lgxpi = sparse(length(x),1);
        lgxpi(xx~=0) = log(xx(xx~=0))/pi;
    else
        lgxpi = log(xx) / pi;
	lgxpi(xx==0) = 0;
    end
    if issparse(x)
        cs = sparse(length(x),len);
    else
        cs = zeros(length(x),len);
    end
%    cd = zeros(length(x),len);
    cs(:,1) = 2 * xx ./ (1+xx);
%    cd(1) = cs(1);
    cs(:,2) = - lgxpi .* cs(:,1) * sqrt(2);
%    cd(2) = cs(2);
    if len > 2
        for i=3:len
            if mod(i,2) == 0
                cs(:,i) = (-2 * lgxpi .* cs(:,i-1) + (i-3) * cs(:,i-2))/ (i-1);
            else
                cs(:,i) = (2 * lgxpi .* cs(:,i-1) + (i-3) * cs(:,i-2))/ (i-1);
            end
%             if i<=20
%                 cd(i) = cs(i);
%             else    
%                 cd(i) = (i-3) * cd(i-2) / (i-1);
%             end
        end
    end
end
