function [metrics2d, metricsInfo2d, metrics3d, metricsInfo3d]=evaluateCVML(resFile, gtFile)
% read a results file, a ground truth file, and a camera calibration file
% in xml format, evaluate in 2D and 3D and print metrics

% (C) Anton Milan, 2012-2013

camFile = '3rd_party/Anton_evaluation/data/PETS2009-calib.xml';
sceneInfo.camPar=parseCameraParameters(camFile);

stateInfo=parseCVML(resFile);
[stateInfo.Xgp, stateInfo.Ygp]=projectToGroundPlane(stateInfo.X, stateInfo.Y, sceneInfo);
stateInfo.Xi=stateInfo.X; stateInfo.Yi=stateInfo.Y;

gtInfo=parseCVML(gtFile);
[gtInfo.Xgp, gtInfo.Ygp]=projectToGroundPlane(gtInfo.X, gtInfo.Y, sceneInfo);
gtInfo.Xi=gtInfo.X; gtInfo.Yi=gtInfo.Y;

%%
fprintf('\nEvaluation 2D:\n');
[metrics2d, metricsInfo2d, addInfo2d]=CLEAR_MOT(gtInfo,stateInfo);
printMetrics(metrics2d,metricsInfo2d,1);

fprintf('\nEvaluation 3D:\n');
evopt.eval3d=1;
[metrics3d, metricsInfo3d, addInfo3d]=CLEAR_MOT(gtInfo,stateInfo,evopt);
printMetrics(metrics3d,metricsInfo3d,1);
end