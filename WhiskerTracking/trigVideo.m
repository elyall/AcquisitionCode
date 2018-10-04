DAQ = daq.createSession('ni');
% DAQ.addDigitalChannel('Dev3', 'port0/line17', 'OutputOnly');
% DAQ.addDigitalChannel('Dev3', 'port0/line18', 'InputOnly');
DAQ.addDigitalChannel('Dev3', 'port0/line4', 'OutputOnly');
DAQ.addDigitalChannel('Dev3', 'port0/line3', 'InputOnly');
DAQ.Rate = 30000;

daqClock = daq.createSession('ni');
daqClock.addCounterOutputChannel('Dev3',0,'PulseGeneration');
clkTerminal = daqClock.Channels(1).Terminal;
daqClock.Channels(1).Frequency = DAQ.Rate;
daqClock.IsContinuous = true;
daqClock.startBackground;
DAQ.addClockConnection('External',['Dev3/' clkTerminal],'ScanClock');

WTUDP = udp('128.32.19.232',55000);
fopen(WTUDP);


%%

trig = zeros(round(2*DAQ.Rate), 1); % 7 seconds
% trig(1) = 1; % start
% trig(1:round(3*DAQ.Rate):round(7*DAQ.Rate)) = 1; % once every 3 seconds, for 6 seconds
for index = 0
    trig(round(4*index*DAQ.Rate)+1:round(DAQ.Rate/300):round((4*index+1.5)*DAQ.Rate)) = 1; % 200 Hz for 1 second
end

figure;
x=(1:numel(trig))/DAQ.Rate;
plot(x,trig);
ylim([-.1,1.1]);
xlim([x(1)-range(x)/20,x(end)+range(x)/20])
xlabel('Time (s)');
ylabel('Voltage (mV)');

%%
TrialIndex = 1;

DlgH = figure;
H = uicontrol('Style', 'PushButton', ...
                    'String', 'Break', ...
                    'Callback', 'delete(gcbf)');
while (ishandle(H))


DAQ.queueOutputData(trig);
in = DAQ.startForeground;
TrialIndex = TrialIndex + 1;

fprintf(WTUDP,'%d',TrialIndex);

first = in-[0;in(1:end-1)];
first = first>0;
fprintf('%d triggers sent;\t %d frames recorded\n',sum(trig),sum(first));

end

%% single trial w/ TCP
% u=udp('128.32.19.135',55000)
% fopen(u)

trig = zeros(round(3*DAQ.Rate), 1); % 3 seconds
trig(1:round(DAQ.Rate/300):round(1*DAQ.Rate)) = 1; % 200 Hz for 1 second

N=20;
in = zeros(length(trig),N);
for index = 1:N
    DAQ.queueOutputData(trig);
    in(:,index) = DAQ.startForeground;
    fprintf(u,sprintf('%d',index+1));
end
in = in(:);
trig = repmat(trig,N,1);
x=(1:numel(trig))/DAQ.Rate;

first = in-[0;in(1:end-1)];
first = first>0;
fprintf('%d triggers sent;\t %d frames recorded\n',sum(trig),sum(first));

%%
plot(x,trig);
hold on;
plot(x,in);
ylim([-.1,1.1]);
xlim([x(1)-range(x)/20,x(end)+range(x)/20])
xlabel('Time (s)');
ylabel('Voltage (mV)');
legend('Trig','Cam');

%%
fclose(WTUDP);
clear(DAQ);

