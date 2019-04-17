function ExaminePortOrientation
%%

%% Identify the video still index file
origDir = cd;
[indexFile, fileDir, ~] = uigetfile('*.mat', 'Locate the ''File_Index'' file for the session of interest.');
cd(fileDir);
load(indexFile); % Loads the variables 'fileIndex' and 'params'

scrsz = get(0,'ScreenSize');
if scrsz(3) == 2560
    scrsz(3) = 1920;
end

%% Something would go here about selecting for X number of frames per trial but for now we're just going to use all the frames
% I'm doing this (below) because using the [{}] trick to open up a cell
% vector only works if all the indices work if they're the same row,
% therefore I have to cellfun transpose the fileIndex at first because I'm
% too lazy to go back and rework the extraction code to extract the data
% in a different orientation.
fileIndices = cellfun(@(a)a', fileIndex, 'uniformoutput', 0);
fileIndices = [fileIndices{:}]'; 
fileIndices(randperm(size(fileIndices,1)),:) = fileIndices; %#ok<NASGU> 
%% File Cropping
crop_decision = questdlg('Do you want to crop the images? (recommended)',...
    'Crop Y/N?', 'Yes',...
    'No','Yes');
if strcmp(crop_decision,'Yes')
    cropFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.8 scrsz(3)*.4],...
        'Name', 'Cropping', 'NumberTitle', 'off', 'MenuBar', 'none',...
        'ToolBar', 'none');    
%     cropFig = figure('InnerPosition', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.8 scrsz(3)*.4],...
%         'Name', 'Cropping');
    figAxes = axes(cropFig, 'Position', [0.04 0.04 .4 .8],...
        'xticklabels', [], 'yticklabels', [], 'color', 'none');
    croppedAxes = axes(cropFig, 'Position', [0.56 0.04 .4 .8],...
        'xticklabels', [], 'yticklabels', []);
    cropping = 1;
else
    cropVals = [];
    cropping = 0;
end

while cropping
    [cropVals] = CropFigure(cropFig, figAxes, croppedAxes, fileIndex);
    crop_decision2 = questdlg('Use this crop?',...
        'Y/N?', 'Yes',...
        'No','Yes');
    if strcmp(crop_decision2,'Yes')
        cropping = 0;
    end
    close(cropFig);
end

%% Identify the port location


%% Now Create the Figure for Inputting Stuff
% analysisFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.6 scrsz(3)*.4],...
%     'Name', 'Orientation Analysis', 'NumberTitle', 'off', 'MenuBar', 'none',...
%     'ToolBar', 'none');
analysisFig = figure('Position', [scrsz(3)/8 scrsz(4)/8 scrsz(3)*.6 scrsz(3)*.4],...
    'Name', 'Orientation Analysis', 'NumberTitle', 'off');
imageAxes = axes(analysisFig, 'Position', [0.1 0.1 0.5 0.8]);
curFig = imread(fileIndices{1,1});

curFigCropped = imcrop(curFig,[cropVals(1,1) cropVals(1,2) cropVals(2,1)-cropVals(1,1) cropVals(2,2)-cropVals(1,2)]);
axes(imageAxes);
imshow(curFigCropped)


%% Define UI buttons
% UI buttons for index control
saveLimitsbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Select Bad Indices',...
    'Position', [0.025,0.25,0.075,0.035],'Callback', @SaveAxisLimits);
removeBadInxsbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Remove Bad Indices',...
    'Position', [0.1,0.25,0.075,0.035],'Callback', @RemoveBadIndx);
clearLimitsbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Clear Stored Indices',...
    'Position', [0.0625,0.15,0.075,0.035],'Callback', @ClearStoredIndexes);
updateRMSbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Refresh RMS Line',...
    'Position', [0.025,0.1,0.15,0.035],'Callback', @UpdateRMS);
indicesListbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'listbox', 'String', storedIndices,...
    'Position', [0.0375,0.3,0.125,0.28]);
returnIndicesbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Return Selected Indices',...
    'Position', [0.025,0.2,0.15,0.035],'Callback', @returnIndices);

% UI buttons for file control
selectFilebtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'listbox', 'String', smFileList,...
    'Position', [0.0375,0.65,0.125,0.28],'Callback', @selectFile);
changeCHbtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Change to Selected Channel',...
    'Position', [0.025,0.6,0.15,0.035],'Callback', @ChangeCH);
Save2Filebtn = uicontrol(analysisFig, 'Units', 'Normalized', 'Style', 'pushbutton', 'String', 'Save Current Signal as File',...
    'Position', [0.025,0.05,0.15,0.035],'Callback', @SaveFile);



    
function cropVals = CropFigure(cropFig, figAxes, croppedAxes, fileIndex)
% Select a file to use to crop
% Choose a random trial
trlNdx = randperm(length(fileIndex),1);
% Choose a random frame
fileToCrop = fileIndex{trlNdx}{randperm(length(fileIndex{trlNdx}),1)};
% Load that frame and plot it
img2crop = imread(fileToCrop);
axes(figAxes);
imshow(img2crop)

crop_decision = questdlg('Use this frame for cropping?',...
    'Yes/No?', 'Yes',...
    'No','Yes');
while strcmp(crop_decision, 'No')
    % Choose a random trial
    trlNdx = randperm(length(fileIndex),1);
    % Choose a random frame
    fileToCrop = fileIndex{trlNdx}{randperm(length(fileIndex{trlNdx}),1)};
    % Load that frame and plot it
    img2crop = imread(fileToCrop);
    imshow(img2crop);
    
    crop_decision = questdlg('Use this frame for cropping?',...
        'Yes/No?', 'Yes',...
        'No','Yes');
end
% Now put in the textbox
title = annotation(cropFig, 'textbox', 'position', [0 0.9 1 0.2],...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom',...
    'linestyle', 'none', 'fitboxtotext', 'on',...
    'String', 'In left figure, choose the top left corner of the desired cropped area');
drawnow
% Now resize the textbox
titPos = get(title, 'position');
while titPos(3)<0.9 && titPos(4)<0.09
    curFS = get(title, 'fontsize');
    set(title, 'fontsize', curFS+1);
    titPos = get(title, 'position');
    drawnow
end

[topLeftX, topLeftY] = ginput(1);

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

[botRightX, botRightY] = ginput(1);

rectangle('Position',[topLeftX,topLeftY,botRightX-topLeftX,botRightY-topLeftY],...
  'EdgeColor', 'r',...
  'LineWidth', 3,...
  'LineStyle','-')

image_crop = imcrop(img2crop,[topLeftX topLeftY botRightX-topLeftX botRightY-topLeftY]);
axes(croppedAxes);
imshow(image_crop)

cropVals = [topLeftX, topLeftY; botRightX, botRightY];
