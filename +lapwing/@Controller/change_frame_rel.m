function change_frame_rel(self,di)

% Change the current frame by di.

z_index_new=self.z_index+di;
self.change_frame_abs(z_index_new);

end
