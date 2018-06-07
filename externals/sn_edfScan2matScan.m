function [header,signalHeader,signalCell] = sn_edfScan2matScan(varargin)
% reads edf in matlab struct, based on blockEdfLoad
%-----------------------------------------------------------
% Dagmar Krefting, 3.12.2015, dagmar.krefting@htw-berlin.de
% Version: 1.1
% Credits: Based on blockEdfLoad by Dennis Dean (2012)
% Dennis A. Dean, II, Ph.D
%
% Program for Sleep and Cardiovascular Medicine
% Brigam and Women's Hospital
% Harvard Medical School
% 221 Longwood Ave
% Boston, MA  02149
%-----------------------------------------------------------
%
%USAGE: [header,signalheader,signalcell] = sn_edfScan2matScan('data',filename, varargin)

% INPUT:
%'data'             name and full path of original edf-file
%                   Default: not set
%OPTIONAL INPUT:
%
%'debug'            Debug flag, Default: 0
%
% OUTPUT:
%          header : A structure containing variables for each header entry
%    signalHeader : A structured array containing signal information,
%                   for each structure present in the data
%      signalCell : A cell array that contains the data for each signal
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
%% Defaults

% Defaults from original blockEdfLoad not be set here
% Operation Flags
RETURN_PHYSICAL_VALUES = 1;
signalLabels = {};      % Labels of signals to return
epochs = [];            % Start and end epoch to return

% debuginformation
debug = false;

%% Get optional parameters

%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %outputfile
        if strcmp(varargin{i},'data')
            filename = varargin{i+1};
            %header
        elseif strcmp(varargin{i},'debug')
            debug = varargin{i+1};
        end
    end
end

%% Start function
if debug
    disp('Welcome to sn_edfScan2matScan')
end

%% Part from blockEdLoad
%-------------------------------------------------------------- Input check
% Check that first argument is a string
if   ~ischar(filename)
    msg = ('Filename is not set or not a string.');
    error(msg);
end

%---------------------------------------------------  Load File Information
% Load edf header to memory
[fid, msg] = fopen(filename);

% Proceed if file is valid
if fid <0
    % file id is not valid
    error(msg);
end

% Open file for reading
% Load file information not used in this version but will be used in
% class version
[filename, permission, machineformat, encoding] = fopen(fid);

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

if debug
    header
end
% End Header Load section

%------------------------------------------------------- Load Signal Header
try
    % Load signal header into memory in one load
    edfSignalHeaderSize = header.num_header_bytes - headerSize;
    [A count] = fread(fid, edfSignalHeaderSize);
    if debug
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
if debug
    disp(['num_signal_header_vars : ',num2str(num_signal_header_vars)])
end
num_signals = header.num_signals;
if debug
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
if debug
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
    if debug
        disp(['Total number of values: ' num2str(count)])
    end
    
    %num_data_records
catch exception
    error(errMsg);
end
%------------------------------------------------- Process Signal Block
% Get values to reshape block
num_data_records = header.num_data_records;
if debug
    disp(['Number of data records : ',num2str(num_data_records)])
end
getSignalSamplesF = @(x)signalHeader(x).samples_in_record;
signalSamplesPerRecord = arrayfun(getSignalSamplesF,[1:num_signals]);
if debug
    disp(['signalSamplesPerRecord : ',num2str(signalSamplesPerRecord)])
end
recordWidth = sum(signalSamplesPerRecord);
if debug
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
            filename);
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