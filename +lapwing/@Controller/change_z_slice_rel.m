function change_z_slice_rel(self,di)

% Change the current z_slice by di.

z_index_new=self.z_index+di;
self.change_z_slice_abs(z_index_new);

end
