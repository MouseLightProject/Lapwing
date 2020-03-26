function change_z_slice_abs(self, new_z_index)
    % Change the current z_slice to the given z_slice index.
    
    z_slice_count = self.model.z_slice_count ;
    if (new_z_index>=1) && (new_z_index<=z_slice_count) ,
        self.model.z_index = new_z_index ;
        set(self.z_index_edit_h, 'String', sprintf('%d',new_z_index)) ;
        set(self.image_h, 'CData', self.model.indexed_z_slice) ;
    end
end
