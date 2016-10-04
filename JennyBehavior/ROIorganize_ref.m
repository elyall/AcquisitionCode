function ROIdata = ROIorganize_ref(ROIdata, AnalysisInfo, frames, ROIid, reference, varargin)

saveOut = false;

TrialIndex = [1 inf];
numFramesBefore = 100; % '[]' for default
numFramesAfter = 150; % '[]' for default
saveFile = '';
SeriesVariables = {}; % strings of fieldnames in 'frames' struct to extract to be trial-wise

index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Trials','trials'}
                TrialIndex = varargin{index+1};
                index = index + 2;
            case 'numFramesBefore'
                numFramesBefore = varargin{index+1};
                index = index + 2;
            case 'numFramesAfter'
                numFramesAfter = varargin{index+1};
                index = index + 2;
            case 'Save'
                saveOut = true;
                index = index + 1;
            case 'SaveFile'
                saveFile = varargin{index+1};
                index = index + 2;
            case 'SeriesVariables'
                SeriesVariables = varargin{index+1};
                index = index + 2;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end


%% Parse input arguments
if ~exist('ROIdata','var') || isempty(ROIdata)
    directory = CanalSettings('DataDirectory');
    [ROIdata, p] = uigetfile({'*.mat'},'Choose ROI file',directory);
    if isnumeric(ROIdata)
        return
    end
    ROIdata = fullfile(p,ROIdata);
end

if ~exist('AnalysisInfo','var') || isempty(AnalysisInfo)
    directory = CanalSettings('ExperimentDirectory');
    [AnalysisInfo, p] = uigetfile({'*.mat'},'Choose Experiment file',directory);
    if isnumeric(AnalysisInfo)
        return
    end
    AnalysisInfo = fullfile(p,AnalysisInfo);
end

index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Trials','trials'}
                TrialIndex = varargin{index+1};
                index = index + 2;
            case 'numFramesBefore'
                numFramesBefore = varargin{index+1};
                index = index + 2;
            case 'numFramesAfter'
                numFramesAfter = varargin{index+1};
                index = index + 2;
            case 'Save'
                saveOut = true;
                index = index + 1;
            case 'SaveFile'
                saveFile = varargin{index+1};
                index = index + 2;
            case 'SeriesVariables'
                SeriesVariables = varargin{index+1};
                index = index + 2;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

%% Load stimulus information and determine trials to pull-out
if ischar(AnalysisInfo)
    load(AnalysisInfo, 'AnalysisInfo', '-mat');
end 

% Determine trials to extract
if TrialIndex(end)==inf
    TrialIndex = cat(2, TrialIndex(end-1), TrialIndex(end-1)+1:size(AnalysisInfo, 1));
end
TrialIndex(AnalysisInfo.ImgIndex(TrialIndex)==0) = []; % remove non-imaged trials
numTrials = numel(TrialIndex);

% Determine frame indices for each trial
totalFrames = numFramesBefore + 1 + numFramesAfter;
PositionIndex = [reference(AnalysisInfo.ExpStimFrames(TrialIndex, 1)) - numFramesBefore, reference(AnalysisInfo.ExpStimFrames(TrialIndex, 1)) + numFramesAfter];
FrameIndex = nan(numTrials, 2);
for tindex = 1:numTrials
    if tindex==1
        FrameIndex(1, 1) = AnalysisInfo.ExpStimFrames(1, 1);
    else
        FrameIndex(tindex, 1) = find(reference(1:AnalysisInfo.ExpStimFrames(tindex, 1))<PositionIndex(tindex,1), 1, 'last');
    end
    FrameIndex(tindex, 2) = find(reference(AnalysisInfo.ExpStimFrames(tindex, 1)+1:end)>PositionIndex(tindex,2), 1, 'first') + AnalysisInfo.ExpStimFrames(tindex,1);
end


%% Determine series data to reshape
if ~isempty(SeriesVariables)
    seriesNames = fieldnames(frames);
    for sindex = numel(SeriesVariables):-1:1
        if ~strcmp(SeriesVariables{sindex}, seriesNames)
            warning('Series variable %s not found', SeriesVariables{sindex});
            SeriesVariables(sindex) = [];
        end
    end
end


%% Load ROI information and determine ROIs to reshape
if ischar(ROIdata)
    ROIFile = ROIdata;
    load(ROIFile, 'ROIdata', '-mat'); % load in roi data
    if saveOut && isempty(saveFile)
        saveFile = ROIFile;
    end
end
if saveOut && isempty(saveFile)
    warning('Cannot save output as no file specified');
    saveOut = false;
end
numROIs = numel(ROIdata.rois);

% Determine ROIs to extract signals for
if ischar(ROIid) && strcmp(ROIid, 'all')
    numROIs = numel(ROIdata.rois);
    ROIid = 1:numROIs;
end

% Organize neuropil data?
neuropil = false;
if isfield(ROIdata.rois, 'rawneuropil')
    neuropil = true;
end

%% Format each type of data to be trial-wise
ROIdata.DataInfo.TrialIndex = TrialIndex;
ROIdata.DataInfo.StimID = AnalysisInfo.StimID(TrialIndex);
ROIdata.DataInfo.numFramesBefore = numFramesBefore;
ROIdata.DataInfo.numStimFrames = zeros(numel(TrialIndex), 1);
ROIdata.DataInfo.numFramesAfter = numFramesAfter;

% Format series variables
% if ~isempty(SeriesVariables)
%     for sindex = 1:numel(SeriesVariables)
%         series.(SeriesVariables{sindex}) = nan(numTrials, totalFrames);
%         for nindex = 1:numTrials
%             series.(SeriesVariables{sindex})(nindex,:) = frames.(SeriesVariables{sindex})(FrameIndex(nindex,1):FrameIndex(nindex,2));
%         end
%     end
% else
%     series = [];
% end

% Format ROIs
% warning('off', 'MATLAB:polyfit:RepeatedPointsOrRescale');
for rindex = ROIid
    ROIdata.rois(rindex).data = nan(numTrials, totalFrames);
    if neuropil
        ROIdata.rois(rindex).neuropil = nan(numTrials, totalFrames);
    end
    
    for nindex = 1:numTrials
        
        try
%             [P,S] = polyfit(reference(FrameIndex(nindex,1):FrameIndex(nindex,2))', ROIdata.rois(rindex).rawdata(FrameIndex(nindex,1):FrameIndex(nindex,2)), 4);
%             ROIdata.rois(rindex).data(nindex,:) = polyval(P,PositionIndex(nindex,1):PositionIndex(nindex,2));
%             if neuropil
%                 [P,S] = polyfit(reference(FrameIndex(nindex,1):FrameIndex(nindex,2))', ROIdata.rois(rindex).rawneuropil(FrameIndex(nindex,1):FrameIndex(nindex,2)), 4);
%                 ROIdata.rois(rindex).neuropil(nindex,:) = polyval(P,PositionIndex(nindex,1):PositionIndex(nindex,2));
%             end
            
            ROIdata.rois(rindex).data(nindex,:) = interp1(reference(FrameIndex(nindex,1):FrameIndex(nindex,2)),ROIdata.rois(rindex).rawdata(FrameIndex(nindex,1):FrameIndex(nindex,2)),PositionIndex(nindex,1):PositionIndex(nindex,2));
            if neuropil
                ROIdata.rois(rindex).neuropil(nindex,:) = interp1(reference(FrameIndex(nindex,1):FrameIndex(nindex,2)),ROIdata.rois(rindex).rawneuropil(FrameIndex(nindex,1):FrameIndex(nindex,2)),PositionIndex(nindex,1):PositionIndex(nindex,2));
            end
            
%             figure; hold on;
%             plot(reference(FrameIndex(nindex,1):FrameIndex(nindex,2)),  ROIdata.rois(rindex).rawdata(FrameIndex(nindex,1):FrameIndex(nindex,2)),'r*');
%             plot(PositionIndex(nindex,1):PositionIndex(nindex,2), ROIdata.rois(rindex).data(nindex,:),'b--');
        catch
            % multiple of same x-value exist
            currentFrames = FrameIndex(nindex,1):FrameIndex(nindex,2);
            [positions, ~, index] = unique(reference(currentFrames));
            currentData = ROIdata.rois(rindex).rawdata(currentFrames);
            if neuropil
                currentNeuropil = ROIdata.rois(rindex).rawneuropil(currentFrames);
            end
            bad = [];
            for pindex = 1:numel(positions)
                temp = find(index==pindex);
                if numel(temp)>1
                    currentData(temp) = mean(ROIdata.rois(rindex).rawdata(currentFrames(temp)));
                    if neuropil
                        currentNeuropil(temp) = mean(ROIdata.rois(rindex).rawneuropil(currentFrames(temp)));
                    end
                    bad = [bad; temp(2:end)];
                end
            end
            currentData(bad) = [];
            currentNeuropil(bad) = [];
            currentFrames(bad) = [];
            ROIdata.rois(rindex).data(nindex,:) = interp1(reference(currentFrames),currentData,PositionIndex(nindex,1):PositionIndex(nindex,2));
            if neuropil
                ROIdata.rois(rindex).neuropil(nindex,:) = interp1(reference(currentFrames),currentNeuropil,PositionIndex(nindex,1):PositionIndex(nindex,2));
            end
%             warning('More frames requested than in ROIdata, filling rest with NaNs');
%             temp = ROIdata.rois(rindex).rawdata(FrameIndex(nindex,1):end);
%             ROIdata.rois(rindex).data(nindex,1:numel(temp)) = temp;
%             if neuropil
%                 ROIdata.rois(rindex).neuropil(nindex,1:numel(temp)) = interp1(reference(FrameIndex(nindex,1):FrameIndex(nindex,2)),ROIdata.rois(rindex).rawdata(FrameIndex(nindex,1):FrameIndex(nindex,2)),PositionIndex(nindex,1):PositionIndex(nindex,2));
%             end
        end
    end
end


%% Save to file
if saveOut
    % Save basic data
    if ~exist(saveFile, 'file')
        save(saveFile, 'ROIdata', 'Data', 'Neuropil', 'AnalysisInfo');
    else
        save(saveFile, 'ROIdata', 'Data', 'Neuropil', 'AnalysisInfo', '-append');
    end
    % Save series data
    if ~isempty(series)
        save(saveFile, 'series', '-append');
    end
    fprintf('ROIdata saved to: %s\n', saveFile);
end
