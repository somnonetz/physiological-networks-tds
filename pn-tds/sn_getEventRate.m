function [eventrate,ep,events,lqv]  = sn_getEventRate(events,varargin)
%calculates the event rate from a vector containing points of time of
%events
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 17.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_getEventRate(events,varargin)
% INPUT:
% events - row vector containing event times in sample units of the original
% signal
%
% OPTIONAL INPUT:
% 'sf'   sampling frequency of the original signal in Hz, default 1 Hz
% 'ersf' sampling frequency of event rate, default 1 Hz
% 'sl'   signal length of original signal in samples, default max(events)
% 'tpa'  time point assignment, time point to which the calculated
%           event-rate (period) is assigned to.
%           'first' = first timepoint of the  two timepoints, the difference is taken from,
%           'interp' = the timepoint in the middle of the first and second time-point.
%           'second' = second timepoint of the two timepoints
%           Default: 'interp'
% 'rsm' resampling method.
%           'interval' the rate is considered as stair function, sampling
%           values are assigned to the rate within the interval.
%           'interpol' the rate is considered continuously, and the sample
%           values are assigned to linearly interpolated values
%           Default: 'interpol'
% 'qv'      quality-values: a vector of same size as events containing quality values    
% 'lql'     lower quality limit of the quality-values: events below should
%           be excluded and event rate interpolated
%
%
%OUTPUT:
% eventrate  vector containing the event rate
% ep event periods - difference in samples between events
% events events in seconds
% lqv low quality values

%MODIFICATION LIST:
% DK (2015-03-21): 'tpa' and 'rsm' options added
% DK (2015-03-31): 'qv' and 'lql' options added
% DK (20170630): plot of lqv removed, but added to output
%------------------------------------------------------------
%% defaults
%signal sampling frequency
sf = 1;
%event rate sampling frequency
ersf = 1;
%signal length
sl = max(events);
%time point assignment
tpa = 'interp';
%reampling method
rsm = 'interpol';
%quality values
qv = ones(length(events),1);
%lower quality limit
lql = 0;

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
            %event rate sampling frequency
        elseif strcmp(varargin{i},'ersf')
            ersf = varargin{i+1};
            %signal length
        elseif strcmp(varargin{i},'sl')
            sl = varargin{i+1};
            %time point assignment
        elseif strcmp(varargin{i},'tpa')
            tpa = varargin{i+1};
            %resampling method
        elseif strcmp(varargin{i},'rsm')
            rsm = varargin{i+1};
        elseif strcmp(varargin{i},'qv')
            qv = varargin{i+1};
        elseif strcmp(varargin{i},'lql')
            lql = varargin{i+1};
        end
    end
end

%% Get event rate
%normalize sample points to a seconds
events = events/sf; 
%calculate event period (ep) in seconds: diff between event times
ep = diff(events);
%event rate is the inverse values
er = 1./ep;
%get low quality values
lqv = qv <= lql;

%add preceding index with logical OR on shifted lqv
lqv = lqv | [ lqv(2:end); false ]; 
%delete eventrate values derived from low quality values
%need to be removed also from events and ep, as they are also used further
%to assign timepoints. 
er(lqv(1:end-1)) = [];
events(lqv(1:end-1)) = [];
ep(lqv(1:end-1)) = [];


%generate vector with equidistant time points in seconds
tv = zeros(floor((sl/sf)*ersf),2);
%points in time
timevector = (0:1/ersf:length(tv)/ersf)';
tv(:,1) = (timevector(1:length(tv)));


if (strcmp(rsm,'interval'))
    %loop over all values (not very efficient...)
    for i = 1:length(tv)
        %check if timestamp is before first event
        if (tv(i,1) < events(1))
            %assign first heart rate
            tv(i,2) = er(1);
        else
            time_diff = events - tv(i,1);
            events_index = length(time_diff(time_diff <= 0));
            tv(i,2) = er(events_index);
        end
    end
    
elseif(strcmp(rsm,'interpol'))
    %time point index - time point to which the calculated period should be assigned: middle point
    %between the two time points the period is calculated from
    if (strcmp(tpa,'interp'))
        whos events
        whos ep
        epi = events(1:end-1)+ep/2;
    elseif (strcmp(tpa,'second'))
        epi = events(2:end);
    else % first
        epi = events(1:end-1);
    end
    
    %interpolate breathingperiods between first and last extrem value;
    tv(:,2) = interp1(epi,er,tv(:,1),'linear','extrap');
    
    % %pad at both ends to fit resampled data
    % padstart = floor(epi(1))-1;
    % padend = sl-ceil(epi(end));
    % eventrate = [repmat(br(1),1,padstart),br,repmat(br(end),1,padend)];
    %
    % %resample breatingrate to ersf
    % eventrate = resample(eventrate,ersf,sf);
end
%only the values, not the timestamps
eventrate = tv(:,2);


end






