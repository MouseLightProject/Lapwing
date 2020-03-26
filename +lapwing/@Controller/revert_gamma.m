function revert_gamma(self)

cmap_name=self.cmap_name;
if strcmp(cmap_name,'red_green') ,
  % feval doesn't work with imported functions?
  cmap=lapwing.red_green(256);
elseif strcmp(cmap_name,'red_blue') ,
  % feval doesn't work with imported functions?
  cmap=lapwing.red_blue(256);
elseif strcmp(cmap_name,'parula') && verLessThan('matlab','8.4') ,
  cmap = jet(256) ;  % no parula colormap in early versions  
else
  cmap=feval(cmap_name,256);
end
set(self.figure_h,'colormap',cmap);

end
