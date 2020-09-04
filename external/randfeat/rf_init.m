function obj = rf_init( kernel_name, kernel_param, dim, Napp, options)
%RF_INIT initialize the kernel with the right parameters and sample in
%order to get the fourier features
%
% kernel_name : supported kernel i.e. 'gaussian', 'laplace', 'chi2',
% 'intersection'
% kernel_param : parameter for the kernel
% dim : dimensionality of the features
% Napp : number of samples for the approximation
% options: options. Now including only: 
%         options.method: 'sampling' or 'signals', signals for [Vedaldi 
%                         and Zisserman 2010] type of fixed interval sampling. 
%                         'sampling' for [Rahimi and Recht 2007] type of 
%                         Monte Carlo sampling.
%
%
% copyright (c) 2010 
% Fuxin Li - fuxin.li@ins.uni-bonn.de
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

if ~isfield(options,'method')
    options.method = 'sampling';
end

obj = options;
obj.name = kernel_name;
obj.dim = dim;
obj.kernel_param = kernel_param;
obj.Napp = Napp;
obj.debug = false;

switch kernel_name
  case {'gaussian','exp_hel'}
    obj.distribution = 'gaussian';
    obj.coeff = 1/sqrt(Napp);
  
  case 'laplace'
        obj.distribution = 'cauchy';
        obj.coeff = 1/sqrt(Napp);
  % these are done with fourier analysis 
  
  case {'chi2','chi2_skewed'}
    switch options.method
      case 'signals'
%         obj.distribution = 'period';
%         obj.Nperdim = 20;
%         obj.period = 6e-1; % this can be optimized
        obj.distribution = 'period';
        obj.period = 1 / sqrt(2*(obj.Nperdim+1));
      case 'sampling'
        obj.distribution = 'sech';
        obj.gn = 1;
      case 'chebyshev'
        obj.distribution = 'chebyshev';
      case 'direct';
            % Do nothing
      otherwise
        error('Unknown sampling method.');
    end
    
  case 'intersection'
    switch options.method
      case 'signals'
        obj.distribution = 'period';
        obj.period = 6e-1;
      case 'sampling'
        obj.distribution = 'cauchy';
        obj.kernel_param = 0.5;
      otherwise
          error('Unknown sampling method.');
    end
  case 'exp_chi2'
    switch options.method
      case 'signals'
        obj.distribution = 'exp_chi2';
        obj.period = 1 / sqrt(2*(obj.Nperdim+1));
      case 'chebyshev'
        obj.distribution = 'exp_chi2';
      case 'sampling'
        error('Not yet implemented');
      case 'direct'
        obj.distribution = 'exp_chi2';
      otherwise
        error('Unknown method!');
    end
    if ~isfield(options,'method2')
        obj.method2 = 'normal';
    end
  case 'jensen_shannon'
    if ~strcmp(options.method,'signals')
        error('We have not yet developed the sampling for Jensen-Shannon kernel.');
    end
    obj.distribution = 'period';
  otherwise
    error('Unknown kernel.');
end

obj = rf_sample(obj);
obj.beta = rand(Napp,1); % 
% These are fixed dimension ones
if (strcmp(options.method,'signals') || strcmp(options.method,'chebyshev')) && (~isfield(obj,'name') || ~strcmp(obj.name,'exp_chi2'))
    obj.final_dim = obj.Nperdim * obj.dim;
else
    obj.final_dim = Napp;
end
if isfield(options,'single') && options.single
    obj.omega = single(obj.omega);
    obj.beta = single(obj.beta);
    if isfield(obj,'omega2')
        obj.omega2 = single(obj.omega2);
    end
end

