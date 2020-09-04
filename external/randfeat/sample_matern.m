function s_vec = sample_matern(nsamples, t, dims)
% Use uniform scale because when dims is high-dimensional, uniform is OK
    s_vec = zeros(nsamples,1);
    for i=1:nsamples
        a = randn(t, dims);
        a = bsxfun(@rdivide,a, sqrt(sum(a.^2,2)));
        a = bsxfun(@times, a, rand(t,1));
        s_vec(i) = norm(sum(a));
    end
end