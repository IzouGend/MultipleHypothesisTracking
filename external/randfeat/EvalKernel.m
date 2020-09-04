function K = EvalKernel(samples1, samples2, kernel, kernelparam)
%EVALKERNEL Fastly Evaluate kernel function between samples1 and samples2
% matrix.
%
% samples1, samples2 - two feature matrices, with each row being an example
%                    kernel is among 'linear', 'rbf' (Gaussian), 'laplace' 
%                    (Laplacian) 'chi2' (Chi-square), 'chi2_skewed' (Skewed 
%                    chi-square), 'intersection' (Histogram intersection), 
%                    'intersection_skewed' (Skewed intersection),
%                    'exp_chi2' (Exponentitated chi-square).
% kernelparam        - kernel parameter (semantic depends on the kernel)
%
% copyright (c) 2010-2012
% Fuxin Li - fli@cc.gatech.edu
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

% Fastly Evaluate kernel function

if (size(samples1,2)~=size(samples2,2))
    error('sample1 and sample2 differ in dimensionality!!');
end
[L1, dim] = size(samples1);
[L2, dim] = size(samples2);

switch kernel
case 'dist2'
    a = sum(samples1.*samples1,2);
    b = sum(samples2.*samples2,2);
    dist2 = a*ones(1,L2);
    dist2 = dist2 + ones(L1,1)*b';
    K = dist2 - 2*samples1*samples2';
case 'linear'
    K = samples1*samples2'/dim;
case 'poly'
    K = (1 + samples1*samples2').^kernelparam;
case 'rbf'
    % If sigle parammeter, expand it.
    if length(kernelparam) < dim
        a = sum(samples1.*samples1,2);
        b = sum(samples2.*samples2,2);
        dist2 = a*ones(1,L2);
        dist2 = dist2 + ones(L1,1)*b';
        dist2 = dist2 - 2*samples1*samples2';
        K = exp(-kernelparam*dist2);
    else
        kernelparam = kernelparam(:);
        a = sum(samples1.*samples1.*repmat(kernelparam',L1,1),2);
        b = sum(samples2.*samples2.*repmat(kernelparam',L2,1),2);
        dist2 = a*ones(1,L2);
        dist2 = dist2 + ones(L1,1)*b';
        dist2 = dist2 - 2*(samples1.*repmat(kernelparam',L1,1))*samples2';
        K = exp(-dist2);
    end
case 'laplace'
    K = zeros(L1,L2);
    for i = 1:L1
        K(i,:) = (sum(abs(repmat(samples1(i,:),L2,1) - samples2),2))';
    end
    K = exp(-kernelparam*K);
case {'chi2','exp_chi2'}
    addpath('./utils');
    % if the mex file is not available for your architecture
    try 
      K = chi2_mex(samples1',samples2');
    catch E
      disp(E);
      K = zeros(L1, L2);
      for i = 1: L1
        si = repmat(samples1(i,:),[L2 1]);
        K(i,:) = 2*sum(si.*samples2 ./(si+samples2 +1e-20),2);
      end
    end
    if strcmpi(kernel,'exp_chi2')
        K = exp(- kernelparam * K);
    end
case 'chi2_skewed'    
    addpath('./utils/');
    % if the mex file is not available for your architecture
    try
      K = chi2_mex_scinv(samples1',samples2',single(kernelparam));
    catch E
      disp(E);
      K = zeros(L1, L2);
      samples1 = double(samples1);
      samples2 = double(samples2);
      for i = 1: L1
        si = repmat(samples1(i,:),[L2 1]);
        K(i,:) = sqrt( prod(4*(si + kernelparam).*(samples2 + kernelparam)./(si+samples2 +2*kernelparam).^2,2));
      end
    end
case 'intersection'
    K = zeros(L1, L2);
    for i = 1: L1
      si = repmat(samples1(i,:),[L2 1]);
      K(i,:) = sum(min(si,samples2),2);
    end
case 'intersection_skewed'
    addpath('./utils/');   
    try
      K = skewhist_mex(samples1',samples2',single(kernelparam));
    catch E
      disp(E);
    end
    
otherwise
    error('Unknown kernel function');
end
