classdef Model < handle
    
    properties
        t0
        dt
        file_name  % the name of the video file currently open
        file  % the handle of a VideoFile object, the current file (or empty)
    end  % properties
    
    properties (Dependent=true)
        fs;  % Hz, sampling rate for playback & export, possibly different from
        % that in file
        n_rows;
        n_cols;
        z_slice_count;  % number of time samples
        tl;  % 2x1 matrix holding min, max time
        %n_rois;
        t;  % a complete timeline for all frames
        a_video_is_open;  % true iff a video is currently open
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
        function n_frame=get.z_slice_count(self)
            if isempty(self.file)
                n_frame=[];
            else
                n_frame=self.file.n_frame;
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
                n_frame=self.z_slice_count;
                if isempty(n_frame) || (n_frame==0) ,
                    tl=[];
                else
                    tl=t0+[0 dt*(n_frame-1)];
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
        %       n_frame=self.z_slice_count;
        %       self.t=t0+dt*(0:(n_frame-1))';
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
        function frame=get_frame(self,i)
            frame=self.file.get_frame(i);
        end
        
        %     % ---------------------------------------------------------------------
        %     function frame_overlay=get_frame_overlay(self,i)
        %       if (1<=i) && (i<=self.overlay_file.z_slice_count)
        %         frame_overlay=self.overlay_file.read_frame_overlay(i);
        %       else
        %         frame_overlay=cell(0,1);  % just return empty overlay
        %       end
        %     end
        
        %   Since we now are keeping the movie on-disk, mutating it becomes
        %   more problematical...
        %     function motion_correct(self)
        %       border=2;  % border to ignore, seems to help with nans and such at the
        %                  % edge of the frames
        %       % find the translation for each frame
        %       options=optimset('maxfunevals',1000);
        %       z_slice_count=self.z_slice_count;
        %       self.file.to_start();
        %       if z_slice_count>0
        %         frame_first=double(self.file.get_next());
        %       end
        %       b_per_frame=zeros(2,z_slice_count);
        %       for k=2:z_slice_count
        %         frame_this=double(self.file.get_next());
        %         b_per_frame(:,k)=...
        %           find_translation(frame_first, ...
        %                            frame_this, ...
        %                            border,...
        %                            b_per_frame(:,k-1),...
        %                            options);
        %       end
        %       % register each frame using the above-determined translation
        %       for k=2:z_slice_count
        %         % implicit conversion to the type of self.data
        %         self.data(:,:,k)=register_frame(double(self.data(:,:,k)), ...
        %                                         eye(2), ...
        %                                         b_per_frame(:,k));
        %       end
        %     end  % motion_correct
        
        % ---------------------------------------------------------------------
        function [d_min,d_max]=min_max(self,i)
            % get the max and min values of frame i
            % d_min and d_max are doubles, regardless the type of self.data
            frame=double(self.get_frame(i));
            d_min=min(min(frame));
            d_max=max(max(frame));
        end  % data_bounds
        
        %     function [h,t]=hist(self,i,n_bins)
        %       % construct a histogram of the data values in frame i
        %       frame=double(self.get_frame(i));
        %       [h,t]=hist(frame(:),n_bins);
        %     end
        
        %     function [h,t]=hist_abs(self,i,n_bins)
        %       frame=double(self.get_frame(i));
        %       frame=abs(frame);
        %       [h,t]=hist(frame(:),n_bins);
        %     end
        
        % ---------------------------------------------------------------------
        function [d_05,d_95]=five_95(self,i)
            % d_05 and d_95 are doubles, regardless the type of self.data
            frame=double(self.get_frame(i));
            d=lapwing.quantile_mine(frame(:),[0.05 0.95]');
            d_05=d(1);
            d_95=d(2);
        end  % five_95
        
        % ---------------------------------------------------------------------
        function d_max=max_abs(self,i)
            % d_max is a double, regardless of the type of self.data
            frame=double(self.get_frame(i));
            d_max=max(max(abs(frame)));
        end  % max_abs
        
        % ---------------------------------------------------------------------
        function d_90=abs_90(self,i)
            % d_90 is a double, regardless the type of self.data
            frame=abs(double(self.get_frame(i)));
            d_90=lapwing.quantile_mine(frame(:),0.9);
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
        
    end  % methods
    
end  % classdef
