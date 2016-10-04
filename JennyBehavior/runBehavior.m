function runBehavior(SaveFile, Fs)

if ~exist('SaveFile', 'var')
    SaveFile = test;
end

if ~exist('Fs', 'var')
    Fs = 30000;
end

%% Initialize NI-DAQ

% Create session
DAQ = daq.createSession('ni'); % initialize session
DAQ.IsContinuous = true; % set session to be continuous (call's 'DataRequired' listener)
DAQ.Rate = Fs; % set sampling frequency
Fs = DAQ.Rate; % the actual sampling frequency is rarely perfect from what is input

% Add clock
% daqClock = daq.createSession('ni');
% daqClock.addCounterOutputChannel('Dev1',0,'PulseGeneration')
% clkTerminal = daqClock.Channels(1).Terminal;
% daqClock.Channels(1).Frequency = DAQ.Rate;
% daqClock.IsContinuous = true;
% daqClock.startBackground;
% DAQ.addClockConnection('External',['Dev1/' clkTerminal],'ScanClock');

% Add ports
% Reward
[~,id]=DAQ.addDigitalChannel('Dev1','port0/line0','InputOnly');
DAQ.Channels(id).Name = 'Reward';
% Motor steps
[~,id]=DAQ.addCounterInputChannel('Dev1','ctr1','EdgeCount');
DAQ.Channels(id).Name = 'MotorSteps';
% Motor direction
[~,id]=DAQ.addDigitalChannel('Dev1','port0/line0','InputOnly');
DAQ.Channels(id).Name = 'MotorDirection';
% Licking
[~,id]=DAQ.addDigitalChannel('Dev1','port0/line0','InputOnly');
DAQ.Channels(id).Name = 'Lick';
% Answer Period
[~,id]=DAQ.addDigitalChannel('Dev1','port0/line0','InputOnly');
DAQ.Channels(id).Name = 'Period';

% Add DataIn callback
DAQ.addlistener('DataAvailable', @SaveDataIn);


%% Initialize Scanbox

% Initialize scanbox connection
Scanbox_handle = udp('128.32.19.203', 'RemotePort', 7000); % create udp port handle
fopen(Scanbox_handle);

% Write file identifiers
% fprintf(state.Scanbox_handle,sprintf('A%s',ScanboxAid));
% fprintf(state.Scanbox_handle,sprintf('U%s',ScanboxUid));
% fprintf(state.Scanbox_handle,sprintf('E%s',ScanboxEid));

%% Start experiment

fopen(SaveFile);
fprintf(Scanbox_handle,'G'); %go
DAQ.startBackground;

%% End experiment

hF = figure(...
    'NumberTitle', 'off',...
    'Name',                 'End session?',...
    'Units',                'Normalized',...
    'Position',             [.4,.4,.2,.2],...
    'Toolbar',              'none');
hO = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'End?',...
    'FontSize',             30,...
    'Parent',               hF,...
    'Units',                'normalized',...
    'Position',             [0,0,1,1],...
    'Callback',             @(hObject,eventData)set(hObject, 'String', 'Ending...', 'BackgroundColor', [1,0,0]),...
    'BackgroundColor',      [0,1,0],...
    'ForegroundColor',      [0,0,0]);

while ~get(hO, 'Value')
    pause(0.1);
end

close(hF);
fprintf(Scanbox_handle,'S'); %stop
fclose(SaveFile);

%% DataIn callback
    function SaveDataIn(src,event) % Display & Save Running Speed
        
        fwrite(SaveFile, event.Data, 'uint16');
        
    end %callback SaveDataIn

end %function runBehavior
