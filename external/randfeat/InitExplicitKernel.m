function obj = InitExplicitKernel( kernel, alpha, D, Napp, options )
%INITEXPLICITKERNEL compute kernel based on explicit linear features
%
% kernel - the name of the kernel. Supported options are: 
%             'rbf': Gaussian, 
%             'laplace': Laplacian, 
%             'chi2': Chi-square, 
%             'chi2_skewed': Skewed Chi-square,
%             'intersection', Histogram Intersection, 
%             'intersection_skewed', Skewed Histogram Intersection
% alpha  - the parameter of the kernel, e.g., the gamma in \exp(-gamma ||x-y||) 
%        for the Gaussian.
% D      - the number of dimensions
% Napp 	 - the number of random points you want to sample
% options: options. Now including only: 
%         options.method: 'sampling' or 'signals', signals for [Vedaldi 
%                         and Zisserman 2010] type of fixed interval sampling. 
%                         'sampling' for [Rahimi and Recht 2007] type of 
%                         Monte Carlo sampling.
%         options.single: if true, generate random features in single
%         precision.
%
% copyright (c) 2010 
% Fuxin Li - fuxin.li@ins.uni-bonn.de
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

% number of explicit features with which to approximate
if nargin < 4
  Napp = 10; 
end
if nargin < 5
    options = [];
end

switch kernel
    case 'rbf'
        % check
        obj = rf_init('gaussian', alpha, D, Napp, options);
    case 'exp_hel'
        obj = rf_init('exp_hel', alpha, D, Napp, options);
        
    case 'laplace'
        % not verified
        obj = rf_init('laplace', alpha, D, Napp, options);
    
  case 'chi2'
    if ~isfield(options, 'method')
      options.method = 'signals';
      if ~isfield(options,'period') || isempty(options.period)
        options.period = 4e-1;
      end
      if ~isfield(options,'Nperdim') || isempty(options.Nperdim)
        options.Nperdim = 7;
      end
    elseif strcmp(options.method,'chebyshev')
        if ~isfield(options,'Nperdim') || isempty(options.Nperdim)
            options.Nperdim = 50;
        end
    elseif strcmp(options.method,'direct')
        if ~isfield(options,'params')
            disp(['The direct method has a param vector that is best ' ...
            'estimated from your histogram data using the function decide_parameter_list.m, using default values ' ...
            '(estimated from a 300-dim BOW histogram) now.']);
            options.params = [0.0116 0.0327 0.9016 0.0041 0.0922 0.0015 0.3198 ...
                0.0077 0.0006 0.0216 0.5956 0.0609 0.0003 0.0027 0.1717 0.0001 ...
                0.7328 0.0010 0.0143 6.52e-5 0.0051 0.2113 4.21e-4 0.0402 0.4841 ...
                2.21e-3 9.87e-5 0.1134 0.00943 2.26e-4 4.306e-5 0.0266 0.3935 ...
                1.187e-3 0.0749 3.345e-3 5.18e-4 3.5e-5 0.26 0.0176 1.213e-4 ...
                6.23e-3 0.0495 7.84e-4 5.3e-5 0.1396 1.797e-3 1.837e-4 ...
                3.42e-4 8.02e-5];
        end
    end
    obj = rf_init('chi2', alpha, D, Napp, options);
  case 'chi2_skewed'
    obj = rf_init('chi2', alpha, D, Napp, options);
    obj.name = 'chi2_skewed';
    
  case 'intersection'
    obj = rf_init('intersection', alpha, D, Napp, options);
  
  case 'intersection_skewed'
    obj = rf_init('intersection', alpha, D, Napp, options);
    obj.name = 'intersection_skewed';
    % Linear: no approximation, Napp is ignored
    
  case 'linear'
    obj.name = 'linear';
    obj.Napp = D;
    obj.dim = D;
    obj.final_dim = D;
    
  case 'exp_chi2'
    if ~isfield(options,'method')
        options.method = 'chebyshev';
    end
    if ~isfield(options,'Nperdim')
        options.Nperdim = 9;
    end
    if strcmp(options.method,'direct')
        if ~isfield(options,'params')
            disp(['The direct method has a parameter vector specified in options.params that is best ' ...
            'estimated from your histogram data using the function decide_parameter_list.m, using default values ' ...
            '(estimated from a 300-dim BOW histogram) now.']);
            options.params = [0.0116 0.0327 0.9016 0.0041 0.0922 0.0015 0.3198 ...
                0.0077 0.0006 0.0216 0.5956 0.0609 0.0003 0.0027 0.1717 0.0001 ...
                0.7328 0.0010 0.0143 6.52e-5 0.0051 0.2113 4.21e-4 0.0402 0.4841 ...
                2.21e-3 9.87e-5 0.1134 0.00943 2.26e-4 4.306e-5 0.0266 0.3935 ...
                1.187e-3 0.0749 3.345e-3 5.18e-4 3.5e-5 0.26 0.0176 1.213e-4 ...
                6.23e-3 0.0495 7.84e-4 5.3e-5 0.1396 1.797e-3 1.837e-4 ...
                3.42e-4 8.02e-5];
        end
    end
    obj = rf_init('exp_chi2', alpha, D, Napp, options);
    case 'jensen_shannon'
        if ~isfield(options,'method')
            options.method = 'signals';
        end
        if ~isfield(options,'period')
            options.period = 0.6;
        end
        if ~isfield(options,'Nperdim')
            options.Nperdim = 9;
        end
        obj = rf_init('jensen_shannon',alpha,D,Napp,options);
  otherwise
    error('Unknown kernel');
end

end

