function [TrialInfo,DataIn] = debugExperiment(ExpFile)


%% UI input
if ~exist('ExpFile', 'var') || isempty(ExpFile)
    [ExpFile,p] = uigetfile({'*.exp'}, 'Choose corresponding Image File to process', cd);
    if isnumeric(ExpFile) % no file selected
        return
    end
    ExpFile = fullfile(p,ExpFile);
end
if exist(ExpFile,'file')
    fprintf('Analyzing ''%s'':\n',ExpFile);
else
    error('File %s does not exist!',ExpFile);
end


%% Load in data

% Load in experiment
load(ExpFile, 'DAQChannels', 'Experiment', 'TrialInfo', '-mat');

% Load binary DAQ data
[p,fn,~] = fileparts(ExpFile);
DataInFile = fullfile(p, strcat(fn,'.bin')); %[strtok(StimFile, '.'),'_datain.bin'];
DataInFID = fopen(DataInFile, 'r');
DataIn = fread(DataInFID, inf, Experiment.saving.dataPrecision);
fclose(DataInFID);


%% Determine # of trials
fprintf('\t%d trials(s) presented:\n',numel(TrialInfo.StimID));
StimIDs = unique(TrialInfo.StimID);
for sindex = 1:numel(StimIDs)
    fprintf('\t\t%d stim %d\n',nnz(TrialInfo.StimID==StimIDs(sindex)), StimIDs(sindex));
end


%% Determine DAQ outputs
OutputNames = DAQChannels(~cellfun(@isempty,strfind(DAQChannels, 'O_')));
fprintf('\tOutput channels: '); fprintf('%s ',OutputNames{:}); fprintf('\n');
if any(ismember(OutputNames,'O_2PTrigger'))
    temp = Experiment.Triggers(:,strcmp(OutputNames,'O_2PTrigger'),1);
    fprintf('\t\t''O_2PTrigger'': %d triggers per trial\n',nnz((temp-[0;temp(1:end-1)])>0));
end


%% Determine DAQ inputs
InputNames = DAQChannels(~cellfun(@isempty,strfind(DAQChannels, 'I_')));
nInputChannels = numel(InputNames);
DataIn = reshape(DataIn, nInputChannels, numel(DataIn)/nInputChannels)';
fprintf('\tInput channels: '); fprintf('%s ',InputNames{:}); fprintf('\n');
if any(ismember(InputNames,'I_FrameCounter'))
    temp = DataIn(:,strcmp(InputNames,'I_FrameCounter'),1);
    fprintf('\t\t''I_FrameCounter'': %d frames recorded\n',nnz((temp-[0;temp(1:end-1)])>0));
end
if any(ismember(InputNames,'I_RunWheelA'))
    temp = DataIn(:,strcmp(InputNames,'I_RunWheelA'),1);
    if any(temp)
        fprintf('\t\t''RunWheel'': running recorded\n');
    else
        fprintf('\t\t''RunWheel'': NO running recorded\n');
    end
end
if any(ismember(InputNames,'I_WhiskerTracker'))
    temp = DataIn(:,strcmp(InputNames,'I_WhiskerTracker'),1);
    if any(temp)
        fprintf('\t\t''I_WhiskerTracker'': %d frames recorded\n',nnz((temp-[0;temp(1:end-1)])>0));
    else
        fprintf('\t\t''I_WhiskerTracker'': NO frames recorded\n');
    end
end
