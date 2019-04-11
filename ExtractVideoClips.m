function ExtractVideoClips
%% Code to extract video stills from relevant behavioral videos

[videoFile, fileDir, ~] = uigetfile('*.avi', 'Locate the .AVI file of interest');
params.VideoFile = [fileDir videoFile];
video = VideoReader([fileDir videoFile]);
files = dir(fileDir);
fileNames = {files.name};
behavFile = cellfun(@(a)~isempty(a), regexp(fileNames, 'BehaviorMatrix'));
if sum(behavFile)==1
    load([fileDir '\' fileNames{behavFile}]);
    params.BehavFile = [fileDir '\' fileNames{behavFile}];
else
    [behavFile, behavDir, ~] = uigetfile('*.mat', 'Identify the associated BehaviorMatrix file');
    load([behavDir '\' behavFile]);
    params.BehavFile = [behavDir '\' behavFile];
end

[trial_time_start, trial_time_end, trial_IDs, time_vals] = trial_time_extract(behavMatrix, behavMatrixColIDs);
clc;
preTrialDur = input('How many millisecond BEFORE trial start do you want to include?');
params.PreTrialDuration = preTrialDur/1000;
postTrialDur = input('How many milliseconds AFTER trial start do you want to include?');
params.PostTrialDuration = postTrialDur/1000;

if ~isdir([fileDir 'VideoStills'])
    mkdir([fileDir 'VideoStills']);
end
videoDir = [fileDir 'VideoStills\'];
fileIndex = cell(size(trial_time_start));
video.CurrentTime = behavMatrix(find(behavMatrix(:,end-1)>=900,1,'first'),1);
curFrame = readFrame(video);
imwrite(curFrame, sprintf('%s%s_PortIndex.jpg', videoDir, videoFile(1:end-4)));
params.PortIndexFig = sprintf('%s%s_PortIndex.jpg', videoDir, videoFile(1:end-4));
for trl = 1:length(trial_time_start)
    curStart = trial_time_start(trl) - params.PreTrialDuration;
    curEnd = trial_time_end(trl) + params.PostTrialDuration;
    curTime = curStart;
    video.CurrentTime = curStart;
    curFrame = readFrame(video);
    prTrlNdx = 1;
    trlNdx = 1;
    poTrlNdx = 1;
    while video.CurrentTime < curEnd
        if curTime>=curStart && curTime<trial_time_start(trl)
            fileID = sprintf('Trial%03i_PrTrl%03i_%d.jpg', trl, prTrlNdx, trial_IDs(trl));
            prTrlNdx = prTrlNdx+1;
        elseif curTime>=trial_time_start(trl) && curTime<trial_time_end(trl)
            fileID = sprintf('Trial%03i_Trl%03i_%d.jpg', trl, trlNdx, trial_IDs(trl));
            trlNdx = trlNdx+1;
        elseif curTime>trial_time_end(trl) && curTime<curEnd
            fileID = sprintf('Trial%03i_PoTrl%03i_%d.jpg', trl, poTrlNdx, trial_IDs(trl));
            poTrlNdx = poTrlNdx+1;
        end 
        imwrite(curFrame, sprintf('%s%s', videoDir, fileID));
        fileIndex{trl} = [fileIndex{trl}; [{fileID} {find(curTime>=time_vals,1,'last')} {curTime}]];
        curTime = video.CurrentTime;
        curFrame = readFrame(video);
    end
end
save(sprintf('%s%s_File_Index.mat', videoDir, videoFile(1:end-4)), 'fileIndex', 'params');
disp 'Clips Extracted!'
end



function [trial_time_start, trial_time_end, trial_IDs, time_vals] = trial_time_extract(statMatrix, statMatrixColIDs)
time_vals = statMatrix(:,strcmp(statMatrixColIDs, 'TimeBin'));
odor_pos = cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'Odor'));
trial_ndxs = find(sum(statMatrix(:,odor_pos),2));
poke_vals = statMatrix(:,strcmp(statMatrixColIDs, 'PokeEvents'));
poke_in = find(poke_vals == 1);
poke_out = find(poke_vals == -1);

trial_time_start = nan(size(trial_ndxs));
trial_time_end = nan(size(trial_ndxs));
trial_IDs = nan(size(trial_ndxs));
for trial = 1:length(trial_ndxs)
    trial_IDs(trial) = find(find(odor_pos)==find(statMatrix(trial_ndxs(trial),:)==1 & odor_pos)); % This is a glorious clusterfuck of find commands but it gets the job done.
    trial_time_start(trial) = time_vals(poke_in(find(poke_in<trial_ndxs(trial),1,'last')));
    trial_time_end(trial) = time_vals(poke_out(find(poke_out>trial_ndxs(trial),1,'first')));
end
end