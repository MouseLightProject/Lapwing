function x=roi_signals(t_o,optical,rois)

% t_o should be a col vector w/ (number of frames) elements
% optical should be a 3d array of shape [n_rows,n_cols,(number of frames)]
% rois should be of dim [n_rois,4] or [n_rows n_cols n_rois]

% analyze each of the rois
if isempty(t_o)||isempty(optical)
  n_rois=0;
  roi_dff=[];
else
  n_rows=size(optical,1);
  n_cols=size(optical,2);
  z_slice_count=size(optical,3);
  ts=(t_o(z_slice_count)-t_o(1))/(z_slice_count-1);
  n_rois=size(rois,3);
  n_ppf=n_rows*n_cols;
  optical=reshape(optical,[n_ppf z_slice_count]);
  rois=reshape(rois,[n_ppf n_rois]);
  x=zeros(z_slice_count,n_rois);
  for j=1:n_rois
    this_roi=rois(:,j);
    x(:,j)=mean(double(optical(logical(this_roi),:)),1)';
  end  
end

