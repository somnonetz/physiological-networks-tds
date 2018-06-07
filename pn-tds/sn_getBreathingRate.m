function [breathingrate,extrema,signal_resampled]  = sn_getBreathingRate(signal,varargin)
%calculates the breathing rate
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 17.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_getBreathingRate(signal,samplingfrequency,varargin)
% INPUT: 
% signal - airflow signal, row: time!
%
% OPTIONAL INPUT:
% 'sf'  sampling frequency of the signal in Hz, default 1 Hz
% 'mp'  minimum period of signal, default 2 secs
%'rsf'  resampling frequency, default 4 Hz
%'nsma' number of samples in moving average, default 11 samples
%'llma' lower limit for accepted extreme values with respect to moving
%       average, as fraction of the moving average, default 0.5
%'brsf' sampling frequency of breathing rate, default 1 Hz
%
%OUTPUT:
%breathingrate  vector containing the breathing rate
%extrema        matrix containing the found extreme values
%               cols: 
%               1: location maximum (in resampled signal)         
%               2: value maximum         
%               3: location minimum (in resampled signal)         
%               4: value minimum         
%MODIFICATION LIST:
% 20150526 (dk): Changed padding in case of first extrema is very early and
% startpad is -1, then subtract a sample at the beginning
% 20150526 (dk): Debug for incidents, where the false positive minimum is
% smaller than following AND maximum greater than preceding maximum. 
%------------------------------------------------------------
%% defaults
sf = 1;
rsf = 4;
mp = 2;
nsma = 11;
llma = 0.5;
brsf = 1;

%% Check for input vars
%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %sampling frequency of signal
        if strcmp(varargin{i},'sf')
            sf = varargin{i+1};
        %resampled sampling frequency
        if strcmp(varargin{i},'rsf')
            rsf = varargin{i+1};
        %minimum period    
        elseif strcmp(varargin{i},'mp')
            mp = varargin{i+1};
        %number of samples in moving average   
        elseif strcmp(varargin{i},'nsma')
            nsma = varargin{i+1};
        %lower limit relative to moving average    
        elseif strcmp(varargin{i},'llma')
            llma = varargin{i+1};
        %breathing rate sampling frequency    
        elseif strcmp(varargin{i},'brsf')
            brsf = varargin{i+1};
        end
    end
end

%% Analyse signal

% resample the signal to rsf
signal_resampled = resample(signal,rsf,sf);

% find extreme values with constraints on the minimum distance in time between two maxima. 
extrema = sn_getExtrema(signal_resampled,'mp',mp,'sf',rsf);

%% exclude extreme values with small amplitudes

%get distance between maximum and minimum (amplitude)
extrema_dist = extrema(:,2)-extrema(:,4);

%get moving average of amplitudes
extrema_dist_mavg = nld_movingAverage(extrema_dist,nsma);

%get extrema with distances smaller then lower limit 
extrema_dist_bin = extrema_dist < llma*extrema_dist_mavg;

%get extrema with larger maximum than preceding extremum
extrema_max_ltp_bin = extrema(:,2) > [0; extrema(1:end-1,2)];

%get extrema with smaller minimum than following extremum
extrema_min_ltf_bin = extrema(:,4) < [extrema(2:end,4); 0];

%% before deleting false extrema, correct for larger maxima and smaller
% minima

%false positives with smaller minima
fpsm = (extrema_dist_bin & extrema_min_ltf_bin);

%false positives with larger maxima
fplm = (extrema_dist_bin & extrema_max_ltp_bin);

%%  DEBUGGING
%find those, where both conditions are given, they must be excluded from
%shifting, otherwise extrema order is not preserved
%probably there is a better solution, but I don't see them in the moment.
%Given the rare situation, the resulting error might be okay
fpsm_fplm = fpsm & fplm;
%invert to set incidents to false
fpsm_fplm = ~fpsm_fplm;
%remove these from fpsm and fplm
fpsm = fpsm & fpsm_fplm;
fplm = fplm & fpsm_fplm;

%store the minimal value to follower
extrema([logical(0); fpsm(1:end-1)],3:4) = extrema([fpsm(1:end-1); logical(0)],3:4);

%store the maximal value to precessor
extrema([fplm(2:end); logical(0)],1:2) = extrema([logical(0); fplm(2:end)],1:2);

% delete extreme values below fraction of moving average
extrema(extrema_dist_bin,:) = [];

%delete also the moving average-values
extrema_dist_mavg(extrema_dist_bin,:) = [];

%% and now the same story for the amplitudes between maxima and following minima 

%get distance between maximum and following minimum
extrema_dist = extrema(1:end-1,2)-extrema(2:end,4);

%use the same moving average as before!!!
%get extrema with distances smaller then lower limit 
edb = extrema_dist < llma*extrema_dist_mavg(1:end-1);

%write minimum values from these false positives to follower
extrema([logical(0); edb(1:end-1)],3:4) = extrema([edb(1:end-1); logical(0)],3:4);

%delete false positives 
extrema(edb,:) = [];

%% Get breathing rate

%calculate period: diff between minima and maxima
bp = diff(extrema(:,[1,3]))/rsf;

%moments to which the calculated period should be assigned: middle point
%between the two time points the period is calculated from
bpi = extrema(1:end-1,[1,3])+bp/2;

%flip cols for having the preceding minimum earlier than following maximum
bp = reshape(flipdim(bp,2)',1,2*length(bp));
bpi = reshape(flipdim(bpi,2)',1,2*length(bpi));
whos bpi
%interpolate breathingperiods between first and last extrem value;
br = interp1(bpi,(1./bp),(floor(bpi(1)):ceil(bpi(end))));

%% needs some correction
%pad at both ends to fit resampled data
padstart = floor(bpi(1))-1;
padend = length(signal_resampled)-ceil(bpi(end));
%if floor is 0, cut first point, not to get confused with indices and
%timepoints
if (padstart == -1)
breathingrate = [br(2:end),repmat(br(end),1,padend)];
else    
breathingrate = [repmat(br(1),1,padstart),br,repmat(br(end),1,padend)];
end

%resample breatingrate to brsf
breathingrate = resample(breathingrate,brsf,rsf);

end






