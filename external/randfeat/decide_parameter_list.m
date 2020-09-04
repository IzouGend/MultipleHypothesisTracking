function params = decide_parameter_list(inputs, len)
% Determine the distribution of input and choose a set of parameters for
% the direct approximation of the chi-square kernel
% Usually, 9 is enough to get a good enough approximation
    if ~exist('len','var') || isempty(len)
        len = 9;
    end
    params = zeros(len,1);
% Histogram on the log values since this reflects our range-capturing
% ability, 50 bins are usually enough
    [s, xlocs] = hist(log(inputs(inputs>0)), 50);
    xx = exp(xlocs);
% Normalize it a bit to make room for unseen items, also, make the numbers
% bigger just for aesthetics.
    s = s ./(sum(s)) * 5000 + 1;
% Base: 2 * xx / (xx+1) * s
    base = xx ./ (xx+1) .* s;
    for i=1:len
         [~,b] = max(abs( base));
         params(i) = xx(b);
%         opts.Display = 'off';
%         opts.LargeScale = 'off';
%         opts.TolFun = 1e-3;
%         opts.TolX = 1e-3 * xx(b);
%         params(i) = fminunc(@(x) my_fun(x, base, xx), double(xx(b)),opts);
        % multiply by (x - k) / (x + k) each time
        base = base .* (xx-params(i))./(xx+params(i));
    end
end

function f = my_fun(k, base, xx)
    f = double(max(abs(base .* (xx-k) ./ (xx+k))));
end