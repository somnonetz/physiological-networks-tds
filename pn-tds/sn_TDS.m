function [tds,xcc,xcl,biosignals_tds,fpb,sbmat,header,signalheader,signalcells] = sn_TDS(varargin)
%reads PSGs (in EDF format) and performs TDS method
%based on Bashan et al. Nat. com. 2012 DOI: 10.1038/ncomms1705
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 15.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: tds = sn_TDS('data',filename,varargin)
%
%INPUT:
%'data'       full filename of the edf, including path.
%
%OPTIONAL INPUT:
% montage_filename filename of montage, giving the signaltypes, default:
% none
% resultpath  directory where the results are stored, default: working
% directory
% outputfilebase string from which the result filenames are deduced, default filebasename of the EDF
% wl_sfe    windowlength of signal feature extraction, default 2 secs
% ws_sfe    windowshift of signal feature extraction, default 1 secs
% wl_xcc windowlength of crosscorrelation in seconds, default 60;
% ws_xcc windowshift of crosscorrelation in seconds, default 30;
% wl_tds windowlength of stability analysis in seconds, default 5;
% ws_tds windowshift of stability analysis in seconds, default 1;
% mld_tds maximum lag difference in window to be accounted as stable sequence, default 2;
% mlf_tds minimum lag fraction in window that need to fulfill mld_tds, default: 0.8;
% debug     if set to 1 debug information is provided, default '0'
%
% OUTPUT
% tds   matrix containing stability matrix of size(timespan,nsignals^2)
%       the time resolution is determined by ws_xcc. The order of the
%       signal2signal is first all combinations with first signal, all
%       combinations with second signal,....,all combinations with nth
%       signal, for three signals e.g. 11-12-13-21-22-23-31-32-33
%
% Modification List
% 20150302 V 1.0.1 (dk):
% - debug option added
% - debug information implemented
% - default EEG channel to channel 2 (C3-M2)
% 20150309 V 1.0.2 (dk)
% - option rr_filetype added ('rr')
% - option breath_filetype added
% - using sn_BlockEdfRead instead of BlocEdfRead to account for invalid
% num_data_records
% 20150331 V 1.0.3 (dk)
% - option ch_all added
% 20150408 V 1.0.4 (dk)
% - options for external chest and abdomen files added
% - renamed resp_file/resp_flag to airflow_file/airflow_flag
% 20170626 V 1.1 (dk)
% - all to varargin (standard)
% - arbitrary channel configuration via montagefile
% - removal of external feature extraction files

%% Defaults feature extraction

%windowlength of signal feature extraction
wl_sfe = 2;
%windowshift of signal feature extraction
ws_sfe = 1;

%default montage
montage = {'eeg';'eeg';'eeg';'eeg';'eeg';'eeg';...
    'eog';'eog';...
    'emg';'emg';'emg';...
    'ecg';...
    'resp';'resp';'resp'};
%external montagefilename
m_filename = '';
% resultpath
resultpath = '.';
%outputfilebase
outputfilebase = '';
%% Defaults crosscorrelation

%window length in seconds
wl_xcc = 60;
%window shift in seconds
ws_xcc = 30;

%% Defaults time delay stability

%windowlength of stability analysis in seconds
wl_tds = 5;
%windowshift of stability analysis in seconds
ws_tds = 1;
%maximum lag difference in window to be accounted as stable sequence
mld_tds = 2;
%minimum lag fraction in window fulfilling mld_tds to account for stable
%sequence
mlf_tds = 0.8;

%% Defaults debug
debug = 0;

%% Check for input vars
%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %outputfile
        if strcmp(varargin{i},'data')
            data = varargin{i+1};
        elseif strcmp(varargin{i},'wl_sfe')
            wl_sfe = varargin{i+1};
        elseif strcmp(varargin{i},'ws_sfe')
            ws_sfe = varargin{i+1};
        elseif strcmp(varargin{i},'montage_filename')
            m_filename = varargin{i+1};
        elseif strcmp(varargin{i},'resultpath')
            resultpath = varargin{i+1};
        elseif strcmp(varargin{i},'outputfilebase')
            outputfilebase = varargin{i+1};
            outputbaseflag=1;
        elseif strcmp(varargin{i},'wl_xcc')
            wl_xcc = varargin{i+1};
        elseif strcmp(varargin{i},'ws_xcc')
            ws_xcc = varargin{i+1};
        elseif strcmp(varargin{i},'wl_tds')
            wl_tds = varargin{i+1};
        elseif strcmp(varargin{i},'ws_tds')
            ws_tds = varargin{i+1};
        elseif strcmp(varargin{i},'mld_tds')
            mld_tds = varargin{i+1};
        elseif strcmp(varargin{i},'mlf_tds')
            mlf_tds = varargin{i+1};
        elseif strcmp(varargin{i},'debug')
            debug = varargin{i+1};
        end
    end
end

%% debug
if debug
    disp('Welcome to sn_TDS')
end

%% get outputfilebase, if not set
if isempty(outputfilebase)
    [path,file,ext] = fileparts(data);
    outputfilebase = file;
end

%% read edf
[header,signalheader,signalcells]= sn_edfScan2matScan('data',data);

%% get headerinfos

%data_record_duration in seconds
drd = header.data_record_duration;
%sampling frequencies of channels
sfch = [signalheader(:).samples_in_record]/drd;

%% get montage infos
if ~isempty(m_filename)
    fid = fopen(m_filename);
    m_tmp = textscan(fid,'%s');
    montage = m_tmp{1};
    fclose(fid);
end

%% define biosignal array
biosignals_tds = [];

%loop over all channels
for i = 1:length(montage)
    switch montage{i}
        case 'eeg'
            %% extract frequency-powerbands
            %get matrix with powerbands
            if debug
                disp(['fpb = sn_getEEGBandPower(signalcells{' num2str(i) '},''wl'',' num2str(wl_sfe) ',''ws'',' num2str(ws_sfe) ',''sf'',' num2str(sfch(i)) ');'])
            end
            [fpb,sbmat] = sn_getEEGBandPower(signalcells{i},'wl',wl_sfe,'ws',ws_sfe,'sf',sfch(i));
            % use mean band amplitude rather than power
            fpb = sqrt(fpb);
            biosignals_tds = [biosignals_tds fpb];
        case 'eog'
            %% get variance of EOGs
            if debug
                disp(['var_eog = sn_getVariance(signalcells{' num2str(i) '},''wl'',' num2str(wl_sfe) ',''ws'',' num2str(ws_sfe) ',''sf'',' num2str(sfch(i)) ');'])
            end
            var_eog = sn_getVariance(signalcells{i},'wl',wl_sfe,'ws',ws_sfe,'sf',sfch(i));
            biosignals_tds = [biosignals_tds var_eog];
        case 'emg'
            %% get variance of EOGs
            if debug
                disp(['var_emg = sn_getVariance(signalcells{' num2str(i) '},''wl'',' num2str(wl_sfe) ',''ws'',' num2str(ws_sfe) ',''sf'',' num2str(sfch(i)) ');'])
            end
            var_emg = sn_getVariance(signalcells{i},'wl',wl_sfe,'ws',ws_sfe,'sf',sfch(i));
            biosignals_tds = [biosignals_tds var_emg];
        case 'ecg'
            %% get qrs timepoints
            if debug
                disp(['rrdata = sn_CQRS(signalcells{' num2str(i) '},sfch(' num2str(i) '))']);
            end
            rrdata = sn_CQRS(signalcells{i},sfch(i));
            %% get heart rate
            if debug
                disp(['heartrate = sn_getEventRate(rrdata,''sf'',' num2str(sfch(i)) ',''ersf'',' num2str(ws_sfe) ',''sl'',' num2str(length(signalcells{i})) ');'])
            end
            heartrate = sn_getEventRate(rrdata,'sf',sfch(i),'ersf',ws_sfe,'sl',length(signalcells{i}));
            %apply moving median to get rid of spikes
            heartrate = nld_movingMedian(heartrate,5);
            if debug
                whos heartrate
            end
            biosignals_tds = [biosignals_tds heartrate];
        case 'resp'
            %% calculate breathingrate
            if debug
                disp(['breathingrate = sn_getBreathingRate(signalcells{' num2str(i) '},''sf'',' num2str(sfch(i)) ',''brsf'',' num2str(ws_sfe) ');'])
            end
            breathingrate = sn_getBreathingRate(signalcells{i},'sf',sfch(i),'brsf',ws_sfe);
            %transpose
            breathingrate = breathingrate';
            biosignals_tds = [biosignals_tds breathingrate];
        otherwise
            disp('signal type unknown, skipping')
    end
end

%control biosignal_tds
if debug
    whos biosignals_tds
end

%get crosscorrelation of signals, samplingfrequency equals windowshift of
%feature extraction
%xcc: maximum correlationcoefficient
%xcl: correlation lag of xcc
if debug
    disp(['[xcc,xcl] = sn_getCrossCorrelation(biosignals_tds,''wl'',' num2str(wl_xcc) ',''ws'',' num2str(ws_xcc) ',''sf'',' num2str(ws_sfe) ');'])
end
[xcc,xcl] = sn_getCrossCorrelation(biosignals_tds,'wl',wl_xcc,'ws',ws_xcc,'sf',ws_sfe);
if debug
    whos xcc
end
%stability analysis
if debug
    disp(['[tds] = sn_getStability(xcl,''wl'',' num2str(wl_tds) ',''ws'',' num2str(ws_tds) ',''mld'',' num2str(mld_tds) ',''mlf'',' num2str(mlf_tds) ',''sf'',' num2str(ws_sfe) ');'])
end
[tds] = sn_getStability(xcl,'wl',wl_tds,'ws',ws_tds,'mld',mld_tds,'mlf',mlf_tds,'sf',ws_sfe);

if debug
    whos tds
end

%% store data

%% save all information
save(fullfile(resultpath,[outputfilebase '_getTDS_all.mat']),'biosignals_tds','xcc','xcl','tds',...
    'data','montage','sfch','header','signalheader',...
    'wl_sfe','ws_sfe','wl_xcc','ws_xcc',...
    'wl_tds','ws_tds','mld_tds','mlf_tds');
%% save tds, channelnames and montage
save(fullfile(resultpath,[outputfilebase '_getTDS.mat']),'tds',...
    'data','montage','signalheader');




