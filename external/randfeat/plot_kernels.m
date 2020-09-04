function plot_kernels(x, y, c)
% for chi2^3  : c = .13
figure;
if ~exist('c','var')
  c = 0.03;
end
gamma = 1.5;
p = 3;
if ~exist('y','var')
  y = .5;
end
plot(x, EvalKernel(single(y),single(x),'chi2_skewed', c),'linewidth',4); hold on;
plot(x, 1-(y*ones(1,length(x)) + x' -2*EvalKernel(single(y),single(x),'chi2')),'color','r','linewidth',4);
% plot(x, exp(-gamma * (1-EvalKernel(single(y),single(x),'chi2_skewed', c))),'color','b','linestyle','--');
plot(x, exp(-gamma * (y*ones(1,length(x)) + x' -2*EvalKernel(single(y),single(x),'chi2'))),'color','r','linestyle','--','linewidth',4);
plot(x, EvalKernel(single(y),single(x),'chi2_skewed', c).^p,'color','k','linewidth',4);

h = legend('\chi^2_{skewed}', '1-\chi^2', 'e^{-\gamma(1-\chi^2)}','[\chi^2_{skewed}]^3'); set(h,'location','best','fontsize',20); % 'e^{-\gamma\chi^2_{skewed}}',
set(gca,'fontsize',20,'linewidth',4); ylim([0 1]);

end