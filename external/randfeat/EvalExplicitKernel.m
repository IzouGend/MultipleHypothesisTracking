function K = EvalExplicitKernel( X, Y, kernel, alpha, Napp )
%EVALEXPLICITKERNEL compute kernel based on explicit linear features

% number of explicit features with which to approximate
if nargin < 5
  Napp = 10; 
end

[Nx D] = size(X);
Ny = size(Y,1);
K = zeros(Nx, Ny);

obj = InitExplicitKernel(kernel, D, alpha, Napp);
% compute features and kernel
z_omega_x = rf_featurize(obj, X);
z_omega_y = rf_featurize(obj, Y);
for i = 1: Nx
  K(i,:) = z_omega_y * z_omega_x(i,:)';
end

end

