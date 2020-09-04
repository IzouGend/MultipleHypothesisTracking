function K = chi_square_kernel(u, v, gamma)    
%    assert(9 > n_workers); 
    
%    setenv('OMP_NUM_THREADS',int2str(n_workers));
    if ~issparse(u) && ~issparse(v)
        K = chi2_mex_single(single(u)',single(v)',false);
    else
        K = chi2(u,v);
    end
    if(exist('gamma','var') && ~isempty(gamma))
        K = exp(-gamma.*K);
    end
end
