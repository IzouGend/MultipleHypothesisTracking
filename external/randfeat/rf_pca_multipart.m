function rf_obj = rf_pca_multipart(rf_obj, LinReg_Build, dim)
% rf_pca_multipart: 
% Learn the PCA basis using a built-in LinearRegressor_Data object.
% Usage for loading Input1, Input2, ... and taking a multi-part PCA on all of them:
% LinReg_Build = LinearRegressor_Data(Input1, Target1);
% LinReg_Build = LinReg_Build + LinearRegressor_Data(Input2, Target2);
% ...
% rf_obj = InitExplicitKernel(...);
% rf_obj = rf_pca_multipart(rf_obj, LinReg_Build, dim);
%
% copyright (c) 2010 - 2012
% Fuxin Li - fli@cc.gatech.edu
% Catalin Ionescu - catalin.ionescu@ins.uni-bonn.de
% Cristian Sminchisescu - cristian.sminchisescu@ins.uni-bonn.de
    if ~strcmp(class(LinReg_Build), 'LinearRegressor_Data')
        error('LinReg_Build must be of class LinearRegressor_Data');
    end
    [rf_obj.pca_basis, rf_obj.pca_mean] = LinReg_Build.PCA(dim);
    rf_obj.final_dim = dim;
    rf_obj.pca_mean = rf_obj.pca_mean';
end
