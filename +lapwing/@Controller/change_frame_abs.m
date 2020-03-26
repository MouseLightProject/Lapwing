function change_frame_abs(self, new_z_index)

% Change the current frame to the given frame index.

n_frames=self.model.n_frames;
if (new_z_index>=1) && (new_z_index<=n_frames)
  self.z_index=new_z_index;
  set(self.z_index_edit_h,'String',sprintf('%d',new_z_index));
  set(self.image_h,'CData',self.indexed_frame);
  %self.sync_overlay();
end

end
