function export_to_tcs_file(self,file_name_abs)

% could take a while
self.hourglass();

try
  self.model.export_to_tcs_file(file_name_abs);
catch excp
  self.unhourglass();
  uiwait(errordlg(excp.message,'Error','modal'));
  %rethrow(excp);
  return
end

% back to usual pointer
self.unhourglass();
                      
end
