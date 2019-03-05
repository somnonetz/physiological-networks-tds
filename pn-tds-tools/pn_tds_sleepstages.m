function [meantds,nsis,hypnogram] = pn_tds_sleepstages(varargin)
% calculates the fraction of stable TDS for different sleep stages
%
% cli:
%   cwlVersion: v1.0-extended
%   class: matlabfunction
%   baseCommand: [meantds,nsis,hypnogram] = pn_tds_sleepstages(varargin)
%   inputs:
%     data:
%       type: matlab-array
%       inputBinding:
%         prefix: data
%       doc: "tds matrix containing TDS, col: signal, row: time. Time resolution
% needs to match the resolution of the hypnogram (30 s)"
%     debug:
%       type: int?
%       inputBinding:
%         prefix: debug
%       doc: "if set to 1 debug information is provided. Default 0"
%     hypnogram:
%       type: matlab-array
%       inputBinding:
%         prefix: hypnogram
%       doc: "hypnogram-array"
%     hypno_coding:
%       type: matlab-struct?
%       inputBinding:
%         prefix: hypno_coding
%       doc: "struct with fields the following fields: 'Wake','REM','NREM1','NREM2','NREM3','NREM4','artefacts')"
%     scoring_scheme:
%       type: string
%       inputBinding:
%         prefix: scoring_scheme
%       doc: "Default: 'simplified' is only 4 sleep stages (DS,LS,
%                       REM, WAKE)
%                       'RK': 6 sleep stages according to Rechtschaffen and
%                       Kales
%                       'AASM': 5 sleep stages according to AASM 2007"
%     remove_transitions:
%       type: int?
%       inputBinding:
%         prefix: remove_transitions
%       doc: "flag for removing transition tds-epochs. Default 0 (off), 1 = on"
%   outputs:
%     table.csv:
%       type: file
%       doc: "A csv extended by the number of epoch and the sleep stage"
%
%   s:author:
%     - class: s:Person
%       s:identifier:  https://orcid.org/0000-0002-7238-5339
%       s:email: mailto:dagmar.krefting@htw-berlin.de
%       s:name: Dagmar Krefting
%
%   s:dateCreated: "2018-12-08"
%   s:license: https://spdx.org/licenses/Apache-2.0
%
%   s:keywords: edam:topic_3063, edam:topic_2082
%     doc: 3063: medical informatics, 2082: matrix
%   s:programmingLanguage: matlab
%
%   $namespaces:
%     s: https://schema.org/
%     edam: http://edamontology.org/
%
%   $schemas:
%     - https://schema.org/docs/schema_org_rdfa.html
%     - http://edamontology.org/EDAM_1.18.owl
%
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Parse Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% required input
myinput.data = NaN;
myinput.hypnogram = NaN;
%% optional input
myinput.debug = 0;
myinput.hypno_coding = struct('Awake',0,'REM',5,'NREM1',1,'NREM2',2,'NREM3',3,'NREM4',4,'artefacts',9);
myinput.scoring_scheme = 'simplified';
myinput.remove_transitions = 0;

try
    myinput = mt_parameterparser('myinputstruct',myinput,'varargins',varargin);
catch ME
    disp(ME)
    return
end

if (myinput.debug)
    myinput;
    disp('Welcome to pn_tds_sleepstages')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Adjust length of hypnogram and tds 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% simplify variables
hypnogram = myinput.hypnogram;
tds = myinput.data;
debug = myinput.debug;
scoring_scheme = myinput.scoring_scheme;
hypno_coding = myinput.hypno_coding;

%% reduce hypnogram to length of tds
if(length(hypnogram) ~= size(tds,1))
    hypnogram = hypnogram(1:min(length(hypnogram),size(tds,1)));
    tds = tds(1:min(length(hypnogram),size(tds,1)),:);
end


%% adjust for scoring scheme

%number of sleep stages (nss)
if (strcmp(scoring_scheme,'simplified'))
    % number of sleep stages
    nss = 4;
    %simplify hypnogram
    if debug; disp('merging NREM3 and NREM4'); end
    hypnogram(hypnogram == hypno_coding.NREM4) = hypno_coding.NREM3;
elseif (strcmp(scoring_scheme,'AASM'))
    % number of sleep stages
    nss = 5;
elseif (strcmp(scoring_scheme,'RK'))
    % number of sleep stages
    nss = 6;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Set transition epochs as artefacts 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% remove sleep stage borders
if myinput.remove_transitions
    if debug; disp('Epochs containing stage transitions are set as artefact'); end
    
    %remove the epochs at the border of the stages: assign them to artifact
     dhyp = zeros(4,length(hypnogram)-1);
    %front border, last epoch of previous transition
    dhyp(1,:) = abs(diff(hypnogram));
    for k = 2:4
    dhyp(k,:) = [dhyp(k-1,2:end), 0];
    end
    tds_trans = sum(dhyp);
    if (debug && ~isdeployed)
    whos tds_trans
    plot(dhyp')
    hold on 
    plot(tds_trans)
    hold off
    end
    %set the respective epochs to artifacts
    hypnogram(tds_trans ~= 0) = hypno_coding.artefacts;
end

%allocate buffer for meantdss
meantds = zeros(size(tds,2),nss);
%number of samples in stage
nsis = zeros(nss,1);

if (strcmp(scoring_scheme,'RK'))
    for i = 0:nss-1
        %samples in stage
        sis = (hypnogram == i);
        nsis(i+1) = sum(sis);
        %fraction of stable sequences in stage
        meantds(:,i+1) = sum(tds(sis,:))/sum(sis);
    end
elseif (strcmp(scoring_scheme,'simplified'))
    %DS
    %samples in stage
    sis = (hypnogram == hypno_coding.NREM3);
    nsis(1) = sum(sis);
    %fraction of stable sequences in stage
    meantds(:,1) = sum(tds(sis,:),1)/sum(sis);
    %LS
    %samples in stage, take only S2 (S1 is inbetween LS and Awake)
    sis = (hypnogram == hypno_coding.NREM2);
    nsis(2) = sum(sis);
    %fraction of stable sequences in stage
    meantds(:,2) = sum(tds(sis,:),1)/sum(sis);
    %REM
    %samples in stage
    sis = (hypnogram == hypno_coding.REM);
    nsis(3) = sum(sis);
    %fraction of stable sequences in stage
    meantds(:,3) = sum(tds(sis,:),1)/sum(sis);
    %AWAKE
    %samples in stage
    sis = (hypnogram == hypno_coding.Awake);
    nsis(4) = sum(sis);
    %fraction of stable sequences in stage
    meantds(:,4) = sum(tds(sis,:),1)/sum(sis);
else
    disp('Sorry, not yet implemented')
end

%reshape meantds
meantds = reshape(meantds,sqrt(size(tds,2)),sqrt(size(tds,2)),nss);
end

