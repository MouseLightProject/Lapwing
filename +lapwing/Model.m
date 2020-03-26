classdef Model < handle
    
    properties (Access = private)
        cmap_name_
        cmap_
        %fps_
    end
    
    properties
        stop_button_hit
        z_index
    end
    
    properties (SetAccess = private)
        t0
        dt
        file_name  % the name of the video file currently open
        file  % the handle of a VideoFile object, the current file (or empty)
        
        % this holds the _playback_ z_slice rate, in z_slices/sec
        % this is the current selection mode
        mode
        % colorbar_min and colorbar_max are constrained to be integers
        colorbar_max_string
        colorbar_min_string
        colorbar_min  % the colorbar min, derived from cb_min_string,
        % dependent in spirit
        colorbar_max  % the colorbar max, derived from cb_min_string,        
    end  % properties
    
    properties (Dependent=true)
        fs  % Hz, sampling rate for playback & export, possibly different from
        % that in file
        n_rows
        n_cols
        z_slice_count  % number of time samples
        tl  % 2x1 matrix holding min, max time
        %n_rois;
        t  % a complete timeline for all z_slices
        is_a_file_open  % true iff a stack is currently open
        z_slice
        indexed_z_slice
        cmap_name
        cmap
    end
    
    methods
        function self=Model()
            self.file_name='';
            self.file=[];
            self.t0=[];  % s
            self.dt=[];  % s
            %       self.roi=struct('border',cell(0,1), ...
            %                       'label',cell(0,1));
            %self.overlay_file=[];
            
            % Set up the view state variables
            self.z_index=[] ;
            %self.fps_ = 20 ;  % for playback
            % this holds the _playback_ z_slice rate, in z_slices/sec
            % this is the current selection mode
            %self.mode='elliptic_roi';
            self.cmap_name = 'gray' ; 
            
            colorbar_min_string='0';
            colorbar_max_string='255';
            colorbar_min=str2double(colorbar_min_string);
            colorbar_max=str2double(colorbar_max_string);
            
            self.colorbar_max_string=colorbar_max_string;
            self.colorbar_min_string=colorbar_min_string;
            self.colorbar_max=colorbar_max;
            self.colorbar_min=colorbar_min;            
            
            self.mode = 'zoom' ;
            self.stop_button_hit = false ;
        end  % function
        
        function delete(self)
            if ~isempty(self.file) ,
                self.file = [] ;  % should close file handles
            end
        end            
        
        function t=get.t(self)
            if ~isempty(self.t0) && ~isempty(self.dt) && ~isempty(self.z_slice_count)
                t=self.t0+self.dt*(0:(self.z_slice_count-1))';
            else
                t=[];
            end
        end
        
        
        function fs=get.fs(self)
            if isempty(self.dt)
                fs=[];
            else
                fs=1/self.dt;
            end
        end
        
        
        function n_row=get.n_rows(self)
            if isempty(self.file)
                n_row=[];
            else
                n_row=self.file.n_row;
            end
        end
        
        
        function n_col=get.n_cols(self)
            if isempty(self.file)
                n_col=[];
            else
                n_col=self.file.n_col;
            end
        end
        
        
        function z_slice_count = get.z_slice_count(self)
            if isempty(self.file) ,
                z_slice_count = [] ;
            else
                z_slice_count = self.file.n_frame ;
            end
        end
        
        %     
        %     function n_roi=get.n_rois(self)
        %       n_roi=length(self.roi);
        %     end
        
        
        function tl=get.tl(self)
            t0=self.t0;
            dt=self.dt;
            if ~isempty(self.t0) && ~isempty(self.dt)
                n_z_slice=self.z_slice_count;
                if isempty(n_z_slice) || (n_z_slice==0) ,
                    tl=[];
                else
                    tl=t0+[0 dt*(n_z_slice-1)];
                end
            else
                tl=[];
            end
        end
        
        
        function set.dt(self,dt)
            self.dt=dt;
        end
        
        %     function sync_t(self)
        %       t0=self.t0;
        %       dt=self.dt;
        %       n_z_slice=self.z_slice_count;
        %       self.t=t0+dt*(0:(n_z_slice-1))';
        %     end
        
        
        function set.fs(self,fs)
            self.dt=1/fs;
        end       
        
        
%         function z_slice = get_z_slice(self, i)
%             z_slice=self.file.get_frame(i);
%         end
        
        %     
        %     function z_slice_overlay=get_z_slice_overlay(self,i)
        %       if (1<=i) && (i<=self.overlay_file.z_slice_count)
        %         z_slice_overlay=self.overlay_file.read_z_slice_overlay(i);
        %       else
        %         z_slice_overlay=cell(0,1);  % just return empty overlay
        %       end
        %     end
        
        %   Since we now are keeping the movie on-disk, mutating it becomes
        %   more problematical...
        %     function motion_correct(self)
        %       border=2;  % border to ignore, seems to help with nans and such at the
        %                  % edge of the z_slices
        %       % find the translation for each z_slice
        %       options=optimset('maxfunevals',1000);
        %       z_slice_count=self.z_slice_count;
        %       self.file.to_start();
        %       if z_slice_count>0
        %         z_slice_first=double(self.file.get_next());
        %       end
        %       b_per_z_slice=zeros(2,z_slice_count);
        %       for k=2:z_slice_count
        %         z_slice_this=double(self.file.get_next());
        %         b_per_z_slice(:,k)=...
        %           find_translation(z_slice_first, ...
        %                            z_slice_this, ...
        %                            border,...
        %                            b_per_z_slice(:,k-1),...
        %                            options);
        %       end
        %       % register each z_slice using the above-determined translation
        %       for k=2:z_slice_count
        %         % implicit conversion to the type of self.data
        %         self.data(:,:,k)=register_z_slice(double(self.data(:,:,k)), ...
        %                                         eye(2), ...
        %                                         b_per_z_slice(:,k));
        %       end
        %     end  % motion_correct
        
        
%         function [d_min, d_max] = min_max(self, i)
%             % get the max and min values of z_slice i
%             % d_min and d_max are doubles, regardless the type of self.data
%             z_slice = double(self.get_z_slice(i)) ;
%             d_min = min(min(z_slice)) ;
%             d_max = max(max(z_slice)) ;
%         end  % data_bounds
        
        %     function [h,t]=hist(self,i,n_bins)
        %       % construct a histogram of the data values in z_slice i
        %       z_slice=double(self.get_z_slice(i));
        %       [h,t]=hist(z_slice(:),n_bins);
        %     end
        
        %     function [h,t]=hist_abs(self,i,n_bins)
        %       z_slice=double(self.get_z_slice(i));
        %       z_slice=abs(z_slice);
        %       [h,t]=hist(z_slice(:),n_bins);
        %     end
        
        
        
        
        
        function open_file_given_file_name(self,file_name)
            % filename is a filename, can be relative or absolute
            
            % break up the file name
            %[~,base_name,ext]=fileparts(filename);
            %filename_local=[base_name ext];
            
            % load the optical data
            file=lapwing.Video_file(file_name);
            
            % OK, now actually store the data in ourselves
            % make up a t0, get dt
            self.t0=0;
            self.dt=file.dt;  % s
            
            % set the model
            self.file=file;
            self.file_name=file_name;
            
            % determine the colorbar bounds
            [data_min,data_max]=self.pixel_data_type_min_max();
            self.colorbar_min_string=sprintf('%d',data_min);
            self.colorbar_max_string=sprintf('%d',data_max);
            self.colorbar_min=str2double(self.colorbar_min_string);
            self.colorbar_max=str2double(self.colorbar_max_string);

            % reset the z_slice index
            self.z_index=1;

            % init roi state
            %self.selected_roi_index=zeros(0,1);
            %self.hide_rois=false;
            
            % set the mode to zoom
            self.mode = 'zoom' ;                        
        end  % method
        
        
        function close_file(self)
            if ~isempty(self.file)
                %self.file.close();
                self.file=[];  % should close file handles
            end
            self.file_name='';
            self.t0=[];
            self.dt=[];  % s
            %       self.roi=struct('border',cell(0,1), ...
            %                       'label',cell(0,1));
            %       if ~isempty(self.overlay_file)
            %         self.overlay_file.close();
            %         self.overlay_file=[];
            %       end
        end  % method
        
        
        function result = get.is_a_file_open(self)
            result=~isempty(self.file);
        end  % method

        function result = get.z_slice(self)
            % Get the current indexed_z_slice, based on model, z_index,
            % colorbar_min, and colorbar_max.
            z_index = self.z_index ;
            result = self.file.get_frame(z_index) ;
        end
        
        function indexed_z_slice = get.indexed_z_slice(self)
            % Get the current indexed_z_slice, based on model, z_index,
            % colorbar_min, and colorbar_max.
            z_slice = double(self.z_slice)  ;
            cb_min = self.colorbar_min ;
            cb_max = self.colorbar_max ;
            indexed_z_slice = uint8(round(255*(z_slice-cb_min)/(cb_max-cb_min))) ;
        end
        
        function set_colorbar_bounds_from_strings(self, new_cb_min_string, new_cb_max_string)            
            % Set the view colorbar bounds given max and min values in strings.  No
            % checking is done to make sure the string values are sane.  Note that in
            % the view, although both string and numerical representations of the
            % colorbar bounds are maintained, the string ones are the more fundamental,
            % and the numerical ones are derived from them.  At the moment, this
            % doesn't matter much, since the bounds are constrained to always be
            % integral.  But if we support movies with floating-point pels at some
            % point, this will be important, since the user can explicitly set the
            % bounds, and we want to keep hold of _exactly_ what the user typed.

            % convert to numbers
            new_cb_min = str2double(new_cb_min_string) ;
            new_cb_max = str2double(new_cb_max_string) ;
            
            % if new values are kosher, change colorbar bounds
            if ~isempty(new_cb_min) && ~isempty(new_cb_max) && ...
                    isfinite(new_cb_min) && isfinite(new_cb_max) && ...
                    (new_cb_max>new_cb_min) ,           
                % store the strings
                self.colorbar_min_string = new_cb_min_string ;
                self.colorbar_max_string = new_cb_max_string ;

                % store the numbers
                self.colorbar_min = new_cb_min ;
                self.colorbar_max = new_cb_max ;           
            end
        end

        function set_colorbar_bounds_from_numbers(self, new_cb_min, new_cb_max)            
            % Set the view colorbar bounds given max and min values as numbers.  This
            % calls self.set_colorbar_bounds_from_strings().  It is assumed that cb_min
            % and cb_max are doubles that happen to be integral.
            
            % if new values are kosher, change colorbar bounds
            if ~isempty(new_cb_min) && ~isempty(new_cb_max) && ...
                    isfinite(new_cb_min) && isfinite(new_cb_max) && ...
                    (new_cb_max>new_cb_min) ,           
                % convert to strings
                new_cb_min_string = sprintf('%d',new_cb_min) ;
                new_cb_max_string = sprintf('%d',new_cb_max) ;            

                % store the strings
                self.colorbar_min_string = new_cb_min_string ;
                self.colorbar_max_string = new_cb_max_string ;

                % store the numbers
                self.colorbar_min = new_cb_min ;
                self.colorbar_max = new_cb_max ;           
            end
        end
        
        function result = get.cmap_name(self) 
            result = self.cmap_name_ ;
        end
        
        function set.cmap_name(self, new_cmap_name)
            % set the chosen cmap_name
            self.cmap_name_ = new_cmap_name ;

            % set the colormap
            self.cmap_ = lapwing.cmap_from_name(new_cmap_name) ;
        end        
        
        function result = get.cmap(self) 
            result = self.cmap_ ;
        end
        
        function brighten(self)            
            cmap = self.cmap_ ;
            self.cmap_ = brighten(cmap, 0.1) ;
        end
        
        function revert_gamma(self)
            self.cmap_ = lapwing.cmap_from_name(self.cmap_name) ;
        end
        
        function darken(self)
            cmap = self.cmap_ ;
            self.cmap_ = brighten(cmap, -0.1) ;
        end

        function change_z_slice_abs(self, new_z_index)
            % Change the current z_slice to the given z_slice index
            z_slice_count = self.z_slice_count ;
            if (new_z_index>=1) && (new_z_index<=z_slice_count) ,
                self.z_index = new_z_index ;
            end
        end
        
        function set_colorbar_bounds(self, method, bounds)            
            switch(method)
                case 'pixel_data_type_min_max'
                    [d_min, d_max] = lapwing.pixel_data_type_min_max(self.file.bits_per_pel) ;
                    self.set_colorbar_bounds_from_numbers(d_min,d_max);
                case 'min_max'
                    z_slice = double(self.z_slice) ;
                    d_min = min(min(z_slice)) ;
                    d_max = max(max(z_slice)) ;
                    self.set_colorbar_bounds_from_numbers(d_min,d_max);
                case 'five_95'
                    z_slice=double(self.z_slice);
                    d=lapwing.quantile_mine(z_slice(:),[0.05 0.95]');
                    d_05=d(1);
                    d_95=d(2);
                    d_05=floor(d_05);  % want int, want to span range
                    d_95=ceil(d_95);  % want int, want to span range
                    self.set_colorbar_bounds_from_numbers(d_05,d_95);
                case 'abs_max'
                    z_slice=double(self.z_slice);
                    cb_max=max(max(abs(z_slice)));
                    self.set_colorbar_bounds_from_numbers(-cb_max,+cb_max);
                case 'ninety_symmetric'
                    % need to fix this, since what it does now is useless
                    z_slice=abs(double(self.z_slice));
                    d_90=lapwing.quantile_mine(z_slice(:),0.9);                    
                    cb_max=ceil(d_90);
                    cb_min=-cb_max;
                    self.set_colorbar_bounds_from_numbers(cb_min,cb_max);
                case 'manual'
                    % break out the returned cell array
                    new_cb_max_string=bounds{1};
                    new_cb_min_string=bounds{2};
                    % convert all these strings to real numbers
                    new_cb_min = floor(str2double(new_cb_min_string)) ; 
                    new_cb_max = ceil(str2double(new_cb_max_string)) ;
                    % change colorbar bounds
                    self.set_colorbar_bounds_from_numbers(new_cb_min, new_cb_max) ;
            end
        end  % method
        
    end  % methods
    
end  % classdef
