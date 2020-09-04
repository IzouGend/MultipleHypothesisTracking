function ds = compute_dseries(x,params)
    % Compute the coefficients analytically
    % the m-th coefficient is:
    % (x - k1)(x + k1) ... (x - k_{m-1})(x+k_{m-1}) 2 * sqrt(k_m) x / (x +
    % k_m)
    if size(x,2) > size(x,1)
        xx = x';
    else
        xx = x;
    end
    if size(params,1) > size(params,2)
        params = params';
    end
    starts = 2 * bsxfun(@times, sqrt(params),bsxfun(@rdivide, xx, bsxfun(@plus, xx, params)));
    prods = bsxfun(@minus, xx, params(1:end-1)) ./ bsxfun(@plus, xx, params(1:end-1));
    prods = [ones(size(xx,1),1) prods];
    ds = cumprod(prods,2).*starts;
end