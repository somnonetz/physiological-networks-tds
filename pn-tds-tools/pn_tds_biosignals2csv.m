function [column_names] = pn_tds_biosignals2csv(varargin)
%reads varargins of a function and gives back the parsed parameters Compumedics dpsg files and converts in matlab struct
%
% cli:
%   cwlVersion: v1.0-extended
%   class: matlabfunction
%   baseCommand: [column_names] = pn_tds_biosignals2csv(varargin)
%
%   inputs:
%     data:
%       type: matlab-archive
%       inputBinding:
%         prefix: data
%       doc: "A matlab archive containing all tds output, typically called *_tds_all.mat"
%     debug:  
%       type: int?
%       inputBinding:
%         prefix: debug
%       doc: "if set to 1 debug information is provided. Default 0"
%     montage:
%       type: textfile?
%       inputBinding:
%         prefix: montage
%       doc: "A Textfile containing the type of the channels"
%     headers:
%       type: matlab-archive?
%       inputBinding:
%         prefix: headers
%       doc: "A matlab-archive containing the header and signal header of original EDF"
%   outputs:
%     table.csv:
%       type: file
%       doc: "A csv containing the signal names in the first row."
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
myinput.eegbands = [{'delta';'theta';'alpha';'sigma';'beta'}];
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

% Load file
d = load(myinput.data)

% overwrite montage if present as parameter
if isfield(myinput,'montage')
    fid = fopen(myinput.montage);
    m_tmp = textscan(fid,'%s');
    d.montage = m_tmp{1};
    fclose(fid);
end

% overwrite montage if present as parameter
if isfield(myinput,'headers')
    load(myinput.headers);
    d.signalheader = signalheader;
end


% create cell array for the column names
column_names = cell(1);

%loop over montage
for i = 1:length(d.montage)
    switch d.montage{i}
        case 'eeg'
            %% add frequency bands
            column_names = [column_names;strcat(myinput.eegbands,['_' d.signalheader(i).signal_labels])]       
        case 'eog'
            %% add Variance and name
            column_names = [column_names;['Var_' d.signalheader(i).signal_labels]]       
        case 'emg'
            %% add Variance and name
            column_names = [column_names;['Var_' d.signalheader(i).signal_labels]]       
        case 'ecg'
            %% add Variance and name
            column_names = [column_names;['HR_' d.signalheader(i).signal_labels]]       
        case 'resp'
             %% add Variance and name
            column_names = [column_names;['BR_' d.signalheader(i).signal_labels]]       
        otherwise
            disp('signal type unknown, skipping')
    end
end

%remove first element, as ist was the initializing empty cell
column_names(1) = []

% replace colon by minus
column_names = regexprep(column_names,':','_')
column_names = regexprep(column_names,' ','_')
column_names = regexprep(column_names,'\.','_')
column_names = regexprep(column_names,'-','_')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Create table and write csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[pathstr,basename,ext] = fileparts(myinput.data); 

T = array2table(d.biosignals_tds,'VariableNames',column_names);
tablename = [basename '.csv'];
writetable(T,tablename);


