function [sbmat,f] = nld_spectrogram(signal,varargin)
%nld_spectrogramm produces shortterm ffts of timeseries
%---------------------------------------------------------
%U.Parlitz   7.5.02/D.Krefting
%--------------------------------------------------------
%INPUT:
%
%signal:    a vector containing time series of data
%
%OPTIONAL INPUT:
%sr:        sampling rate in seconds
%wl:        window length in samples
%ws:        window shift in samples
%f0:        main frequency in Hz
%cb:        colorbar option: 'on'
%ww:        windowing: flattop='ft', hann='ha'
%sc:        scaling: linear='ln', default log10
%fn:        figure number, default: 10
%ft:        figure title, default "Spectrogram of data"
%dp:        display, off=0, default=on=1
%
%OUTPUT:
%sbmat:     matrix containing the absolute values (I think it is the power spectrum) of shortterm ffts
%f:         vector containing the frequency-values
%
%MODIFICATIONS: 23.5.02/02.04.2003/17.11.2004/31.1.2005/07.03.2006/06.04.2006
%2008-04-28 (dagi): display option added for use without graphics
%2008-01-26 (dagi): outpuf f added
%2015-02-19 (dagi): Pad for symmetric windows
%2015-03-28 (dagi): modified padding method
%DK (20170630): calculating f independent of dp option

%defaults
samplingrate = 1;
window_length = 512;
window_shift = 100;
mainfrequency = 0;
cb = 0;
ha = 0;
sc = 0;
fn = 20;
ft = 'Spectrogram of data';
%display, default=on
dp = 1;

%checking input
n = size(varargin,2);
if n > 0
    for i = 1:2:n-1
        if varargin{i} == 'sr'
            samplingrate = varargin{i+1}
        elseif varargin{i} == 'wl'
            window_length = varargin{i+1}
        elseif  varargin{i} == 'ws'
            window_shift = varargin{i+1}
        elseif  varargin{i} == 'f0'
            mainfrequency = varargin{i+1}
        elseif  (varargin{i} == 'cb') & (varargin{i+1} == 'on')
            cb = 1;
        elseif  (varargin{i} == 'ww') & (varargin{i+1} == 'ha')
            ha = 1;
        elseif  (varargin{i} == 'ww') & (varargin{i+1} == 'ft')
            ha = 2;
        elseif  (varargin{i} == 'sc') & (varargin{i+1} == 'ln')
            sc = 1;
        elseif  varargin{i} == 'fn'
            fn = varargin{i+1};
        elseif  varargin{i} == 'ft'
            ft = varargin{i+1};
        elseif  varargin{i} == 'dp'
            dp = varargin{i+1};
            
        end
    end
end

%creating window
if (ha == 1)
    hw = hann(window_length);
    whos hw
elseif (ha == 2)
    hw = flattop(window_length);
else
    hw = 1;
end

%spectrogramm produces shortterm ffts of timeseries
signal = squeeze(signal);
%whos signal
signal_length = length(signal)

%substraction of dc
signal = signal- mean(signal);

%cut redundant spectrum part
spectrum_length = window_length/2;

%calculate number of shorterm fft
%window_number = 1 + fix((length-window_length)/window_shift)
window_number = fix((signal_length-window_length)/window_shift) +1;

%get sample number (number of samples with windowshift and unity wl)
sample_number = floor((signal_length -1 )/window_shift) +1


%allocate matrix for result
sbmat = zeros(spectrum_length,window_number) ;

% Windows loop
% ----------------
istart = 1 - window_shift;

for iwin = 1:window_number
    
    istart = istart + window_shift;
    iend = istart + window_length-1;
    %multiply with window
    signal_clip = signal(istart:iend);
    signal_window = signal_clip.*hw ;
    %fouriertransform
    ft_t = fft(signal_window);
    %powerspectrum
    pspec = ft_t .* conj(ft_t);
    %set zero of lowest value
    pspec(1) = min(pspec(2:spectrum_length));
    %cut redundant part
    pspec =pspec(1:spectrum_length);
    %log_scaling
    %log_pspec = log10(pspec(2:spectrum_length+1));
    %log_pspec = log10(pspec(1:spectrum_length));
    %log_pspec = log10(pspec(spectrum_length+1:end));
    %result
    %sbmat(:,iwin) = flipdim(pspec',1) ;
    sbmat(:,iwin) = pspec' ;
    
end

%delay: (window_length/2), divided by window-shift
delay = floor(window_length/(2*window_shift))

% remains, samples to be added at the end
remains = sample_number - delay - window_number

%pad result with constant values (first and last averaged value
%result = [repmat(result(1,:),delay,1); result; repmat(result(end,:),remains,1)];

%pad for symmetric windows
%padindices = round(window_length/(2*window_shift));
%sbmat = [ repmat(sbmat(:,1),1,padindices), sbmat, repmat(sbmat(:,end),1,padindices)];

sbmat = [ repmat(sbmat(:,1),1,delay), sbmat, repmat(sbmat(:,end),1,remains)];

%axes of frequency
freqmax = (spectrum_length-1)/(2*spectrum_length)/samplingrate;
x = [0 iwin*window_shift*samplingrate];
y = [0 freqmax];
%should be the other way round??
%f = [0:spectrum_length-1]*samplingrate/(2*spectrum_length);
%corrected
f = [0:spectrum_length-1]/(samplingrate*2*spectrum_length);

if (dp == 1)
    figure(fn)
    set(gcf,'Name',ft);
    if (sc == 1)
        %imagesc(x,y,sbmat);
        imagesc(x,y,sbmat)
    else
        n_zeros = find(sbmat == 0);
        sbmat2 = sbmat;
        sbmat2(n_zeros) = NaN;
        imagesc(x,y,log10(sbmat2));
        clear sbmat2;
    end
    set(gca,'FontSize',18,'FontWeight','bold');
    set (gca,'ygrid','on');
    set(gca,'ydir','normal');
    ylabel('f[Hz]') ;
    xlabel('t[s]');
    
    
    %colorbar
    if cb == 1
        colorbar ;
    end
end