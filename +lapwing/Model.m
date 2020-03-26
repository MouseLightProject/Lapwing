classdef Model < handle
    
    properties (Access = private)
        cmap_name_
        cmap_
    end
    
    properties
        t0
        dt
        file_name  % the name of the video file currently open
        file  % the handle of a VideoFile object, the current file (or empty)
        
        z_index
        % this holds the _playback_ z_slice rate, in z_slices/sec
        stop_button_hit
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
        a_video_is_open  % true iff a video is currently open
        indexed_z_slice
        cmap_name
        cmap
    end
    
    methods
        % ---------------------------------------------------------------------
        function self=Model()
            self.file_name='';
            self.file=[];
            self.t0=[];  % s
            self.dt=[];  % s
            %       self.roi=struct('border',cell(0,1), ...
            %                       'label',cell(0,1));
            %self.overlay_file=[];
            
            % Set up the view state variables
            self.z_index=[];
            % this holds the _playback_ z_slice rate, in z_slices/sec
            self.stop_button_hit = false ;
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
        end  % function
        
        % ---------------------------------------------------------------------
        function t=get.t(self)
            if ~isempty(self.t0) && ~isempty(self.dt) && ~isempty(self.z_slice_count)
                t=self.t0+self.dt*(0:(self.z_slice_count-1))';
            else
                t=[];
            end
        end
        
        % ---------------------------------------------------------------------
        function fs=get.fs(self)
            if isempty(self.dt)
                fs=[];
            else
                fs=1/self.dt;
            end
        end
        
        % ---------------------------------------------------------------------
        function n_row=get.n_rows(self)
            if isempty(self.file)
                n_row=[];
            else
                n_row=self.file.n_row;
            end
        end
        
        % ---------------------------------------------------------------------
        function n_col=get.n_cols(self)
            if isempty(self.file)
                n_col=[];
            else
                n_col=self.file.n_col;
            end
        end
        
        % ---------------------------------------------------------------------
        function z_slice_count = get.z_slice_count(self)
            if isempty(self.file) ,
                z_slice_count = [] ;
            else
                z_slice_count = self.file.n_frame ;
            end
        end
        
        %     % ---------------------------------------------------------------------
        %     function n_roi=get.n_rois(self)
        %       n_roi=length(self.roi);
        %     end
        
        % ---------------------------------------------------------------------
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
        
        % ---------------------------------------------------------------------
        function set.dt(self,dt)
            self.dt=dt;
        end
        
        %     function sync_t(self)
        %       t0=self.t0;
        %       dt=self.dt;
        %       n_z_slice=self.z_slice_count;
        %       self.t=t0+dt*(0:(n_z_slice-1))';
        %     end
        
        % ---------------------------------------------------------------------
        function set.fs(self,fs)
            self.dt=1/fs;
        end
        
        % ---------------------------------------------------------------------
        function add_roi(self,border,label)
            % border 2 x n_vertex, label a string
            n_roi_old=length(self.roi);
            self.roi(n_roi_old+1).border=border;
            self.roi(n_roi_old+1).label=label;
        end
        
        % ---------------------------------------------------------------------
        function delete_rois(self,i_to_delete)
            keep=true(size(self.roi));
            keep(i_to_delete)=false;
            self.roi=self.roi(keep);
        end
        
        % ---------------------------------------------------------------------
        function set_roi(self,border,label)
            % border, label cell arrays
            n_roi=length(border);
            self.roi=struct('border',cell(n_roi,1), ...
                'label',cell(n_roi,1));
            [self.roi.border]=deal(border{:});
            [self.roi.label]=deal(label{:});
        end
        
        % ---------------------------------------------------------------------
        function in_use=label_in_use(self,label_test)
            labels={self.roi.label};
            in_use=any(strcmp(label_test,labels));
        end
        
        % ---------------------------------------------------------------------
        function z_slice=get_z_slice(self,i)
            z_slice=self.file.get_frame(i);
        end
        
        %     % ---------------------------------------------------------------------
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
        
        % ---------------------------------------------------------------------
        function [d_min,d_max]=min_max(self,i)
            % get the max and min values of z_slice i
            % d_min and d_max are doubles, regardless the type of self.data
            z_slice=double(self.get_z_slice(i));
            d_min=min(min(z_slice));
            d_max=max(max(z_slice));
        end  % data_bounds
        
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
        
        % ---------------------------------------------------------------------
        function [d_05,d_95]=five_95(self,i)
            % d_05 and d_95 are doubles, regardless the type of self.data
            z_slice=double(self.get_z_slice(i));
            d=lapwing.quantile_mine(z_slice(:),[0.05 0.95]');
            d_05=d(1);
            d_95=d(2);
        end  % five_95
        
        % ---------------------------------------------------------------------
        function d_max=max_abs(self,i)
            % d_max is a double, regardless of the type of self.data
            z_slice=double(self.get_z_slice(i));
            d_max=max(max(abs(z_slice)));
        end  % max_abs
        
        % ---------------------------------------------------------------------
        function d_90=abs_90(self,i)
            % d_90 is a double, regardless the type of self.data
            z_slice=abs(double(self.get_z_slice(i)));
            d_90=lapwing.quantile_mine(z_slice(:),0.9);
        end  % five_95
        
        % ---------------------------------------------------------------------
        function [d_min,d_max]=pixel_data_type_min_max(self)
            if self.file.bits_per_pel==8
                d_min=0;
                d_max=255;
            elseif self.file.bits_per_pel==16
                d_min=0;
                d_max=65535;
            else
                % This should not ever happen.
                d_min=0;
                d_max=1;
            end
            
        end
        
        % ---------------------------------------------------------------------
        function open_video_given_file_name(self,file_name)
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
        end  % method
        
        % ---------------------------------------------------------------------
        function close_video(self)
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
        
        % ---------------------------------------------------------------------
        function result=get.a_video_is_open(self)
            result=~isempty(self.file);
        end  % method
        
        function reset_state_for_newly_opened_file(self)
            % Called after a new file has been opened in the model.  Updates the view
            % appropriately, and initializes the view state as appropriate for a newly
            % opened file.

            % Update the view's internal state

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
        end
        
        function indexed_z_slice = get.indexed_z_slice(self)
            % Get the current indexed_z_slice, based on model, z_index,
            % colorbar_min, and colorbar_max.
            z_slice = double(self.get_z_slice(self.z_index))  ;
            cb_min=self.colorbar_min;
            cb_max=self.colorbar_max;
            indexed_z_slice=uint8(round(255*(z_slice-cb_min)/(cb_max-cb_min)));
        end
        
        function set_colorbar_bounds_from_strings(self, cb_min_string, cb_max_string)            
            % Set the view colorbar bounds given max and min values in strings.  No
            % checking is done to make sure the string values are sane.  Note that in
            % the view, although both string and numerical representations of the
            % colorbar bounds are maintained, the string ones are the more fundamental,
            % and the numerical ones are derived from them.  At the moment, this
            % doesn't matter much, since the bounds are constrained to always be
            % integral.  But if we support movies with floating-point pels at some
            % point, this will be important, since the user can explicitly set the
            % bounds, and we want to keep hold of _exactly_ what the user typed.
            
            % change the figure strings
            self.colorbar_min_string=cb_min_string;
            self.colorbar_max_string=cb_max_string;
            
            % change the axes and colorbar
            cb_min=str2double(cb_min_string);
            cb_max=str2double(cb_max_string);
            
            % store the translated vals in self
            self.colorbar_min=cb_min;
            self.colorbar_max=cb_max;            
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

    end  % methods
    
end  % classdef
