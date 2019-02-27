function [T] = pn_tds_biosignalscsv_hypnogram(varargin)
%reads varargins of a function and gives back the parsed parameters Compumedics dpsg files and converts in matlab struct
%
% cli:
%   cwlVersion: v1.0-extended
%   class: matlabfunction
%   baseCommand: [column_names] = pn_tds_biosignalscsv_hypnogram(varargin)
%
%   inputs:
%     data:
%       type: csv
%       inputBinding:
%         prefix: data
%       doc: "A csv created with pn_tds_biosignal2csv"
%     debug:
%       type: int?
%       inputBinding:
%         prefix: debug
%       doc: "if set to 1 debug information is provided. Default 0"
%     hypnogram:
%       type: edf
%       inputBinding:
%         prefix: hypnogram
%       doc: "the corresponding hypnogram in edf-format"
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
% Notes
% It is based on the montage identifiers eeg, eog,

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Parse Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% required input
myinput.data = NaN;
myinput.hypnogram = NaN;
myinput.debug = 0;

try
    myinput = mt_parameterparser('myinputstruct',myinput,'varargins',varargin);
catch ME
    disp(ME)
    return
end

if (myinput.debug)
    myinput
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Load file and construct the column names
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load csv file
d = readtable(myinput.data);

% read hypnogram
[h,sh,s] = sn_edfScan2matScan('data',myinput.hypnogram);
hypnogram = s{1};

%expand to 30 values (one epoch is 30 seconds
hypnofull = repmat(hypnogram,1,30);
hypnofull = reshape(hypnofull',30*length(hypnogram),1);

% create epoch index 
epoch_index = (1:length(hypnogram))';
%expand to 30 values
epoch_index = repmat(epoch_index,1,30);
epoch_index = reshape(epoch_index',30*length(hypnogram),1);

%create a table with epochs and sleepstage
T = array2table([epoch_index,hypnofull],'Variablenames',{'epoch';'sleepstage'});

%correct for different table heights
minheight = min(height(d),height(T));

%cut tables
T = T(1:minheight,:);
d = d(1:minheight,:);

%concatenate both tables
T = [T d];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Create table and write csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[pathstr,basename,ext] = fileparts(myinput.data);

tablename = [basename '_hypno.csv'];
writetable(T,tablename);


