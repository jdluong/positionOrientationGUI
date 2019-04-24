function ExtractVideoClips
%% Just to be safe
fclose all;
%% Code to extract video stills from relevant behavioral videos
% Find the Video file and prep the video variable
[videoFile, fileDir, ~] = uigetfile('*.avi', 'Locate the .AVI file of interest');
params.VideoFile = [fileDir videoFile];
video = VideoReader([fileDir videoFile]);
cd(fileDir);

% Now find the FrameMarkers file. This is the exported timestamps for every
% frame in the video created using CinePlex Markup
[frameMarkFilename, ~, ~] = uigetfile('*.txt', 'Locate the FrameMarkers.txt file associated with it');
frameMarkFile = fopen(frameMarkFilename);

% Now find the BehaviorMatrix file created using the StatMatrixCreator
files = dir(fileDir);
fileNames = {files.name};
behavFile = cellfun(@(a)~isempty(a), regexp(fileNames, 'BehaviorMatrix'));
if sum(behavFile)==1
    load([fileDir '\' fileNames{behavFile}]);
    params.BehavFile = [fileDir '\' fileNames{behavFile}];
else
    [behavFile, behavDir, ~] = uigetfile('*.mat', 'Identify the associated BehaviorMatrix file');
    load([behavDir '\' behavFile]);
    params.BehavFile = [behavDir behavFile];
end

% Extract the trial time data
[trial_time_start, trial_time_end, trial_IDs, time_vals] = trial_time_extract(behavMatrix, behavMatrixColIDs);
clc;

% Determine timeperiods of interest
preTrialDur = input('How many millisecond BEFORE trial start do you want to include?');
params.PreTrialDuration = preTrialDur/1000;
postTrialDur = input('How many milliseconds AFTER trial end do you want to include?');
params.PostTrialDuration = postTrialDur/1000;
trialWindows = [trial_time_start-params.PreTrialDuration trial_time_end+params.PostTrialDuration];

% Check directory & make if it doesn't exist
if ~isdir([fileDir 'VideoStills'])
    mkdir([fileDir 'VideoStills']);
end
videoDir = [fileDir 'VideoStills\'];
% Initialize the variables
fileIndex = cell(size(trial_time_start));
portIndexTaken = 0;
trial = 1;
prTrlNdx = 1;
trlNdx = 1;
poTrlNdx = 1;
    
curFrame = readFrame(video);
txt = fgetl(frameMarkFile);

while trial <= length(trial_time_start)
    writing = 1;
    curMarkerTime = str2double(txt);
    if curMarkerTime>=behavMatrix(find(behavMatrix(:,end-1)>=900,1,'first'),1) && ~portIndexTaken
        imwrite(curFrame, sprintf('%s%s_PortIndex.jpg', videoDir, videoFile(1:end-4)));
        params.PortIndexFig = sprintf('%s_PortIndex.jpg', videoFile(1:end-4));
        portIndexTaken = 1;
    end
    if curMarkerTime>=trialWindows(trial,1) && curMarkerTime<trial_time_start(trial)
        fileID = sprintf('Trial%03i_PrTrl%03i_%d.jpg', trial, prTrlNdx, trial_IDs(trial));
        prTrlNdx = prTrlNdx+1;
    elseif curMarkerTime>=trial_time_start(trial) && curMarkerTime<trial_time_end(trial)
        fileID = sprintf('Trial%03i_Trl%03i_%d.jpg', trial, trlNdx, trial_IDs(trial));
        trlNdx = trlNdx+1;
    elseif curMarkerTime>=trial_time_end(trial) && curMarkerTime<trialWindows(trial,2)
        fileID = sprintf('Trial%03i_PoTrl%03i_%d.jpg', trial, poTrlNdx, trial_IDs(trial));
        poTrlNdx = poTrlNdx+1;
    elseif curMarkerTime>trialWindows(trial,2)
        trial = trial+1;
        prTrlNdx = 1;
        trlNdx = 1;
        poTrlNdx = 1;
        writing = 0;
    else
        writing = 0;
    end
    if writing==1
        imwrite(curFrame, sprintf('%s%s', videoDir, fileID));
        fileIndex{trial} = [fileIndex{trial}; [{fileID} {find(curMarkerTime>=time_vals,1,'last')} {curMarkerTime}]];
    end
    txt = fgetl(frameMarkFile);
    curFrame = readFrame(video);
end
fclose all;
% 
% 
% video.CurrentTime = behavMatrix(find(behavMatrix(:,end-1)>=900,1,'first'),1);
% imwrite(curFrame, sprintf('%s%s_PortIndex.jpg', videoDir, videoFile(1:end-4)));
% params.PortIndexFig = sprintf('%s_PortIndex.jpg', videoFile(1:end-4));
% for trl = 1:length(trial_time_start)
%     curStart = trial_time_start(trl) - params.PreTrialDuration;
%     curEnd = trial_time_end(trl) + params.PostTrialDuration;
%     curTime = curStart;
%     video.CurrentTime = curStart;
%     curFrame = readFrame(video);
%     prTrlNdx = 1;
%     trlNdx = 1;
%     poTrlNdx = 1;
%     while video.CurrentTime < curEnd
%         if curTime>=curStart && curTime<trial_time_start(trl)
%             fileID = sprintf('Trial%03i_PrTrl%03i_%d.jpg', trl, prTrlNdx, trial_IDs(trl));
%             prTrlNdx = prTrlNdx+1;
%         elseif curTime>=trial_time_start(trl) && curTime<trial_time_end(trl)
%             fileID = sprintf('Trial%03i_Trl%03i_%d.jpg', trl, trlNdx, trial_IDs(trl));
%             trlNdx = trlNdx+1;
%         elseif curTime>trial_time_end(trl) && curTime<curEnd
%             fileID = sprintf('Trial%03i_PoTrl%03i_%d.jpg', trl, poTrlNdx, trial_IDs(trl));
%             poTrlNdx = poTrlNdx+1;
%         end 
%         imwrite(curFrame, sprintf('%s%s', videoDir, fileID));
%         fileIndex{trl} = [fileIndex{trl}; [{fileID} {find(curTime>=time_vals,1,'last')} {curTime}]];
%         curTime = video.CurrentTime;
%         curFrame = readFrame(video);
%     end
% end
save(sprintf('%s%s_File_Index.mat', videoDir, videoFile(1:end-4)), 'fileIndex', 'params', 'time_vals');
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