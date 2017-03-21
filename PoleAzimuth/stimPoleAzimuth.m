function [TrialInfo, SaveFile] = stimPoleAzimuth(SaveFile, varargin)


%% Configure Settings
gd.Internal.ImagingType = 'scim';               % 'sbx' or 'scim'
gd.Internal.ImagingComp.ip = '128.32.173.30';   % SCANBOX ONLY: for UDP
gd.Internal.ImagingComp.port = 7000;            % SCANBOX ONLY: for UDP

Display.units = 'pixels';
Display.position = [400, 400, 1400, 600];

gd.Internal.save.path = 'C:\Users\Resonant-2\OneDrive\StimData';
if ~isdir(gd.Internal.save.path)
    gd.Internal.save.path = cd;
end
gd.Internal.save.base = '0000';
gd.Internal.save.depth = '000';
gd.Internal.save.index = '000';
gd.Internal.save.save = true;

gd.Experiment.saving.SaveFile = fullfile(gd.Internal.save.path, gd.Internal.save.base);
gd.Experiment.saving.DataFile = '';
gd.Experiment.saving.dataPrecision = 'uint16';

gd.Experiment.timing.stimDuration = 1.5;    % in seconds
gd.Experiment.timing.ITI = 4.5;             % in seconds
gd.Experiment.timing.randomITImax = 2;      % in seconds

gd.Experiment.params.samplingFrequency = 30000;
gd.Experiment.params.numTrials = 5;             % positive integer: default # of trials to present
gd.Experiment.params.randomITI = false;         % booleon:          add on random time to ITI?
gd.Experiment.params.catchTrials = true;        % booleon:          give control stimulus?
gd.Experiment.params.numCatchesPerBlock = 1;    % positive integer: default # of catch trials to present per block
gd.Experiment.params.repeatBadTrials = false;   % booleon:          repeat non-running trials
gd.Experiment.params.speedThreshold = 100;      % positive scalar:  velocity threshold for good running trials (deg/s)
gd.Experiment.params.whiskerTracking = false;   % booleon:          send triggers for whisker tracking camera?
gd.Experiment.params.frameRateWT = 200;         % positive scalar:  frame rate of whisker tracking
gd.Experiment.params.blockShuffle = true;       % booleon:          shuffle block order each block?
gd.Experiment.params.runSpeed = true;           % booleon;          record rotary encoder's velocity? % temporarily commented out
gd.Experiment.params.holdStart = true;          % booleon:          wait to start experiment until after first frame trigger received?
gd.Experiment.params.delay = 3;                 % positive scalar:  amount of time to delay start of experiment (either after first frame trigger received)

% Text user details
gd.Internal.textUser.number = '7146241885';
gd.Internal.textUser.carrier = 'att';

% Properties for display or processing input data
gd.Internal.buffer.numTrials = 2;           %4*gd.Experiment.params.samplingFrequency * (gd.Experiment.timing.stimDuration+gd.Experiment.timing.ITI);
gd.Internal.buffer.downSample = 30;

% Stim dependent variables
gd.Experiment.params.angleMove = 30;        % positive scalar:  default angle for stepper motor to move each trial
gd.Internal.LinearStage.APport = 'com3';    % string:           specifies port
gd.Internal.LinearStage.MLport = 'com4';    % string:           specifies port


%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

if exist('SaveFile', 'var')
    gd.Experiment.saving.SaveFile = SaveFile;
    gd.Internal.save = true;
end


%% Create & Populate Figure

% Create figure
gd.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Stimulus: Vertical Pole',...
    'ToolBar',              'none',...
    'Units',                Display.units,...
    'Position',             Display.position);%,...
% 'KeyPressFcn',          @(hObject,eventdata)KeyPressCallback(hObject, eventdata, guidata(hObject)));

% Create Panels
gd.Saving.panel = uipanel(...
    'Title',                'Filename',...
    'Parent',               gd.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .8, .4, .2]);
gd.Controls.panel = uipanel(...
    'Title',                'Controls',...
    'Parent',               gd.fig,...
    'Units',                'Normalized',...
    'Position',             [0, 0, .15, .8]);
gd.Stimuli.panel = uipanel(...
    'Title',                'Stimuli',...
    'Parent',               gd.fig,...
    'Units',                'Normalized',...
    'Position',             [.15, 0, .25, .8]);
gd.Parameters.panel = uipanel(...
    'Title',                'Parameters',...
    'Parent',               gd.fig,...
    'Units',                'Normalized',...
    'Position',             [.4, 0, .25, 1]);
gd.Run.panel = uipanel(...
    'Title',                'Run Experiment',...
    'Parent',               gd.fig,...
    'Units',                'Normalized',...
    'Position',             [.65, 0, .35, 1]);

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

% CONTROLS
% stepper motor text
gd.Controls.stepperMotorText = uicontrol(...
    'Style',                'text',...
    'String',               'Move stepper (relative)',...
    'Parent',               gd.Controls.panel,...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.85,1,.05]);
% stepper motor CCW
gd.Controls.stepCCW = uicontrol(...
    'Style',                'pushbutton',...
    'String',               '<CCW',...
    'Parent',               gd.Controls.panel,...
    'Units',                'normalized',...
    'Position',             [0,.75,.35,.1],...
    'Callback',             @(hObject,eventdata)stepCCW(hObject, eventdata, guidata(hObject)));
% stepper motor degrees
gd.Controls.stepAngle = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.angleMove,...
    'Parent',               gd.Controls.panel,...
    'Units',                'normalized',...
    'Position',             [.35,.75,.3,.1]);
% stepper motor CW
gd.Controls.stepCW = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'CW>',...
    'Parent',               gd.Controls.panel,...
    'Units',                'normalized',...
    'Position',             [.65,.75,.35,.1],...
    'Callback',             @(hObject,eventdata)stepCW(hObject, eventdata, guidata(hObject)));
% anterior-posterior linear motor text
gd.Controls.apMotorText = uicontrol(...
    'Style',                'text',...
    'String',               'Move anterior-posterior (absolute)',...
    'Parent',               gd.Controls.panel,...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.6,1,.1]);
% anterior-posterior linear motor position
gd.Controls.apMotorPos = uicontrol(...
    'Style',                'edit',...
    'String',               '0',...
    'Parent',               gd.Controls.panel,...
    'Units',                'normalized',...
    'UserData',             'ap',...
    'Position',             [.35,.5,.3,.1],...
    'Callback',             @(hObject,eventdata)linearMotorPos(hObject, eventdata, guidata(hObject)));
% medial-lateral linear motor text
gd.Controls.mlMotorText = uicontrol(...
    'Style',                'text',...
    'String',               'Move medial-lateral (absolute)',...
    'Parent',               gd.Controls.panel,...
    'HorizontalAlignment',  'center',...
    'Units',                'normalized',...
    'Position',             [0,.35,1,.1]);
% medial-lateral linear motor position
gd.Controls.mlMotorPos = uicontrol(...
    'Style',                'edit',...
    'String',               '0',...
    'Parent',               gd.Controls.panel,...
    'Units',                'normalized',...
    'UserData',             'ml',...
    'Position',             [.35,.25,.3,.1],...
    'Callback',             @(hObject,eventdata)linearMotorPos(hObject, eventdata, guidata(hObject)));

% STIMULI
% load stimuli
gd.Stimuli.load = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Load',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [0,.9,.5,.1],...
    'Callback',             @(hObject,eventdata)LoadStimuli(hObject, eventdata, guidata(hObject)));
% save stimuli
gd.Stimuli.save = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Save',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.5,.9,.5,.1],...
    'Enable',               'off',...
    'Callback',             @(hObject,eventdata)SaveStimuli(hObject, eventdata, guidata(hObject)));
% position table
gd.Stimuli.positionTable = uitable(...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [0,.7,1,.2],...
    'RowName',              {'AP','ML'},...
    'ColumnName',           {'Active?','First (mm)','Last (mm)','# Steps'},...
    'ColumnEditable',       [true,true,true,true],...
    'ColumnFormat',         {'logical','numeric','numeric','numeric'},...
    'ColumnWidth',          {50,70,70,70},...
    'Data',                 [{true;false},num2cell([zeros(2,1),[17.5;7.5],[8;4]])],...
    'CellEditCallback',     @(hObject,eventdata)EditStimInputs(hObject, eventdata, guidata(hObject)));
% stimuli list
gd.Stimuli.list = uitable(...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'Normalized',...
    'Position',             [0,0,.6,.7],...
    'ColumnName',           {'AP Pos','ML Pos','Delete'},...
    'ColumnFormat',         {'numeric','numeric','logical'},...
    'ColumnEditable',       [true,true,true],...
    'ColumnWidth',          {72,72,50},...
    'CellEditCallback',     @(hObject,eventdata)EditStimuli(hObject, eventdata, guidata(hObject)));
% choose type
gd.Stimuli.type = uicontrol(...
    'Style',                'popupmenu',...
    'String',               {'Grid';'Random'},...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.65,.4,.05]);
% toggle weighting
gd.Stimuli.weightToggle = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Weight sampling?',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.6,.4,.05],...
    'UserData',             {'Weight sampling?','Weighting samples'},...
    'Callback',             @(hObject,eventdata)ChangeStimuliSampling(hObject,eventdata,guidata(hObject)));
% number of samples
gd.Stimuli.numSamples = uicontrol(...
    'Style',                'edit',...
    'String',               '0',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.5,.2,.1]);
gd.Stimuli.numSamplesText = uicontrol(...
    'Style',                'text',...
    'String',               '# samples',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.5,.2,.075],...
    'HorizontalAlignment',  'right');
% set AP sampling weights
gd.Stimuli.apDistWeights = uicontrol(...
    'Style',                'edit',...
    'String',               num2str([1,1]),...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Enable',               'off',...
    'Position',             [.7,.4,.3,.1]);
gd.Stimuli.apText = uicontrol(...
    'Style',                'text',...
    'String',               'AP:',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.4,.1,.075],...
    'HorizontalAlignment',  'right');
% set ML sampling weights
gd.Stimuli.mlDistWeights = uicontrol(...
    'Style',                'edit',...
    'String',               num2str([1,1]),...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Enable',               'off',...
    'Position',             [.7,.3,.3,.1]);
gd.Stimuli.mlText = uicontrol(...
    'Style',                'text',...
    'String',               'ML:',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.3,.1,.075],...
    'HorizontalAlignment',  'right');
% create stimuli
gd.Stimuli.generateStimuli = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Generate Stimuli',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,.1,.4,.2],...
    'Callback',             @(hObject,eventdata)GenerateStimuli(hObject, eventdata, guidata(hObject)));
% view stimuli
gd.Stimuli.view = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'View',...
    'Parent',               gd.Stimuli.panel,...
    'Units',                'normalized',...
    'Position',             [.6,0,.4,.1],...
    'Enable',               'off',...
    'Callback',             @(hObject,eventdata)ViewStimuli(hObject, eventdata, guidata(hObject)));

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
    'HorizontalAlignment',  'right',...
    'Units',                'normalized',...
    'Position',             [w1,.3,w2,.1]);
gd.Parameters.delay = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Experiment.params.delay,...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [w1+w2,.3,w3,.1]);
% block shuffle toggle
gd.Parameters.shuffle = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Shuffle blocks?',...
    'Parent',               gd.Parameters.panel,...
    'Units',                'normalized',...
    'Position',             [0,.2,.5,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Shuffle blocks?','Shuffling blocks'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));
% record run speed
gd.Parameters.runSpeed = uicontrol(...
    'Style',                'checkbox',...
    'String',               'Record velocity?',...
    'Parent',               gd.Parameters.panel,...
    'Enable',               'off',... % temporary
    'Units',                'normalized',...
    'Position',             [.5,.2,.5,.1],...
    'UserData',             {[.94,.94,.94;0,1,0],'Record velocity?','Recording velocity'},...
    'Callback',             @(hObject,eventdata)set(hObject,'BackgroundColor',hObject.UserData{1}(hObject.Value+1,:),'String',hObject.UserData{hObject.Value+2}));

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

guidata(gd.fig, gd); % save guidata

%% Initialize Defaults

% Saving
if gd.Internal.save.save
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
    set(gd.Parameters.shuffle,'Value',true,'String','Shuffling blocks','BackgroundColor',[0,1,0]);
end
% Record velocity
% if gd.Experiment.params.runSpeed % temporarily commented out
    set(gd.Parameters.runSpeed,'Value',true,'String','Recording velocity','BackgroundColor',[0,1,0]);
% end % temporarily commented out
% Hold start
if gd.Experiment.params.holdStart
    set(gd.Parameters.holdStart,'Value',true,'String','Waiting for frame trigs','BackgroundColor',[0,1,0]);
end

CreateFilename(gd.Saving.FullFilename, [], gd);

% For timing
% gd=guidata(gd.fig);
% gd.Run.run.Value = true;
% RunExperiment(gd.Run.run,[],gd); % timing debugging
end


%% SAVING CALLBACKS

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


%% CONTROLS CALLBACKS

function stepCCW(hObject, eventdata, gd)
moveStepperMotor(str2num(gd.Controls.stepAngle.String), gd.Experiment.params.samplingFrequency, 1, 2, true, 2);
fprintf('Motor: Stepper motor moved %d degrees CCW\n', str2num(gd.Controls.stepAngle.String));
end

function stepCW(hObject, eventdata, gd)
moveStepperMotor(-str2num(gd.Controls.stepAngle.String), gd.Experiment.params.samplingFrequency, 1, 2, true, 2);
fprintf('Motor: Stepper motor moved %d degrees CW\n', str2num(gd.Controls.stepAngle.String));
end

function linearMotorPos(hObject, eventdata, gd)
if str2num(hObject.String) < 0
    hObject.String = '0';
elseif str2num(hObject.String) > 25
    hObject.String = '25';
end
switch hObject.UserData
    case 'ap'
        H_LinearStage = serial(gd.Internal.LinearStage.APport, 'BaudRate', 9600);
        fopen(H_LinearStage);
        moveLinearMotor(str2num(gd.Controls.apMotorPos.String), H_LinearStage); %move linear motor
        fclose(H_LinearStage);
        fprintf('Anterior-Posterior motor: moved to position %.1f mm down track\n', str2num(gd.Controls.apMotorPos.String));
        clear H_LinearStage;
    case 'ml'
        H_LinearStage = serial(gd.Internal.LinearStage.MLport, 'BaudRate', 9600);
        fopen(H_LinearStage);
        moveLinearMotor(str2num(gd.Controls.mlMotorPos.String), H_LinearStage); %move linear motor
        fclose(H_LinearStage);
        fprintf('Medial-Lateral motor: Linear motor moved to position %.1f mm down track\n', str2num(gd.Controls.mlMotorPos.String));
        clear H_LinearStage;
end
end


%% STIMULI CALLBACKS
function LoadStimuli(hObject, eventdata, gd)
% Select and load file
[f,p] = uigetfile({'*.stim';'*.mat'},'Select stim file to load',cd);
if isnumeric(f)
    return
end
load(fullfile(p,f), 'stimuli', '-mat');
fprintf('Loaded stimuli from: %s\n', fullfile(p,f));

% Load stimuli
gd.Stimuli.list.Data = num2cell(stimuli); % display stimuli
gd.Experiment.Position = stimuli;         % save loaded stimuli
guidata(hObject, gd);
end

function SaveStimuli(hObject, eventdata, gd)
% Determine file to save to
[f,p] = uiputfile({'*.stim';'*.mat'},'Save stimuli as?',cd);
if isnumeric(f)
    return
end
saveFile = fullfile(p,f);

% Save stimuli
stimuli = gd.Experiment.Position;
if ~exist(saveFile,'file')
    save(fullfile(p,f), 'stimuli', '-mat', '-v7.3');
else
    save(fullfile(p,f), 'stimuli', '-mat', '-append');
end
fprintf('Stimuli saved to: %s\n', fullfile(p,f));
end

function EditStimInputs(hObject, eventdata, gd)
val = hObject.Data{eventdata.Indices(1),eventdata.Indices(2)};
if eventdata.Indices(2)==1
    temp = {gd.Stimuli.apDistWeights, gd.Stimuli.mlDistWeights};
    if val && gd.Stimuli.weightToggle.Value
        set(temp{eventdata.Indices(1)}, 'Enable', 'on');
    else
        set(temp{eventdata.Indices(1)}, 'Enable', 'off');
    end
elseif eventdata.Indices(2)==2 && val < 0
    hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = 0;
elseif eventdata.Indices(2)==3 && val > 25
    hObject.Data{eventdata.Indices(1),eventdata.Indices(2)} = 25;
end
end

function ChangeStimuliSampling(hObject,eventdata,gd)
objs = [gd.Stimuli.apDistWeights, gd.Stimuli.mlDistWeights];
if hObject.Value
    toggle = [gd.Stimuli.positionTable.Data{:,1}];
    set(objs(toggle),'Enable','on');
else
    set(objs,'Enable','off');
end
end

function GenerateStimuli(hObject, eventdata, gd)
% Gather inputs
toggle = [gd.Stimuli.positionTable.Data{:,1}];
if ~any(toggle)
    error('Need at least one active axis!');
end
stimParams = cell2mat(gd.Stimuli.positionTable.Data(:,2:end));

% Determine # of samples
numSamples = str2num(gd.Stimuli.numSamples.String);
if isempty(numSamples)
    numSamples = 0;
end

% Determine weights
if gd.Stimuli.weightToggle.Value
    weights = {str2num(gd.Stimuli.apDistWeights.String), str2num(gd.Stimuli.mlDistWeights.String)};
    weights = weights(toggle);
else
    weights = {};
end

% Generate stimuli
if gd.Stimuli.type.Value == 1
    stimuli = genDistribution(numSamples,stimParams(toggle',:),'Distribution','grid','Weights',weights);
elseif gd.Stimuli.type.Value == 2
    stimuli = genDistribution(numSamples,stimParams(toggle',:),'Distribution','random','Weights',weights);
end
out = nan(size(stimuli,1),numel(toggle));
out(:,toggle) = stimuli;

gd.Experiment.Position = out; % Update registry
guidata(hObject, gd);
gd.Stimuli.list.Data = out; % display stimuli
gd.Stimuli.view.Enable = 'on';
end

function ViewStimuli(hObject, eventdata, gd)
stimuli = gd.Experiment.Position;
if any(isnan(stimuli(:)))
    stimuli(:,any(isnan(stimuli),1))=[];
    numDims = 1;
else
    numDims=2;
end
nbins = 20;
figure;
if numDims == 1
    subplot(1,2,1); plot(zeros(size(stimuli,1),1),stimuli,'k.'); ylabel('Value');
    subplot(1,2,2); histogram(stimuli,nbins); xlabel('Position'); ylabel('count');
elseif numDims == 2
    subplot(1,3,1); plot(stimuli(:,2),stimuli(:,1),'k.'); xlabel('ML'); ylabel('AP');
    subplot(1,3,2); histogram(stimuli(:,2),nbins); xlabel('ML Position'); ylabel('count'); 
    subplot(1,3,3); histogram(stimuli(:,1),nbins); xlabel('AP Position'); ylabel('count'); 
end
end

function EditStimuli(hObject, eventdata, gd)
if eventdata.Indices(2)==3
    gd.Experiment.Position(eventdata.Indices(1),:) = []; % remove stimulus
    guidata(hObject, gd);
    hObject.Data(eventdata.Indices(1),:) = []; % update display
end
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


%% RUN EXPERIMENT
function RunExperiment(hObject, eventdata, gd)

if hObject.Value
    try
        if ~isfield(gd.Experiment,'Position') || isempty(gd.Experiment.Position)
            error('No stimulus loaded! Please load some stimuli.');
        end
        Experiment = gd.Experiment;
        
        %% Record date & time information
        Experiment.timing.init = datestr(now);
        
        %% Determine filenames to save to
        if gd.Saving.save.Value
            saveOut = true;
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
            saveOut = false;
        end
        
        %% Set parameters
        
        Experiment.imaging.ImagingType = gd.Parameters.imagingType.String{gd.Parameters.imagingType.Value};
        Experiment.imaging.ImagingMode = gd.Parameters.imagingMode.String;
        
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
        
        % Stim specific
        Experiment.params.angleMove = str2double(gd.Controls.stepAngle.String);

        %% Initialize button
        hObject.BackgroundColor = [0,0,0];
        hObject.ForegroundColor = [1,1,1];
        hObject.String = 'Stop';
        
        %% Initialize NI-DAQ session
        gd.Internal.daq = [];
        
        DAQ = daq.createSession('ni');                  % initialize session
        DAQ.IsContinuous = true;                        % set session to be continuous (call's 'DataRequired' listener)
        DAQ.Rate = Experiment.params.samplingFrequency; % set sampling frequency
        Experiment.params.samplingFrequency = DAQ.Rate; % the actual sampling frequency is rarely perfect from what is input
        
        % Add ports
        
        % Imaging Computer Trigger (for timing)
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line0','OutputOnly');
        DAQ.Channels(id).Name = 'O_2PTrigger';
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line1','InputOnly');
        DAQ.Channels(id).Name = 'I_FrameCounter';
        
        % Motor Rotation
        [~,id] = DAQ.addAnalogOutputChannel('Dev1',0:1,'Voltage');
        % [~,id] = DAQ.addDigitalChannel('Dev1','port0/line4:5','OutputOnly');
        DAQ.Channels(id(1)).Name = 'O_MotorStep';
        DAQ.Channels(id(2)).Name = 'O_MotorDir';
        
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
        
%         % Add clock
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

        
        %% Determine stimuli
        
        % Determine axes
        Experiment.stim.activeAxes = false(1,2);
        for aindex = 1:2
            if ~any(isnan(Experiment.Position(:,aindex)))
                Experiment.stim.activeAxes(aindex) = true;
            end
        end
        
        % Determine stimulus IDs
        [Experiment.Position,~,Block] = unique(Experiment.Position,'rows');
        Experiment.StimID = 1:size(Experiment.Position,1);
        if Experiment.params.catchTrials
            Experiment.StimID = [0, Experiment.StimID];
            Block = [zeros(Experiment.params.numCatchesPerBloc,1); Block];
            Experiment.Position = [nan(1,2); Experiment.Position];
        end
        numStimuli = numel(Experiment.StimID);

        
        %% Create triggers
        
        % Compute timing of each trial
        Experiment.timing.trialDuration = Experiment.timing.stimDuration + Experiment.timing.ITI;
        Experiment.timing.numScansPerTrial = ceil(Experiment.params.samplingFrequency * Experiment.timing.trialDuration);
        
        % Adjust Callback timing so next trial is queued right after previous trial starts
        DAQ.NotifyWhenScansQueuedBelow = Experiment.timing.numScansPerTrial - startTrig;
        
        % Initialize blank triggers
        Experiment.Triggers = zeros(Experiment.timing.numScansPerTrial, numel(OutChannels), Experiment.params.catchTrials+1);
        
        % Build stepper motor triggers
        stepTriggers = moveStepperMotor(Experiment.params.angleMove, Experiment.params.samplingFrequency, 1, 2, false, 2);
        numStepTriggers = size(stepTriggers, 1);
        
        % Determine timing
        numITITriggers = floor(Experiment.params.samplingFrequency * Experiment.timing.ITI);    
        if numITITriggers < 2*numStepTriggers
            error('Not enough time for bar to move in and out');
        end
        startTrig = numITITriggers-numStepTriggers+1;                    % move during end of ITI but leave room for bar moving out
        endTrig = Experiment.timing.numScansPerTrial-numStepTriggers+1;  % bar moving out occurs during ITI but is queued with previous trial

        % Trigger imaging computer on every single trial
        Experiment.Triggers([startTrig, endTrig], strcmp(OutChannels,'O_2PTrigger'), :) = 1; % trigger at beginning and end of stimulus
        % Experiment.Triggers(startTrig:endTrig-1, strcmp(OutChannels,'O_2PTrigger'), :) = 1; % high during whole stimulus
        
        % Move In Stepper Motor
        stopMove = startTrig-1;
        beginMove = stopMove-numStepTriggers+1;
        Experiment.Triggers(beginMove:stopMove, strcmp(OutChannels,'O_MotorStep'), 1) = stepTriggers(:,1);
        if Experiment.params.catchTrials
            Experiment.Triggers(beginMove:stopMove, strcmp(OutChannels,'O_MotorStep'), 2) = stepTriggers(:,1);
            Experiment.Triggers(beginMove:stopMove-1, strcmp(OutChannels,'O_MotorDir'), 2) = 5;
        end
        
        % Move Out Stepper Motor
        beginMove = Experiment.timing.numScansPerTrial-numStepTriggers+1;
        stopMove = Experiment.timing.numScansPerTrial;
        Experiment.Triggers(beginMove:stopMove, strcmp(OutChannels,'O_MotorStep'), 1) = stepTriggers(:,1);
        Experiment.Triggers(beginMove:stopMove-1, strcmp(OutChannels,'O_MotorDir'), 1) = 5;
        if Experiment.params.catchTrials
            Experiment.Triggers(beginMove:stopMove, strcmp(OutChannels,'O_MotorStep'), 2) = stepTriggers(:,1);
        end
        
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
        
        
        %% Initialize linear motors
        if Experiment.stim.activeAxes(1)
            H_LinearStage(1) = serial(gd.Internal.LinearStage.APport, 'BaudRate', 9600);
            fopen(H_LinearStage(1));
        end
        if Experiment.stim.activeAxes(2)
            H_LinearStage(2) = serial(gd.Internal.LinearStage.MLport, 'BaudRate', 9600);
            fopen(H_LinearStage(2));
        end
        
        
        %% Initialize imaging session (scanbox only)
        if strcmp(Experiment.imaging.ImagingType, 'sbx')
            H_Scanbox = udp(gd.Internal.ImagingComp.ip, 'RemotePort', gd.Internal.ImagingComp.port); % create udp port handle
            fopen(H_Scanbox);
            fprintf(H_Scanbox,sprintf('A%s',gd.Saving.base.String));
            fprintf(H_Scanbox,sprintf('U%s',gd.Saving.depth.String));
            fprintf(H_Scanbox,sprintf('E%s',gd.Saving.index.String));
        end
        
        
        %% Initialize saving
        if saveOut
            save(SaveFile, 'DAQChannels', 'Experiment', '-mat', '-v7.3');
            H_DataFile = fopen(Experiment.saving.DataFile, 'w');
        end
        
        
        %% Initialize shared variables (only share what's necessary)
        
        % Necessary variables
        numTrialsObj = gd.Run.numTrials;
        ImagingType = Experiment.imaging.ImagingType;
        ImagingMode = Experiment.imaging.ImagingMode;
        numScansBaseline = Experiment.params.samplingFrequency * numSecondsBaseline;
        currentBlockOrder = Block;
        numBlock = numel(currentBlockOrder);
        ControlTrial = Experiment.params.catchTrials;
        BlockShuffle = Experiment.params.blockShuffle;
        currentTrial = 0;
        TrialInfo = struct('StimID', [], 'Running', [], 'RunSpeed', []);
        Stimulus = Experiment.Stimulus;
        ExperimentReachedEnd = false; % boolean to see if max trials has been reached
        
        % Stim dependent
        ActiveAxes = find(Experiment.stim.activeAxes);
        Triggers = Experiment.Triggers;
        Positions = Experiment.Position;
        preppedTrial = false;
        currentNewTrial = 0;

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
        
        % Variables for calculating and displaying running speed
        RunChannelIndices = [find(strcmp(InChannels, 'I_RunWheelB')),find(strcmp(InChannels,'I_RunWheelA'))];
        numBufferScans = gd.Internal.buffer.numTrials*Experiment.timing.numScansPerTrial;
        DataInBuffer = zeros(numBufferScans, 2);
        dsamp = gd.Internal.buffer.downSample;
        dsamp_Fs = Experiment.params.samplingFrequency / dsamp;
        smooth_win = gausswin(dsamp_Fs, 23.5/2);
        smooth_win = smooth_win/sum(smooth_win);
        sw_len = length(smooth_win);
        d_smooth_win = [0;diff(smooth_win)]/(1/dsamp_Fs);
        hAxes = gd.Run.runSpeedAxes;
        
        % Variables for displaying stim info
        numScansReturned = DAQ.NotifyWhenDataAvailableExceeds;
        BufferStim = zeros(numBufferScans, 1); % initialize with blank trial: QueueData will append another trial to it, and SaveDataIn will remove scans from it
        
        % Variables for determing if mouse was running
        RepeatBadTrials = Experiment.params.repeatBadTrials;
        StimuliToRepeat = [];
        SpeedThreshold = Experiment.params.speedThreshold;
        RunIndex = 1;
        
        
        %% Start Experiment
        
        % Start imaging
        if strcmp(Experiment.imaging.ImagingType, 'sbx')
            if ~strcmp(ImagingMode,'Trial Imaging')
                fprintf(H_Scanbox,'G'); % start imaging
            end
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
        if strcmp(Experiment.imaging.ImagingType, 'sbx')
            if ~strcmp(ImagingMode,'Trial Imaging')
                fprintf(H_Scanbox,'S'); % stop imaging
            end
            fclose(H_Scanbox);          % close connection
        end
        
        % If saving: append stop time, close file, & increment file index
        if saveOut
            save(SaveFile, 'Experiment', '-append');        % update with "Experiment.timing.finish" info
            fclose(H_DataFile);                             % close binary file
            gd.Saving.index.String = sprintf('%03d',str2double(gd.Saving.index.String) + 1); % increment file index for next experiment
            CreateFilename(gd.Saving.FullFilename, [], gd); % update filename for next experiment
        end
        
        % Text user
        if gd.Run.textUser.Value
            send_text_message(gd.Internal.textUser.number,gd.Internal.textUser.carrier,'',sprintf('Experiment finished at %s',Experiment.timing.finish(end-7:end)));
        end
        
        % Close connections
        for findex = 1:size(H_LinearStage,2)
            fclose(H_LinearStage(findex));
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
            if strcmp(Experiment.imaging.ImagingType, 'sbx')
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
        
        % Refresh buffer
        DataInBuffer = cat(1, DataInBuffer(numScansReturned+1:end,:), eventdata.Data(:,RunChannelIndices));   % concatenate new data and remove old data
        BufferStim = BufferStim(numScansReturned+1:end); % remove corresponding old data from stimulus buffer
        
        % Convert entire buffer of pulses to run speed
        Data = [0;diff(DataInBuffer(:,1))>0];       % gather pulses' front edges
        Data(all([Data,DataInBuffer(:,2)],2)) = -1; % set backwards steps to be backwards
        Data = cumsum(Data);                        % convert pulses to counter data
        x_t = downsample(Data, dsamp);              % downsample data to speed up computation
        x_t = padarray(x_t, sw_len, 'replicate');   % pad for convolution
        dx_dt = conv(x_t, d_smooth_win, 'same');    % perform convolution
        dx_dt([1:sw_len,end-sw_len+1:end]) = [];    % remove values produced by padding the data
        % dx_dt = dx_dt * 360/360;                  % convert to degrees (360 pulses per 360 degrees)
        
        % Display new data and stimulus info
        currentStim = downsample(BufferStim(1:numBufferScans), dsamp);
        plot(hAxes, numBufferScans:-dsamp:1, dx_dt, 'b-', numBufferScans:-dsamp:1, 500*(currentStim>0), 'r-');
        ylim([-100,600]);
        
        % Record average running speed during stimulus period
        if any(diff(BufferStim(numBufferScans-numScansReturned:numBufferScans)) == -RunIndex) % stimulus ended during current DataIn call
            preppedTrial = false; % last stimulus ended -> prep next trial
            
            % Trial Imaging mode: stop recording data
            if strcmp(ImagingMode,'Trial Imaging') && strcmp(ImagingType,'sbx')
                fprintf(H_Scanbox,'S'); % stop recording
            end
            
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
            
        elseif strcmp(ImagingMode,'Trial Imaging') && any(diff(BufferStim(numBufferScans+1:numBufferScans+numScansBaseline)) == RunIndex) && strcmp(ImagingType,'sbx') % next stimulus starts within window
            fprintf(H_Scanbox,'G'); % start recording
        end %analyze last trial
        
        % Move motor(s) into position for next trial
        if currentTrial>=RunIndex && ~preppedTrial  % next trial has been queued -> move motors into position
            preppedTrial = true;
            
            if TrialInfo.StimID(RunIndex)==0        % next trial is a control trial
                temp = randi([ControlTrial+1,numStimuli]);
                for index=ActiveAxes
                    moveLinearMotor(Positions(temp,index), H_LinearStage(index)); %move motor
                end
            else                                    % next trial is not a control trial
                for index=ActiveAxes
                    moveLinearMotor(Positions(TrialInfo.StimID(RunIndex)+ControlTrial,index), H_LinearStage(index)); %move motor
                end
            end
        end %prep next trial
            
    end %SaveDateIn

%% Callback: QueueOutputData
    function QueueData(src,eventdata)
        
        % Queue next trial
        if ~Started % imaging system hasn't started yet, queue one "blank" trial
            DAQ.queueOutputData(zeros(2*DAQ.NotifyWhenScansQueuedBelow, numel(OutChannels)));
            BufferStim = cat(1, BufferStim, zeros(2*DAQ.NotifyWhenScansQueuedBelow, 1));
            
        elseif  hObject.Value && (currentTrial < str2double(numTrialsObj.String) || ~isempty(StimuliToRepeat)) % user hasn't quit, and requested # of trials hasn't been reached or no trials need to be repeated
            
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
            
            % First QueueData call: move motors into position for first trial
            if currentTrial == 1
                if TrialInfo.StimID(currentTrial)==0        % first trial is a control trial
                    temp = randi([ControlTrial+1,numStimuli]);
                    for index=ActiveAxes
                        moveLinearMotor(Positions(temp,index), H_LinearStage(index)); %move motor
                    end
                else                                        % first trial is not a control trial
                    for index=ActiveAxes
                        moveLinearMotor(Positions(TrialInfo.StimID(1)+ControlTrial,index), H_LinearStage(index)); %move motor
                    end
                end
            end
            
            % Queue triggers
            if TrialInfo.StimID(currentTrial) ~= 0              % current trial is not control trial
                if ~MaxRandomScans                              % do not add random ITI
                    DAQ.queueOutputData(Triggers(:,:,1));       % queue stim triggers
                else
                    TrialInfo.numRandomScansPost(currentTrial) = randi([0,MaxRandomScans]); % determine amount of extra scans to add
                    DAQ.queueOutputData(cat(1,Triggers(:,:,1),zeros(TrialInfo.numRandomScansPost(currentTrial),numel(OutChannels)))); % queue stim triggers with extra scans
                end
            else                                                % current trial is control trial
                if ~MaxRandomScans                              % do not add random ITI
                    DAQ.queueOutputData(Triggers(:,:,2));       % queue control triggers
                else
                    TrialInfo.numRandomScansPost(currentTrial) = randi([0,MaxRandomScans]); % determine amount of extra scans to add
                    DAQ.queueOutputData(cat(1,Triggers(:,:,2),zeros(TrialInfo.numRandomScansPost(currentTrial),numel(OutChannels)))); % queue control triggers with extra scans
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
            
        elseif ~ExperimentReachedEnd
            % Queue blank trial to ensure last trial does not have to be
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