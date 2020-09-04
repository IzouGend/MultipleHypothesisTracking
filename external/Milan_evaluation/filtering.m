vid_name = 'PETS2009';
mat_files = dir(['./' vid_name '/track/' '*.mat']);

for i = 1:length(mat_files)

load(['./' vid_name '/track/' mat_files(i).name]);


T_num = 2;
T_mov = 0.0100;
ct = 0;
for j = 1:max(dres_dp_final.id)
   idx1 = (dres_dp_final.id == j);
   idx2 = (dres_dp_final.det_type == -1);
   idx = idx1&idx2;
   
   if sum(idx) < T_num  
       continue;
   end
   
   cs1 = sum(abs(diff(dres_dp_final.x(idx))))/length(idx);
   cs2 = sum(abs(diff(dres_dp_final.y(idx))))/length(idx);
   
   if cs1 + cs2 < T_mov 
       ct = ct+1
          dres_dp_final.x(idx1) = [];
   dres_dp_final.y(idx1) = [];
   dres_dp_final.w(idx1) = [];
   dres_dp_final.h(idx1) = [];
   dres_dp_final.r(idx1) = [];
   dres_dp_final.fr(idx1) = [];
   dres_dp_final.id(idx1) = [];
   dres_dp_final.det_type(idx1) = [];
   end        
   
  
end
    
    save (['./' vid_name '/track_filtered/' mat_files(i).name],'dres_dp_final');

end