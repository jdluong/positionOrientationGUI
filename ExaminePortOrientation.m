function ExaminePortOrientation
%% Get the Screensize to use for all the windows this analysis requires
scrsz = get(0,'ScreenSize');
if scrsz(3) == 2560
    scrsz(3) = 1920;
end
%% Determine whether you are starting a new analysis or continuing a previous one
analysisDecision = questdlg('Are you starting a new analysis or continuing an existing one?',...
    'What are you doing?', 'Starting New',...
    'Continuing Previous','Starting New');

switch analysisDecision
    %% If starting a new analysis
    case 'Starting New'
        %% Identify the video still index file
        [indexFile, fileDir, ~] = uigetfile('*.mat', 'Locate the ''File_Index'' file for the session of interest.');
        if fileDir==0
            disp('Analysis Cancelled');
            return
        end
        cd(fileDir);
        load(indexFile); % Loads the variables 'fileIndex', 'params' and 'time_vals'
        
        %% Something would go here about selecting for X number of frames per trial but for now we're just going to use all the frames
        % I'm doing this (below) because using the [{}] trick to open up a cell
        % vector only works if all the indices work if they're the same row,
        % therefore I have to cellfun transpose the fileIndex at first because I'm
        % too lazy to go back and rework the extraction code to extract the data
        % in a different orientation.
        fileIndices = cellfun(@(a)a', fileIndex, 'uniformoutput', 0);
        fileIndices = [fileIndices{:}]';
%         fileIndices(randperm(size(fileIndices,1)),:) = fileIndices;   % Comment in to shuffle the file indices
        fileIndices = [fileIndices, cell(size(fileIndices,1), 6)];
        fileIndicesColIDs = [{'FileID'}, {'FrameIndex'}, {'FrameTimestamp'}, {'PortX'}, {'PortY'}, {'HeadX'}, {'HeadY'}, {'TailX'}, {'TailY'}];
        
        %% File Cropping
        crop_decision = questdlg('Do you want to crop the images? (recommended)',...
            'Crop Y/N?', 'Yes',...
            'No','Yes');
        switch crop_decision
            case 'Yes'
                cropVals = CropFigure(scrsz, fileIndices);
            case 'No'
                cropVals = [];
        end
        
        %% Determine Port Location
        portVals = DefinePortLoc(scrsz, params.PortIndexFig, cropVals);
        fileIndices(:,4) = {portVals(1)};
        fileIndices(:,5) = {portVals(2)};
        
        %% Create OrientationValues Structure
        orientData = struct('FileIndices', {fileIndices},...
            'FileIndicesColIDs', {fileIndicesColIDs},...
            'CropVals', cropVals, 'PortVals', portVals, 'Params', params,...
            'CurIndex', 1);            
        
    %% If continuing a previous analysis
    case 'Continuing Previous'
        [orientationFile, fileDir, ~] = uigetfile('*.mat', 'Locate the ''Orientation_Data'' for the session of interest.');
        cd(fileDir);
        load(orientationFile); % Loads the variables 'fileIndex' and 'params'
        %% Verify Crop
        cropVals = CropFigure(scrsz, orientData.FileIndices, orientData.CropVals);
        orientData.CropVals = cropVals;
        %% Verify Port Location
        portVals = DefinePortLoc(scrsz, orientData.Params.PortIndexFig, orientData.CropVals, orientData.PortVals);
        orientData.PortVals = portVals;
end       
%% Now Create the Figure for Inputting Stuff
% analysisFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.6 scrsz(3)*.4],...
%     'Name', 'Orientation Analysis', 'NumberTitle', 'off', 'MenuBar', 'none',...
%     'ToolBar', 'none');
analysisFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.6 scrsz(3)*.4],...
    'Name', 'Orientation Analysis', 'NumberTitle', 'off','Tag', 'AnalysisFig',...
    'UserData', orientData);
imageAxes = axes(analysisFig, 'Position', [0.1 0.1 0.5 0.8], 'visible', 'off');
curFig = imread(orientData.FileIndices{orientData.CurIndex,1});
curFigCropped = imcrop(curFig,[cropVals(1,1) cropVals(1,2) cropVals(2,1)-cropVals(1,1) cropVals(2,2)-cropVals(1,2)]);
curImg = imshow(curFigCropped);
set(curImg, 'Tag', 'CurImg');
set(imageAxes, 'Tag', 'ImageAxes');
hold on;
portDot = plot(portVals(1)-cropVals(1,1),portVals(2)-cropVals(1,2), 'Marker', 'o', 'MarkerFaceColor', 'blue', 'MarkerSize', 10, 'Tag', 'PortDot');
headDot = plot(1,1, 'Marker', 'o', 'MarkerFaceColor', 'red', 'MarkerSize', 10, 'visible', 'off', 'Tag', 'HeadDot');
tailDot = plot(1,1, 'Marker', 'o', 'MarkerFaceColor', 'green', 'MarkerSize', 10, 'visible', 'off', 'Tag', 'TailDot');

annotation(analysisFig, 'rectangle', 'Position', [0.6,0.37,0.375, 0.25]);
fileNameTxt = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'text', 'String', sprintf('%s (%i/%i)', orientData.FileIndices{orientData.CurIndex,1}, orientData.CurIndex, size(orientData.FileIndices,1)),...
    'Position', [0.1 0.9 0.5 0.05], 'Tag', 'FileNameTXT', 'FontSize', 12);
markHeadLoc = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Mark Head (Implant) Location',...
    'Position', [0.6135,0.5,0.35,0.08], 'Tag', 'HeadMarkPB', 'FontSize', 14, 'Callback', @MarkHeadLocation);
markTailLoc = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Mark the Base of the Rat''s Tail',...
    'Position', [0.6135,0.4,0.35,0.08], 'Tag', 'TailMarkPB', 'FontSize', 14, 'Callback', @MarkTailLocation);
saveProgress = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Save Current Progress',...
    'Position', [0.6,0.75,0.375,0.15], 'Tag', 'SavePB', 'FontSize', 14, 'Callback', @SaveProgress);
nextSlide = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Next Slide',...
    'Position', [0.6,0.1,0.375,0.2], 'Tag', 'NexSlidePB', 'FontSize', 14, 'Callback', @NextSlide);

end

function cropVals = CropFigure(scrsz, fileIndices, cropValsIn)
%% Make Figure for Cropping
cropFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.8 scrsz(3)*.4],...
    'Name', 'Cropping', 'NumberTitle', 'off', 'MenuBar', 'none',...
    'ToolBar', 'none');
%     cropFig = figure('InnerPosition', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.8 scrsz(3)*.4],...
%         'Name', 'Cropping');
figAxes = axes(cropFig, 'Position', [0.04 0.04 .4 .8],...
    'xticklabels', [], 'yticklabels', [], 'color', 'none',...
    'visible', 'off');
croppedAxes = axes(cropFig, 'Position', [0.56 0.04 .4 .8],...
    'xticklabels', [], 'yticklabels', [],...
    'visible', 'off');
title = annotation(cropFig, 'textbox', 'position', [0 0.9 1 0.2],...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom',...
    'linestyle', 'none', 'fitboxtotext', 'on',...
    'visible', 'off');
if nargin == 2
    cropVals = nan(2);
else
    cropVals = cropValsIn;
end

%% Find an acceptable image to crop with
% Select a file to use to crop
% Choose a random frame
fileToCrop = fileIndices{randperm(length(fileIndices),1),1};
% Load that frame and plot it
img2crop = imread(fileToCrop);
axes(figAxes);
image2crop = imshow(img2crop);
crop_decision = questdlg('Use this frame for cropping?',...
    'Yes/No?', 'Yes',...
    'No','Yes');
while strcmp(crop_decision, 'No')
    % Choose a random frame
    fileToCrop = fileIndices{randperm(length(fileIndices),1),1};
    % Load that frame and plot it
    img2crop = imread(fileToCrop);
    imshow(img2crop);
    
    crop_decision = questdlg('Use this frame for cropping?',...
        'Yes/No?', 'Yes',...
        'No','Yes');
end
cropOutline = rectangle('Position',[1 1 1 1], 'EdgeColor', 'r',...
    'LineWidth', 3,'LineStyle','-', 'visible', 'off');
%% Crop!
cropping = 1;
while cropping
    if sum(sum(isnan(cropVals)))==4
        % Now put in the textbox
        set(title, 'fontsize', 9, 'String', 'In left figure, choose the top left corner of the desired cropped area', 'visible', 'on');
        drawnow
        % Now resize the textbox
        titPos = get(title, 'position');
        while titPos(3)<0.9 && titPos(4)<0.09
            curFS = get(title, 'fontsize');
            set(title, 'fontsize', curFS+1);
            titPos = get(title, 'position');
            drawnow
        end
        
        [cropVals(1,1), cropVals(1,2)] = ginput(1);
        
        set(title, 'fontsize', 9, 'String', 'Now, choose the bottom right corner of the desired crop');
        drawnow
        % Now resize the textbox again
        titPos = get(title, 'position');
        while titPos(3)<0.9 && titPos(4)<0.09
            curFS = get(title, 'fontsize');
            set(title, 'fontsize', curFS+1);
            titPos = get(title, 'position');
            drawnow
        end
        
        [cropVals(2,1), cropVals(2,2)] = ginput(1);
    end        
    
    set(cropOutline, 'Position',[cropVals(1,1) cropVals(1,2) cropVals(2,1)-cropVals(1,1) cropVals(2,2)-cropVals(1,2)], 'visible', 'on');
    
    image_crop = imcrop(img2crop,[cropVals(1,1) cropVals(1,2) cropVals(2,1)-cropVals(1,1) cropVals(2,2)-cropVals(1,2)]);
    axes(croppedAxes);
    croppedImage = imshow(image_crop);
    
    set(title, 'visible', 'off');
    
    crop_decision2 = questdlg('Use this crop?',...
        'Y/N?', 'Yes',...
        'No','Yes');
    if strcmp(crop_decision2,'Yes')
        cropping = 0;
    else
        set(croppedImage, 'visible', 'off');
        set(cropOutline, 'visible', 'off');
        cropVals = nan(2);
    end
end
close(cropFig);
end

function portVals = DefinePortLoc(scrsz, portIndexFig, cropVals, portValsIn)
%% Analyze Inputs
if nargin == 3
    portVals = nan(1,2);
else
    portVals = portValsIn;
    portVals(1) = portVals(1) - cropVals(1,1);
    portVals(2) = portVals(2) - cropVals(1,2);
end
%% Create Figure
portFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.4 scrsz(3)*.4],...
    'Name', 'PortLoc', 'NumberTitle', 'off', 'MenuBar', 'none',...
    'ToolBar', 'none');
portAxes = axes(portFig, 'Position', [0.1 0.1 0.8 0.8], 'visible', 'off');
title = annotation(portFig, 'textbox', 'position', [0 0.9 1 0.1],...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom',...
    'linestyle', 'none', 'fitboxtotext', 'on',...
    'visible', 'off');

%% Load & Crop Image
portImg = imread(portIndexFig);
portImgCropped = imcrop(portImg,[cropVals(1,1) cropVals(1,2) cropVals(2,1)-cropVals(1,1) cropVals(2,2)-cropVals(1,2)]);
axes(portAxes);
imshow(portImgCropped);
hold on;
portHairsCirc = plot(1, 1, 'ro', 'markersize', 30, 'visible', 'off');
portHairsCros = plot(1, 1, 'r+', 'markersize', 30, 'visible', 'off');

portIDing = 1;
%% Identify Port Location
while portIDing == 1
    if sum(isnan(portVals))==2
        set(title, 'fontsize', 9, 'String', 'Click the center of the port', 'visible', 'on');
        drawnow
        % Now resize the textbox
        titPos = get(title, 'position');
        while titPos(3)<0.9 && titPos(4)<0.09
            curFS = get(title, 'fontsize');
            set(title, 'fontsize', curFS+1);
            titPos = get(title, 'position');
            drawnow
        end
        [portVals(1), portVals(2)] = ginput(1);
    end
    set(portHairsCirc, 'XData', portVals(1), 'YData', portVals(2), 'visible', 'on');
    set(portHairsCros, 'XData', portVals(1), 'YData', portVals(2), 'visible', 'on')
    port_decision2 = questdlg('Use this as Port Position?',...
        'Y/N?', 'Yes',...
        'No','Yes');
    if strcmp(port_decision2,'Yes')
        portIDing = 0;
    else
        set(portHairsCirc, 'visible', 'off');
        set(portHairsCros, 'visible', 'off');
        portVals = nan(1,2);
    end
end
% Convert the portVals back to the uncropped reference frame
portVals(1) = portVals(1) + cropVals(1,1);
portVals(2) = portVals(2) + cropVals(1,2);
close(portFig);
end

function MarkHeadLocation(source,event)
set(source, 'string', 'Marking');
headLoc = findobj('Tag', 'HeadDot');
analysisFig = findobj('Tag', 'AnalysisFig');
orientData = get(analysisFig, 'UserData');
[curHeadX, curHeadY] = ginput(1);
set(headLoc, 'XData', curHeadX, 'YData', curHeadY, 'visible', 'on');
headXcol = strcmp(orientData.FileIndicesColIDs, 'HeadX');
headYcol = strcmp(orientData.FileIndicesColIDs, 'HeadY');

orientData.FileIndices{orientData.CurIndex, headXcol} = curHeadX + orientData.CropVals(1,1);
orientData.FileIndices{orientData.CurIndex, headYcol} = curHeadY + orientData.CropVals(1,2);

set(analysisFig, 'UserData', orientData);
set(source, 'string', 'Mark Head (Implant) Location');
end

function MarkTailLocation(source,event)
set(source, 'string', 'Marking');
tailLoc = findobj('Tag', 'TailDot');
analysisFig = findobj('Tag', 'AnalysisFig');
orientData = get(analysisFig, 'UserData');
[curTailX, curTailY] = ginput(1);
set(tailLoc, 'XData', curTailX, 'YData', curTailY, 'visible', 'on');
tailXcol = strcmp(orientData.FileIndicesColIDs, 'TailX');
tailYcol = strcmp(orientData.FileIndicesColIDs, 'TailY');

orientData.FileIndices{orientData.CurIndex, tailXcol} = curTailX + orientData.CropVals(1,1);
orientData.FileIndices{orientData.CurIndex, tailYcol} = curTailY + orientData.CropVals(1,2);

set(analysisFig, 'UserData', orientData);
set(source, 'string', 'Mark the Base of the Rat''s Tail');
end

function NextSlide(source,event)
headLoc = findobj('Tag', 'HeadDot');
set(headLoc, 'visible', 'off');
tailLoc = findobj('Tag', 'TailDot');
set(tailLoc, 'visible', 'off');
fileNameTxt = findobj('Tag', 'FileNameTXT');

analysisFig = findobj('Tag', 'AnalysisFig');
orientData = get(analysisFig, 'UserData');
headXcol = strcmp(orientData.FileIndicesColIDs, 'HeadX');
tailXcol = strcmp(orientData.FileIndicesColIDs, 'TailX');
% Check to make sure everything is marked
if isempty(orientData.FileIndices{orientData.CurIndex, headXcol})
    msgbox('Head Location Not Marked!', 'Error','error');
    return
elseif isempty(orientData.FileIndices{orientData.CurIndex, tailXcol})
    msgbox('Tail Location Not Marked!', 'Error','error');
    return
end
orientData.CurIndex = orientData.CurIndex+1;
if orientData.CurIndex > size(orientData.FileIndices,1)
    SaveProgress
    msgbox('Analysis Complete!');
    close(analysisFig);
else
    fig2display = imread(orientData.FileIndices{orientData.CurIndex,1});
    curFigCropped = imcrop(fig2display,[orientData.CropVals(1,1) orientData.CropVals(1,2) orientData.CropVals(2,1)-orientData.CropVals(1,1) orientData.CropVals(2,2)-orientData.CropVals(1,2)]);
    curImg = findobj('Tag', 'CurImg');
    set(curImg, 'CData', curFigCropped);
    set(fileNameTxt, 'String', sprintf('%s (%i/%i)', orientData.FileIndices{orientData.CurIndex,1}, orientData.CurIndex, size(orientData.FileIndices,1)));
    set(analysisFig, 'UserData', orientData);
end
end

function SaveProgress(source,event)
analysisFig = findobj('Tag', 'AnalysisFig');
orientData = get(analysisFig, 'UserData');
if ~isfield(orientData, 'FileSaveName')
    [file, path] = uiputfile('_Orientation_Data.mat', 'Determine the output file name');
    orientData.FileSaveName = [path file];
end
save(orientData.FileSaveName, 'orientData');
set(analysisFig, 'UserData', orientData);
end