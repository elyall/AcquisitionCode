function position = determineMotorPosition(DataIn)

numPulsesPerRotation = 7000;
indexStep = 1;
indexDir = 2;

DataIn(:,indexDir) = -DataIn(:,indexDir);
DataIn(DataIn(:,indexDir)==0, indexDir) = 1;

position = [0;cumsum(DataIn(:,indexStep).*DataIn(:,indexDir))];

if ~isempty(numPulsesPerRotation)
    position = rem(position, numPulsesPerRotation);
end