function [TrialType, number] = characterizeTrials(AnalysisInfo, DataIn)

ValveIndex = 1;
LickIndex = 6;


numTrials = size(AnalysisInfo, 1);
TrialType = cell(numTrials, 1);
number = false(numTrials, 4);
for tindex = 1:numTrials
    if AnalysisInfo.StimID(tindex) < 270 % go stimulus
        if any(DataIn(AnalysisInfo.ExpScans(tindex, 1):AnalysisInfo.ExpScans(tindex, 2), ValveIndex)) % reward given -> hit
            TrialType{tindex} = 'hit';
            number(tindex,1) = true;
        else % miss
            TrialType{tindex} = 'miss';
            number(tindex,2) = true;
        end
    else % no go stimulus
        if ~any(DataIn(AnalysisInfo.ExpStimScans(tindex,1):AnalysisInfo.ExpStimScans(tindex,2), LickIndex)) % licked during answer (stim) period -> false alarm
            TrialType{tindex} = 'correctrejection';
            number(tindex,3) = true;
        else % correct rejection
            TrialType{tindex} = 'falsealarm';
            number(tindex,4) = true;
        end
    end 
end