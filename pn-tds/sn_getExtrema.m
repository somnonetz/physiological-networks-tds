function extrema = sn_getExtrema(signal,varargin)
%gets all extreme values and then chooses the most prominent ones within a
%window of minimum period length
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 16.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_getExtrama(signal,varargin)
% INPUT: 
% signal - periodic time signal, row: time!

%OPTIONAL INPUT:
%'sf'  sampling frequency of time series, default: 4 Hz
%'mp'  minimum period of signal, default 1 sec
%OUTPUT:
%extrema nx4-matrix with extreme values
%           cols:
%               1: location maximum         
%               2: value maximum         
%               3: location minimum         
%               4: value minimum         

%MODIFICATION LIST:
% 
%------------------------------------------------------------
%% defaults
sf = 4;
mp = 2;

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
        %minimum period    
        elseif strcmp(varargin{i},'mp')
            mp = varargin{i+1};
        end
    end
end

%% find maxima

%windowlength in samples, where only one maximum should appear
d=mp*sf;

%get size of dataset
dim = size(signal);

%get sign of gradients from time series
signal_grad_sign = sign(diff(signal));

%allocate buffer, based on minimum period
nmax_extrema = ceil(length(signal)/d);
%row:extrema, col: maxindex maxvalue minindex minvalue
%extrema = ones(nmax_extrema,,4);

extrema_temp = zeros(nmax_extrema,4);
%loopindex
l = 1;
    %loop over time
    for k = 1:dim(1)-2
        %detect maxima
        %change from positive to zero or negative gradient
        if ((signal_grad_sign(k) ==1) && (signal_grad_sign(k+1) < 1))
            %the maximum sample is one ahead the gradient, therefore k+1
            extrema_temp(l,1) = k+1;
            extrema_temp(l,2) = signal(k+1,1);
            l = l+1;
        %detect minima
        %change from zero or negative gradient to positive gradient
        elseif ((signal_grad_sign(k) < 1) && (signal_grad_sign(k+1) == 1))
              extrema_temp(l,3) = k+1;
              extrema_temp(l,4) = signal(k+1);
        end        
    end
    %clip extrema_temp
    %get maximum index for maxima :-)
    [~,I] = max(extrema_temp(:,1));
    extrema_temp = extrema_temp(1:I,:);
    %loop over all maxima
    m = 1;
    %m must be smaller than the length of extrema
    while (m < length(extrema_temp(:,1)))
        %look if distance is too short
        if (extrema_temp(m+1,1)-extrema_temp(m,1) < d)
            %find larger maximum
            %first maximum is larger
            if (extrema_temp(m,2) >= extrema_temp(m+1,2))
                %check for smaller minimum for following maximum
                if (m+2 <= length(extrema_temp(:,1)))
                    if (extrema_temp(m+1,4) < extrema_temp(m+2,4))
                    %copy smaller minimum
                    extrema_temp(m+2,3:4) = extrema_temp(m+1,3:4);
                    end
                end
                %delete smaller maximum value
                extrema_temp(m+1,:) = [];
            %second maximum is larger    
            else
                %both minima are possible, check for smaller minimum
                if (extrema_temp(m,4) < extrema_temp(m+1,4))
                    %copy smaller minimum
                    extrema_temp(m+1,3:4) = extrema_temp(m,3:4);
                end
                %delete smaller maximum
                extrema_temp(m,:) = [];
            end
        %if distance between maxima is okay, do nothing but increment    
        else    
            m = m+1;
        end
    end
    %get maximum index for maxima :-)
    [~,I] = max(extrema_temp(:,1));
    extrema = extrema_temp(1:I,:);    
end