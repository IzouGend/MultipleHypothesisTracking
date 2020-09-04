function plot_histo_distrib()
VOCpath = '/home/catalin/share/VOC2009/VOC2009/MyFilteredSegments/SegmenterLongRangeSegmenter/';

filename = {'bow_dense_sift_4_scales_figure_300__train_initial_back_sqrt_logtest_90','bow_dense_sift_4_scales_ground_300__train_initial_back_sqrt_logtest_90',...
  'bow_dense_color_sift_3_scales_figure_300__train_initial_back_sqrt_logtest_90', 'bow_dense_color_sift_3_scales_ground_300__train_initial_back_sqrt_logtest_90'};
% filename = {'mask_phog_scale_inv_10_orientations_3_levels__train_initial_back_sqrt_logtest_90', ...
%      'mask_phog_scale_inv_20_orientations_2_levels__train_initial_back_sqrt_logtest_90',...
%      'back_mask_phog_nopb_20_orientations_3_levels__train_initial_back_sqrt_logtest_90'};
figure; hold on;


for i = 1: length(filename)
  load([VOCpath filename{i}]);
  [h(:,i) x] = hist(Feats(:), (0:.05:1),'linewidth',4);
end

bar(x, h);
set(gca,'yscale','log','fontsize',20); xlim([-0.02 1.02]);
h = legend('BoW dense SIFT 4 scales figure','BoW dense SIFT 4 scales ground','BoW dense SIFT 3 scales figure','BoW dense SIFT 3 scales ground');
% h = legend('pHoG 1','pHoG 2', 'pHoG 3');
set(h,'location','best', 'fontsize',20);
% load('back_mask_phog_nopb_20_orientations_3_levels__train_initial_back_sqrt_logtest_90');
set(gca,'linewidth',4);
end