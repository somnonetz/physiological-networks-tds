function [ result ] = sn_getVariance(signal,varargin)
%calculates variance of the signal in moving window
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 15.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_getVariance(signal,varargin)
% INPUT: 
% signal    vector of biosignal timeseries

%OPTIONAL INPUT:
%'sf'  sampling frequency of time series, default: 200
%'wl'  window length of fourier transform in seconds, default: 2
%'ws'  window shift of fourier transform in seconds, default: 1
%OUTPUT:
%var_signal vector containing variances for the chosen windows

%MODIFICATION LIST:
% DK (2015-03-22): use same delay-method as in nld_movingAverage
%------------------------------------------------------------
%% defaults
sf = 200;
wl = 2;
ws = 1;


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


%% get variance
%samplingrate in seconds
sr = 1/sf;

%windowlength in samples
window_length = wl*sf;
%windowshift in samples
window_shift = ws*sf;

signal_length = length(signal)

%get window_number
window_number = floor((signal_length-(window_length))/window_shift)+1
%get sample number (number of samples with windowshift and unity wl) 
sample_number = floor((signal_length -1 )/window_shift) +1 


% Windows loop
% ----------------
istart = 1;

% put all windows in matrix and then use var just once
% allocate buffer
clips = zeros(window_number,window_length);

for iwin = 1:window_number
    %get end index of window
    iend = istart + window_length-1;
 
    %put signal in window in clips matrix
    clips(iwin,:) = signal(istart:iend);
    
    %start index of next window
    istart = istart + window_shift;
end

%clips needs to be transposed, as var is calculated for each column
var_signal = var(clips');
% the result is a single row, we need one column
result = var_signal';

%% 
%correct for delays, time should be in the center of the window, currently
%at the beginning, missing values at the end of the signal
%padindices = round(wl/(2*ws));
%var_signal = [ repmat(var_signal(1),padindices,1); var_signal; repmat(var_signal(end),padindices,1)];

%delay: (window_length/2), divided by window-shift 
delay = floor(window_length/(2*window_shift))

% remains, samples to be added at the end
remains = sample_number - delay - window_number

%pad result with constant values (first and last averaged value
result = [repmat(result(1,:),delay,1); result; repmat(result(end,:),remains,1)];



end

