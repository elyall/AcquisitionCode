function [AnalysisInfo, frames] = behaviorPostProcess(info, DataIn, data, numFrames, varargin)


numFramesBefore = 0; % numeral
saveOut = false;
SaveFile = '';

%% Parse input arguments
if ~exist('info', 'var') || isempty(info)
    directory = cd;
    [info,p] = uigetfile({'*.mat'}, 'Choose scanbox info file', directory);
    if isnumeric(info)
        return
    end
    info = fullfile(p,info);
end

if ~exist('DataIn', 'var') || isempty(DataIn)
    directory = cd;
    [DataIn,p] = uigetfile({'*.bin'}, 'Choose NI-DAQ DataIn File', directory);
    if isnumeric(DataIn)
        return
    end
    DataIn = fullfile(p,DataIn);
end

if ~exist('data', 'var') || isempty(data)
    directory = cd;
    [data,p] = uigetfile({'*.txt'}, 'Choose stimulation text file', directory);
    if isnumeric(data)
        return
    end
    data = fullfile(p,data);
end

if ~exist('numFrames', 'var') || isempty(numFrames)
    directory = cd;
    [numFrames,p] = uigetfile({'*.sbx;*.tiff;*.imgs'}, 'Choose images file', directory);
    if isnumeric(numFrames)
        return
    end
    numFrames = load2PConfig(fullfile(p,numFrames));
    numFrames = numFrames.Frames;
end
    
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'numFramesBefore'
                numFramesBefore = varargin{index+1};
                index = index + 2;
            case 'Save'
                saveOut = true;
                index = index + 1;
            case 'SaveFile'
                SaveFile = varargin{index+1};
                index = index + 1;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

if saveOut && isempty(SaveFile)
    warning('Cannot save output as no file specified');
    saveOut = false;
end

%% Load in data

% Image info
if ischar(info)
    InfoFile = info;
    load(InfoFile, 'info');
end
if iscellstr(numFrames)
    ImageFiles = numFrames;
    Config = load2PConfig(ImageFiles);
    numFrames = sum([Config(:).Frames]);
end

% Stim info
if ischar(data)
    TextFile = data;
    data = csvread(TextFile);
end
numScans = size(data, 1);

%% Determine number of trials
[TrialIndex, temp] = unique(data(:,6));
nTrials = numel(TrialIndex);
nImagingTrials = numel(info.frame)/2;

%% Initialize output
AnalysisInfo = table(zeros(nTrials,1),zeros(nTrials,1),zeros(nTrials,1),cell(nTrials,1),zeros(nTrials,1),zeros(nTrials,1),zeros(nTrials,2),zeros(nTrials,2),zeros(nTrials,2), zeros(nTrials,2),zeros(nTrials,2),zeros(nTrials,2),zeros(nTrials,2),zeros(nTrials,2),...
    'VariableNames', {'StimID', 'TrialIndex', 'ImgIndex', 'ImgFilename', 'nFrames', 'nScans', 'ExpStimFrames', 'ExpStimScans', 'StimFrameLines', 'EventIDs', 'TrialStimFrames', 'TrialStimScans', 'ExpFrames', 'ExpScans'});
frames = struct('Stimulus', nan(numFrames,1), 'Trial', nan(numFrames,1));

AnalysisInfo = [AnalysisInfo, table(cell(nTrials,1),cell(nTrials,1),cell(nTrials,1),cell(nTrials,1),'VariableNames',{'Clock','Lick','MotorPosition','Reward'})];
frames.Lick = nan(numFrames,1);
frames.MotorPosition = nan(numFrames,1);
frames.Reward = nan(numFrames,1);
frames.RunningSpeed = nan(numFrames, 1);

%% Process and parse experiment

% AnalysisInfo.ImgFilename = ImageFile;
AnalysisInfo.TrialIndex = TrialIndex;
AnalysisInfo.StimID = data(temp, 11);
for tindex = 1:nTrials
    
    % Imaging data
    if tindex <= nImagingTrials %assumes first trial is recorded but possibly not last trial
        AnalysisInfo.ImgIndex(tindex) = tindex;
        AnalysisInfo.ExpStimFrames(tindex, :) = info.frame((tindex-1)*2+1:tindex*2);
        frames.Stimulus(AnalysisInfo.ExpStimFrames(tindex,1):AnalysisInfo.ExpStimFrames(tindex,2)) = AnalysisInfo.StimID(tindex);
        AnalysisInfo.StimFrameLines(tindex, :) = info.line((tindex-1)*2+1:tindex*2);
        AnalysisInfo.EventIDs(tindex, :) = info.event_id((tindex-1)*2+1:tindex*2);
        AnalysisInfo.TrialStimFrames(tindex, :) = [numFramesBefore + 1, numFramesBefore + diff(AnalysisInfo.ExpStimFrames(tindex, :)) + 1];
        AnalysisInfo.ExpFrames(tindex, 1) = AnalysisInfo.ExpStimFrames(tindex, 1) - numFramesBefore;
        if tindex > 1
            AnalysisInfo.ExpFrames(tindex-1, 2) = AnalysisInfo.ExpFrames(tindex, 1) - 1;
            AnalysisInfo.nFrames(tindex-1) = diff(AnalysisInfo.ExpFrames(tindex-1, :))+1;
        end
        frames.Trial(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)) = tindex;
    end
    if tindex == nImagingTrials
        AnalysisInfo.ExpFrames(tindex, 2) = numFrames;
        AnalysisInfo.nFrames(tindex) = diff(AnalysisInfo.ExpFrames(tindex, :))+1;
    end
    
    
    % Behavior data
    AnalysisInfo.ExpStimScans(tindex, 1) = find(data(:,6)==AnalysisInfo.TrialIndex(tindex), 1, 'first');
    index = AnalysisInfo.ExpStimScans(tindex, 1);
    while data(index, 2) == 1 && index < numScans
        index = index + 1;
    end
    AnalysisInfo.ExpStimScans(tindex, 2) = index;
    AnalysisInfo.TrialStimScans(tindex, :) = [1, diff(AnalysisInfo.ExpStimScans(tindex, :))+1];
    AnalysisInfo.ExpScans(tindex, :) = [AnalysisInfo.ExpStimScans(tindex, 1), find(data(:,6)==AnalysisInfo.TrialIndex(tindex), 1, 'last')];
    AnalysisInfo.nScans(tindex) = diff(AnalysisInfo.ExpScans(tindex, :))+1;
    
    % Clock information
    AnalysisInfo.Clock{tindex} = data(AnalysisInfo.ExpScans(tindex, 1):AnalysisInfo.ExpScans(tindex, 2), 7);
    
    % Lick information
    AnalysisInfo.Lick{tindex} = data(AnalysisInfo.ExpScans(tindex, 1):AnalysisInfo.ExpScans(tindex, 2), 4);
    
    % Motor position
    AnalysisInfo.MotorPosition{tindex} = data(AnalysisInfo.ExpScans(tindex, 1):AnalysisInfo.ExpScans(tindex, 2), 1);
    
    % Reward information
    AnalysisInfo.Reward{tindex} = data(AnalysisInfo.ExpScans(tindex, 1):AnalysisInfo.ExpScans(tindex, 2), 3);
    
end

% Parse continuous data to be frame-wise
for tindex = 1:nImagingTrials
    clockTimes = AnalysisInfo.Clock{tindex}-AnalysisInfo.Clock{tindex}(1);
    
    frameTimes = 0:clockTimes(end)/(AnalysisInfo.nFrames(tindex)-1):clockTimes(end);
    frames.MotorPosition(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)) = interp1(clockTimes, AnalysisInfo.MotorPosition{tindex}, frameTimes);
    
    nSamplesPerFrame = 1000;
    upSampleTimes = 0:clockTimes(end)/(AnalysisInfo.nFrames(tindex)*nSamplesPerFrame-1):clockTimes(end);
    upSampledLick = round(interp1(clockTimes, AnalysisInfo.Lick{tindex}, upSampleTimes));
    upSampledReward = round(interp1(clockTimes, AnalysisInfo.Reward{tindex}, upSampleTimes));
    frames.Lick(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)) = any(reshape(upSampledLick, nSamplesPerFrame, AnalysisInfo.nFrames(tindex)), 1);
    frames.Reward(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)) = any(reshape(upSampledReward, 1000, AnalysisInfo.nFrames(tindex)), 1);
    
%     figure('Units', 'Pixels', 'Position', [100,100,900,900]);
%     subplot(1,3,1);
%     plot(frameTimes, frames.Lick(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)), 'b');
%     hold on
%     plot(clockTimes, AnalysisInfo.Lick{tindex}, 'r--');
% 
%     subplot(1,3,2);
%     plot(frameTimes, frames.MotorPosition(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)), 'b');
%     hold on
%     plot(clockTimes, AnalysisInfo.MotorPosition{tindex}, 'r--');
%     legend('Frames', 'Arduino');
%     
%     subplot(1,3,3);
%     plot(frameTimes, frames.Reward(AnalysisInfo.ExpFrames(tindex,1):AnalysisInfo.ExpFrames(tindex,2)), 'b');
%     hold on
%     plot(clockTimes, AnalysisInfo.Reward{tindex}, 'r--');
%     
%     drawnow
end

if saveOut
    save(SaveFile, 'AnalysisInfo', 'frames', '-append');
end
