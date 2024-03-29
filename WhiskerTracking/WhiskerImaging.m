function WhiskerImaging

% Initialize Saving
gd.Internal.save.path = strcat('E:\Evan\',datestr(now,'yymmdd'));
gd.Internal.save.base = '0000_c2';
gd.Internal.save.index = 1;
gd.Internal.save.filename = fullfile(gd.Internal.save.path, strcat(gd.Internal.save.base, num2str(gd.Internal.save.index),'.raw'));

% Initialize Imaging
gd.Internal.imaging.port = 'COM5';
inputs = {...
    'Brightness','',1.5625;...
    'FrameRate','Manual',200;...
    'Gain','Manual',2.823;...
    'Shutter','Manual',0.984};
%     'Exposure','Manual',0.8287;... % exposure doesn't do anything for the flea3

% Display parameters
Display.units = 'pixels';
Display.position = [300, 200, 1200, 700];


%% Generate GUI

% Create figure
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Whisker Imaging',...
    'Units',                Display.units,...
    'Position',             Display.position,...
    'ToolBar',              'none',...
    'MenuBar',              'none',...
    'DeleteFcn',            @(hObject,eventdata)closeFig(hObject,eventdata,guidata(hObject)));

% Create panels
gd.gui.file.panel = uipanel(...
    'Title',                'File Information',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .8, .2, .2]);
gd.gui.control.panel = uipanel(...
    'Title',                'Controls',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, 0, .2, .8]);
gd.gui.axes.panel = uipanel(...
    'Title',                'Video',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.2, .25, .8, .75]);
gd.gui.sliders.panel = uipanel(...
    'Title',                'Settings',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.2, 0, .8, .25]);

% Create file selection
% select directory
gd.gui.file.dir = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Dir',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,.5,.3,.5],...
    'Callback',             @(hObject,eventdata)ChooseDir(hObject, eventdata, guidata(hObject)));
% basename input
gd.gui.file.base = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.base,...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.5,.5,.5],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject)));
% file index
gd.gui.file.index = uicontrol(...
    'Style',                'edit',...
    'String',               num2str(gd.Internal.save.index),...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.5,.2,.5],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject)));
% display filename
gd.gui.file.filename = uicontrol(...
    'Style',                'text',...
    'String',               '',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.5]);

% Create controls
% preview control
gd.gui.control.preview = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Preview',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,1,.2],...
    'Callback',             @(hObject,eventdata)PreviewImages(hObject, eventdata, guidata(hObject)));
% snap control
gd.gui.control.snap = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Take Frame',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.6,1,.2],...
    'Callback',             @(hObject,eventdata)TakeFrame(hObject, eventdata, guidata(hObject)));
% trigger control
gd.gui.control.trigger = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Trigger: External',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.5,1,.1],...
    'Callback',             @(hObject,eventdata)ChangeSource(hObject, eventdata, guidata(hObject)));
% frames per trigger
gd.gui.control.framesPerTrigger = uicontrol(...
    'Style',                'edit',...
    'String',               '1',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.4,.2,.1],...
    'Callback',             @(hObject,eventdata)ChangeFramesPerTrigger(hObject, eventdata, guidata(hObject)));
gd.gui.control.framesPerTriggerText = uicontrol(...
    'Style',                'text',...
    'String',               'Frames Per Trigger:',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.425,.79,.05],...
    'HorizontalAlignment',  'right');
% new file toggle
gd.gui.control.newFilePerTrigger = uicontrol(...
    'Style',                'popupmenu',...
    'String',               {'Single File','New File Per Trigger'},...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.35,1,.05]);
% image control
gd.gui.control.run = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Capture Images?',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.2],...
    'BackgroundColor',      [0,1,0],...
    'Callback',             @(hObject,eventdata)CaptureImages(hObject, eventdata, guidata(hObject)));

% Create Axes
% axes
gd.gui.axes.axes = axes(...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [.2,0,.8,1]);
axis square off
% format selector
gd.gui.axes.format = uicontrol(...
    'Style',                'popupmenu',...
    'String',               {'1280x960','640x512'},...
    'Value',                2,...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.9,.2,.1],...
    'Callback',             @(hObject,eventdata)initCamera(guidata(hObject)));
% frames acquired counter
gd.gui.axes.acqCounter = uicontrol(...
    'Style',                'text',...
    'String',               'Frames Acquired: 0',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,.2,.1],...
    'HorizontalAlignment',  'right');
% frames acquired counter
gd.gui.axes.saveCounter = uicontrol(...
    'Style',                'text',...
    'String',               'Frames Saved: 0',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.75,.2,.1],...
    'HorizontalAlignment',  'right');
% test frame rate
gd.gui.axes.testFrameRate = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Test Frame Rate',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.1,.2,.1],...
    'Callback',             @(hObject,eventdata)TestFrameRate(hObject, eventdata, guidata(hObject)));
% frame rate text
gd.gui.axes.FrameRate = uicontrol(...
    'Style',                'text',...
    'String',               'frame rate: ',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.025,.2,.05],...
    'HorizontalAlignment',  'left');

% Settings
gd.Internal.settings.modes = {'Off','Manual','Auto'};
% inputs
gd.Internal.settings.num = size(inputs,1);
gd.Internal.settings.handles = [];
h = 1/gd.Internal.settings.num;
for index = 1:gd.Internal.settings.num
    b = (gd.Internal.settings.num-index)*h;
    gd.gui.sliders.text.(inputs{index,1}) = uicontrol(...
        'Style',                'text',...
        'String',               sprintf('%s: %.3f',inputs{index,1},.5),...
        'Parent',               gd.gui.sliders.panel,...
        'Units',                'normalized',...
        'Position',             [0,b,.15,h],...
        'HorizontalAlignment',  'right');
    gd.gui.sliders.(inputs{index,1}) = uicontrol(...
        'Style',                'slider',...
        'Parent',               gd.gui.sliders.panel,...
        'Units',                'normalized',...
        'Position',             [.15,b,.75,h],...
        'UserData',             inputs{index,1},...
        'Min',                  0,...
        'Max',                  2,...
        'Value',                1,...
        'Callback',             @(hObject,eventdata)ChangeSetting(hObject, eventdata, guidata(hObject)));
    gd.Internal.settings.handles = [gd.Internal.settings.handles,gd.gui.sliders.(inputs{index,1})];
    val = find(strcmp(gd.Internal.settings.modes,inputs{index,2}));
    if ~isempty(val)
        gd.gui.sliders.state.(inputs{index,1}) = uicontrol(...
            'Style',                'popupmenu',...
            'String',               gd.Internal.settings.modes,...
            'Parent',               gd.gui.sliders.panel,...
            'Units',                'normalized',...
            'UserData',             inputs{index,1},...
            'Position',             [.9,b,.1,h],...
            'Value',                val,...
            'Callback',             @(hObject,eventdata)ToggleAuto(hObject, eventdata, guidata(hObject)));
            gd.Internal.settings.handles = [gd.Internal.settings.handles,gd.gui.sliders.state.(inputs{index,1})];
    else
        gd.gui.sliders.state.(inputs{index,1}) = [];
    end
end
gd.Internal.settings.inputs = inputs;

gd = CreateFilename(gd);
try
    gd = initCamera(gd);
catch ME
    error('Problem connecting to camera -> try ''imaqreset'' (may need to open FlyCap2 and set camera to Mode 0)');
end
guidata(gd.gui.fig,gd);
end

function closeFig(hObject,eventdata,gd)
% delete(imaqfind);
close(hObject);
end

%% File Saving
function ChooseDir(hObject, eventdata, gd)
temp = uigetdir(gd.Internal.save.path, 'Choose directory to save to');
if ischar(temp)
    gd.Internal.save.path = temp;
    guidata(hObject, gd);
end
gd=CreateFilename(gd);
guidata(hObject,gd);
end

function gd=CreateFilename(gd)
gd.Internal.save.filename = fullfile(gd.Internal.save.path, strcat(gd.gui.file.base.String, '_', gd.gui.file.index.String, '.avi'));
gd.gui.file.filename.String = gd.Internal.save.filename;
if exist(gd.Internal.save.filename, 'file')
    gd.gui.file.filename.BackgroundColor = [1,0,0];
else
    gd.gui.file.filename.BackgroundColor = [.94,.94,.94];
end
guidata(gd.gui.fig,gd);
end

%% Initialization
function gd = initCamera(gd)
if isfield(gd,'vid')
    delete(gd.vid);
end
gd.vid = videoinput('pointgrey', 1, 'F7_Raw8_640x512_Mode1');
% if gd.gui.axes.format.Value == 1
%     gd.vid = videoinput('pointgrey', 1, 'F7_Mono8_1280x1024_Mode0');
% elseif gd.gui.axes.format.Value == 2
%     gd.vid = videoinput('pointgrey', 1, 'F7_Mono8_640x512_Mode1');
% end
gd.src = getselectedsource(gd.vid);
gd.vid.ReturnedColorspace = 'grayscale';

% Set camera settings
for index = 1:gd.Internal.settings.num
    str = gd.Internal.settings.inputs{index,1};
    val = gd.Internal.settings.inputs{index,3};
    
    % Set limits
    temp = propinfo(gd.src,str);                            % determine limits
    gd.gui.sliders.(str).Min = temp.ConstraintValue(1);     % set lower bound
    gd.gui.sliders.(str).Max = temp.ConstraintValue(2);     % set upper bound
    
    % Set mode
    if ~isempty(gd.gui.sliders.state.(str))
        gd.src.(sprintf('%sMode',str)) = gd.Internal.settings.modes{gd.gui.sliders.state.(str).Value}; % set mode
    end
    
    % Set value
    if val<temp.ConstraintValue(1)      % ensure value is above lower bound
        val = temp.ConstraintValue(1);
    elseif val>temp.ConstraintValue(2)  % ensure value is below upper bound
        val = temp.ConstraintValue(2);
    end
    gd.src.(str) = val;                 % set value
    gd.gui.sliders.(str).Value = val;   % update gui slider
    gd.gui.sliders.text.(str).String = sprintf('%s: %.3f',str,val); % update gui text
    
end
gd.src.TriggerDelayMode = 'Off'; %'Off' or 'Manual'
% gd.src.TriggerDelay = 0;

% Create out pulses
gd.src.Strobe2 = 'On';
gd.src.Strobe2Polarity = 'High';

guidata(gd.gui.fig,gd);
end


%% Change settings
function ChangeSource(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Trigger: Internal','BackgroundColor',[0,0,0],'ForegroundColor',[1,1,1]);
else
    set(hObject,'String','Trigger: External','BackgroundColor',[.94,.94,.94],'ForegroundColor',[0,0,0]);
end
end

function ChangeSetting(hObject, eventdata, gd)
gd.src.(hObject.UserData) = hObject.Value; % set camera value
guidata(hObject,gd);
gd.gui.sliders.text.(hObject.UserData).String = sprintf('%s: %.3f',hObject.UserData,hObject.Value); % update value shown on gui
end

function ToggleAuto(hObject, eventdata, gd)
mode = gd.Internal.settings.modes{hObject.Value};   % determine mode
gd.src.(sprintf('%sMode',hObject.UserData)) = mode; % set mode
if ismember(mode,{'Off','Auto'})                    % update whether slider is enabled
    gd.gui.sliders.(hObject.UserData).Enable = 'off';
else
    gd.gui.sliders.(hObject.UserData).Enable = 'on';
end
guidata(hObject,gd);
end

function gd = TestFrameRate(hObject, eventdata, gd)
triggerconfig(gd.vid, 'immediate'); % set trigger type
gd.vid.FramesPerTrigger = 100;      % set number of frames to capture
gd.vid.LoggingMode = 'memory';      % set to log frames to memory
start(gd.vid);                      % start acquisition
wait(gd.vid,120);                   % wait for acquisition to stop
[f,t,m] = getdata(gd.vid);          % acquire timestamps
frameRate = 1/mean(diff(t));        % calculate framerate
guidata(hObject,gd);                % save guidata
gd.gui.axes.FrameRate.String = sprintf('frame rate: %.2f', frameRate); % display frame rate
end

%% Imaging
function TakeFrame(hObject, eventdata, gd)
frame = getsnapshot(gd.vid);
axes(gd.gui.axes.axes);
imagesc(frame); 
colormap gray; axis square off
end

function PreviewImages(hObject, eventdata, gd)
if hObject.Value
    axes(gd.gui.axes.axes);
    hImage = image(zeros(gd.vid.VideoResolution));
    preview(gd.vid, hImage);
    axis square off
    hObject.String = 'Stop Preview';
else
    stoppreview(gd.vid);
    hObject.String = 'Preview';
end
guidata(hObject,gd);
end

function gd = createFile(gd)
gd.vid.LoggingMode = 'disk'; %disk&memory
[p,~]=fileparts(gd.Internal.save.filename);
if ~exist(p,'dir')
    mkdir(p);
end
DiskLogger = VideoWriter(gd.Internal.save.filename, 'Grayscale AVI');
DiskLogger.FrameRate = gd.Experiment.imaging.frameRate;
gd.vid.DiskLogger = DiskLogger;
end

function CaptureImages(hObject, eventdata, gd)
if hObject.Value
    
    % Update GUI
    set(hObject,'String','Stop','BackgroundColor',[1,0,0]);
    set([gd.gui.file.dir,gd.gui.file.base,gd.gui.file.index],'Enable','off');
    set([gd.gui.control.trigger,gd.gui.control.snap,gd.gui.axes.format],'Enable','off');
    set(gd.Internal.settings.handles,'Enable','off');
    
    % Set frame rate
    gd.Experiment.imaging.frameRate = gd.gui.sliders.FrameRate.Value;
    
    % Set trigger properties
    if gd.gui.control.trigger.Value
        triggerconfig(gd.vid, 'immediate'); % internal
        gd.vid.FramesPerTrigger = Inf;
    else
        triggerconfig(gd.vid, 'hardware', 'risingEdge', 'externalTriggerMode0-Source0'); % external
        gd.vid.FramesPerTrigger = str2double(gd.gui.control.framesPerTrigger.String);
        if ~gd.gui.control.newFilePerTrigger.Value
            gd.vid.TriggerRepeat = Inf;
        else
            gd.vid.TriggerRepeat = 0;
        end
    end    
    
    % Reset camera and frame counter
    flushdata(gd.vid);
    gd.gui.axes.acqCounter.String = 'Frames Acquired: 0';
    
    % Create file and start recording
    if gd.gui.control.newFilePerTrigger.Value == 1  % save all frames to one file
        
        % Start file
        gd = createFile(gd);
        start(gd.vid);
        
        % Wait for user to stop acquisition
        while hObject.Value
            pause(.5);
            gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
            gd.gui.axes.saveCounter.String = sprintf('Frames Saved: %d',gd.vid.DiskLoggerFrameCount);
        end
        
    else                                            % save invidiual triggers to different files
        filecounter = 1;
        while hObject.Value
            
            % Start file
            gd = createFile(gd);
            start(gd.vid);
            
            % Wait for all frames to be recorded to current file
            while gd.vid.DiskLoggerFrameCount < gd.vid.FramesPerTrigger
                % wait(gd.vid, 60); % wait until gd.vid.FramesPerTrigger are acquired or until 60s has elapsed
                pause(.01);
                gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
                gd.gui.axes.saveCounter.String = sprintf('Frames Saved: %d',gd.vid.DiskLoggerFrameCount);
            end
            
            % Stop current file
            stop(gd.vid);
            fprintf('Finished %d: %d frames saved to: %s\n',filecounter,gd.vid.DiskLoggerFrameCount,gd.Internal.save.filename);
            filecounter = filecounter + 1;
            
            % MEMORY LOGGING: Save data to file
            % [data, time, metadata] = getdata(gd.vid); % gather frames
            % flushdata(vid,'triggers'); % remove oldest frames
            % save(filename, 'data', 'time', 'metadata', '-mat', '-v7.3');
            
            % Prepare next file
            gd.gui.file.index.String = num2str(str2double(gd.gui.file.index.String) + 1);
            gd = CreateFilename(gd);
        end
    end
    
else
    % Stop recording
    hObject.String = 'Stopping...';
    stop(gd.vid);
    
    % Update frame count
    gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
    gd.gui.axes.saveCounter.String = sprintf('Frames Saved: %d',gd.vid.DiskLoggerFrameCount);
    
    % Make sure all frames get saved to disk
    while gd.vid.FramesAcquired ~= gd.vid.DiskLoggerFrameCount
        pause(.1);
        gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
        gd.gui.axes.saveCounter.String = sprintf('Frames Saved: %d',gd.vid.DiskLoggerFrameCount);
    end
    
    % Index filename
    if gd.vid.DiskLoggerFrameCount~=0
        fprintf('Finished: %d frames saved to: %s\n',gd.vid.DiskLoggerFrameCount,gd.Internal.save.filename);
        gd.gui.file.index.String = num2str(str2double(gd.gui.file.index.String) + 1);
        gd = CreateFilename(gd);
    end
    
    % Update GUI
    guidata(hObject,gd);
    set([gd.gui.file.dir,gd.gui.file.base,gd.gui.file.index],'Enable','on');
    set([gd.gui.control.trigger,gd.gui.control.snap,gd.gui.axes.format],'Enable','on');
    set(gd.Internal.settings.handles,'Enable','on');
    set(hObject,'String','Capture Images?','BackgroundColor',[0,1,0]);
end
end