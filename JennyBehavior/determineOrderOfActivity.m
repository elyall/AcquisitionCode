function [ROIorder, MaxResponse] = determineOrderOfActivity(ROIdata, ROIid, TrialID, StimID, varargin)

datatype = 'dFoF'; % 'dFoF' or 'raw'
zscoreby = 'none'; % 'all' or 'individual' or 'none'
avgTrials = false;
type = 'max'; % 'max' or value to threshold

%% Check input arguments
if ~exist('ROIdata','var') || isempty(ROIdata)
    directory = CanalSettings('DataDirectory');
    [ROIFile, p] = uigetfile({'*.mat'},'Choose ROI file',directory);
    if isnumeric(ROIFile)
        return
    end
    ROIFile = fullfile(p,ROIFile);
    load(ROIFile, 'ROIdata');
elseif ischar(ROIdata)
    load(ROIdata, 'ROIdata');
end
if ~exist('ROIid','var') || isempty(ROIid)
    ROIid = 'all';
end
if ~exist('TrialID','var') || isempty(TrialID)
    TrialID = 1;
end
if ~exist('StimID','var')
    StimID = [];
end

index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'datatype'
                datatype = varargin{index+1};
                index = index + 2;
            case 'avg'
                avgTrials = true;
                index = index + 1;
            case 'zscoreby'
                zscoreby = varargin{index+1};
                index = index + 2;
            case 'type'
                type = varargin{index+1};
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

%% Determine ROIs
if ischar(ROIid)
    ROIid = 1:numel(ROIdata.rois);
end
numROIs = numel(ROIid);

%% Determine trials
if ischar(TrialID) && strcmp(TrialID, 'all')
    if isempty(StimID)
        TrialID = 1:numel(ROIdata.DataInfo.TrialIndex);
    else
        TrialID = 1:sum(ROIdata.DataInfo.StimID == StimID);
    end
end
numTrials = numel(TrialID);

%% Determine order
numFrames = ROIdata.DataInfo.numFramesBefore + ROIdata.DataInfo.numFramesAfter + 1;
data = nan(numROIs, numFrames, numTrials);
for tindex = 1:numTrials
    
    % Determine trial info
    if isempty(StimID)
        TrialIndex = TrialID(tindex);
    else
        TrialIndex = find(ROIdata.DataInfo.StimID == StimID);
        TrialIndex = TrialIndex(TrialID(tindex));
    end
    
    % Extract data
    for rindex = 1:numROIs
        switch datatype
            case 'dFoF'
                data(rindex,:,tindex) = ROIdata.rois(ROIid(rindex)).dFoF(TrialIndex,:);
            case 'raw'
                data(rindex,:,tindex) = ROIdata.rois(ROIid(rindex)).data(TrialIndex,:);
        end
    end
      
    % Z-score data
    switch zscoreby
        case 'all'
            data = reshape(zscore(data(:)),numROIs,numFrames);
        case 'individual'
            data = zscore(data, [], 2);
    end
    
end

if avgTrials
    data = mean(data,3);
    numTrials = 1;
end

ROIorder = nan(numROIs, numTrials);
MaxResponse = nan(numROIs, numTrials);
for tindex = 1:numTrials
    switch type
        case 'max'
            [valResponse, timeResponse] = max(data(:,:,tindex), [], 2);
        otherwise
            timeResponse = nan(numROIs, 1);
            valResponse = nan(numROIs, 1);
            for rindex = 1:numROIs
                time = find(data(rindex, :, tindex) > type, 1, 'first');
                if ~isempty(time)
                    timeResponse(rindex) = time;
                    valResponse(rindex) = data(rindex, timeResponse(rindex), tindex);
                end
            end
    end
    [~, ROIorder(:,tindex)] = sort(timeResponse);
    MaxResponse(:,tindex) = valResponse(ROIorder(:,tindex));
end

