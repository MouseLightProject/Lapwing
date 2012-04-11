function all_new_rois(self)

% Updates the view to reflect the ROIs currently in the model.

% Get the labels and borders from the model.
labels={self.model.roi.label};
borders={self.model.roi.border};

% clear the old roi borders & labels
if self.border_roi_h  % if nonempty
  delete(self.border_roi_h);
  delete(self.label_roi_h);
end

% generate graphics objects for the new ROIs
n_rois=length(labels);
label_h=zeros(n_rois,1);
border_h=zeros(n_rois,1);
for j=1:n_rois
  border_this=borders{j};
  com=roving.border_com(border_this);
  label_h(j)=...
    text('Parent',self.image_axes_h,...
         'Position',[com(1) com(2) 1],...
         'String',labels{j},...
         'HorizontalAlignment','center',...
         'VerticalAlignment','middle',...
         'Color',[0 0 1],...
         'Tag','label_h',...
         'Clipping','on',...
         'ButtonDownFcn',@(~,~)(self.handle_image_mousing()) );
  border_h(j)=...
    line('Parent',self.image_axes_h,...
         'Color',[0 0 1],...
         'Tag','border_h',...
         'XData',border_this(1,:),...
         'YData',border_this(2,:),...
         'ZData',ones([1 size(border_this,2)]),...
         'ButtonDownFcn',@(~,~)(self.handle_image_mousing()) );
end
   
% write the new ROI into the figure state
self.selected_roi_index=zeros(0,1);
self.border_roi_h=border_h;
self.label_roi_h=label_h;

% no ROI is selected, so disable some menus
set(self.delete_roi_menu_h,'Enable','off');
set(self.rename_roi_menu_h,'Enable','off');

% modify ancillary crap
if n_rois>0
  % need to set image erase mode to normal, since now there's something
  % other than the image in that image axes
  set(self.image_h,'EraseMode','normal');
  set(self.delete_all_rois_menu_h,'Enable','on');
  set(self.save_rois_to_file_menu_h,'Enable','on');
  set(self.hide_rois_menu_h,'Enable','on');
  self.set_hide_rois(false);
  set(self.select_button_h,'Enable','on');
  set(self.move_all_button_h,'Enable','on');
  set(self.export_to_tcs_menu_h,'Enable','on');
end  

end