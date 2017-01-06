function [TrialInfo, SaveFile] = stimPoleAzimuth(SaveFile, numConditions, varargin)

if ~exist('numConditions','var')
    numConditions = 1;
end

%% Configure Settings
gd.Internal.ImagingType = 'scim';               % 'sbx' or 'scim'
gd.Internal.ImagingComp.ip = '128.32.173.30';   % SCANBOX ONLY: for UDP
gd.Internal.ImagingComp.port = 7000;            % SCANBOX ONLY: for UDP

Display.units = 'pixels';
Display.position = [400, 400, 1400, 500];

gd.Internal.save.path = 'C:\Users\Resonant-2\OneDrive\StimData';
if ~isdir(gd.Internal.save.path)
    gd.Internal.save.path = cd;
end
gd.Internal.save.base = '0000';
gd.Internal.save.depth = '000';
gd.Internal.save.index = '000';

gd.Experiment.saving.save = true;
gd.Experiment.saving.SaveFile = fullfile(gd.Internal.save.path, gd.Internal.save.base);
gd.Experiment.saving.DataFile = '';
gd.Experiment.saving.dataPrecision = 'uint16';

gd.Experiment.timing.stimDuration = .5;     %seconds
gd.Experiment.timing.ITI = 5;               %seconds
gd.Experiment.timing.randomITImax = 3;      %seconds

gd.Experiment.stim.frequency = 10;          %hz
gd.Experiment.stim.wailDuration = 0.02;     %seconds
gd.Experiment.stim.voltage = 5;             %volts
gd.Experiment.stim.bidirectional = false;   %boolean
if numConditions == 1
    gd.Experiment.stim.piezos = table({true},{'Dev1'},{'0'},{''},'VariableNames',{'Active','Device','Port','Whisker'});
elseif numConditions == 2
    gd.Experiment.stim.piezos = table({true;true},{'Dev1';'Dev1'},{'0';'1'},{'';''},'VariableNames',{'Active','Device','Port','Whisker'});
end

gd.Experiment.params.samplingFrequency = 30000;
gd.Experiment.params.numTrials = 5;             % positive integer: default # of trials to present
gd.Experiment.params.randomITI = false;         % true or false:    add on random time to ITI?
gd.Experiment.params.catchTrials = false;       % true or false:    give control stimulus?
gd.Experiment.params.numCatchesPerBlock = 1;    % positive integer: default # of catch trials to present per block
gd.Experiment.params.repeatBadTrials = false;   % true or false:    repeat non-running trials
gd.Experiment.params.speedThreshold = 100;      % positive scalar:  velocity threshold for good running trials (deg/s)
gd.Experiment.params.whiskerTracking = false;   % true or false:    send triggers for whisker tracking camera?
gd.Experiment.params.frameRateWT = 200;         % positive scalar:  frame rate of whisker tracking
gd.Experiment.params.blockShuffle = false;      % true or false:    shuffle block order each block?
gd.Experiment.params.runSpeed = false;          % true or false;    record rotary encoder's velocity? % temporarily won't record running speed
gd.Experiment.params.holdStart = true;          % true or false:    wait to start experiment until after first frame trigger received?
gd.Experiment.params.delay = 0;                 % positive scalar:  amount of time to delay start of experiment (either after first frame trigger received)

% Text user details
gd.Internal.textUser.number = '7146241885';
gd.Internal.textUser.carrier = 'att';

% Properties for display or processing input data
gd.Internal.buffer.numTrials = 2;           %4*gd.Experiment.params.samplingFrequency * (gd.Experiment.timing.stimDuration+gd.Experiment.timing.ITI);
gd.Internal.buffer.downSample = 30;

% Trigger display
gd.Internal.viewHandle = [];

%% Parse input arguments
% index = 1;
% while index<=length(varargin)
%     try
%         switch varargin{index}
%             case 'stimDuration'
%                 gd.Experiment.timing.stimDuration = varargin{index+1};
%                 index = index + 2;
%             case 'control'
%                 gd.Experiment.params.catchTrials = varargin{index+1};
%                 index = index + 2;
%             otherwise
%                 warning('Argument ''%s'' not recognized',varargin{index});
%                 index = index + 1;
%         end
%     catch
%         warning('Argument %d not recognized',index);
%         index = index + 1;
%     end
% end

if exist('SaveFile', 'var')
    gd.Experiment.saving.SaveFile = SaveFile;
    gd.Internal.save = true;
end


%% Create & Populate Figure

% Create figure & panels
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Stimulus: Vertical Pole',...
    'ToolBar',              'none',...
    'Units',                Display.units,...
    'Position',             Display.position);%,...
% 'KeyPressFcn',          @(hObject,eventdata)KeyPressCallback(hObject, eventdata, guidata(hObject)));
gd.Saving.panel = uipanel(...
    'Title',                'Filename',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .8, .4, .2]);
gd.gui.stim.panel = uipanel(...
    'Title',                'Stimulus',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, 0, .4, .8]);
gd.Parameters.panel = uipanel(...
    'Title',                'Parameters',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.4, 0, .25, 1]);
gd.Run.panel = uipanel(...
    'Title',                'Run Experiment',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.65, 0, .35, 1]);

% STIMULI
% Piezo toggle
gd.gui.stim.piezos = uitable(...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [0,.6,1,.4],...
    'ColumnName',           {'Active?','Device','Port','Whisker'},...
    'ColumnEditable',       [true, false, false, true],...
    'ColumnFormat',         {'logical','char','char','char', 'char'},...
    'ColumnWidth',          {50,50,75,75},...
    'Data',                 table2cell(gd.Experiment.stim.piezos));
% stimulus frequency
gd.gui.stim.frequency = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.frequency,...
    'Units',                'normalized',...
    'Position',             [.35,.4,.15,.15],...
    'UserData',             {'stim','frequency', 0, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.frequencyText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Frequency',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.4,.35,.1]);
% voltage
gd.gui.stim.voltage = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.voltage,...
    'Units',                'normalized',...
    'Position',             [.85,.4,.15,.15],...
    'UserData',             {'stim','voltage', 0, 5},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.voltageText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Voltage',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [.5,.4,.35,.1]);
% wail duration
gd.gui.stim.wailDuration = uicontrol(...
    'Style',                'edit',...
    'Parent',               gd.gui.stim.panel,...
    'String',               gd.Experiment.stim.wailDuration,...
    'Units',                'normalized',...
    'Position',             [.35,.2,.15,.15],...
    'UserData',             {'stim','wailDuration', 0.02, []},...
    'Callback',             @(hObject,eventdata)ChangeStim(hObject, eventdata, guidata(hObject)));
gd.gui.stim.wailDurationText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Wail Duration',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.2,.35,.1]);
% bidirectional toggle
gd.gui.stim.bidirectional = uicontrol(...
    'Style',                'checkbox',...
    'Parent',               gd.gui.stim.panel,...
    'Value',               gd.Experiment.stim.bidirectional,...
    'Units',                'normalized',...
    'Position',             [.9,.2,.1,.15],...
    'Callback',             @(hObject,eventdata)ChangeWail(hObject, eventdata, guidata(hObject)));
gd.gui.stim.bidirectionalText = uicontrol(...
    'Style',                'text',...
    'Parent',               gd.gui.stim.panel,...
    'String',               'Bidirectional',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [.5,.2,.35,.1]);
% View triggers
gd.gui.stim.view = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'View',...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,.5,.2],...
    'Callback',             @(hObject,eventdata)ViewTriggers(hObject, eventdata, guidata(hObject)));
% Test stimuli
gd.gui.stim.test = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Test',...
    'Parent',               gd.gui.stim.panel,...
    'Units',                'normalized',...
    'Position',             [.5,0,.5,.2],...
    'Callback',             @(hObject,eventdata)TestTriggers(hObject, eventdata, guidata(hObject)));

% SAVING DATA
% save button
gd.Saving.save = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Save?',...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [0,.5,.15,.5],...
    'BackgroundColor',      [1,0,0],...
    'UserData',             {[1,0,0;0,1,0],'Save?','Saving'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% directory selection
gd.Saving.dir = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Dir',...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [.15,.5,.15,.5],...
    'Callback',             @(hObject,eventdata)ChooseDir(hObject, eventdata, guidata(hObject)));
% basename input
gd.Saving.base = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.base,...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.5,.23,.5],...
    'Callback',             @(hObject,eventdata)SetFilename(hObject, eventdata, guidata(hObject)));
% depth input
gd.Saving.depth = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.depth,...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [.53,.5,.24,.5],...
    'Callback',             @(hObject,eventdata)SetDepth(hObject, eventdata, guidata(hObject)));
% file index
gd.Saving.index = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.index,...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [.77,.5,.23,.5],...
    'Callback',             @(hObject,eventdata)SetFileIndex(hObject, eventdata, guidata(hObject)));
% filename text
gd.Saving.FullFilename = uicontrol(...
    'Style',                'text',...
    'String',               '',...
    'Parent',               gd.Saving.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.5],...
    'Callback',             @(hObject,eventdata)CreateFilename(hObject, eventdata, guidata(hObject)));

% PARAMETERS
w1 = .6;
w2 = .25;
w3 = 1-w1-w2;
% image acq type
gd.Parameters.imagingType = uicontrol(...
    'Style',                'popupmenu',...
    'String',               {'scim';'sbx'},...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.9,w1,.1]);
% length of stimulus
gd.Parameters.stimDurText = uicontrol(...
    'Style',                'text',...
    'String',               'Stimulus (s)',...
    'Parent',               gd.Parameters.panel,...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [w1,.9,w2,.1]);
gd.Parameters.stimDur = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.timing.stimDuration,...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [w1+w2,.9,w3,.1]);
% image acq mode
gd.Parameters.imagingMode = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Constant Imaging',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,w1,.1],...
    'UserData',             {[.94,.94,.94;1,1,1],'Constant Imaging','Trial Imaging'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% length of inter-trial interval
gd.Parameters.ITIText = uicontrol(...
    'Style',                'text',...
    'String',               'ITI (s)',...
    'Parent',               gd.Parameters.panel,...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [w1,.8,w2,.1]);
gd.Parameters.ITI = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.timing.ITI,...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [w1+w2,.8,w3,.1]);
% random interval toggle
gd.Parameters.randomITI = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Add random ITI?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.7,w1,.1],...
    'Callback',             @(hObject,eventdata)toggleRandomITI(hObject,eventdata,guidata(hObject)));
% random interval max
gd.Parameters.randomITIText = uicontrol(...
    'Style',                'text',...
    'String',               'Max (s)',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'HorizontalAlignment',  'right',...
    'Enable',               'off',...
    'Position',             [w1,.7,w2,.1]);
gd.Parameters.randomITImax = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.timing.randomITImax,...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Enable',               'off',...
    'Position',             [w1+w2,.7,w3,.1]);
% catch trial toggle
gd.Parameters.control = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Catch Trials?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.6,w1,.1],...
    'Callback',             @(hObject,eventdata)toggleCatchTrials(hObject,eventdata,guidata(hObject)));
% number of catch trials
gd.Parameters.controlText = uicontrol(...
    'Style',                'text',...
    'String',               '# Per Block',...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'HorizontalAlignment',  'right',...
    'Position',             [w1,.6,w2,.1]);
gd.Parameters.controlNum = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.numCatchesPerBlock,...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'Position',             [w1+w2,.6,w3,.1]);
% repeat bad trials toggle
gd.Parameters.repeatBadTrials = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Repeat bad trials?',...
    'Parent',               gd.Parameters.panel,...
    'Value',                gd.Experiment.params.repeatBadTrials,...
    'Units',                'normalized',...
    'Position',             [0,.5,w1,.1],...
    'Callback',             @(hObject,eventdata)toggleRepeatBadTrials(hObject,eventdata,guidata(hObject)));
% bad trial mean velocity threshold
gd.Parameters.goodVelocityThresholdText = uicontrol(...
    'Style',                'text',...
    'String',               'Threshold (deg/s)',...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'HorizontalAlignment',  'right',...
    'Position',             [w1,.5,w2,.1]);
gd.Parameters.goodVelocityThreshold = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.speedThreshold,...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'Position',             [w1+w2,.5,w3,.1]);
% whisker imaging toggle
gd.Parameters.whiskerTracking = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Trigger Camera?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.4,2*w1/3,.1],...
    'Callback',             @(hObject,eventdata)toggleWhiskerTracking(hObject,eventdata,guidata(hObject)));
% whisker imaging type
gd.Parameters.wtType = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Frame',...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'Position',             [2*w1/3,.4,w1/3,.1],...
    'UserData',             {[.94,.94,.94;1,1,1],'Frame','Trial'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% whisker imaging frame rate
gd.Parameters.wtFrameRateText = uicontrol(...
    'Style',                'text',...
    'String',               'Frame Rate (Hz)',...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [w1,.4,w2,.1]);
gd.Parameters.wtFrameRate = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.frameRateWT,...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',...
    'Units',                'normalized',...
    'Position',             [w1+w2,.4,w3,.1],...
    'Callback',             @(hObject,eventdata)ChangeWTFrameRate(hObject,eventdata,guidata(hObject)));
% start after frame trigger recieved toggle
gd.Parameters.holdStart = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Wait for frame triggers?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.3,w1,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Wait for frame triggers?','Waiting for frame trigs'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% delay
gd.Parameters.delayText = uicontrol(...
    'Style',                'text',...
    'String',               'Start delay (s)',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [w1,.3,w2,.1]);
gd.Parameters.delay = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.delay,...
    'Parent',               gd.Parameters.panel,...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [w1+w2,.3,w3,.1]);
% block shuffle toggle
gd.Parameters.shuffle = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Shuffle blocks?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.2,.5,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Shuffle within block?','Shuffling each block'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% record run speed
gd.Parameters.runSpeed = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Record velocity?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [.5,.2,.5,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Record velocity?','Recording velocity'},...
    'Callback',             @(hObject,eventdata)ToggleCaptureRunSpeed(hObject,eventdata,guidata(hObject)));

% EXPERIMENT
% number of trials
gd.Run.numTrialsText = uicontrol(...
    'Style',                'text',...
    'String',               '# Trials',...
    'Parent',               gd.Run.panel,...
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [0,.925,.15,.05]);
gd.Run.numTrials = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.numTrials,...
    'Parent',               gd.Run.panel,...
    'Units',                'normalized',...
    'Position',             [.15,.9,.15,.1]);
% send text message when complete
gd.Run.textUser = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Send text?',...
    'Parent',               gd.Run.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,.3,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Send text?','Sending text'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% run button
gd.Run.run = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Run?',...
    'Parent',               gd.Run.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.8,.7,.2],...
    'Callback',             @(hObject,eventdata)RunExperiment(hObject, eventdata, guidata(hObject)));
% running speed axes
gd.Run.runSpeedAxes = axes(...
    'Parent',               gd.Run.panel,...
    'Units',                'normalized',...
    'Position',             [.075,.075,.9,.7]);

guidata(gd.gui.fig, gd); % save guidata

%% Initialize Defaults

% Saving
if gd.Experiment.saving.save
    set(gd.Saving.save,'Value',true,'String','Saving','BackgroundColor',[0,1,0]);
end

% Imaging type
switch gd.Internal.ImagingType % set initial selection
    case 'scim'
        gd.Parameters.imagingType.Value = 1;
    case 'sbx'
        gd.Parameters.imagingType.Value = 2;
end

% Add random ITI
if gd.Experiment.params.randomITI
    gd.Parameters.randomITI.Value = true;
    toggleRandomITI(gd.Parameters.randomITI,[],gd);
end
% Present catch trials
if gd.Experiment.params.catchTrials
    gd.Parameters.control.Value = true;
    toggleCatchTrials(gd.Parameters.control,[],gd);
end
% Repeat bad trials
if gd.Experiment.params.repeatBadTrials
    gd.Parameters.repeatBadTrials.Value = true;
    toggleRepeatBadTrials(gd.Parameters.repeatBadTrials,[],gd);
end
% Trigger whisker tracking camera
if gd.Experiment.params.whiskerTracking
    gd.Parameters.whiskerTracking.Value = true;
    toggleWhiskerTracking(gd.Parameters.whiskerTracking,[],gd);
end
% Block shuffle
if gd.Experiment.params.blockShuffle
    set(gd.Parameters.shuffle,'Value',true,'String','Shuffling each block','BackgroundColor',[0,1,0]);
end
% Record velocity
if gd.Experiment.params.runSpeed
    gd.Parameters.runSpeed.Value = true;
end
ToggleCaptureRunSpeed(gd.Parameters.runSpeed,[],gd);
% Hold start
if gd.Experiment.params.holdStart
    set(gd.Parameters.holdStart,'Value',true,'String','Waiting for frame trigs','BackgroundColor',[0,1,0]);
end

CreateFilename(gd.Saving.FullFilename, [], gd);

% For timing
% gd=guidata(gd.gui.fig);
% gd.Run.run.Value = true;
% RunExperiment(gd.Run.run,[],gd); % timing debugging
end


%% FILENAME CALLBACKS
function ChooseDir(hObject, eventdata, gd)
temp = uigetdir(gd.Internal.save.path, 'Choose directory to save to');
if ischar(temp)
    gd.Internal.save.path = temp;
    guidata(hObject, gd);
end
CreateFilename(gd.Saving.FullFilename, [], gd);
end

function SetFilename(hObject, eventdata, gd)
gd.Internal.save.base = hObject.String;
CreateFilename(gd.Saving.FullFilename, [], gd);
end

function SetDepth(hObject, eventdata, gd)
if numel(hObject.String)>3
    hObject.String = hObject.String(1:3);
end
CreateFilename(gd.Saving.FullFilename, [], gd);
end

function SetFileIndex(hObject, eventdata, gd)
if numel(hObject.String)>3
    hObject.String = hObject.String(end-2:end);
end
CreateFilename(gd.Saving.FullFilename, [], gd);
end

function CreateFilename(hObject, eventdata, gd)
gd.Experiment.saving.SaveFile = fullfile(gd.Internal.save.path, strcat(gd.Saving.base.String, '_', gd.Saving.depth.String, '_', gd.Saving.index.String, '.exp'));
hObject.String = gd.Experiment.saving.SaveFile;
guidata(hObject, gd);
if exist(gd.Experiment.saving.SaveFile, 'file')
    hObject.BackgroundColor = [1,0,0];
else
    hObject.BackgroundColor = [.94,.94,.94];
end
end


%% STIMULI CALLBACKS
% function LoadStimuli(hObject, eventdata, gd)
% % Select and load file
% [f,p] = uigetfile({'*.stim';'*.mat'},'Select stim file to load',cd);
% if isnumeric(f)
%     return
% end
% load(fullfile(p,f), 'stimuli', '-mat');
% fprintf('Loaded stimuli from: %s\n', fullfile(p,f));
% 
% % Load stimuli
% gd.Stimuli.list.Data = num2cell(stimuli); % display stimuli
% gd.Experiment.Position = stimuli;         % save loaded stimuli
% guidata(hObject, gd);
% end
% 
% function SaveStimuli(hObject, eventdata, gd)
% % Determine file to save to
% [f,p] = uiputfile({'*.stim';'*.mat'},'Save stimuli as?',cd);
% if isnumeric(f)
%     return
% end
% saveFile = fullfile(p,f);
% 
% % Save stimuli
% stimuli = gd.Experiment.Position;
% if ~exist(saveFile,'file')
%     save(fullfile(p,f), 'stimuli', '-mat', '-v7.3');
% else
%     save(fullfile(p,f), 'stimuli', '-mat', '-append');
% end
% fprintf('Stimuli saved to: %s\n', fullfile(p,f));
% end

%% Stimuli
function ChangeStim(hObject, eventdata, gd)
newValue = str2num(get(hObject,'String'));
UD = get(hObject,'UserData');
if isempty(newValue)                                                    % not a number
    set(hObject,'String',gd.Experiment.(hObject.UserData{1}).(hObject.UserData{2}));
elseif ~isempty(UD{3}) && newValue < UD{3}  % lower bound
    set(hObject,'String',UD{3});
    gd.Experiment.(UD{1}).(UD{2}) = UD{3};
    guidata(hObject,gd);
elseif ~isempty(UD{4}) && newValue > UD{4}  % upper bound
    set(hObject,'String',UD{4});
    gd.Experiment.(UD{1}).(UD{2}) = UD{4};
    guidata(hObject,gd);
else                                                                    % valid input
    gd.Experiment.(UD{1}).(UD{2}) = newValue;
    guidata(hObject, gd);
end
if get(gd.gui.stim.view,'Value')
    ViewTriggers(gd.gui.stim.view, [], gd);
end
end

function ChangeWail(hObject, eventdata, gd)
gd.Experiment.stim.bidirectional = get(hObject,'Value');
guidata(hObject,gd);
if get(gd.gui.stim.view,'Value')
    ViewTriggers(gd.gui.stim.view, [], gd);
end
end

function ViewTriggers(hObject, eventdata, gd)
if get(hObject,'Value')
    Fs = gd.Experiment.params.samplingFrequency;
    Triggers = generatePiezoTrig(gd.Experiment.stim.wailDuration, gd.Experiment.stim.bidirectional, gd.Experiment.stim.frequency, ceil(str2double(gd.Parameters.stimDur.String)*gd.Experiment.params.samplingFrequency), gd.Experiment.params.samplingFrequency);
    Triggers = Triggers*gd.Experiment.stim.voltage; % scale to proper voltage
    if isempty(gd.Internal.viewHandle) || ~ishghandle(gd.Internal.viewHandle) % figure doesn't exist
%         pos = get(gd.gui.fig,'OuterPosition');
%         pos2 = get(gd.gui.stim.panel,'Position');
%         pos = [pos(1),.1,pos(3),pos(2)+pos(4)*pos2(2)-.11];
        gd.Internal.viewHandle = figure('NumberTitle','off','Name','Single Trial Triggers',...
            'Units','normalized'); %,'OuterPosition',pos
        guidata(hObject,gd);
    else
        figure(gd.Internal.viewHandle);
    end
    cla; hold on;
    Color = {'r','b','g','c'};
%     x = [0,gd.Experiment.timing.baselineDur];
%     y = [min(Triggers(:)),max(Triggers(:))];
%     patch(x([1,1,2,2]),[y,flip(y)],Color{4},'EdgeAlpha',0,'FaceAlpha',.2);
%     x = [gd.Experiment.timing.avgFirst,gd.Experiment.timing.avgLast];
%     patch(x([1,1,2,2]),[y,flip(y)],Color{3},'EdgeAlpha',0,'FaceAlpha',.2);
    x = 0:1/Fs:(size(Triggers,1)-1)/Fs;
    plot(x,Triggers,Color{1});
    axis tight
    ylabel('Voltage');
    xlabel('Time (s)');
%     legend('Baseline','Avg Period','Piezo','Camera');
    hold off;
else
    if ~isempty(gd.Internal.viewHandle) && ishghandle(gd.Internal.viewHandle) % figure doesn't exist
        delete(gd.Internal.viewHandle);
    end
end
end

function TestTriggers(hObject, eventdata, gd)
if get(hObject,'Value')
    DAQ = daq.createSession('ni');
    DAQ.Rate = gd.Experiment.params.samplingFrequency;
    PD = get(gd.gui.stim.piezos,'Data');
    ActivePiezos = [PD{:,1}];
    if ~any(ActivePiezos)
        set(hObject,'Value',false);
        error('Requires at least one active piezo!');
    end
    for index = find(ActivePiezos)
        [~,id] = DAQ.addAnalogOutputChannel(gd.Experiment.stim.piezos.Device{index},str2double(gd.Experiment.stim.piezos.Port{index}),'Voltage');
        DAQ.Channels(id).Name = sprintf('O_Piezo%d',index);
    end
    
    Triggers = generatePiezoTrig(gd.Experiment.stim.wailDuration, gd.Experiment.stim.bidirectional, gd.Experiment.stim.frequency, ceil(str2double(gd.Parameters.stimDur.String)*gd.Experiment.params.samplingFrequency), gd.Experiment.params.samplingFrequency);
    Triggers = Triggers*gd.Experiment.stim.voltage; % scale to proper voltage
    Triggers = repmat(Triggers(:,1),1,nnz(ActivePiezos));
    
    set(hObject,'String','Testing...'); drawnow;
    while get(hObject,'Value')
        DAQ.queueOutputData(Triggers);
        DAQ.startForeground;
        if ~get(hObject,'Value')
            break
        end
    end
    clear DAQ;
    set(hObject,'String','Test');
else
    set(hObject,'String','Stopping...'); drawnow;
end
end

function trig = generatePiezoTrig(duration, bidirectional, freq, numScans, Fs)

% Create half wave
f = 1/duration;
t = (0:1/Fs:duration/2)';
halfwave = -0.5*cos(2*pi*f*t)+0.5;

% Create wave
if ~bidirectional
    wave = [halfwave;flip(halfwave)];
else
    
    % Create full wave
    f = 1/(2*duration);
    t = (0:1/Fs:duration)';
    midwave = cos(2*pi*f*t);

    wave = [halfwave;midwave;-flip(halfwave)];
end

% Determine if duration of wave is longer than single period for desired frequency
numScansPerWail = round(1/freq*Fs);
stim_lag = numScansPerWail - numel(wave);
if stim_lag < 0 %wave is longer than single period
    warning('Wail duration parameter is longer than single period for desired frequency. Frequency will set to the maximum frequency allowed with the given duration.');
    stim_lag = 0;
end

% Build single wail
single_stim = [wave;zeros(stim_lag,1)]; %single period
numScansPerWail = numel(single_stim);

% Build for entire duraiton
numWails = floor(numScans/numScansPerWail);
trig = repmat(single_stim,numWails,1);

end


%% PARAMETERS CALLBACKS

function toggleRandomITI(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Adding random ITI','BackgroundColor',[0,1,0]);
    set([gd.Parameters.randomITIText,gd.Parameters.randomITImax],'Enable','on');
else
    set(hObject,'String','Add random ITI?','BackgroundColor',[.94,.94,.94]);
    set([gd.Parameters.randomITIText,gd.Parameters.randomITImax],'Enable','off');
end
end

function toggleCatchTrials(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Sending catch trials','BackgroundColor',[0,1,0]);
    set([gd.Parameters.controlText,gd.Parameters.controlNum],'Enable','on');
else
    set(hObject,'String','Catch Trials?','BackgroundColor',[.94,.94,.94]);
    set([gd.Parameters.controlText,gd.Parameters.controlNum],'Enable','off');
end
end

function toggleRepeatBadTrials(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Repeating bad trials','BackgroundColor',[0,1,0]);
    set([gd.Parameters.goodVelocityThresholdText,gd.Parameters.goodVelocityThreshold],'Enable','on');
else
    set(hObject,'String','Repeat bad trials?','BackgroundColor',[.94,.94,.94]);
    set([gd.Parameters.goodVelocityThresholdText,gd.Parameters.goodVelocityThreshold],'Enable','off');
end
end

function toggleWhiskerTracking(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Triggering Camera','BackgroundColor',[0,1,0]);
    set([gd.Parameters.wtType,gd.Parameters.wtFrameRateText,gd.Parameters.wtFrameRate],'Enable','on');
else
    set(hObject,'String','Trigger Camera?','BackgroundColor',[.94,.94,.94]);
    set([gd.Parameters.wtType,gd.Parameters.wtFrameRateText,gd.Parameters.wtFrameRate],'Enable','off');
end
end

function ChangeWTFrameRate(hObject,eventdata,gd)
newValue = str2num(hObject.String);
if newValue <= 0
    newValue = .0000001;
    hObject.String = num2str(newValue);
end
gd.Experiment.params.frameRateWT = newValue;
guidata(hObject, gd);
end

function ToggleCaptureRunSpeed(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Recording velocity','BackgroundColor',[0,1,0]);
    gd.Parameters.repeatBadTrials.Enable = 'on';
else
    set(hObject,'String','Record velocity?','BackgroundColor',[.94,.94,.94]);
    set(gd.Parameters.repeatBadTrials,'Value',false,'Enable','off');
end
toggleRepeatBadTrials(gd.Parameters.repeatBadTrials,[],gd);
end


%% RUN EXPERIMENT
function RunExperiment(hObject, eventdata, gd)

if hObject.Value
    try
        Experiment.stim.piezos = cell2table(gd.gui.stim.piezos.Data,'VariableNames',{'Active','Device','Port','Whisker'});
        ActivePiezos = [Experiment.stim.piezos{:,1}];
        if ~any(ActivePiezos)
            error('Requires at least one active piezo!');
        end
        Experiment = gd.Experiment;
        
        %% Record date & time information
        Experiment.timing.init = datestr(now);
        
        %% Determine filenames to save to
        if gd.Saving.save.Value
            Experiment.saving.save = true;
            % mat file
            if exist(Experiment.saving.SaveFile, 'file')
                answer = questdlg(sprintf('File already exists! Continue?\n%s', Experiment.saving.SaveFile), 'Overwrite file?', 'Yes', 'No', 'No');
                if strcmp(answer, 'No')
                    hObject.Value = false;
                    return
                end
            end
            SaveFile = Experiment.saving.SaveFile;
            % bin file
            Experiment.saving.DataFile = strcat(Experiment.saving.SaveFile(1:end-4), '.bin');
        else
            Experiment.saving.save = false;
        end
        
        %% Set parameters
        
        Experiment.ImagingType = gd.Parameters.imagingType.String{gd.Parameters.imagingType.Value};
        Experiment.ImagingMode = gd.Parameters.imagingMode.String;

        Experiment.timing.stimDuration = str2double(gd.Parameters.stimDur.String);
        
        Experiment.timing.ITI = str2double(gd.Parameters.ITI.String);
        
        Experiment.params.randomITI = gd.Parameters.randomITI.Value;
        if Experiment.params.randomITI
            Experiment.timing.randomITImax = str2double(gd.Parameters.randomITImax.String);
        else
            Experiment.timing.randomITImax = false;
        end
        
        Experiment.params.catchTrials = gd.Parameters.control.Value;
        if Experiment.params.catchTrials
            Experiment.params.numCatchesPerBlock = str2double(gd.Parameters.controlNum.String);
        else
            Experiment.params.numCatchesPerBlock = false;
        end
        
        Experiment.params.repeatBadTrials = gd.Parameters.repeatBadTrials.Value;
        if Experiment.params.repeatBadTrials
            Experiment.params.speedThreshold = str2double(gd.Parameters.speedThreshold.String);
        else
            Experiment.params.speedThreshold = false;
        end
        
        Experiment.params.whiskerTracking = gd.Parameters.whiskerTracking.Value;
        if Experiment.params.whiskerTracking
            Experiment.params.frameRateWT = str2double(gd.Parameters.wtFrameRate.String);
        else
            Experiment.params.frameRateWT = false;
        end
        
        Experiment.params.blockShuffle = gd.Parameters.shuffle.Value;
        
        Experiment.params.runSpeed = gd.Parameters.runSpeed.Value;
        
        Experiment.params.holdStart = gd.Parameters.holdStart.Value;
        Experiment.params.delay = str2double(gd.Parameters.delay.String);
        
        %% Initialize button
        hObject.BackgroundColor = [0,0,0];
        hObject.ForegroundColor = [1,1,1];
        hObject.String = 'Stop';
        
        %% Initialize NI-DAQ session
        gd.Internal.daq = [];
        
        DAQ = daq.createSession('ni'); % initialize session
        DAQ.IsContinuous = true; % set session to be continuous (call's 'DataRequired' listener)
        DAQ.Rate = Experiment.params.samplingFrequency; % set sampling frequency
        Experiment.params.samplingFrequency = DAQ.Rate; % the actual sampling frequency is rarely perfect from what is input
        
        % Add ports
        
        % Imaging Computer Trigger (for timing)
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line0','OutputOnly');
        DAQ.Channels(id).Name = 'O_2PTrigger';
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line1','InputOnly');
        DAQ.Channels(id).Name = 'I_FrameCounter';
        
        % Piezo Control
        for pindex = find(ActivePiezos)
            [~,id] = DAQ.addAnalogOutputChannel(Experiment.stim.piezos.Device{pindex},str2double(Experiment.stim.piezos.Port{pindex}),'Voltage');
            DAQ.Channels(id).Name = sprintf('O_Piezo%d',pindex);
        end
        
        % Running Wheel
        if Experiment.params.runSpeed
            [~,id] = DAQ.addDigitalChannel('Dev1','port0/line5:7','InputOnly');
            DAQ.Channels(id(1)).Name = 'I_RunWheelA';
            DAQ.Channels(id(2)).Name = 'I_RunWheelB';
            DAQ.Channels(id(3)).Name = 'I_RunWheelIndex';
        end
        
        % Whisker tracking
        if Experiment.params.whiskerTracking
            [~,id] = DAQ.addDigitalChannel('Dev1','port0/line17','OutputOnly');
            DAQ.Channels(id).Name = 'O_WhiskerTracker';
            [~,id] = DAQ.addDigitalChannel('Dev1','port0/line2','OutputOnly');
            DAQ.Channels(id).Name = 'O_WhiskerIllumination';
            [~,id] = DAQ.addDigitalChannel('Dev1','port0/line18','InputOnly');
            DAQ.Channels(id).Name = 'I_WhiskerTracker';
        end
        
        % Cleanup
        DAQChannels = {DAQ.Channels(:).Name};
        OutChannels = DAQChannels(~cellfun(@isempty,strfind(DAQChannels, 'O_')));
        InChannels = DAQChannels(~cellfun(@isempty,strfind(DAQChannels, 'I_')));
        
%         % Add clock (only necessary when no analog channels)
%         daqClock = daq.createSession('ni');
%         daqClock.addCounterOutputChannel('Dev1',0,'PulseGeneration');
%         clkTerminal = daqClock.Channels(1).Terminal;
%         daqClock.Channels(1).Frequency = DAQ.Rate;
%         daqClock.IsContinuous = true;
%         daqClock.startBackground;
%         DAQ.addClockConnection('External',['Dev1/' clkTerminal],'ScanClock');
        
        % Add Callbacks
        DAQ.addlistener('DataRequired', @QueueData);    % create listener for queueing trials
        DAQ.NotifyWhenScansQueuedBelow = DAQ.Rate-1; % queue more data when less than a second of data left
        DAQ.addlistener('DataAvailable', @SaveDataIn);  % create listener for when data is returned
        % DAQ.NotifyWhenDataAvailableExceeds = round(DAQ.Rate/100);

        % Compute timing of each trial
        Experiment.timing.trialDuration = Experiment.timing.stimDuration + Experiment.timing.ITI;
        Experiment.timing.numScansPerTrial = ceil(Experiment.params.samplingFrequency * Experiment.timing.trialDuration);
        
        
        %% Determine stimuli

        % Determine stimulus IDs
        Experiment.StimID = 1:nnz(ActivePiezos);
        Block = Experiment.StimID;
        
        % Determine if presenting control stimulus
        if Experiment.params.catchTrials
            Experiment.StimID = [0, Experiment.StimID];
            Block = [zeros(Experiment.params.numCatchesPerBlock,1); Block];
        end
        
        
        %% Create triggers 

        % Build piezo triggers
        Experiment.piezoTrigs = zeros(Experiment.timing.numScansPerTrial,1);
        piezoTrigs = generatePiezoTrig(Experiment.stim.wailDuration, Experiment.stim.bidirectional, Experiment.stim.frequency, ceil(Experiment.timing.stimDuration*Experiment.params.samplingFrequency), Experiment.params.samplingFrequency);
        piezoTrigs = piezoTrigs*Experiment.stim.voltage; % scale to proper voltage
        startTrig = round(Experiment.timing.ITI*Experiment.params.samplingFrequency)+1;
        endTrig = startTrig+numel(piezoTrigs)-1;
        Experiment.piezoTrigs(startTrig:endTrig) = piezoTrigs;
        
        % Adjust Callback timing so next trial is queued right after previous trial starts
        DAQ.NotifyWhenScansQueuedBelow = Experiment.timing.numScansPerTrial - startTrig;

        % Initialize triggers
        Experiment.Triggers = zeros(Experiment.timing.numScansPerTrial, numel(OutChannels), Experiment.params.catchTrials+1);
        
        % Trigger imaging computer on every single trial
        Experiment.Triggers([startTrig, endTrig], strcmp(OutChannels,'O_2PTrigger'), :) = 1; % trigger at beginning and end of stimulus
        % Experiment.Triggers(startTrig:endTrig-1, strcmp(OutChannels,'O_2PTrigger'), :) = 1; % high during whole stimulus
    
        % Trigger whisker tracking camera on every single trial
        if Experiment.params.whiskerTracking
            if Experiment.timing.ITI >= 0.01
                if ~gd.Parameters.wtType.Value	% single trigger per frame
                    Experiment.Triggers(startTrig:ceil(DAQ.Rate/Experiment.params.frameRateWT):endTrig, strcmp(OutChannels,'O_WhiskerTracker')) = 1; % image during stimulus period
                else                            % single trigger per trial
                    Experiment.Triggers(startTrig, strcmp(OutChannels,'O_WhiskerTracker')) = 1; % image during stimulus period
                end
                Experiment.Triggers(startTrig-ceil(DAQ.Rate/100):endTrig, strcmp(OutChannels,'O_WhiskerIllumination')) = 1; % start LED a little before the start of imaging
            else % ITI is too short for LED to turn on and off
                if ~gd.Parameters.wtType.Value	% single trigger per frame
                    Experiment.Triggers(1:ceil(DAQ.Rate/Experiment.params.frameRateWT):endTrig, strcmp(OutChannels,'O_WhiskerTracker')) = 1; % image during entire time
                else                            % single trigger per trial
                    Experiment.Triggers(startTrig) = 1; % image during stimulus period
                end
                Experiment.Triggers(:, strcmp(OutChannels,'O_WhiskerIllumination')) = 1; % image during entire time
            end
        end
        
        % Build up vector to display when stimulus is present
        Experiment.Stimulus = zeros(Experiment.timing.numScansPerTrial,1);
        Experiment.Stimulus(startTrig:endTrig-1) = 1;
        
        
        %% Initialize imaging session (scanbox only)
        if strcmp(Experiment.ImagingType, 'sbx')
            H_Scanbox = udp(gd.Internal.ImagingComp.ip, 'RemotePort', gd.Internal.ImagingComp.port); % create udp port handle
            fopen(H_Scanbox);
            fprintf(H_Scanbox,sprintf('A%s',gd.Saving.base.String));
            fprintf(H_Scanbox,sprintf('U%s',gd.Saving.depth.String));
            fprintf(H_Scanbox,sprintf('E%s',gd.Saving.index.String));
        end
        
        
        %% Initialize saving
        if Experiment.saving.save
            save(SaveFile, 'DAQChannels', 'Experiment', '-mat', '-v7.3');
            H_DataFile = fopen(Experiment.saving.DataFile, 'w');
        end
        
        
        %% Initialize shared variables (only share what's necessary)
        
        % Necessary variables
        numTrialsObj = gd.Run.numTrials;
        Triggers = Experiment.Triggers;
        PiezoTrigs = Experiment.piezoTrigs;
        PiezoChannelIDs = find(~cellfun(@isempty,strfind(OutChannels,'Piezo')));
        currentBlockOrder = Block;
        numBlock = numel(currentBlockOrder);
%         ControlTrial = Experiment.params.catchTrials;
        BlockShuffle = Experiment.params.blockShuffle;
        currentTrial = 0;
        currentNewTrial = 0;
        TrialInfo = struct('StimID', []);
        saveOut = Experiment.saving.save;
        Stimulus = Experiment.Stimulus;
        ExperimentReachedEnd = false; % boolean to see if max trials has been reached

        % Variables for displaying stim info
        numBufferScans = gd.Internal.buffer.numTrials*Experiment.timing.numScansPerTrial;
        dsamp = gd.Internal.buffer.downSample;
        numScansReturned = DAQ.NotifyWhenDataAvailableExceeds;
        BufferStim = zeros(numBufferScans, 1);
        hAxes = gd.Run.runSpeedAxes;
        
        % If adding random ITI
        if Experiment.params.randomITI
            MaxRandomScans = floor(Experiment.timing.randomITImax*Experiment.params.samplingFrequency);
        else
            MaxRandomScans = 0;
        end
        
        % If delaying start
        Delay = Experiment.params.delay;
        DelayTimer = false;                                             % only necessary when Delay or HoldStart
        FrameChannelIndex = find(strcmp(InChannels, 'I_FrameCounter')); % only necessary for HoldStart
        if Delay || Experiment.params.holdStart
            Started = false;
        else
            Started = true;
        end
        
        % If saving input data
        if saveOut
            Precision = Experiment.saving.dataPrecision;
        end
        
        % If capturing run speed
        CaptureRunSpeed = Experiment.params.runSpeed;
        if CaptureRunSpeed
            % Variables for calculating and displaying running speed
            RunChannelIndices = [find(strcmp(InChannels, 'I_RunWheelB')),find(strcmp(InChannels,'I_RunWheelA'))];
            DataInBuffer = zeros(numBufferScans, 2);
            dsamp_Fs = Experiment.params.samplingFrequency / dsamp;
            smooth_win = gausswin(dsamp_Fs, 23.5/2);
            smooth_win = smooth_win/sum(smooth_win);
            sw_len = length(smooth_win);
            d_smooth_win = [0;diff(smooth_win)]/(1/dsamp_Fs);
            TrialInfo.Running = [];
            TrialInfo.RunSpeed = [];
            % Variables for determing if mouse was running
            RepeatBadTrials = Experiment.params.repeatBadTrials;
            StimuliToRepeat = [];
            SpeedThreshold = Experiment.params.speedThreshold;
            RunIndex = 1;
        end

        
        %% Start Experiment
        
        % Start imaging
        if strcmp(Experiment.ImagingType, 'sbx')
            fprintf(H_Scanbox,'G'); % start imaging
        end
        
        % Start experiment
        QueueData();                                % queue initial output triggers (blanks)
        if ~Experiment.params.holdStart && Delay    % delay starts right away
            DelayTimer = tic;                       % start delay timer
        end
        Experiment.timing.start = datestr(now);     % record time experiment started
        DAQ.startBackground;                        % start experiment
        
        %% During Experiment
        while DAQ.IsRunning                         % experiment hasn't ended yet
            pause(1);                               % free up command line
        end
        Experiment.timing.finish = datestr(now);    % record time experiment ended
        
        %% End Experiment
        
        % Scanbox only: stop imaging
        if strcmp(Experiment.ImagingType, 'sbx')
            fprintf(H_Scanbox,'S'); % stop imaging
            fclose(H_Scanbox);      % close connection
        end
        
        % If saving: append stop time, close file, & increment file index
        if saveOut
            save(SaveFile, 'Experiment', '-append'); % update with "Experiment.timing.finish" info
            fclose(H_DataFile);                      % close binary file
            gd.Saving.index.String = sprintf('%03d',str2double(gd.Saving.index.String) + 1); % increment file index for next experiment
            CreateFilename(gd.Saving.FullFilename, [], gd); % update filename for next experiment
        end
        
        % Text user
        if gd.Run.textUser.Value
            send_text_message(gd.Internal.textUser.number,gd.Internal.textUser.carrier,'',sprintf('Experiment finished at %s',Experiment.timing.finish(end-7:end)));
        end   
        
        % Reset button properties
        hObject.Value = false;
        hObject.BackgroundColor = [.94,.94,.94];
        hObject.ForegroundColor = [0,0,0];
        hObject.String = 'Run';
        
    catch ME
        warning('Running experiment failed');
        
        % Reset button properties
        hObject.Value = false;
        hObject.BackgroundColor = [.94,.94,.94];
        hObject.ForegroundColor = [0,0,0];
        hObject.String = 'Run';
        
        % Close any open connections
        try
            if strcmp(Experiment.ImagingType, 'sbx')
                fprintf(H_Scanbox,'S'); %stop
                fclose(H_Scanbox);
            end
            for findex = 1:size(H_LinearStage,2)
                fclose(H_LinearStage(findex));
            end
        end
        clear DAQ H_Scanbox H_LinearStage
        
        % Rethrow error
        rethrow(ME);
    end
    
else % user quit experiment (hObject.Value = false)
    
    % Change button properties to reflect change in state
    hObject.BackgroundColor = [1,1,1];
    hObject.ForegroundColor = [0,0,0];
    hObject.String = 'Stopping...';
    
end

%% Callback: DataIn
    function SaveDataIn(src,eventdata)
        
        % Save input data
        if saveOut
            fwrite(H_DataFile, eventdata.Data', Precision);
        end
        
        % If experiment hasn't started, determine whether to start experiment
        if ~Started                                       % experiment hasn't started
            if DelayTimer                                   % delay timer started previously 
                if toc(DelayTimer)>=Delay                       % requested delay time has been reached
                    Started = true;                               	% start experiment
                end
            elseif any(eventdata.Data(:,FrameChannelIndex)) % first frame trigger received
                if Delay                                    % delay requested
                    DelayTimer = tic;                           % start delay timer
                else                                        % no delay requested
                    Started = true;                               % start experiment
                end
            end
        end
        
        % Update stimulus buffer and plot current state
        BufferStim = BufferStim(numScansReturned+1:end);                    % remove corresponding old data from stimulus buffer
        currentStim = downsample(BufferStim(1:numBufferScans), dsamp);      % downsample for plotting
        plot(hAxes, numBufferScans:-dsamp:1, 500*(currentStim>0), 'r-');    % display stimulus state

        % Calculate run speed of whole buffer
        if CaptureRunSpeed
            DataInBuffer = cat(1, DataInBuffer(numScansReturned+1:end,:), eventdata.Data(:,RunChannelIndices));   % concatenate new data and remove old data
            Data = [0;diff(DataInBuffer(:,1))>0];       % gather pulses' front edges
            Data(all([Data,DataInBuffer(:,2)],2)) = -1; % set backwards steps to be backwards
            Data = cumsum(Data);                        % convert pulses to counter data
            x_t = downsample(Data, dsamp);              % downsample data to speed up computation
            x_t = padarray(x_t, sw_len, 'replicate');   % pad for convolution
            dx_dt = conv(x_t, d_smooth_win, 'same');    % perform convolution
            dx_dt([1:sw_len,end-sw_len+1:end]) = [];    % remove values produced by padding the data
            % dx_dt = dx_dt * 360/360;                  % convert to degrees (360 pulses per 360 degrees)
            plot(hAxes, numBufferScans:-dsamp:1, dx_dt, 'b-', numBufferScans:-dsamp:1, 500*(currentStim>0), 'r-');
        
            % Record average running speed during stimulus period
            if any(diff(BufferStim(numBufferScans-numScansReturned:numBufferScans)) == -RunIndex) % stimulus ended during current DataIn call
                preppedTrial = false; % last stimulus ended -> prep next trial
                
                % Calculate mean running speed
                TrialInfo.RunSpeed(RunIndex) = mean(dx_dt(currentStim==RunIndex)); % calculate mean running speed during stimulus
                fprintf('\t\t\tT%d S%d RunSpeed= %.2f', RunIndex, TrialInfo.StimID(RunIndex), TrialInfo.RunSpeed(RunIndex)); % display running speed
                
                % Determine if mouse was running during previous trial
                if TrialInfo.RunSpeed(RunIndex) < SpeedThreshold
                    TrialInfo.Running(RunIndex) = false;                                        % record that trial was bad
                    if RepeatBadTrials                                                          % repeate trial
                        fprintf(' (trial to be repeated)');
                        StimuliToRepeat = [StimuliToRepeat, TrialInfo.StimID(RunIndex)];        % add trial to repeat queue
                    end
                else % mouse was running
                    TrialInfo.Running(RunIndex) = true;                                         % record that trial was good
                end
                RunIndex = RunIndex+1; % increment index
                
                % Save to file
                if saveOut
                    save(SaveFile, 'TrialInfo', '-append');
                end
                
            end %analyze last trial
        end
        
        ylim(hAxes, [-100,600]);    
            
    end %SaveDateIn

%% Callback: QueueOutputData
    function QueueData(src,eventdata)
        
        % Queue next trial
        if hObject.Value && ~Started % user hasn't quit, and imaging system hasn't started yet 
            DAQ.queueOutputData(zeros(2*DAQ.NotifyWhenScansQueuedBelow, numel(OutChannels)));   % queue "blank" period
            BufferStim = cat(1, BufferStim, zeros(2*DAQ.NotifyWhenScansQueuedBelow, 1));        % update buffer
            
        elseif  hObject.Value && (currentTrial < str2double(numTrialsObj.String) || ~isempty(StimuliToRepeat)) % user hasn't quit, and requested # of trials hasn't been reached or trials need to be repeated
            
            % Update index
            currentTrial = currentTrial + 1;
            ExperimentReachedEnd = false;
            
            % Determine StimID of stimulus to queue
            if currentTrial <= str2double(numTrialsObj.String) % haven't reached end of experiment
                currentNewTrial = currentNewTrial + 1;
                blockIndex = rem(currentNewTrial-1, numBlock)+1;
                if BlockShuffle && blockIndex == 1                                  % if starting new block, shuffle the stimuli order
                    currentBlockOrder = currentBlockOrder(randperm(numBlock));      % shuffle block
                end
                TrialInfo.StimID(currentTrial) = currentBlockOrder(blockIndex);     % determine StimID for current trial
            else %trials need to be repeated
                TrialInfo.StimID(currentTrial) = StimuliToRepeat(1);                % present first trial in repeat queue
                StimuliToRepeat(1) = [];                                            % remove trial from repeat queue
            end
       
            % Queue triggers
            if TrialInfo.StimID(currentTrial) ~= 0              % current trial is not control trial
                currentTrigs = Triggers;
                currentTrigs(:,PiezoChannelIDs(TrialInfo.StimID(currentTrial))) = PiezoTrigs;
                if ~MaxRandomScans                              % do not add random ITI
                    DAQ.queueOutputData(currentTrigs);          % queue stim triggers
                else
                    TrialInfo.numRandomScansPost(currentTrial) = randi([0,MaxRandomScans]); % determine amount of extra scans to add
                    DAQ.queueOutputData(cat(1,currentTrigs,zeros(TrialInfo.numRandomScansPost(currentTrial),numel(OutChannels)))); % queue normal stim triggers with extra scans
                end
            else                                                % current trial is control trial
                if ~MaxRandomScans                              % do not add random ITI
                    DAQ.queueOutputData(Triggers);              % queue control triggers
                else
                    TrialInfo.numRandomScansPost(currentTrial) = randi([0,MaxRandomScans]); % determine amount of extra scans to add
                    DAQ.queueOutputData(cat(1,Triggers,zeros(TrialInfo.numRandomScansPost(currentTrial),numel(OutChannels)))); % queue normal control triggers with extra scans
                end
            end
            
            % Update buffer
            if ~MaxRandomScans
                BufferStim = cat(1, BufferStim, Stimulus*currentTrial);
            else
                BufferStim = cat(1, BufferStim, Stimulus*currentTrial, zeros(TrialInfo.numRandomScansPost(currentTrial),1));
            end
            
            % Update information
            fprintf('\nQueued trial %d: stimulus %d', currentTrial, TrialInfo.StimID(currentTrial));
            if saveOut
                save(SaveFile, 'TrialInfo', '-append');
            end
            
        elseif Started && ~ExperimentReachedEnd % experiment occurred and queued its final trial
            % Queue blank period to ensure last trial does not have to be
            % repeated and to ensure no within trial frames get clipped
            DAQ.queueOutputData(zeros(2*DAQ.NotifyWhenScansQueuedBelow, numel(OutChannels)));
            BufferStim = cat(1, BufferStim, zeros(2*DAQ.NotifyWhenScansQueuedBelow, 1));
            ExperimentReachedEnd = true;
        
        else % experiment is complete -> don't queue more scans
            if currentTrial >= str2double(numTrialsObj.String)
                fprintf('\nComplete: finished %d trials(s) (max trials reached)\n', currentTrial);
            elseif ~hObject.Value
                fprintf('\nComplete: finished %d trial(s) (user quit)\n', currentTrial);     
            end
        end
    end

end


%% Send Text
function send_text_message(number,carrier,subject,message)
% SEND_TEXT_MESSAGE send text message to cell phone or other mobile device.
%    SEND_TEXT_MESSAGE(NUMBER,CARRIER,SUBJECT,MESSAGE) sends a text message
%    to mobile devices in USA. NUMBER is your 10-digit cell phone number.
%    CARRIER is your cell phone service provider, which can be one of the
%    following: 'Alltel', 'AT&T', 'Boost', 'Cingular', 'Cingular2',
%    'Nextel', 'Sprint', 'T-Mobile', 'Verizon', or 'Virgin'. SUBJECT is the
%    subject of the message, and MESSAGE is the content of the message to
%    send.
% 
%    Example:
%      send_text_message('234-567-8910','Cingular', ...
%         'Calculation Done','Don't forget to retrieve your result file')
%      send_text_message('234-567-8910','Cingular', ...
%         'This is a text message without subject')
%
%   See also SENDMAIL.
%
% You must modify the first two lines of the code (code inside the double 
% lines) before using.

% Ke Feng, Sept. 2007
% Please send comments to: jnfengke@gmail.com
% $Revision: 1.0.0.0 $  $Date: 2007/09/28 16:23:26 $

% =========================================================================
% YOU NEED TO TYPE IN YOUR OWN EMAIL AND PASSWORDS:
mail = 'adesnik.colony@gmail.com';    %Your GMail email address
% mail = 'matlabsendtextmessage@gmail.com';    %Your GMail email address
password = 'matlabtext';          %Your GMail password
% and disable security: https://www.google.com/settings/security/lesssecureapps
% =========================================================================

if nargin == 3
    message = subject;
    subject = '';
end

% Format the phone number to 10 digit without dashes
number = strrep(number, '-', '');
if length(number) == 11 && number(1) == '1';
    number = number(2:11);
end

% Information found from
% http://www.sms411.net/2006/07/how-to-send-email-to-phone.html
switch strrep(strrep(lower(carrier),'-',''),'&','')
    case 'alltel';    emailto = strcat(number,'@message.alltel.com');
    case 'att';       emailto = strcat(number,'@txt.att.net');
    case 'boost';     emailto = strcat(number,'@myboostmobile.com');
    case 'cricket';   emailto = strcat(number,'@sms.mycricket.com');
    case 'sprint';    emailto = strcat(number,'@messaging.sprintpcs.com');
    case 'tmobile';   emailto = strcat(number,'@tmomail.net');
    case 'verizon';   emailto = strcat(number,'@vtext.com');
    case 'virgin';    emailto = strcat(number,'@vmobl.com');
end

%% Set up Gmail SMTP service.
% Note: following code found from
% http://www.mathworks.com/support/solutions/data/1-3PRRDV.html
% If you have your own SMTP server, replace it with yours.

% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);

% The following four lines are necessary only if you are using GMail as
% your SMTP server. Delete these lines wif you are using your own SMTP
% server.
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

%% Send the email
sendmail(emailto,subject,message)

if strcmp(mail,'matlabsendtextmessage@gmail.com')
    disp('Please provide your own gmail for security reasons.')
    disp('You can do that by modifying the first two lines ''send_text_message.m''')
    disp('after the bulky comments.')
end
end