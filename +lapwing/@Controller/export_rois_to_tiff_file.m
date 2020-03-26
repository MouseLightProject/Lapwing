function export_rois_to_tiff_file(self, file_name_abs)

% could take a while
self.hourglass();

try
  self.model.export_rois_to_tiff_file(file_name_abs);
catch excp
  self.unhourglass();
  uiwait(errordlg(excp.message,'Error','modal'));
  %rethrow(excp);
  return
end

% back to usual pointer
self.unhourglass();
                      
end
