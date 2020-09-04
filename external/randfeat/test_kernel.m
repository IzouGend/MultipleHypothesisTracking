function test_kernel(x,y, kernel_type, kernel_par, Napp, options)
% Test the kernel matrix approximation quality.
% x,y are input feature matrices. Each row is an example
% kernel_type is among 'linear', 'rbf' (Gaussian), 'laplace' (Laplacian)
% 'chi2' (Chi-square), 'chi2_skewed' (Skewed chi-square), 'intersection'
% (Histogram intersection), 'intersection_skewed' (Skewed intersection),
% 'exp-chi2' (Exponentiated chi-square).
% kernel_par is the kernel parameter.
% Napp is the number of random feature dimensions, for options.method = signals,
% the final dimensionality would be (2*floor(Napp/2) + 1) * input_dimension
% (the Napp is the number of approximation terms per dimension without the 
% central term).
% options: options. See the help of InitExplicitKernel for the possible
% options.
%
% copyright (c) 2010 - 2012
% Fuxin Li - fli@cc.gatech.edu
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

if ~exist('kernel_type','var')
    kernel_type = 'chi2_skewed'; % chi2, gaussian
end
if ~exist('kernel_par','var')
    kernel_par = [0.03];
end
if ~exist('Napp','var')
    Napp = 2000;
end
if ~exist('options','var') || ~isfield(options,'approx')
  options.approx = 'mc';
end
if ~isfield(options, 'redo_kdet')
    options.redo_kdet = false;
end
%setenv('OMP_NUM_THREADS','8');


% generate data
if ~exist('x','var') && ~exist('y','var')
    N = 300;
    D = 50;
    x = rand(N,D);
    y = rand(N/2,D);
    if D>1
        x = x./repmat(sum(x,2),[1 D]);
        y = y./repmat(sum(y,2),[1 D]);
    end
else
    [N D] = size(x);
end

kdetname = [kernel_type '_' num2str(kernel_par) '_' num2str(D) '.mat'];

if exist(kdetname,'file') && ~options.redo_kdet
    load(kdetname);
else
    Kdet = EvalKernel(x,y, kernel_type, kernel_par);
    save(kdetname, 'Kdet');
end

% compute explicit feature based representation for the kernel
obj = InitExplicitKernel(kernel_type, kernel_par, D, Napp, options);
obj
%z_omega_x = rf_featurize(obj, x, obj.Napp);
%z_omega_y = rf_featurize(obj, y, obj.Napp);

if isfield(options,'Npcadim') && options.Npcadim
    [z_omega_x,obj] = rf_pca_featurize(obj, x, true, options.Npcadim, obj.Napp);
    z_omega_y = rf_pca_featurize(obj, x, false);
else
    % To prevent error
    options.Npcadim = 0;
    z_omega_x = rf_featurize(obj,x,obj.Napp);
    z_omega_y = rf_featurize(obj,y,obj.Napp);
end
mean_omega_x = mean(z_omega_x);
mean_omega_y = mean(z_omega_y);

% Kprob = zeros(size(Kdet));
Kbasic = zeros(size(Kdet));
Kpca = zeros(size(Kdet));

% Perform centering on the kernel matrix
if options.Npcadim
    Kdet = (eye(N) - 1/N * ones(N)) * Kdet * (eye(N) - 1/N * ones(N));
end
% Additive kernels
if strcmp(kernel_type,'chi2') || strcmp(kernel_type,'intersection')
    Napp = size(z_omega_x,2);
    Kbasic = full(z_omega_x * z_omega_y');
    deltaK = Kdet - Kbasic;
      max_norm = max(max(abs(deltaK)));
      mean_norm = mean(mean(abs(deltaK)));
       disp(['Mean norm : ' num2str(mean_norm)]);
       disp(['Max norm : ' num2str(max_norm)]);
else
    for i=1:obj.final_dim
    Kbasic = Kbasic + z_omega_x(:,i) * z_omega_y(:,i)';
    if strcmp(kernel_type,'chi2') || strcmp(kernel_type,'intersection')
        deltaK = Kdet - Kbasic;
    else
        deltaK = i * Kdet - Kbasic;
    end
  
    if strcmp(kernel_type, 'chi2') || strcmp(kernel_type,'intersection')
      max_norm(i) = max(max(abs(deltaK)));
      mean_norm(i) = mean(mean(abs(deltaK)));
    else
      max_norm(i) = max(max(abs(deltaK)))/i;
      mean_norm(i) = mean(mean(abs(deltaK)))/i;
    end

    if mod(i, 100) == 0
        disp(['Computed  ' num2str(i/obj.final_dim) ' | Mean norm : ' num2str(mean_norm(i))]);
    end
    end
end

% compare
save([kernel_type '_dim_' int2str(obj.dim) '_' options.approx '_results_new.mat'], 'x','y','Kdet','z_omega_x','z_omega_y','max_norm','mean_norm');
if ~strcmp(kernel_type,'chi2') && ~strcmp(kernel_type,'intersection')
    Napp = obj.final_dim;
monte_carlo_rate = 1 ./ sqrt(1:Napp); %hold on; plot(monte_carlo_rate);
figure;plot(1:Napp,max_norm(1:Napp),'r-',1:Napp,mean_norm(1:Napp),'b-',1:Napp, monte_carlo_rate(1:Napp),'g-');
%figure;plot(1:Napp,max_norm(1:Napp),'r-',1:Napp,mean_norm(1:Napp),'b-',1:Napp, monte_carlo_rate(1:Napp),'g-');
set(gca,'yscale','log'); h = legend('Max Norm', 'Mean Norm', 'Monte Carlo rate'); set(h, 'location','best', 'fontsize', 16);
title('Error on approximating the kernel matrix');
xlabel('Number of Random Feature Dimensions');
ylabel('Approximation Error');
set(gca,'XTick', [0:500:Napp]);
set(findall(gcf,'-property','FontSize'),'FontSize',25);
set(findall(gcf,'-property','LineWidth'),'LineWidth',4);
set(gca,'YScale','log');
set(gcf,'Units','normalized','Position',[0.2 0.2 0.8 0.8]);
set(gcf,'PaperPositionMode','auto');
% legend({'max(|K - K_0|) (Multiplicative)','mean(|K - K_0|) (Multiplicative)','Monte Carlo Convergence Rate O(m^{-1/2})',...
%     'max(|K - K_0|) (Additive [11])', 'mean(|K - K_0|) (Additive [11])'},'Location','NorthEast','FontSize',25);
end
end