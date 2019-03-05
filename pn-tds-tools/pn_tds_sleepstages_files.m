function [meantds,nsis,hypnogram] = pn_tds_sleepstages_files(varargin)
% a wrapper for pn_tds_sleepstages, that loads the respective files
%
% cli:
%   cwlVersion: v1.0-extended
%   class: matlabfunction
%   baseCommand: [meantds,nsis,hypnogram] = pn_tds_sleepstages_files(varargin)
%   inputs:
%     data:
%       type: matlab-archive
%       inputBinding:
%         prefix: data
%       doc: "matlab-archive with tds matrix containing TDS, col: signal, row: time. Time resolution
% needs to match the resolution of the hypnogram (30 s)"
%     debug:
%       type: int?
%       inputBinding:
%         prefix: debug
%       doc: "if set to 1 debug information is provided. Default 0"
%     hypnogramfile:
%       type: file
%       inputBinding:
%         prefix: hypnogram
%       doc: "edf with hypnogram"
%     hypnogramfileformat:
%       type: string?
%       inputBinding:
%         prefix: hypnogramfileformat
%       doc: "devicename, that has different hypnogram-format.
%                   Default: 'edf'
%                   Currently supported: alice6, compumedics"
%     hypno_coding:
%       type: matlab-archive
%       inputBinding:
%         prefix: hypno_coding
%       doc: "matfile containing the hypno_coding struct"
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
%     outputfile_appendix:
%       type: string
%       inputBinding:
%         prefix: outputfile_appendix
%       doc: "string, that will be appended to the basename before '_stages.mat'. Default ''.  "
%   outputs:
%     matfile:
%       type: File
%       outputBinding:
%         glob: *_tds_stages.mat
%       doc: "A matfile containing meantds, nsis and the hypnogram"
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Parse Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% required input
myinput.data = NaN;
myinput.hypnogramfile = NaN;
%% optional input
myinput.debug = 0;
%default: siesta hypnogram encoding
myinput.hypnogramfileformat = 'edf';
myinput.hypno_coding = struct('Awake',0,'REM',5,'NREM1',1,'NREM2',2,'NREM3',3,'NREM4',4,'artefacts',9);
myinput.scoring_scheme = 'simplified';
myinput.remove_transitions = 0;
myinput.outputfile_appendix = '';

try
    myinput = mt_parameterparser('myinputstruct',myinput,'varargins',varargin);
catch ME
    disp(ME)
    return
end

if (myinput.debug)
    myinput
    disp('Welcome to pn_tds_sleepstages_files')
end

debug = myinput.debug;
data = myinput.data;
hypnogramfile = myinput.hypnogramfile;
hypnogramfileformat = myinput.hypnogramfileformat;

% check if deployed and set numeric parameters 
%if ~isdeployed
%    debug=logical(debug);
%    myinput.remove_transitions=logical(myinput.remove_transitions);
%end
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Read files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%read matfile
if debug
    disp(['Reading matlab-archive: ' data ])
end

load(data);

% read hypnogram

if debug
    disp(['Reading hypnogramfile: ' hypnogramfile ' with format ' hypnogramfileformat])
end

%read hypnogramfile
if(strcmp(hypnogramfileformat,'edf'))
    %read from edf
    [~,~,signalcells]= sn_edfScan2matScan('data', hypnogramfile);
    %extract hypnogram from cell
    hypnogram = signalcells{1};
elseif(strcmp(hypnogramfileformat,'compumedics'))
    %read from SLPSTAG.DAT
    [ hypnogram ] = sn_readSlp_hypnogram(hypnogramfile);
elseif(strcmp(hypnogramfileformat,'compumedicsXML'))
    %read from edf.XML
    [ hypnogram ] = sn_readcompumedicsXML_hypnogram('data',hypnogramfile);
elseif(strcmp(hypnogramfileformat,'alice6'))
    %read from rlm
    [ hypnogram ] = sn_readAlice6_hypnogram(hypnogramfile);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. call pn_tds_sleepstages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meantds = '';
nsis = '';

[meantds,nsis,hypnogram] = pn_tds_sleepstages('data',tds,...
    'hypnogram',hypnogram,...
    'debug',myinput.debug,...
    'hypnogramfileformat',myinput.hypnogramfileformat,...
    'hypno_coding',myinput.hypno_coding,...
    'scoring_scheme',myinput.scoring_scheme,...
    'remove_transitions',myinput.remove_transitions);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Create filename and save data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[pathstr,basename,ext] = fileparts(myinput.data);

archivename = [basename myinput.outputfile_appendix '_stages.mat'];
if(debug);disp(['Writing results to: ' archivename]);end
save(archivename,'meantds','nsis','hypnogram');


