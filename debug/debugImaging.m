function [info,Config] = debugImaging(ImageFile)


%% UI input
if ~exist('ImageFile', 'var') || isempty(ImageFile)
    [ImageFile,p] = uigetfile({'*.sbx;*.tif;*.imgs'}, 'Choose corresponding Image File to process', cd);
    if isnumeric(ImageFile) % no file selected
        return
    end
    ImageFile = fullfile(p,ImageFile);
end
fprintf('Analyzing ''%s'':\n',ImageFile);


%% Determine # of trials
[p,fn,~] = fileparts(ImageFile);
InfoFile = fullfile(p, strcat(fn,'.mat'));
load(InfoFile, 'info', '-mat');
fprintf('\t%d trigger(s) received (line 1: %d, line 2: %d)\n',numel(info.frame), nnz(info.event_id==1), nnz(info.event_id==2));


%% Determine # of frames
Config = load2PConfig(ImageFile);
fprintf('\tFile contains: %d frame(s), %d channel(s), %d depth(s)\n',Config.Frames,Config.Channels,Config.Depth);
fprintf('\tData captured at: %f Hz\n',Config.FrameRate);