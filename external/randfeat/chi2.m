function chi = chi2(X,Y)
   rowy = size(Y,1);
   rowx = size(X,1);
   chi = zeros(rowy, rowx);
   for i=1:rowx
       if mod(i,100) == 0
           disp('100 points finished.');
       end
       if rowy > 1
%           rX = repmat(X(i,:), rowy,1);
           rX = X(ones(rowy,1) * i,:);
           s1 = (rX - Y).^2;
           s2 = rX + Y;
           s1(s2>0) = s1(s2>0) ./ s2(s2>0);
           chi(:,i) = full(sum(s1,2));
       end
    end
end
