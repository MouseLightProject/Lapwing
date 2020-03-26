function play(self,direction)

    % play the movie
    start_z_index=self.z_index;
    z_slice_count=self.model.z_slice_count;
    %n_rois=length(self.model.roi);
    % tempargh set(self.image_h,'EraseMode','none');
    fps=self.model.fs;
    % sometimes self.model.fs is nan, b/c the frame rate was not specified.
    if ~isfinite(fps)
        fps=20;  % just for playback purposes
    end
    spf=1/fps;
    % if (direction>0)
    %   frame_sequence=start_z_index:z_slice_count;
    % else
    %   frame_sequence=start_z_index:-1:1;
    % end
    self.stop_button_hit = false ;
    z_index=start_z_index;
    %for z_index=frame_sequence
    %tic;
    while (1<=z_index) && (z_index<=z_slice_count) ,
        %dt_this=toc;
        %fs=1/dt_this
        tic;
        self.z_index=z_index;
        set(self.image_h,'CData',self.indexed_frame);
        set(self.z_index_edit_h,'String',num2str(z_index));
        %self.sync_overlay();
        drawnow;  % N.B.: this allows other callbacks to run!
        while (toc < spf)
        end
        if self.stop_button_hit ,
            break
        end
        z_index=z_index+direction;
    end
    self.stop_button_hit=false;

end