function [header,signalHeader,signalCell] = sn_edfScan2matScan(varargin)
%reads edf in matlab struct, based on blockEdfLoad. it corrects only for
%edf incompatibility, not for edf+. 
%
% cli:
%   cwlVersion: v1.0-extended
%   class: matlabfunction
%   baseCommand: [events,extrema] = sn_edfScan2matScan(varargin)
%
%   inputs:
%     data:
%       type: file
%       inputBinding:
%         prefix: data
%       doc: "name and full path of original edf-file"
%     debug:  
%       type: int?
%       inputBinding:
%         prefix: debug
%       doc: "if set to 1 debug information is provided. Default 0"
%
%   outputs:
%     header:
%       type: matlab-struct
%       doc: "A structure containing variables for each header entry"
%     signalHeader:
%       type: matlab-struct-array
%       doc: "A struc-array containing edf signal headers"
%     signalCell:
%       type: matlab-cell-array
%       doc: "A cell array that contains the data for each signal"
%
%   s:author:
%     - class: s:Person
%       s:identifier:  https://orcid.org/0000-0002-7238-5339
%       s:email: mailto:dagmar.krefting@htw-berlin.de
%       s:name: Dagmar Krefting
% 
%   s:dateCreated: "2019-01-12"
%   s:license: https://spdx.org/licenses/Apache-2.0 
% 
%   s:keywords: edam:topic_3063, edam:topic_2082
%     doc: 3063: medical informatics, 2082: matrix
%   s:programmingLanguage: matlab
%   s:isBasedOn: https://github.com/DennisDean/BlockEdfLoad
% 
%   $namespaces:
%     s: https://schema.org/
%     edam: http://edamontology.org/
% 
%   $schemas:
%     - https://schema.org/docs/schema_org_rdfa.html
%     - http://edamontology.org/EDAM_1.18.owl
%
% Output Structures:
%    header:
%       edf_ver
%       patient_id
%       local_rec_id
%       recording_startdate
%       recording_starttime
%       num_header_bytes
%       reserve_1
%       num_data_records
%       data_record_duration
%       num_signals
%    signalHeader (structured array with entry for each signal):
%       signal_labels
%       tranducer_type
%       physical_dimension
%       physical_min
%       physical_max
%       digital_min
%       digital_max
%       prefiltering
%       samples_in_record
%       reserve_2
%
%MODIFICATION LIST:
%------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0. Parse Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% required input
myinput.data = NaN;
% dimension to be averaged
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Define Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults from original blockEdfLoad not be set here
% Operation Flags
RETURN_PHYSICAL_VALUES = 1;
signalLabels = {};      % Labels of signals to return
epochs = [];            % Start and end epoch to return


%% Start function
if (myinput.debug)
    disp('Welcome to sn_edfScan2matScan')
end

%% Part from blockEdLoad
%-------------------------------------------------------------- Input check
% Check that first argument is a string
if   ~ischar(myinput.data)
    msg = ('Filename is not set or not a string.');
    error(msg);
end

%---------------------------------------------------  Load File Information
% Load edf header to memory
[fid, msg] = fopen(myinput.data);

% Proceed if file is valid
if fid <0
    % file id is not valid
    error(msg);
end

% Open file for reading
% Load file information not used in this version but will be used in
% class version
[myinput.data, permission, machineformat, encoding] = fopen(fid);

%-------------------------------------------------------------- Load Header
try
    % Load header information in one call
    edfHeaderSize = 256;
    [A count] = fread(fid, edfHeaderSize);
    %whos A
catch exception
    msg = 'File load error. Check available memory.';
    error(msg);
end

%----------------------------------------------------- Process Header Block
% Create array/cells to create struct with loop
headerVariables = {...
    'edf_ver';            'patient_id';         'local_rec_id'; ...
    'recording_startdate';'recording_starttime';'num_header_bytes'; ...
    'reserve_1';          'num_data_records';   'data_record_duration';...
    'num_signals'};
headerVariablesConF = {...
    @strtrim;   @strtrim;   @strtrim; ...
    @strtrim;   @strtrim;   @str2num; ...
    @strtrim;   @str2num;   @str2num;...
    @str2num};
headerVariableSize = [ 8; 80; 80; 8; 8; 8; 44; 8; 8; 4];
headerVarLoc = vertcat([0],cumsum(headerVariableSize));
headerSize = sum(headerVariableSize);

% Create Header Structure
header = struct();
for h = 1:length(headerVariables)
    conF = headerVariablesConF{h};
    value = conF(char((A(headerVarLoc(h)+1:headerVarLoc(h+1)))'));
    header = setfield(header, headerVariables{h}, value);
end

if (myinput.debug)
    header
end
% End Header Load section

%% check for errors in header

% occured errors:
% siesta-data: starttime separator is colon, not dot
if ~isempty(strfind(header.recording_starttime,':'));
    disp('Correcting separator of starttime')
    header.recording_starttime = strrep(header.recording_starttime,':','.');
end

%------------------------------------------------------- Load Signal Header
try
    % Load signal header into memory in one load
    edfSignalHeaderSize = header.num_header_bytes - headerSize;
    [A count] = fread(fid, edfSignalHeaderSize);
    if (myinput.debug)
        whos A
    end
catch exception
    msg = 'File load error. Check available memory.';
    error(msg);
end

%------------------------------------------ Process Signal Header Block
% Create array/cells to create struct with loop
signalHeaderVar = {...
    'signal_labels'; 'transducer_type'; 'physical_dimension'; ...
    'physical_min'; 'physical_max'; 'digital_min'; ...
    'digital_max'; 'prefiltering'; 'samples_in_record'; ...
    'reserve_2' };
signalHeaderVarConvF = {...
    @strtrim; @strtrim; @strtrim; ...
    @str2num; @str2num; @str2num; ...
    @str2num; @strtrim; @str2num; ...
    @strtrim };
%number of Variables in Header - should be 10
num_signal_header_vars = length(signalHeaderVar);
if (myinput.debug)
    disp(['num_signal_header_vars : ',num2str(num_signal_header_vars)])
end
num_signals = header.num_signals;
if (myinput.debug)
    disp(['num_signals : ',num2str(num_signals)])
end
signalHeaderVarSize = [16; 80; 8; 8; 8; 8; 8; 80; 8; 32];
signalHeaderBlockSize = sum(signalHeaderVarSize)*num_signals;
signalHeaderVarLoc = vertcat([0],cumsum(signalHeaderVarSize*num_signals));
signalHeaderRecordSize = sum(signalHeaderVarSize);

% Create Signal Header Struct
signalHeader = struct(...
    'signal_labels', {},'transducer_type', {},'physical_dimension', {}, ...
    'physical_min', {},'physical_max', {},'digital_min', {},...
    'digital_max', {},'prefiltering', {},'samples_in_record', {},...
    'reserve_2', {});

% Get each signal header variable
for v = 1:num_signal_header_vars
    varBlock = A(signalHeaderVarLoc(v)+1:signalHeaderVarLoc(v+1))';
    varSize = signalHeaderVarSize(v);
    conF = signalHeaderVarConvF{v};
    for s = 1:num_signals
        varStart = varSize*(s-1)+1;
        varEnd = varSize*s;
        value = conF(char(varBlock(varStart:varEnd)));
        
        structCmd = ...
            sprintf('signalHeader(%.0f).%s = value;',s, signalHeaderVar{v});
        eval(structCmd);
    end
end
% End Signal Load Section
if (myinput.debug)
    signalHeader
end

%-------------------------------------------------------- Load Signal Block
% Read digital values to the end of the file
try
    % Set default error mesage
    errMsg = 'File load error. Check available memory.';
    
    % Load entire file
    [A count] = fread(fid, 'int16');
    %whos A
    if (myinput.debug)
        disp(['Total number of values: ' num2str(count)])
    end
    
    %num_data_records
catch exception
    error(errMsg);
end
%------------------------------------------------- Process Signal Block
% Get values to reshape block
num_data_records = header.num_data_records;
if (myinput.debug)
    disp(['Number of data records : ',num2str(num_data_records)])
end
getSignalSamplesF = @(x)signalHeader(x).samples_in_record;
signalSamplesPerRecord = arrayfun(getSignalSamplesF,[1:num_signals]);
if (myinput.debug)
    disp(['signalSamplesPerRecord : ',num2str(signalSamplesPerRecord)])
end
recordWidth = sum(signalSamplesPerRecord);
if (myinput.debug)
    disp(['Recordwidth : ',num2str(recordWidth)])
end
%whos A
%Modification by Dagmar Krefting
%check for invalid num_data_records
if (num_data_records == -1)
    disp('Invalid number of data records, calculating correct value...')
    num_data_records = count/recordWidth;
    disp(['Number of data records: ' num2str(num_data_records)])
end
%num_data_records
% Reshape - Each row is a data record
%check if calculated and given datanumrecords are identical
if( (count/recordWidth) ~= num_data_records)
    msg = (['Given number of records: ' num2str(num_data_records)...
        ' does not match calculated number: ' num2str(count/recordWidth)...
        ' . File maybe corrupted.']);
    error(msg);
end

A = reshape(A, recordWidth, num_data_records)';

% Create raw signal cell array
signalCell = cell(1,num_signals);
signalLocPerRow = horzcat([0],cumsum(signalSamplesPerRecord));
for s = 1:num_signals
    % Get signal location
    signalRowWidth = signalSamplesPerRecord(s);
    signalRowStart = signalLocPerRow(s)+1;
    signaRowEnd = signalLocPerRow(s+1);
    
    % Create Signal
    signal = reshape(A(:,signalRowStart:signaRowEnd)',...
        signalRowWidth*num_data_records, 1);
    
    % Get scaling factors
    dig_min = signalHeader(s).digital_min;
    dig_max = signalHeader(s).digital_max;
    phy_min = signalHeader(s).physical_min;
    phy_max = signalHeader(s).physical_max;
    
    % Assign signal value
    value = signal;
    
    % Convert to phyical units
    if RETURN_PHYSICAL_VALUES == 1
        % Convert from digital to physical values
        value = (signal-dig_min)/(dig_max-dig_min);
        value = value.*double(phy_max-phy_min)+phy_min;
    else
        fprintf('Digital to Physical conversion is NOT performned: %s\n',...
            data);
    end
    
    signalCell{s} = value;
end

% End Signal Load Section

%------------------------------------------------------ Create return value
% Close file explicitly
if fid > 0
    fclose(fid);
end

%% end of blockEdfLoad

end % End of blockEdfLoad function