% copyright (c) 2010 
% Fuxin Li - fuxin.li@ins.uni-bonn.de
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de

% Classification DEMO with linear approximation to different kernels

addpath('./liblinear')
load phog_features;
%disp('Training model with linear kernel.');
% svmmodel = svmlin_train(double(Labels(1:1601)'), sparse(double(Feats(1:1601,:))),'-q -c 25');
% [pred, accuracy] = svmlin_predict(double(Labels(1602:3202)'), sparse(double(Feats(1602:3202,:))), svmmodel);


% disp('Training model with the original LIBSVM on the chi-square kernel.')
%     if ~exist('K','var') || isempty(K)
%         K = chi_square_kernel(double(Feats(1:1601,:)),sparse(double(Feats(1:1601,:))), 1.5);
%     end
%     K1 = [(1:1601)' K];
%     svmmodel = libsvm_train(double(Labels(1:1601))',double(K1),'-t 4 -c 25');
%     K = chi_square_kernel(double(Feats(1:1601,:)),sparse(double(Feats(1602:3202,:))), 1.5);
%     K2 = [(1:1601)' K];
%     [pred,accuracy] = libsvm_predict(double(Labels(1602:3202))', K2, svmmodel);
%     
% disp('Training model with random Fourier features on additive chi-square kernel.');
% kobj = InitExplicitKernel('chi2',[], size(Feats,2), 5,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% 
% svmmodel = svmlin_train(double(Labels(1:1601)'), sparse(z_omega(1:1601,:)),'-q -c 25');
% [pred, accuracy] = svmlin_predict(double(Labels(1602:3202)'), sparse(z_omega(1602:3202,:)), svmmodel);
% 
% disp('Training model with random Fourier features on Gaussian kernel.')
% kobj = InitExplicitKernel('rbf',10, size(Feats,2), 1500,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% svmmodel = svmlin_train(double(Labels(1:1601)'), sparse(z_omega(1:1601,:)),'-q -c 25');
% [pred, accuracy] = svmlin_predict(double(Labels(1602:3202)'), sparse(z_omega(1602:3202,:)), svmmodel);
% 
% disp('Training model with random Fourier features on Laplacian kernel.')
% kobj = InitExplicitKernel('laplace',1, size(Feats,2), 1500,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% svmmodel = svmlin_train(double(Labels(1:1601)'), sparse(z_omega(1:1601,:)),'-q -c 25');
% [pred, accuracy] = svmlin_predict(double(Labels(1602:3202)'), sparse(z_omega(1602:3202,:)), svmmodel);
% 
% disp('Training model with random Fourier features on skewed chi-square kernel.')
% kobj = InitExplicitKernel('chi2_skewed',0.03, size(Feats,2), 1500,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% svmmodel = svmlin_train(double(Labels(1:1601)'), sparse(z_omega(1:1601,:)),'-q -c 25');
% [pred, accuracy] = svmlin_predict(double(Labels(1602:3202)'), sparse(z_omega(1602:3202,:)), svmmodel);

% disp('Training model with random Fourier features on skewed intersection kernel.')
% kobj = InitExplicitKernel('intersection_skewed',0.02, size(Feats,2), 1500,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% svmmodel = libsvm_train(double(Labels(1:1601)'), z_omega(1:1601,:),'-t 0 -c 25');
% [pred, accuracy] = libsvm_predict(double(Labels(1602:3202)'), z_omega(1602:3202,:), svmmodel);
% 
% disp('Training model with random Fourier features on exp-hellinger kernel.')
% kobj = InitExplicitKernel('exp_hel',1.5, size(Feats,2), 5000,[]);
% z_omega = rf_featurize(kobj, double(Feats));
% svmmodel = libsvm_train(double(Labels(1:1601)'), z_omega(1:1601,:),'-q -c 25');
% [pred, accuracy] = libsvm_predict(double(Labels(1602:3202)'), z_omega(1602:3202,:), svmmodel);


% disp('Training model with random Fourier features on Gaussian chi-square kernel on Chebyshev.')
% opt.Nperdim = 6;
% opt.Npcadim = 3000;
% %RandStream.setDefaultStream(RandStream('mt19937ar', 'Seed', 5489));
% opt.method = 'chebyshev';
% kobj = InitExplicitKernel('exp_chi2',1.5, size(Feats,2), 8000,opt);
% 
% means = mean(Feats);
% means2 = mean(Feats.^2);
% 
% D = dirichlet_sample({means}, {means2}, 10000, size(Feats,2))';
% [z1, kobj] = rf_pca_featurize(kobj,double(D), true, opt.Npcadim);
% z_omega = rf_pca_featurize(kobj, double(Feats), false);
% %z_omega = rf_pca_featurize(kobj, double(Feats),true,opt.Npcadim);
% %z_omega = rf_featurize(kobj,double(Feats));
% for i=1:20
%     svmmodel = libsvm_train(double(Labels(1:1601)'), z_omega(1:1601,1:i*100),'-t 0 -c 25');
%     [pred, accuracy] = libsvm_predict(double(Labels(1602:3202)'), z_omega(1602:3202,1:i*100), svmmodel);
% end
%svmmodel = libsvm_train(double(Labels(1:1601)'), z_omega(1:1601,:),'-q -c 25');
%[pred, accuracy] = libsvm_predict(double(Labels(1602:3202)'), z_omega(1602:3202,:), svmmodel);

% disp('Training model with random Fourier features on Gaussian chi-square kernel on Vedaldi.')
% opt.Nperdim = n-1;
% opt.method = 'signals';
% kobj2 = InitExplicitKernel('exp_chi2',1.5, size(Feats,2), 3000,opt);
% kobj2.omega2 = kobj.omega2;
% z_omega = rf_featurize(kobj2, double(Feats));
% svmmodel = libsvm_train(double(Labels(1:1601)'), z_omega(1:1601,:),'-q -c 25');
% [pred, accuracy] = libsvm_predict(double(Labels(1602:3202)'), z_omega(1602:3202,:), svmmodel);
% clear kobj;