function sn_plotTDS(tds,varargin)
%plots time series of tds-analysis
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 19.2.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: sn_plotTDS(TDS-matrix,varargin)
% INPUT: 
% tds    matrix of intersignal stability, cols signalcombinations, row time
% or stages
%
%OPTIONAL INPUT:
% rowdim    dimension of the row 'time'|'stages', default: 'stages'       
% slabels    vector containing the labels of the signals
% rlabels    vector containing the labels of the rows
% fth        fraction threshold for significant stability, default: 0.07
%
%OUTPUT:
%none

%MODIFICATION LIST:
% 
%------------------------------------------------------------
%% Defaults
fth = 0.07;
rowdim = 'stages';
rlabels = {'S1';'S2';'S3';'S4';'REM';'Wake'};

%number of signals
ns = sqrt(size(tds,2))
slabels = num2str((1:ns)');
separator = ' - ';

whos labels
%% Check for input vars
%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %samplingfrequency
        if strcmp(varargin{i},'fth')
            sf = varargin{i+1};
        %labels
        elseif strcmp(varargin{i},'slabels')
            slabels = varargin{i+1};
        elseif strcmp(varargin{i},'rlabels')
            rlabels = varargin{i+1};
        elseif strcmp(varargin{i},'rowdim')
            rowdim = varargin{i+1};
        end
    end
end

%get unique combinations
C = nchoosek((1:ns),2);
%indices of unique combinations
keepvector = (C(:,1)-1)*ns+C(:,2);

%tds_unique
tds_unique = tds(:,keepvector)';

%create slabels
separatorvector = repmat(separator,length(C),1);
labelvector = [slabels(C(:,1),:) separatorvector slabels(C(:,2),:)];

%for stages,
if strcmp(rowdim,'stages')
    tds_unique(tds_unique < fth) = 0;
end

%plot tds
imagesc(tds_unique)
set(gca,'ytick',[1:length(C)],'yticklabel',labelvector);

%Stage labels
if strcmp(rowdim,'stages')
   set(gca,'xtick',[1:size(tds,1)],'xticklabel',rlabels);
   xlabel('Sleep Stages')
else 
    xlabel('t[30s]')
end


%end function
end





