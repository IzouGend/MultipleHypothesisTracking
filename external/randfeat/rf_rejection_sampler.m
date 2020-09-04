function X = rf_rejection_sampler(obj, N)
%rf_rejection_sampler 
% - pdfp is the end distribution from which we want to sample
% - N is the number of samples
% - M is the rejection parameter
% - invcdfq is the inverse pdf of q (used for sampling from q)
% - pdfq is the pdf of q
%
% CAVEAT : The pdfs and invcdf are one dimensional so this only works if the
% distribution across dimensions are uncorrelated.

pdfp = obj.pdfp;
M = obj.M;
invcdfq = obj.invcdfq;
pdfq = obj.pdfq;

maxIt = obj.maxIt;
counter = 1;
X = [];
k = obj.k; 
nacc = 0;


tic;
while counter < maxIt && nacc <= N*obj.dim
  % sample from q
  qpts = qsample(invcdfq, obj.dim, k);

  % sample from u
  u = rand(size(qpts,1),1);

  % accept/reject
  scores =  pdfp(qpts) ./ (pdfq(qpts)*M) ;
  accept = scores > u;
  
  X = [X qpts(accept)];
  nacc = numel(X);  
  counter = counter + 1;
end

if nacc < N*obj.dim
  warning('Less samples than demanded! ');
end

disp(['Accepted samples : ' num2str(nacc)]);
disp(['Rejected samples : ' num2str(counter*obj.k*obj.dim - nacc)]);
disp(['Sampling time :    ' num2str(toc)]);


% deliver exactly as many samples as needed
nacc = nacc - mod(nacc, obj.dim);
X = reshape(X(1:(min(N*obj.dim, nacc))),obj.dim,min(N*obj.dim, nacc)/obj.dim);

if obj.debug
  
  figure;
  hold on;
  histnorm(X(1,:),50);
  plot([min(min(X,X)):(max(max(X,X))-min(min(X,X)))/100:max(max(X,X))],pdfp([min(min(X,X)):(max(max(X,X))-min(min(X,X)))/100:max(max(X,X))]),'Color','k');
  plot([min(min(X,X)):(max(max(X,X))-min(min(X,X)))/100:max(max(X,X))],M*pdfq([min(min(X,X)):(max(max(X,X))-min(min(X,X)))/100:max(max(X,X))]), 'color','r');
  legend('Empirical','Target','Proposal');
  
end

end


function X = qsample(invcdfq, dim, k)
% samples k points from a distribution given its invpdf
u = rand(k, dim);
X = invcdfq(u);
end