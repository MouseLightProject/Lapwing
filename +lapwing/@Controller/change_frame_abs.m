function change_frame_abs(self, new_z_index)

% Change the current frame to the given frame index.

z_slice_count=self.model.z_slice_count;
if (new_z_index>=1) && (new_z_index<=z_slice_count)
  self.z_index=new_z_index;
  set(self.z_index_edit_h,'String',sprintf('%d',new_z_index));
  set(self.image_h,'CData',self.indexed_frame);
  %self.sync_overlay();
end

end
