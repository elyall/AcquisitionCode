function position = determineRunningWheelPosition(DataIn)

indexA = 1;
indexB = 2;

%% Set beginning and end to be zero
numScans = size(DataIn, 1);

% Reset beginning
index = 1;
while any(DataIn(index,:))
    DataIn(index,:) = [0,0];
    index = index + 1;
end

% Reset end
index = numScans;
while any(DataIn(index,:))
    DataIn(index,:) = [0,0];
    index = index - 1;
end

%% Compute position
% http://www.ni.com/tutorial/7109/en/
dataA = find([0;diff(DataIn(:,indexA))]); %indices when pin first goes high
numEdges = numel(dataA);

position = zeros(numScans, 1);
for sindex = 1:2:numEdges
    if DataIn(dataA(sindex), indexB) ~= 1 % pin B is low when A goes high
        position(dataA(sindex)) = 1;
    else % pin B is already high when A goes high
        position(dataA(sindex+1)) = -1;
    end
end
