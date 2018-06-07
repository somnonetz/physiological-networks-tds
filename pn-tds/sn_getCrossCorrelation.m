function [ xcc_signal,xcl_signal ] = sn_getCrossCorrelation(signal,varargin)
%calculates best crosscorrelation for signals, signal windows are normalized to zero mean and unit std 
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 15.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
% USAGE: sn_getCrossCorrelation(signal,varargin)
%
% INPUT: 
% signal - matrix of biosignal timeseries, column = signals, row=time

% OPTIONAL INPUT:
%'wl'  window length of fourier transform in seconds, default: 60
%'ws'  window shift of fourier transform in seconds, default: 30
%'sf'  sampling frequency of time series, default: 1
%
% OUTPUT:
%var_signal vector containing variances for the chosen windows

%MODIFICATION LIST:
% 
%------------------------------------------------------------
%% defaults
sf = 1;
wl = 60;
ws = 30;

%% Check for input vars
%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %samplingfrequency
        if strcmp(varargin{i},'sf')
            sf = varargin{i+1};
        %windowlength
        elseif strcmp(varargin{i},'wl')
            wl = varargin{i+1};
        %windowshift
        elseif strcmp(varargin{i},'ws')
            ws = varargin{i+1};
        end
    end
end

%% get window-clips

%windowlength in samples
window_length = wl*sf;
%windowshift in samples
window_shift = ws*sf;

%% get total number of windows that fit into the signal

% signal sizes
signal_dims = size(signal); 
signal_length = signal_dims(1);
signal_number = signal_dims(2);

%calculate the number of windows that fit, consider signal-lengts, that are
%not multiples of window length, and consider overlapping windows
%(window-shift is different from window length)
window_number = fix((signal_length-window_length)/window_shift)+1;

%get sample number (number of samples with windowshift and unity wl) 
sample_number = floor((signal_length -1 )/window_shift) +1 


%allocate buffer
%max coefficient
xcc_signal = zeros(window_number,signal_number*signal_number);
%max lag
xcl_signal = zeros(window_number,signal_number*signal_number);
% Windows loop
% ----------------
istart = 1 - window_shift;

for iwin = 1:window_number

     istart = istart + window_shift; 
     iend = istart + window_length-1;
     %get signal window 
     signal_clip = signal(istart:iend,:);
     %subtract offset
     signal_clip = signal_clip - repmat(mean(signal_clip),window_length,1);
     %normalize to unit standard-deviation
     signal_clip = signal_clip./repmat(std(signal_clip),window_length,1);
     %cross- and autocorrelation: row: corrcoef, col: signalcombinations 
     [ccx_clip,lags_clip] = xcorr(signal_clip);
     [c_max,I] = max(abs(ccx_clip));
     xcc_signal(iwin,:) = c_max;
     xcl_signal(iwin,:) = lags_clip(I);
     %whos c_max
     %whos I
end

%pad crosscorrelation matrices in case of larger window_length than
%window_shift
%get signalremainder not being windowed
srm = signal_length - iend;
% %get number of windowshifts that would fit into the remainder
 padnumber = floor(srm/window_shift);
 if padnumber > 0
%     %pad last value
     xcc_signal = [xcc_signal;repmat(xcc_signal(end,:),padnumber,1)];
     xcl_signal = [xcl_signal;repmat(xcl_signal(end,:),padnumber,1)];
 end




end

