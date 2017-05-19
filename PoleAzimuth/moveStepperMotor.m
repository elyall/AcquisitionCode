function triggers = moveStepperMotor(RelativeAngle, samplingFrequency, indexStep, indexDir, DAQ, numOutPorts)
% RelativeAngle <0 means CW movement, and >0 means CCW

baseangle = 0.09; %length of a single microstep in degrees
analog = true;

%% Parse input arguments
if ~exist('RelativeAngle', 'var') || isempty(RelativeAngle)
    RelativeAngle = 30;
end

if ~exist('samplingFrequency', 'var') || isempty(samplingFrequency)
    samplingFrequency = 30000;
end

if ~exist('indexStep', 'var') || isempty(indexStep)
    indexStep = 1;
end

if ~exist('indexDir', 'var') || isempty(indexDir)
    indexDir = 2;
end

if ~exist('DAQ', 'var') || isempty(DAQ)
    DAQ = false;
elseif isequal(DAQ, true)
    DAQ = daq.createSession('ni'); % initialize session
    DAQ.Rate = samplingFrequency;
    if analog
        [~,id] = DAQ.addAnalogOutputChannel('Dev1',0:1,'Voltage');
    else
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line4:5','OutputOnly');
    end
    DAQ.Channels(id(1)).Name = 'O_MotorStep';
    DAQ.Channels(id(2)).Name = 'O_MotorDir';
    clearDAQ = true;
end

if ~exist('numOutPorts', 'var') || isempty(numOutPorts)
    numOutPorts = 2;
end

Slow = 27;  % # of zeros in each slow step (sets start and end speed of motor)
Fast = 7;   % # of zeros in each fast step (set maximum speed allowed)


%% Create step triggers

numSteps = abs(round(RelativeAngle*1/baseangle)); %number of microsteps motor will make

% Create acceleration and decceleration steps
n = Slow-Fast; % # of steps in accel & deccel
if 2*n > numSteps %if acceleration and decceleration will move further than requested
    n = floor(numSteps/2); %only move the distance requested within the acceleration and decceleration
    Fast = Slow - n;
end
stepScan = cumsum([1,Slow:-1:(Slow-n)]);
accel = zeros(max(stepScan),1);
accel(stepScan) = 1;
deccel = flip(accel);
 
% Create center steps
numStepsMiddle = numSteps - 2*n;
steps = repmat([1;zeros(Fast,1)],numStepsMiddle,1);

% Create final trigger vector
stepTriggers = cat(1,0,accel,zeros(Fast,1),steps,deccel,0);


%% Create output
triggers = zeros(numel(stepTriggers), numOutPorts);
triggers(:,indexStep) = stepTriggers;


%% Set direction
if RelativeAngle < 0 % CW
    triggers(1:end-1,indexDir) = 1;
end

%% Digital to analog
if analog
    triggers = 5*triggers;
end

%% Move motor
if ~isequal(DAQ, false)
    DAQ.queueOutputData(triggers);
    DAQ.startForeground;
    if exist('clearDAQ', 'var')
        clear DAQ
    end
end