function ROIdata = gaussFilterROIs(ROIdata, ROIid, sigma, width)

%% Parse input arguments
if ~exist('ROIdata','var') || isempty(ROIdata)
    directory = CanalSettings('DataDirectory');
    [ROIdata, p] = uigetfile({'*.mat'},'Choose ROI file',directory);
    if isnumeric(ROIdata)
        return
    end
    ROIdata = fullfile(p,ROIdata);
end

if ~exist('ROIid', 'var')
    ROIid = [1 inf];
elseif ischar(ROIid) && strcmp(ROIid, 'all')
    ROIid = [1 inf];
end

if ~exist('sigma', 'var')
    sigma = 1;
end

if ~exist('width', 'var')
    width = 5;
end


%% Load in data
if ischar(ROIdata)
    load(ROIdata, 'ROIdata');
end


%% Determine ROIs to filter
if ROIid(end) == inf
    ROIid = [ROIid(1:end-1), ROIid(1:end-1)+1:numel(ROIdata.rois)];
end


%% Create filter
x = linspace(-width / 2, width / 2, width);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize


%% Filter data
for rindex = ROIid
    ROIdata.rois(ROIid(rindex)).rawdata = conv(ROIdata.rois(ROIid(rindex)).rawdata, gaussFilter, 'same');
    if isfield(ROIdata.rois(1), 'rawneuropil')
        ROIdata.rois(ROIid(rindex)).rawneuropil = conv(ROIdata.rois(ROIid(rindex)).rawneuropil, gaussFilter, 'same');
    end
end

