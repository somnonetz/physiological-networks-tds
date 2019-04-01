function [ tds,C ] = sn_getStability(signal,varargin)
%calculates stable sequences in lag-sequence
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 16.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_getStability(timelagsignal,varargin)
% INPUT: 
% timelagsignal - matrix of timelags, column = signals, row=time

%OPTIONAL INPUT:
%'wl'  window length of sequence in seconds, default: 5
%'ws'  window shift of sequence in seconds, default: 1
%'sf'  sampling frequency of time series, default: 1
%'mld' maximum lag difference considered as stable, default: 2
%'mlf' minimum lag fraction in window that need to fulfill mld, default: 0.8;
%OUTPUT:
%var_signal vector containing variances for the chosen windows

%MODIFICATION LIST:
% 
%------------------------------------------------------------
%% defaults
wl = 5;
ws = 1;
sf = 1;
mld = 2;
mlf = 0.8;

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
        %maximum lag difference
        elseif strcmp(varargin{i},'mld')
            mld = varargin{i+1};
        %minimum lag fraction in window
        elseif strcmp(varargin{i},'mlf')
            mlf = varargin{i+1};
        end
    end
end



%% get window-clips

%windowlength in samples
window_length = wl*sf;
%windowshift in samples
window_shift = ws*sf;
%minimum lag number in samples
minimum_lag_number = mlf*window_length;

%get window_number
signal_dims = size(signal); 
signal_length = signal_dims(1);
signal_number = signal_dims(2);
window_number = fix((signal_length-window_length)/window_shift);

%allocate buffer
%time-delay-stability array
tds = zeros(window_number,signal_number);

%All combinations of minimum number of lags (mln) chosen from sequence (wl)
window_indices = 1:window_length;
%column: indices, row: combinations
C = nchoosek(window_indices,minimum_lag_number);
%extend to meet all 
%number of combinations
n_comb = nchoosek(window_length, minimum_lag_number);
%vector for diffs
diff_lags = zeros(n_comb,1);


% Windows loop
% ----------------
istart = 1 - window_shift;

for iwin = 1:window_number

     istart = istart + window_shift; 
     iend = istart + window_length-1;
     %get signal window 
     signal_clip = signal(istart:iend,:);
     %loop over all signals - to be optimized later
     for isig = 1:signal_number
         signal_clip_isig = signal_clip(:,isig)';
        %loop over rows, indexing of matrices goes with linear indices
        for irow = 1:n_comb
            max_diff(irow) = max(signal_clip_isig(C(irow,:))) - min(signal_clip_isig(C(irow,:)));
        end
        if(min(max_diff) <= mld)
            tds(iwin,isig) = 1;
        end
     end
end

%here we have first the delay at the beginning, but also possible missing
%values at the end due to windowshift-windowlength-stuff...
%pad for symmetric windows 
%delay
delay = floor(window_length/2);
%padding at the end
%remainder
srm = signal_length-iend+delay;
padend = floor(srm/window_shift);

tds = [ repmat(tds(1,:),delay,1); tds ; repmat(tds(end,:),padend,1)];



end

