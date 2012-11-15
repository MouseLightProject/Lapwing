function resize(self)

% IMPORTANT: Need to make sure we save the current
% main figure units, set them to pels, then set them back at the end
% Some functions, like errordlg(), set them briefly to other things, and
% sometimes the resize callback gets called during this interval, and that
% causes the figure to get messed-up.

% get current units, save; set units to pels
units_before=get(self.figure_h,'units');
set(self.figure_h,'units','pixels');

% get basic dims
pos=get(self.figure_h,'position');
figure_width=pos(3);
figure_height=pos(4);

%
% spec out the layout of the figure
%

% the figure
%image_area_width=512;
%image_area_height=512;

%n_mode_buttons=5;
mode_button_width=70;
mode_button_height=30;
mode_button_spacer_height=0;

%n_action_buttons=2;
%action_button_width=mode_button_width;
%action_button_height=mode_button_height;
%action_button_spacer_height=0;

button_image_pad_width=20;  % pad between mode/action buttons and image 
colorbar_area_width=30;
image_colorbar_pad_width=50;  % pad between image area and colorbar
n_vcr_buttons=7;
vcr_button_width=60;
vcr_button_height=20;
figure_right_pad_size=20;
figure_left_pad_size=20;
figure_top_pad_size=40;
figure_bottom_pad_size=50;
% figure_width=figure_left_pad_size+...
%            mode_button_width+...
%            button_image_pad_width+...
%            image_area_width+...
%            image_colorbar_pad_width+...
%            colorbar_area_width+...
%            figure_right_pad_size;        
image_frame_area_width=figure_width - ...
                 (figure_left_pad_size+...
                  mode_button_width+...
                  button_image_pad_width+...
                  image_colorbar_pad_width+...
                  colorbar_area_width+...
                  figure_right_pad_size);
image_frame_area_width=max(image_frame_area_width,1);  
%figure_height=figure_top_pad_size+image_area_height+ ...
%              figure_bottom_pad_size;
image_frame_area_height=figure_height - ...
                  (figure_top_pad_size+figure_bottom_pad_size);
image_frame_area_height=max(image_frame_area_height,1);  
% The "frame" is the area where the image goes.  It consists of a
% transparent "matte" surrounding the image, with the image centered in the
% frame.
colorbar_area_height=image_frame_area_height;
%vcr_button_spacer_width= ...
%  frame_area_width/n_vcr_buttons-vcr_button_width;
vcr_button_spacer_width=10;
vcr_button_bar_width= ...
  n_vcr_buttons*vcr_button_width+(n_vcr_buttons-1)*vcr_button_spacer_width;
vcr_button_bar_x_offset= ...
  figure_left_pad_size+mode_button_width+...
  button_image_pad_width+(image_frame_area_width-vcr_button_bar_width)/2;

% determine the zoom factor.  It should be the largest integer
% s.t. the image still fits within the image area
if isempty(self.image_h)
  im=[];
else
  im=get(self.image_h,'cdata');
end
if isempty(im)
  n_row=512;
  n_col=512;
else
  [n_row,n_col]=size(im);
end
zoom=min((image_frame_area_width/n_col), ...
         (image_frame_area_height/n_row));

% position the colorbar axes
colorbar_axes_position=[figure_left_pad_size+...
                          mode_button_width+...
                          button_image_pad_width+...
                          image_frame_area_width+...
                          image_colorbar_pad_width,...
                        figure_bottom_pad_size,...
                        colorbar_area_width,...
                        colorbar_area_height];
set(self.colorbar_axes_h, ... = ...
    'Position',colorbar_axes_position);

% position the image axes
image_area_width=zoom*n_col;
image_area_height=zoom*n_row;
matte_width=(image_frame_area_width-image_area_width)/2;
matte_height=(image_frame_area_height-image_area_height)/2;
image_axes_position=...
  [figure_left_pad_size+mode_button_width+button_image_pad_width+ ...
     matte_width,...
   figure_bottom_pad_size+matte_height,...
   image_area_width,...
   image_area_height];
set(self.image_axes_h,'Position',image_axes_position);

% VCR-style controls
set(self.to_start_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (1-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.play_backward_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (2-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.frame_backward_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (3-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.stop_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (4-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.frame_forward_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (5-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.play_forward_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (6-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);
set(self.to_end_button_h , ...
            'Position',...
              [vcr_button_bar_x_offset+...
                 (7-1)*(vcr_button_width+vcr_button_spacer_width),...
               (figure_bottom_pad_size-vcr_button_height)/2,...
               vcr_button_width,...
               vcr_button_height]);

% % Set the number of pixels to add to the extent to get things to look 
% % nice.  This varies by platform.
% if ismac
%   edit_pad_width=14;
%   edit_pad_height=7;
% else
%   edit_pad_width=10;
%   edit_pad_height=2;
% end

%
% Frame index counter
%

% get the size of the text object that says "Frame"
pos=get(self.frame_text_h,'position');
frame_text_width=pos(3);
frame_text_height=pos(4);

% compute the x,y of same
frame_text_left_margin=figure_left_pad_size+mode_button_width+...
                       button_image_pad_width;
frame_text_baseline= ...
  figure_height-(figure_top_pad_size+frame_text_height)/2;

% set the position of same
set(self.frame_text_h, ...
    'Position',[frame_text_left_margin,...
                frame_text_baseline,...
                frame_text_width,...
                frame_text_height]);
              
% get the size of the editbox containing the current frame index              
pos=get(self.frame_index_edit_h,'position');
frame_index_edit_width=pos(3);
frame_index_edit_height=pos(4);

% set the position of same
set(self.frame_index_edit_h,...
    'Position',[frame_text_left_margin+frame_text_width,...
                frame_text_baseline+...
                  (frame_text_height-frame_index_edit_height)/2+2,...
                frame_index_edit_width,...
                frame_index_edit_height]);
              
% get the size of the text object that says "of <number of frames total>"
pos=get(self.of_n_frames_text_h,'position');
of_n_frames_text_width=pos(3);
of_n_frames_text_height=pos(4);

% set the position of same
set(self.of_n_frames_text_h,'Position',...
                       [frame_text_left_margin+frame_text_width+...
                          frame_index_edit_width,...
                        frame_text_baseline,...
                        of_n_frames_text_width,...
                        of_n_frames_text_height]);

                      
% Frames per second controls
pos=get(self.FPS_text_h,'position');
FPS_text_width=pos(3);
FPS_text_height=pos(4);
pos=get(self.FPS_edit_h,'position');
FPS_edit_width=pos(3);
FPS_edit_height=pos(4);
FPS_elements_width=FPS_text_width+FPS_edit_width;
FPS_elements_left_margin=figure_left_pad_size+mode_button_width+...
                         button_image_pad_width+image_frame_area_width-...
                         FPS_elements_width;
FPS_elements_baseline= ...
  figure_height-(figure_top_pad_size+FPS_text_height)/2;
set(self.FPS_text_h, ...
    'Position',[FPS_elements_left_margin,...
                FPS_elements_baseline,...
                FPS_text_width,...
                FPS_text_height]);
set(self.FPS_edit_h,...
    'Position',[FPS_elements_left_margin+FPS_text_width,...
                FPS_elements_baseline+...
                  (FPS_text_height-FPS_edit_height)/2+2,...
                FPS_edit_width,...
                FPS_edit_height]);

% Mode buttons
set(self.elliptic_roi_button_h , ...
            'Position',...
              [figure_left_pad_size,...
               figure_bottom_pad_size+image_frame_area_height-...
                 mode_button_height-...
                 (1-1)*(mode_button_height+mode_button_spacer_height),...
               mode_button_width,...
               mode_button_height]);
set(self.rect_roi_button_h , ...
            'Position',...
              [figure_left_pad_size,...
               figure_bottom_pad_size+image_frame_area_height-...
                 mode_button_height-...
                 (2-1)*(mode_button_height+mode_button_spacer_height),...
               mode_button_width,...
               mode_button_height]);
set(self.select_button_h , ...
            'Position',...
              [figure_left_pad_size,...
               figure_bottom_pad_size+image_frame_area_height-...
                 mode_button_height-...
                 (3-1)*(mode_button_height+mode_button_spacer_height),...
               mode_button_width,...
               mode_button_height]);
set(self.zoom_button_h , ...
            'Position',...
              [figure_left_pad_size,...
               figure_bottom_pad_size+image_frame_area_height-...
                 mode_button_height-...
                 (4-1)*(mode_button_height+mode_button_spacer_height),...
               mode_button_width,...
               mode_button_height]);
set(self.move_all_button_h , ...
            'Position',...
              [figure_left_pad_size,...
               figure_bottom_pad_size+image_frame_area_height-...
                 mode_button_height-...
                 (5-1)*(mode_button_height+mode_button_spacer_height),...
               mode_button_width,...
               mode_button_height]);

             
% restore fig units
set(self.figure_h,'units',units_before);

end