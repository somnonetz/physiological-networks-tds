function [ fpb,sbmat ] = sn_getEEGBandPower(signal,varargin)
%calculates overall power of EEG frequency bands
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 15.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.1
%-----------------------------------------------------------
%
%USAGE: sn_getEEGBandPower(signal,varargin)
% INPUT: 
% signal - vector of EEG timeseries

%OPTIONAL INPUT:
%'wl'  window length of fourier transform in seconds, default: 2
%'ws'  window shift of fourier transform in seconds, default: 1
%'sf'  sampling frequency of time series, default: 200
%'bl'  bandlimits matrix (2, number_bands)
%       bl(1,n) = lower frequency limit of nth band)
%       bl(2,n) = upper frequency limit of nth band)
%OUTPUT:
%fpb   matrix containing the added power of frequency bands:
%      columns:
%       1: delta-waves ( 0.5 -  3.5 Hz)
%       2: theta-waves ( 4.0 -  7.5 Hz)
%       3: alpha-waves ( 8.0 - 11.5 Hz)
%       4: sigma-waves (12.0 - 15.5 Hz)
%       5: beta-waves  (16.0 - 19.5 Hz)

%MODIFICATION LIST:
% Dagi (150330): debugging in frequency-band sum up
% DK (170630): display off in spectrogram
%------------------------------------------------------------
%% defaults
wl = 2;
ws = 1;
sf = 200;

%band limits
bandlimits = [ 0.5 4 8 12 16; 3.5 7.5 11.5 15.5 19.5]; 

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
        %bandlimits matrix
        elseif strcmp(varargin{i},'bl')
            bandlimits = varargin{i+1};
        end
    end
end



%% get spectrogram
%samplingrate in seconds
sr = 1/sf;

%windowlength in samples
wls = wl*sf;
%windowshift in samples
wss = ws*sf;

%get spectrogram
%rows: frequency, columns: timeseries
[sbmat,f] = nld_spectrogram(signal,'sr',sr,'wl',wls,'ws',wss,'dp',0);

%get frequency resolution
df = f(2);

%get indices of band limits (+1: accounting for f(1) = 0)
bandindices = (bandlimits/df)+1;
%for lower limit: ceil, for upper limit: floor
bandindices(1,:) = ceil(bandindices(1,:));
bandindices(2,:) = floor(bandindices(2,:))

%% Cumulative power of frequency bands

%allocate buffer
fpb = zeros(length(sbmat),5);

%loop over bands
for i = 1:5
    fpb(:,i) = sum(sbmat(bandindices(1,i):bandindices(2,i),:));
end

end

