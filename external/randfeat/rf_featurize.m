function F = rf_featurize(obj, X, Napp)
%RF_FEATURIZE returns the features corresponding to the inputs X
%
% obj   - random feature object initialized by rf_init.
% Napp  - specifies the number of features to be extracted. If obj.method is
%       signals then it is specified per dimension as 2*floor(Napp/2)+1 
%       otherwise it is the number of terms in the MC approximation.
%
% copyright (c) 2010 
% Fuxin Li - fuxin.li@ins.uni-bonn.de
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de
if ~exist('Napp','var') || isempty(Napp)
    Napp = obj.Napp;
end
%   if strcmp(obj.name,'exp_chi2')
%       if isfield(obj,'omega2')
%           obj.omega2 = obj.omega2';
%       end
%       F = mex_featurize(obj, double(X), Napp)';
%   else
[N D] = size(X);

if D ~= obj.dim
  error('Dimension mismatch!');
end

% Use mex_featurize if it's exp-chi2 and not Nystrom method.
% if strcmp(obj.name,'exp_chi2') && ~strcmp(obj.method,'nystrom')
%     if isfield(obj,'omega2')
%         obj.omega2 = obj.omega2';
%     end
%     try
%         F = mex_featurize(obj, double(X), Napp)';
%     catch
%         [N D] = size(X);
%     obj.omega2 = obj.omega2';
%     end
%     if isfield(obj,'omega') && Napp > size(obj.omega,2) && strcmp(obj.method,'sampling')
%         disp(['Warning: selected number of random features ' num2str(Napp) 'more than built-in number of random features ' num2str(size(obj.omega,2)) '.']);
%         disp(['Changing the number of random features to ' num2str(size(obj.omega,2)) '.']);
%         disp('You can increase the built-in number in rf_init()');
%         Napp = size(obj.omega,2);
%     end
% end
    switch obj.name
        case 'gaussian'
            F = sqrt(2) * (cos( X * obj.omega(:,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi));
        case 'exp_hel'
            if ~isempty(find(X<0,1,'first'))
                error('Error: Input matrices have negative entries in the Hellinger kernel.');
            end
            for i=1:Napp
                XX2(i) = obj.omega(:,i)' * obj.omega(:,i);
            end
            XX = XX - mean(XX);
            XX2 = XX2 - D/2 * log(obj.kernel_param/pi);
            XX2 = XX2 - mean(XX2);
            weights = exp(-XX ./ 4*(obj.gamma + obj.kernel_param));
            weights2 = exp(XX2 * obj.kernel_param * obj.kernel_param / (obj.gamma + obj.kernel_param));
            F = cos(obj.gamma ./ (obj.kernel_param + obj.gamma) .* sqrt(X) * obj.omega(:,1:Napp));
            % Singleton expansion is automatic
%            F = bsxfun(@times,F,weights);
            % Remove weights2 for now it's too small
%            F = bsxfun(@times,F,weights2);
    case {'chi2','exp_chi2'}
        % only this fourier analytic treatment no mc estimation yet for chi2
        if issparse(X)
            F = spalloc(N, D*obj.Nperdim,nnz(X)*obj.Nperdim);
        else
            F = zeros(N, D*obj.Nperdim);
        end
        if strcmp(obj.method, 'signals')
            even_odd = zeros(N,obj.Nperdim-1);
            even_odd(:,2:2:end) = - pi / 2;
            for i = 1: D
              if issparse(X)
                Xnz = X(:,i) ~= 0;
                F(Xnz,((i-1)*obj.Nperdim+1):(i*obj.Nperdim)) = sqrt(obj.period) * [sech(0)*sqrt(X(Xnz,i)), ...
                cos(log(X(Xnz,i))*obj.omega(i,1:(obj.Nperdim-1))+even_odd(Xnz,:)) .* sqrt(2 * X(Xnz,i) * sech(pi * obj.omega(i,1:(obj.Nperdim-1))))];
              else
                  if obj.Nperdim > 1
                F(:,((i-1)*obj.Nperdim+1):(i*obj.Nperdim)) = sqrt(obj.period) * [sech(0)*sqrt(X(:,i)), ...
                cos(log(X(:,i))*obj.omega(i,1:(obj.Nperdim-1))+even_odd) .* sqrt(2 * X(:,i) * sech(pi * obj.omega(i,1:(obj.Nperdim-1))))];
                  else
                      F(:,i) = sqrt(obj.period) * sech(0)*sqrt(X(:,i));
                  end
              end
            end
        elseif strcmp(obj.method, 'chebyshev')
            % compute the coefficients
            % cseries type
            for i = 1:D
                % for each dimension
                % Small anyway, sparsify won't hurt
                ck = compute_cseries(X(:,i),obj.Nperdim);
                F(:,i:D:end) = ck;
            end
        elseif strcmp(obj.method,'direct')
            for i=1:D
                params = obj.params(1:obj.Nperdim);
                dk = compute_dseries(X(:,i), params);
%                dk = [bsxfun(@times, 1 - X(:,i), compute_dseries(X(:,i), 0.007, obj.Nperdim / 2)) ...
%                    bsxfun(@times, X(:,i), compute_dseries(X(:,i), 1, obj.Nperdim / 2))];
                F(:,i:D:end) = dk;
            end
         end
         F(isinf(F)) = 0;
         F(isnan(F)) = 0;
%         SF = sqrt(1 - sum(F.^2,2));
%         SF(SF<0) = 0;
%         SF(SF==1) = 0;
        if strcmp(obj.name,'exp_chi2')
%            F = sqrt(2) * (cos( [F SF] * obj.omega2(1:D*obj.Nperdim+1,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi));
            F = sqrt(2) * (cos( F * obj.omega2(1:D*obj.Nperdim,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi));
        end
    case 'chi2_skewed'
        % skewed multiplicative chi-square kernel
        F = sqrt(2) * cos( log(X+obj.kernel_param) * 0.5 * obj.omega(:,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi);
    case 'intersection_skewed'
        F = sqrt(2) * cos( log(X+obj.kernel_param) * obj.omega(:,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi);
    case 'laplace'
        F = sqrt(2) * (cos( X * obj.omega(:,1:Napp) + obj.beta(1:Napp,ones(1,N))'*2*pi));
        % Linear is just replicate
    case 'linear'
        F = X;
    case 'jensen_shannon'
            if issparse(X)
                F = spalloc(N, D*obj.Nperdim,nnz(X)*obj.Nperdim);
            else
                F = zeros(N, D*obj.Nperdim);
            end
        even_odd = zeros(N,obj.Nperdim-1);
        even_odd(:,2:2:end) = - pi / 2;
        for i = 1: D
            if issparse(X)
                Xnz = X(:,i) ~= 0;
                F(Xnz,((i-1)*obj.Nperdim+1):(i*obj.Nperdim)) = sqrt(obj.period) * [sech(0)*sqrt(X(Xnz,i)), ...
                cos(log(X(Xnz,i))*obj.omega(i,1:(obj.Nperdim-1))+even_odd(Xnz,:)) .* sqrt(2 * X(Xnz,i) * (sech(pi * obj.omega(i,1:(obj.Nperdim-1)))./(1+4* obj.omega(i,1:(obj.Nperdim-1)).^2)))];
            else
                F(:,((i-1)*obj.Nperdim+1):(i*obj.Nperdim)) = sqrt(obj.period) * [sech(0)*sqrt(X(:,i)), ...
                    cos(log(X(:,i))*obj.omega(i,1:(obj.Nperdim-1))+even_odd) .* sqrt(2 * X(:,i) * (sech(pi * obj.omega(i,1:(obj.Nperdim-1)))./(1+4* obj.omega(i,1:(obj.Nperdim-1)).^2)))];
                F(isinf(F)) = 0;
                F(isnan(F)) = 0;
            end
        end
    case 'intersection'
    F = [];
    for i = 1: D
      cterm = cos(log(X(:,i))*obj.omega(i,:)) .* sqrt(2/pi* X(:,i) * (1./(1 + 4 * obj.omega(i,:).^2)));
%       cterm(isnan(cterm)) = 0;
      sterm = sin(log(X(:,i))*obj.omega(i,:)) .* sqrt(2/pi* X(:,i) * (1./(1 + 4 * obj.omega(i,:).^2)));
%       sterm(isnan(sterm)) = 0;
      
      F = [F sqrt(obj.period) * [sqrt(2/pi)*sqrt(X(:,i)), cterm, sterm ]];
    end
    % this is a clean up of the rf. If X is 0 then log(X) becomes infinity
    % and cos(log(X)) is NaN. We correct this in the end by putting 0
    F(isnan(F)) = 0; 
%        F = sqrt(2) * (cos( F * obj.omega2' + repmat(obj.beta'*2*pi,N,1)));
    otherwise
        error('Unknown kernel approximation scheme');
end
%    end
%end
