DAQ = daq.createSession('ni');
DAQ.addDigitalChannel('Dev1', 'port0/line17', 'OutputOnly');
DAQ.addDigitalChannel('Dev1', 'port0/line18', 'InputOnly');
DAQ.Rate = 30000;

daqClock = daq.createSession('ni');
daqClock.addCounterOutputChannel('Dev1',0,'PulseGeneration');
clkTerminal = daqClock.Channels(1).Terminal;
daqClock.Channels(1).Frequency = DAQ.Rate;
daqClock.IsContinuous = true;
daqClock.startBackground;
DAQ.addClockConnection('External',['Dev1/' clkTerminal],'ScanClock');

trig = zeros(round(7*DAQ.Rate), 1);
trig(1) = 1;
% trig(2:round(2*DAQ.Rate):round(6*DAQ.Rate)) = 1;
% trig(1:round(DAQ.Rate/200):round(3*DAQ.Rate)) = 1;

DAQ.queueOutputData(trig);

out = DAQ.startForeground;
clear DAQ daqClock

first = out-[0;out(1:end-1)];
first = first>0;
numFramesRequested = sum(trig)
numFramesRecorded = sum(first)