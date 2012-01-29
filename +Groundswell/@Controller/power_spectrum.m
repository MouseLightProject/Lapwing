function power_spectrum(self)

% get the figure handle
groundswell_figure_h=self.view.fig_h;

% get stuff we'll need
selected=self.view.get_selected_axes();
t=self.model.t;
data=self.model.data;
N=size(data,1);
names=self.model.names;
units=self.model.units;

% get the selected signal
n_signals=sum(selected);
if n_signals==0
  return;
elseif n_signals>1
  errordlg('Can only calculate power spectrum on one signal at a time.',...
           'Error');
  return;
end
data=data(:,selected);
name=names{selected};
units=units{selected};

% calc sampling rate
dt=(t(end)-t(1))/(length(t)-1);
f_samp=1/dt;
f_nyquist=0.5*f_samp;

% throw up the dialog box
param_str=inputdlg({ 'Number of windows:' , ...
                     'Time-bandwidth product (NW):' , ...
                     'Number of tapers:' , ...
                     'Maximum frequency (Hz):' ,...
                     'Extra FFT powers of 2:' , ...
                     'Confidence level:' },...
                     'Power spectrum parameters...',...
                   1,...
                   { '1' , ...
                     '4' , ...
                     '7' , ...
                     sprintf('%0.3f',f_nyquist) , ...
                     '2' , ...
                     '0.95' },...
                   'off');
if isempty(param_str)
  return;
end

% break out the returned cell array
n_windows_str=param_str{1};
NW_str=param_str{2};
K_str=param_str{3};
W_keep_str=param_str{4};
p_FFT_extra_str=param_str{5};
conf_level_str=param_str{6};

%
% convert strings to numbers, and do sanity checks
%

% n_windows
n_windows=str2double(n_windows_str);
if isempty(n_windows)
  errordlg('Number of windows not valid','Error');
  return;
end
if n_windows~=round(n_windows)
  errordlg('Number of windows must be an integer','Error');
  return;
end
if n_windows<1
  errordlg('Number of windows must be >= 1','Error');
  return;
end

% NW
NW=str2double(NW_str);
if isempty(NW)
  errordlg('Time-bandwidth product (NW) not valid','Error');
  return;
end
if NW<1
  errordlg('Time-bandwidth product (NW) must be >= 1','Error');
  return;
end

% K
K=str2double(K_str);
if isempty(K)
  errordlg('Number of tapers not valid','Error');
  return;
end
if K~=round(K)
  errordlg('Number of tapers must be an integer','Error');
  return;
end
if K>2*NW-1
  errordlg('Number of tapers must be <= 2*NW-1','Error');
  return;
end

% W_keep
W_keep=str2double(W_keep_str);
if isempty(W_keep)
  errordlg('Maximum frequency not valid','Error');
  return;
end
if W_keep<0
  errordlg('Maximum frequency must be >= 0','Error');
  return;
end
if W_keep>f_nyquist
  errordlg(sprintf(['Maximum frequency must be <= half the ' ...
                    'sampling frequency (%0.3f Hz)'],f_samp),...
           'Error');
  return;
end

% p_FFT_extra
p_FFT_extra=str2double(p_FFT_extra_str);
if isempty(p_FFT_extra)
  errordlg('Extra FFT powers of 2 not valid','Error');
  return;
end
if p_FFT_extra~=round(p_FFT_extra)
  errordlg('Extra FFT powers of 2 must be an integer','Error');
  return;
end
if p_FFT_extra<0
  errordlg('Extra FFT powers of 2 must be >= 0','Error');
  return;
end

% conf_level
conf_level=str2double(conf_level_str);
if isempty(conf_level)
  errordlg('Confidence level not valid','Error');
  return;
end
if conf_level<0
  errordlg('Confidence level must be >= 0','Error');
  return;
end
if conf_level>=1
  errordlg('Confidence level must be < 1',...
           'Error');
  return;
end

%
% all parameters are converted, and are in-bounds
%



%
% do the analysis
%

% may take a while
set(groundswell_figure_h,'pointer','watch');
drawnow('update');
drawnow('expose');

% % to test
% data(:,1)=cos(2*pi*1*t);

% get just the data in view
tl_view=self.view.tl_view;
jl=interp1([t(1) t(end)],[1 N],tl_view,'linear','extrap');
jl(1)=floor(jl(1));
jl(2)= ceil(jl(2));
jl(1)=max(1,jl(1));
jl(2)=min(N,jl(2));
t_short=t(jl(1):jl(2));
data_short=data(jl(1):jl(2));
clear t data;
N=length(data_short);
dt=(t_short(end)-t_short(1))/(N-1);

% center the data
data_short_mean=mean(data_short,1);
data_short_cent=data_short-data_short_mean;

% determine window size
N_window=floor(N/n_windows);
%T_window=dt*N_window;

% want N to be integer multiple of N_window
N=N_window*n_windows;
data_short_cent=data_short_cent(1:N,:);
%T=dt*N;

% put windows into the second index
data_short_cent_windowed=...
  reshape(data_short_cent,[N_window n_windows]);

% calc the power spectrum, using multitaper routine
[f,~,...
 N_fft,f_res_diam,~,...
 ~,...
 Pxx_log,~,Pxx_log_ci]=...
  pow_mt(dt,data_short_cent_windowed,...
         NW,K,W_keep,p_FFT_extra,conf_level);
%n_f=length(f);

% make power spectrum object
Groundswell.Power_spectrum(f,Pxx_log,Pxx_log_ci,name,units, ...
                           f_samp,W_keep,f_res_diam,N_fft);

% set pointer back
set(groundswell_figure_h,'pointer','arrow');
drawnow('update');
drawnow('expose');
