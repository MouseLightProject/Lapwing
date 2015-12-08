classdef Video_file < handle

  properties
    ext;  % the file type extension, e.g. '.tif', '.mj2'
    file;  % the file-type specific file object
    bits_per_pel;  % number of bits per pixel
    n_row;
    n_col;
    n_frame;
    rate;  % Hz, sampling rate
    i_frame;  % last frame read, 1-based index
    original_libtiff_warning_state  % used to restore libtiff warning state after we close a tiff file
  end  % properties

  properties (Dependent=true)
    dt;  % s, 1/rate
  end  % properties
  
  methods
    function self=Video_file(file_name)
      [~,~,self.ext]=fileparts(file_name);
      switch self.ext
        case '.tif'
          info=imfinfo(file_name);
          self.n_frame=length(info);
          self.original_libtiff_warning_state = warning('query', 'MATLAB:imagesci:tiffmexutils:libtiffWarning') ;
          warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
          self.file=Tiff(file_name,'r');
          frame=self.file.read();
          if ndims(frame)>2  %#ok
            error('Video_file:UnsupportedPixelType', ...
                  'Video_file only supports 8- and 16-bit grayscale videos.');
          end
          if isa(frame,'uint8')
            self.bits_per_pel=8;
          elseif isa(frame,'uint16')
            self.bits_per_pel=16;
          else
            error('Video_file:UnsupportedPixelType', ...
                  'Video_file only supports 8- and 16-bit grayscale videos.');
          end
          [self.n_row,self.n_col]=size(frame);
          self.file.close();
          self.file=Tiff(file_name,'r');
          self.rate=NaN;  % Hz, NaN signifies frame rate is unknown
          self.i_frame=0;
        case '.mj2'
          self.file=VideoReader(file_name);
          self.bits_per_pel=get(self.file,'BitsPerPixel');
          if self.bits_per_pel~=8 && self.bits_per_pel~=16
            error('Video_file:UnsupportedPixelType', ...
                  'Video_file only supports 8- and 16-bit grayscale videos.');
          end          
          self.n_row=get(self.file,'Width');
          self.n_col=get(self.file,'Height');
          self.n_frame=get(self.file,'NumberOfFrames');
          self.rate=get(self.file,'FrameRate');
          self.i_frame=0;
        otherwise
          error('Video_file:UnableToLoad','Unable to load that file type');
      end
    end  % constructor method

    function dt=get.dt(self)
      if isempty(self.rate)
        dt=[];
      else
        dt=1/self.rate;
      end
    end
    
    function frame=get_frame(self,i)
      switch self.ext
        case '.tif'
          self.file.setDirectory(i);
          frame=self.file.read();
        case '.mj2'
          frame=self.file.read(i);
        otherwise
          error('Video_file:InternalError','Internal error');
      end          
      self.i_frame=i;
    end
    
    function frame=get_next(self)
      switch self.ext
        case '.tif'
          frame=self.file.read();
        case '.mj2'
          frame=self.file.read(self.i_frame+1);
        otherwise
          error('Video_file:InternalError','Internal error');
      end          
      self.i_frame=self.i_frame+1;
    end
    
    function frame=get_prev(self)
      frame=self.get_frame(self.i_frame);
    end
    
    function pred=at_end(self)
      pred=(self.i_frame==self.n_frame);
    end
    
    function pred=at_start(self)
      pred=(self.i_frame==0);
    end

    function to_start(self)
      self.i_frame=0;
    end
    
    function close(self)
      if ~isempty(self.file)
        switch self.ext
          case '.tif'
            self.file.close();
            warning(self.original_libtiff_warning_state);
          case '.mj2'
          otherwise
            error('Video_file:InternalError','Internal error');
        end
      end
    end
    
    function delete(self)
      self.close();
    end
  end  % methods

end  % classdef
