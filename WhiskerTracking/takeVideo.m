function Images = takeVideo(numTrials, FrameRate, Duration)

numFrames = 150;

if ~exist('numTrials', 'var')
    numTrials = 1;
end

if ~exist('FrameRate', 'var')
    FrameRate = 150;
end

if ~exist('Duration', 'var')
    Duration = 1;
end

numFrames = round(Duration*FrameRate);
Duration = numFrames/FrameRate;

vid = videoinput('pointgrey', 1, 'F7_Raw8_1280x1024_Mode0');
src = getselectedsource(vid);
vid.FramesPerTrigger = numFrames;
vid.LoggingMode = 'disk';
scan
% triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode0-Source0'); % acquire 1 frame per triger
triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode0-Source0'); % aquire X number of frames per trigger

diskLogger = VideoWriter('C:\Users\Resonant-2\OneDrive\test.avi', 'Grayscale AVI');
vid.DiskLogger = diskLogger;
diskLogger.FrameRate = FrameRate;

%% Start imaging
preview(vid);
start(vid);

%% Stop acquiring images (and save to disk if necessary)
stop(vid);

Images = getdata(vid);
save('D:\OneDrive\MATLAB\test_0002.mat', 'Images');
clear Images;