% LinearRegressor_Data class supports an out-of-core linear regressor where 
% the data cannot be loaded into memory.
% Usage example:

% L1 = LinearRegressor_Data(Input, Target);
% L1 = LinearRegressor_Data(Input, Target, Weights);

% Input is an n*D data matrix, with n training points in D dimensions. 
% Target is n * c, where c is the number of output dimensions. Weights is 
% an optional n * 1 vector for the weight on each training point.
%
% %Other training data can be added to L1:
% 
% L1 = L1 + LinearRegressor_Data(Input2, Target2);
%
% % Training data can also be subtracted out from L1
%
% L1 = L1 - LinearRegressor_Data(Input2, Target2);
%
% %You may also do a weighted addition since scalar multiplication has also 
% been implemented:
%
% L1 = 3 * L1 + 2 * LinearRegressor_Data(Input2, Target2);
%
% After building L1 up, you can choose from different regressors. Now 
% implemented are ridge regression, group lasso and PCA. 
%% For least squares/ridge regression, just use:
%
% w = L1.Regress(Lambda);
% Lambda is the ridge regression weight.
% The first dimension in the resulting weight vector is a constant.
% Starting from the second dimension it corresponds to dimensions in the
% input.
% Therefore, a proper testing procedure for an n*D matrix Input_Test is:
% ybar = w(1) + Input_Test * w(2:end);
%
%% For PCA, use:
% L1.PCA(d);
% in order to get d eigenvectors.
%
%% For Lasso/Group Lasso, use:
% L1.GroupLasso(Lambda, groups);
% Note the group Lasso depends on the SLEP sparse learning package
% downloadable at:
% http://www.public.asu.edu/~jye02/Software/SLEP/
% If you want to use it please download the package and add the path to
% glLeastR to MATLAB paths.
%% where Lambda is the regularization parameter and groups specify which variates are grouped together. groups = 1:D gives regular LASSO.
% Currently only Regress supports sparse matrices. Group LASSO supports only dense matrices.

% copyright (c) 2010 - 2012
% Fuxin Li - fli@cc.gatech.edu
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

classdef LinearRegressor_Data < handle
% classdef LinearRegressor_Data
    properties
        Hessian
        FeatSum
        N
        InputTarget
    end
    methods
        function obj = plus(obj,B)
			if strcmp(class(B),'LinearRegressor_Data')
	            obj.Hessian = obj.Hessian + B.Hessian;
                obj.FeatSum = obj.FeatSum + B.FeatSum;
                obj.N = obj.N + B.N;
                obj.InputTarget = obj.InputTarget + B.InputTarget;
            else
				error('Only supports adding LinearRegressor_Data class objects.');
			end
        end
        function obj = minus(obj,B)
			if strcmp(class(B),'LinearRegressor_Data')
	            obj.Hessian = obj.Hessian - B.Hessian;
                obj.FeatSum = obj.FeatSum - B.FeatSum;
                obj.N = obj.N - B.N;
                obj.InputTarget = obj.InputTarget - B.InputTarget;
            else
				error('Only supports adding LinearRegressor_Data class objects.');
			end
        end        
        function obj = mtimes(A,B)
            if strcmp(class(A), 'LinearRegressor_Data')
                obj = A;
                factor = B;
            else
                obj = B;
                factor = A;
            end
            obj.Hessian = factor * obj.Hessian;
            obj.FeatSum = factor * obj.FeatSum;
            obj.N = factor * obj.N;
            obj.InputTarget = factor * obj.InputTarget;
        end
        function obj = times(obj,B)
            obj = mtimes(obj,B);
        end
        function obj = rdivide(obj,B)
            obj = mtimes(obj,1./B);
        end
        function obj = mrdivide(obj,B)
            obj = mtimes(obj,1./B);
        end
        function obj = prune_targets(obj,to_keep)
            obj.InputTarget = obj.InputTarget(:,to_keep);
        end
        function obj = renew_targets(obj, new_InputTarget)
            if size(new_InputTarget,1) ~= size(obj.Hessian,1)+1
                error('New InputTarget must have same dimensionality as the original Hessian!');
            end
            obj.InputTarget = new_InputTarget;
        end
        function no_target = no_target(obj)
            if size(obj.InputTarget,2) == 0
                no_target = true;
            else
                no_target = false;
            end
        end
        function obj = LinearRegressor_Data(Input, Target, W, Hessian)
            [n, d] = size(Input);
            if exist('W','var') && ~isempty(W)
                % disp('Using weights');
                % Change to column vector
                if (size(W,2) > size(W,1))
                    W = W';
                end
                Target = bsxfun(@times, Target, sqrt(W));
                Input = repmat(sqrt(W), 1, d) .* Input;
            end
            if exist('Hessian','var') && ~isempty(Hessian)
                obj.Hessian = Hessian;
            else
                obj.Hessian = Input'*Input;
            end
            
            % chanho added to handle one training example case
            if size(Input,1) > 1
                obj.FeatSum = sum(Input)';
            else
                obj.FeatSum = Input';
            end
            
            obj.N = n;
            %    HessiHessian = [BiasVec'*BiasVec BiasVec'*Input; Input'*BiasVec Input'*Input];
            % obj.InputTarget = [sum(Target); Input'* Target];
            
            % chanho added to handle one training example case
            if size(Target,1) > 1
                obj.InputTarget = [sum(Target); Input'* Target];
            else
                obj.InputTarget = [Target; Input'* Target];
            end
        end
        function Weight = Regress(obj, Lambda, Reg_Mat)
            Hes = [obj.N obj.FeatSum';obj.FeatSum obj.Hessian];
            if nargin < 2
                Lambda = 1e-8*min(diag(Hes));
            end
            d = size(Hes,1);
            % Try out a parameter that goes higher with more training examples with sqrt(N).
            Lambda = Lambda * sqrt(obj.N);
            
            Weight = cell(size(obj.InputTarget,2),1);
            if exist('Reg_Mat','var') && ~isempty(Reg_Mat)
                Reg_Hes = Hes + Lambda * [1 zeros(1,d-1);zeros(d-1,1) Reg_Mat];
            else
                if ~issparse(Hes)
                    Reg_Hes = Hes + Lambda * eye(d);
                    % Don't regularize the constant
                    Reg_Hes(1,1) = Reg_Hes(1,1) - Lambda;
                else
                    Reg_Hes = Hes + Lambda * speye(d);
                    Reg_Hes(1,1) = Reg_Hes(1,1) - Lambda;
                end
            end
%            for i=1:size(obj.InputTarget,2)
                %disp(['Regressing the ' int2str(i) '-th output']);
                %t = tic();
                if issparse(Hes)
                    for i=1:size(obj.InputTarget,2)
                        Weight{i} = bicgstab(Reg_Hes, obj.InputTarget(:,i),1e-6,500);
                    end
                else
                    Weight = Reg_Hes\obj.InputTarget;
                end
                %toc(t);
%            end
            if length(Weight)==1
                Weight = Weight{1};
            end
        end
        function Weight = GroupLasso(obj, Lambda, groups)
            Hes = [obj.N obj.FeatSum';obj.FeatSum obj.Hessian];
            if nargin < 2
                Lambda = 1e-8*min(diag(Hes));
            end
            d = size(Hes,1);
            
            glOpts.mFlag=1;
            glOpts.lFlag=0;
            glOpts.q=2;
            if size(groups,1) > size(groups,2)
                groups = groups';
            end
            glOpts.ind = [0 1 cumsum(groups)+1];
            Weight = cell(size(obj.InputTarget,2),1);
            for i=1:size(obj.InputTarget,2)
                disp(['Regressing the ' int2str(i) '-th output']);
                t = tic();
                Weight{i} = glLeastR(Hes, obj.InputTarget(:,i), Lambda, glOpts);
                toc(t);
            end
        end
		% Perform PCA on Hessian, Return Mean vector as well
		function [Basis, Means, Eigenval] = PCA(obj, ndims)
		% Eigenvectors, I should probably implement a custom version because MATLAB symmetric eigenvalues don't use MKL and is rather slow.
        % UPDATE: MATLAB fixed that.
            t = tic();
			Means = obj.FeatSum ./ obj.N;
			[Basis, Eigenval] = eig(obj.Hessian - obj.N .* (Means * Means'));
            Basis = fliplr(Basis);
            Basis = Basis(:,1:ndims);
            disp('Time for Eigenvectors: ');
            toc(t);
        end
    end
end
