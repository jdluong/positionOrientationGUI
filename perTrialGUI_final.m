function varargout = perTrialGUI_final(varargin)
% PERTRIALGUI_FINAL MATLAB code for perTrialGUI_final.fig
%      PERTRIALGUI_FINAL, by itself, creates a new PERTRIALGUI_FINAL or raises the existing
%      singleton*.
%
%      H = PERTRIALGUI_FINAL returns the handle to a new PERTRIALGUI_FINAL or the handle to
%      the existing singleton*.
%
%      PERTRIALGUI_FINAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PERTRIALGUI_FINAL.M with the given input arguments.
%
%      PERTRIALGUI_FINAL('Property','Value',...) creates a new PERTRIALGUI_FINAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before perTrialGUI_final_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to perTrialGUI_final_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help perTrialGUI_final

% Last Modified by GUIDE v2.5 10-Oct-2018 15:43:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @perTrialGUI_final_OpeningFcn, ...
                   'gui_OutputFcn',  @perTrialGUI_final_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before perTrialGUI_final is made visible.
function perTrialGUI_final_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to perTrialGUI_final (see VARARGIN)

% Choose default command line output for perTrialGUI_final
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes perTrialGUI_final wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%% 1) loading and parsing data
video = VideoReader('SuperChris-2-12-09.AVI');
load('SuperChris-2-12-09_BehaviorMatrix.mat') %***
head_xcoords = behavMatrix(:,find(cellfun(@(a)~isempty(a), regexp(behavMatrixColIDs, 'Xval'))));
head_ycoords = behavMatrix(:,find(cellfun(@(a)~isempty(a), regexp(behavMatrixColIDs, 'Yval'))));
setappdata(handles.figure1,'head_xcoords',head_xcoords);
setappdata(handles.figure1,'head_ycoords',head_ycoords);

[trial_time_start, trial_time_end, time_vals] = trial_time_extract(behavMatrix, behavMatrixColIDs);
% 1/14/19: trial_time_start and _end has 5 cells, for each odor. Use this
% for 11 frame extraction for testing 
num_of_frames = 4; % a parameter
trial_num_regexp = '\d*(?=_)';
framesBeforeAfter = 5; % used in 3)

num_of_trials = 0;
for i = 1:length(trial_time_start)
    num_of_trials = num_of_trials + length(trial_time_start{i});
end

% not used right now
trial_frame_nums = cell(1);
trial_frame_imgs = cell(1);

%% 2) FINAL extract frames with coords in behavMatrix
% have to copy this for the coord accuracy test thing; use this block
% after 

% all_coord_ind = [];
% for j = 1:length(trial_time_start)
%     for n = 1:2 % length(trial_time_start{j})
%         % extract time_vals (in ms) from trial start to end 
%         timeSubArray = time_vals(floor(trial_time_start{j}(n)*1000):...
%             floor(trial_time_end{j}(n)*1000)); % floor bc it's like 3.001
%         % make array of indices of the time values ^; used later to find statM
%         % indices for the coordinates
%         indnumSubArray = floor(timeSubArray*1000);
%         % extract array of head_xcoords corresponding to indices of timeSubArray 
%         posSubArray = head_xcoords(floor(trial_time_start{j}(n)*1000):...
%             floor(trial_time_end{j}(n)*1000));
%         % find index values relative to posSubArray, not relative to whole
%         % statMatrix
%         xval_ind_pos_subArray = find(posSubArray);
%             % have to find relative to whole statMatrix using xval_ind
%             xval_ind_statM = zeros(1,length(xval_ind_pos_subArray));
%             for m = 1:length(xval_ind_pos_subArray)
%                 xval_ind_statM(m) = indnumSubArray(xval_ind_pos_subArray(m));
%             end 
%         all_coord_ind = [all_coord_ind, xval_ind_statM];
%         % iteratively append the indices of recorded values 
%     end 
% end 
% setappdata(handles.figure1,'all_coord_ind',all_coord_ind) 
% % allows INDICES of recorded x-y values in statM to be accessed in GUI


%% START 1/15/19 coord accuracy test
%% 2) Extracting indices where there are coordinates during trial time RLY INELEGANT
% getting indices of first two trials of each odor that have coord recorded
odor_coord_ind = cell(1);
for j = 1:length(trial_time_start)
    for n = 1:2 % length(trial_time_start{j})
        % extract time_vals (in ms) from trial start to end 
        timeSubArray = time_vals(floor(trial_time_start{j}(n)*1000):...
            floor(trial_time_end{j}(n)*1000)); % floor bc it's like 3.001
        % make array of indices of the time values ^; used later to find statM
        % indices for the coordinates
        indnumSubArray = floor(timeSubArray*1000);
        % extract array of head_xcoords corresponding to indices of timeSubArray 
        posSubArray = head_xcoords(floor(trial_time_start{j}(n)*1000):...
            floor(trial_time_end{j}(n)*1000));
        % find index values relative to posSubArray, not relative to whole
        % statMatrix
        xval_ind_pos_subArray = find(posSubArray);
        % have to find relative to whole statMatrix using xval_ind
        xval_ind_statM = zeros(1,length(xval_ind_pos_subArray));
            for m = 1:length(xval_ind_pos_subArray)
                xval_ind_statM(m) = indnumSubArray(xval_ind_pos_subArray(m));
            end 
        odor_coord_ind{j} = [xval_ind_statM(1), xval_ind_statM(2)];
        % iteratively append the indices of recorded values 
    end 
end 
setappdata(handles.figure1,'odor_coord_ind',odor_coord_ind);
% allows INDICES of recorded x-y values in statM to be accessed in GUI

%% 3) extracting uint8 matrices and putting them into cells
% change frames to milliseconds
secBeforeAfter = floor(framesBeforeAfter/30*1000); 

% cell that will be populated with uint8 images of all frames by odor
% 1x5 cell, where col1 = odor A, col2 = odor 2, etc.
all_odor_frame_imgs = cell(1);

for j = 1:length(trial_time_start) % for each odor
    % this is reinitialized for every next odor
    odor_frame_imgs = cell(1);
    for y = 1:2 % for the first two trials of each odor
        frameCell = cell(1); 
        
        % create video structure that uint8 will populate using readFrame
        video_struct = struct('cdata',zeros(video.Height,video.Width,3,'uint8'),...
            'colormap',[]);
        
        % initialize start time of frame extraction as how many frames
        % (in seconds) before the start of trial 
        video.CurrentTime = time_vals(odor_coord_ind{j}(y)-secBeforeAfter); 

        index = 1;
        % keep going until after the amt of frames after trial end
        while video.CurrentTime <= time_vals(odor_coord_ind{j}(y)+secBeforeAfter+1) 
            video_struct(index).cdata = readFrame(video);
            index = index+1;
        end
        if isempty(odor_frame_imgs{1}) == 1 
        % this if-statement only executes once, the first image stored
            for x = 1:length(video_struct)
                frameCell{x} = video_struct(x).cdata;
            end 
            odor_frame_imgs{end} = frameCell;
        else
        % appends uint8 matrix (image) to odor_frame_imgs
            for x = 1:length(video_struct)
                frameCell{x} = video_struct(x).cdata;
            end 
            odor_frame_imgs{end+1} = frameCell;
        end
    end
    all_odor_frame_imgs{j} = odor_frame_imgs;
end

%% END 1/15/19 coord accuracy test; change uint8 -> jpg block 

%% 3) converting uint8 snapshots into .jpg

% saving the image (uint8 --> .jpg file) and naming
mkdir(pwd,'odor_trialSnaps_jpgs');
cd ([pwd,'/odor_trialSnaps_jpgs']);
for odor = 1:length(all_odor_frame_imgs)
    for trial = 1:2
        for frame = 1:11
            imwrite(all_odor_frame_imgs{odor}{trial}{frame},...
                [int2str(odor),'_', int2str(trial), '_frame',...
                int2str(frame),'.jpg'],'jpg')
        end 
    end 
end


%% 4) creating variables GUI can use to navigate .jpg's 
jpgs_dir = pwd;
dir_files = dir(jpgs_dir); % list all jpg's in folder
file_names = {dir_files.name}; % file_names = cell of strings, so use file_names{1}
jpg_file_log = file_names(cellfun(@(a)~isempty(a), regexp(file_names, '.jpg'))); 
frame_nums_sort = [];
 
% sorting frames per trial to test xval and yval accuracy
% this took SO LONG
for coord = 1:(length(jpg_file_log)/11)
    temp = zeros(1,11);
    for frame = 1:11
        frame_num = regexp(jpg_file_log{frame+(11*(coord-1))},'(?<=frame)\d*','match');
        temp(1,frame) = str2double(frame_num);
    end 
    [~,sort_ind] = sort(temp);
    frame_nums_sort(end+1:end+11) = sort_ind + ((coord-1)*11);
end 
jpg_file_log = jpg_file_log(frame_nums_sort);

setappdata(handles.figure1,'jpg_file_length',length(jpg_file_log));
setappdata(handles.figure1,'jpg_file_log',jpg_file_log);
setappdata(handles.figure1,'jpgs_dir',jpgs_dir);

%% DELETE UP TO HERE

%% FINAL? frame extraction function starts here
% for j = 1:length(trial_time_start)
%     % each odor
%     for k = 1:length(trial_time_start{j})
%         % each trial per odor  
%         video_struct = struct('cdata',zeros(video.Height,video.Width,3,'uint8'),...
%             'colormap',[]);
%         video.CurrentTime = trial_time_start{j}(k); % parameter
%         
%         index = 1;
%         while video.CurrentTime <= trial_time_end{j}(k) % another parameter
%             video_struct(index).cdata = readFrame(video);
%             index = index+1;
%         end
%         
%         % pulling out 4 equally spaced frames in duration
%         frame_nums = zeros(1,num_of_frames);
%         frame_imgs = cell(1,num_of_frames);
%         for a = 1:num_of_frames
%             % use floor() to avoid overindexing a frame 
%             % in image(video_struct(frame#).cdata), frame# must be integer
%             frame_nums(a) = floor(size(video_struct,2)/num_of_frames * a);
%             % storing a uint8 (video_struct(frame#).cdata) in cell 
%             frame_imgs{a} = video_struct(frame_nums(a)).cdata;
%         end
%         if isempty(trial_frame_nums{1}) == 1
%             trial_frame_nums{1} = frame_nums;
%             trial_frame_imgs{1} = frame_imgs;
%         else
%             trial_frame_nums{end+1} = frame_nums;
%             trial_frame_imgs{end+1} = frame_imgs;
%         end
%     end
% end
% 
% %% converting uint8 snapshots into .jpg
% mkdir(pwd,'trialSnaps_jpgs');
% cd ([pwd,'/trialSnaps_jpgs']);
% for trial_num = 1:length(trial_frame_imgs)
%     for frame_num = 1:num_of_frames
%         imwrite(trial_frame_imgs{trial_num}{frame_num},...
%             [int2str(trial_num),'_',int2str(trial_frame_nums{trial_num}(frame_num)),'.jpg'],...
%              'jpg')
%     end
% end
% 
% %% creating variables to navigate .jpg's
% jpgs_dir = pwd;
% dir_files = dir(jpgs_dir); % list all jpg's in folder
% % % file_dates = {dir_files.datenum}; % sort files by date
% % % [~,idx] = sort(file_dates);
% % % dir_files = dir_files(idx); % keeps the correct order of tetrodes; doesn't really work
% file_names = {dir_files.name}; % file_names = cell of strings, so use file_names{1}
% jpg_file_log = file_names(cellfun(@(a)~isempty(a), regexp(file_names, '.jpg'))); 
% trial_nums = zeros(length(jpg_file_log),1);
% % sorting trials to test xval and yval accuracy
% for trial = 1:length(jpg_file_log)
%     trial_num = regexp(jpg_file_log{1},trial_num_regexp,'match');
%     trial_nums(trial,1) = str2double(trial_num);
% end 
% [~,sort_ind] = sort(trial_nums);
% jpg_file_log = jpg_file_log(sort_ind);
% 
% setappdata(handles.figure1,'jpg_file_length',length(jpg_file_log));
% setappdata(handles.figure1,'jpg_file_log',jpg_file_log);
% setappdata(handles.figure1,'jpgs_dir',jpgs_dir);


%% begin gui stuff
cd .. % goes back to folder with GUI file
axes(handles.axes4); 
image = imread([jpgs_dir, '/', jpg_file_log{1}]);
imshow(image)
[xlist, ylist] = ginput(2);
setappdata(handles.figure1,'crop_coord',[xlist(1) ylist(1) xlist(2)-xlist(1) ylist(2)-ylist(1)])
image_crop = imcrop(image,[xlist(1) ylist(1) xlist(2)-xlist(1) ylist(2)-ylist(1)]);
imshow(image_crop)
crop_decision = questdlg('Are you satisfied with this crop? It will be used for all frames from now on.',...
                'Confirm Crop', 'Yes, I am satisfied.',...
                'No, I want to recrop.','No, I want to recrop.');
switch crop_decision
    case 'No, I want to recrop.'
        recrop = 1;
        while recrop == 1
            imshow(image)
            [xlist, ylist] = ginput(2);
            image_crop = imcrop(image,[xlist(1) ylist(1) xlist(2)-xlist(1) ylist(2)-ylist(1)]);
            imshow(image_crop)
            crop_decision = questdlg('Are you satisfied with this crop? It will be used for all frames from now on.',...
                            'Confirm Crop', 'Yes, I am satisfied.',...
                            'No, I want to recrop.', 'No, I want to recrop.');
            switch crop_decision
                case 'No, I want to recrop.'
                    recrop = 1; 
                case 'Yes, I am satisfied.'
                    recrop = 0;
            end 
        end
    case 'Yes, I am satisfied.'
end
delete(handles.axes4);
main_axes = handles.axes1;
setappdata(handles.figure1,'main_axes',main_axes)
axes(main_axes);
set(gca,'NextPlot','add')
image = imshow(image_crop);
image.PickableParts = 'none';
main_axes.PickableParts = 'all';

% set(handles.head_xcoord,'String',head_xcoords(all_coord_ind(1)));
% set(handles.head_ycoord,'String',head_ycoords(all_coord_ind(1)));
% ^^ do we even need that

%% start change
set(handles.head_xcoord,'String',head_xcoords(odor_coord_ind{1}(1)));
set(handles.head_ycoord,'String',head_ycoords(odor_coord_ind{1}(1)));
set(handles.file_name,'String',jpg_file_log{1});

frame_count = 1;
setappdata(handles.figure1,'frame_count',frame_count);
trial_count = 1;
setappdata(handles.figure1,'trial_count',trial_count);
odor_count = 1;
setappdata(handles.figure1,'odor_count',odor_count);
%% end change 

% trial_data = []; <--- keep this
trial_data = cell(1);
setappdata(handles.figure1,'trial_data',trial_data);

jpg_count = 1;
setappdata(handles.figure1,'jpg_count',jpg_count);

% --- Outputs from this function are returned to the command line.
function varargout = perTrialGUI_final_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in undo_tail.
function undo_tail_Callback(hObject, eventdata, handles)
% hObject    handle to undo_tail (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isappdata(handles.figure1,'tail_point')
   msgbox('There is no coordinate to undo.','Error','error');
else 
    tail_point = getappdata(handles.figure1, 'tail_point');
    delete(tail_point)
    rmappdata(handles.figure1,'tail_point');
end 
set(handles.tail_xcoord,'String','-');
set(handles.tail_ycoord,'String','-');


% --- Executes on mouse press over axes background.
%% SIZE OF VIDEO SEEMS TO BE X = 480, Y = 640
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
coordinates_crop = getappdata(handles.figure1,'crop_coord');
if isappdata(handles.figure1,'tail_point')
    msgbox('Please undo your tail coordinate before entering another.', 'Error','error');
else
    axes(handles.axes1);
    coordinates_click = get(handles.axes1,'CurrentPoint'); 
    coordinates_click = coordinates_click(1,1:2);
    set(handles.tail_xcoord,'String',num2str(coordinates_click(1)+coordinates_crop(1)));
    set(handles.tail_ycoord,'String',num2str(coordinates_click(2)+coordinates_crop(2)));
    tail_point = scatter(coordinates_click(1),coordinates_click(2),20,'w','filled');
    setappdata(handles.figure1, 'tail_point', tail_point)
end 

function tail_xcoord_Callback(hObject, eventdata, handles)
% hObject    handle to tail_xcoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tail_xcoord as text
%        str2double(get(hObject,'String')) returns contents of tail_xcoord as a double
if isnan(str2double(get(handles.tail_xcoord,'String')))
    msgbox('Please enter a number.', 'Invalid Entry','error');
    set(handles.tail_xcoord,'String','')
elseif isempty(get(handles.tail_xcoord,'String'))
    set(handles.tail_xcoord,'String','')
else
    setappdata(handles.figure1,'tail_xcoord',str2double(get(handles.tail_xcoord,'String')))
end 

function tail_ycoord_Callback(hObject, eventdata, handles)
% hObject    handle to tail_ycoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tail_ycoord as text
%        str2double(get(hObject,'String')) returns contents of tail_ycoord as a double
if isnan(str2double(get(handles.tail_ycoord,'String')))
    msgbox('Please enter a number.', 'Invalid Entry','error');
    set(handles.tail_ycoord,'String','')
elseif isempty(get(handles.tail_ycoord,'String'))
    set(handles.tail_ycoord,'String','')
else
    setappdata(handles.figure1,'tail_ycoord',str2double(get(handles.tail_ycoord,'String')))
end 

% --- Executes on button press in manual_entry.
function manual_entry_Callback(hObject, eventdata, handles)
% hObject    handle to manual_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
coordinates = getappdata(handles.figure1,'crop_coord');
tail_xcoord = getappdata(handles.figure1,'tail_xcoord');
tail_ycoord = getappdata(handles.figure1,'tail_ycoord');
if isappdata(handles.figure1,'tail_point')
    msgbox('Please undo your tail coordinate before entering another.', 'Error','error');
else
    axes(handles.axes1)
    % tail_xcoord-coordinates(1),tail_ycoord-coordinates(2)? for scatter
    tail_point = scatter(tail_xcoord-coordinates(1),tail_ycoord-coordinates(2),20,'w','filled');
    setappdata(handles.figure1,'tail_point',tail_point)
end 

% --- Executes on button press in pushbutton4.
function next_frame_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
format short
%% start change
coordinates = getappdata(handles.figure1,'crop_coord');
odor_count = getappdata(handles.figure1,'odor_count');
trial_count = getappdata(handles.figure1,'trial_count');
frame_count = getappdata(handles.figure1,'frame_count');
jpg_count = getappdata(handles.figure1,'jpg_count');
jpg_file_log = getappdata(handles.figure1,'jpg_file_log');
jpgs_dir = getappdata(handles.figure1,'jpgs_dir');
trial_data = getappdata(handles.figure1,'trial_data');
main_axes = getappdata(handles.figure1,'main_axes');
head_xcoords = getappdata(handles.figure1,'head_xcoords');
head_ycoords = getappdata(handles.figure1,'head_ycoords');
odor_coord_ind = getappdata(handles.figure1,'odor_coord_ind');

% have to add coordinates(x) to trial_data to keep coordinates consistent
% with actual size of picture
%% had to change trial_data data structure; 1x5 cell with 2x11x2 double mat
trial_data{odor_count}(frame_count,1,trial_count) = str2double(get(handles.tail_xcoord,'String'));
trial_data{odor_count}(frame_count,2,trial_count) = str2double(get(handles.tail_ycoord,'String'));
setappdata(handles.figure1,'trial_data',trial_data);
set(handles.uitable1,'Data',trial_data{odor_count}(:,:,trial_count));
axes(main_axes);
set(gca,'NextPlot','add');

%% end condition 
if jpg_count == length(jpg_file_log)
    save('accuracyTestXY.mat','trial_data','odor_coord_ind','head_xcoords','head_ycoords');
    postProcessing();
    close(handles.figure1); %% can't do this 
end 

%% reinitializing to ensure we're in the right odor/trial/frame
jpg_count = jpg_count+1;
frame_count = frame_count+1;
if frame_count == 12
    frame_count = 1;
    if trial_count == 1
        trial_count = trial_count+1;
    else
        trial_count =  1;
        odor_count = odor_count+1;
    end
end
setappdata(handles.figure1,'frame_count',frame_count);
%% error here ^^ after finished postprocessing cuase we can't just close(figure1
setappdata(handles.figure1,'trial_count',trial_count);
setappdata(handles.figure1,'odor_count',odor_count);
setappdata(handles.figure1,'jpg_count',jpg_count);

%% getting and displaying next image
set(handles.file_name,'String',jpg_file_log{jpg_count});
jpg_image = imread([jpgs_dir, '/', jpg_file_log{jpg_count}]);
image = imshow(imcrop(jpg_image, coordinates)); 
image.PickableParts = 'none';
main_axes.PickableParts = 'all';
set(handles.tail_xcoord,'String','-');
set(handles.tail_ycoord,'String','-');
set(handles.head_xcoord,'String',num2str(head_xcoords(odor_coord_ind{odor_count}(trial_count))));
set(handles.head_ycoord,'String',num2str(head_ycoords(odor_coord_ind{odor_count}(trial_count))));
tail_point = getappdata(handles.figure1, 'tail_point');
delete(tail_point)
rmappdata(handles.figure1,'tail_point');
if jpg_count == length(jpg_file_log)
    set(handles.next_frame,'String','SAVE');
end
% tail_point = scatter(head_xcoords(odor_coord_ind{odor_count}(trial_count))-coordinates(1),head_ycoords(odor_coord_ind{odor_count}(trial_count))-coordinates(2),20,'w','filled');
%% end change; WE'RE doing the STEM NOW

% % coordinates = getappdata(handles.figure1,'crop_coord');
% % jpg_count = getappdata(handles.figure1,'jpg_count');
% % jpg_file_log = getappdata(handles.figure1,'jpg_file_log');
% % jpgs_dir = getappdata(handles.figure1,'jpgs_dir');
% % trial_data = getappdata(handles.figure1,'trial_data');
% % main_axes = getappdata(handles.figure1,'main_axes');
% % head_xcoords = getappdata(handles.figure1,'head_xcoords');
% % head_ycoords = getappdata(handles.figure1,'head_ycoords');
% % 
% % % have to add coordinates(x) to trial_data to keep coordinates consistent
% % % with actual size of picture
% % trial_data(end+1,1) = str2double(get(handles.tail_xcoord,'String'));
% % trial_data(end,2) = str2double(get(handles.tail_ycoord,'String'));
% % setappdata(handles.figure1,'trial_data',trial_data);
% % set(handles.uitable1,'Data',trial_data);
% % axes(main_axes);
% % set(gca,'NextPlot','add')
% % jpg_count = jpg_count + 1;
% % setappdata(handles.figure1,'jpg_count',jpg_count);
% % jpg_image = imread([jpgs_dir, '/', jpg_file_log{jpg_count}]);
% % image = imshow(imcrop(jpg_image, coordinates)); 
% % image.PickableParts = 'none';
% % main_axes.PickableParts = 'all';
% % set(handles.tail_xcoord,'String','-');
% % set(handles.tail_ycoord,'String','-');
% % set(handles.head_xcoord,'String',num2str(head_xcoords(all_coord_ind(jpg_count))));
% % set(handles.head_ycoord,'String',num2str(head_ycoords(all_coord_ind(jpg_count))));
% % tail_point = getappdata(handles.figure1, 'tail_point');
% % delete(tail_point)
% % rmappdata(handles.figure1,'tail_point');
% % if file_count == getappdata(handles.figure1,'jpg_file_length')
% %     save('trial_data.mat',
    
%% ============= stuff we don't need? ===============

% --- Executes during object creation, after setting all properties.
function tail_xcoord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tail_xcoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function tail_ycoord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tail_ycoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% FUNCTION: POST PROCESSING OF DATA
function postProcessing()

load('accuracyTestXY.mat');

format long

dataOutput = cell(1);
for odor = 1:length(trial_data)
    bothTrials = cell(1);
    for trial = 1:2
        timePlot = zeros(1,11);
        distPlot = zeros(1,11);
        xTicks = zeros(1,11);
        for frame = 1:11 % 11 is hardcoded
            timePlot(frame) = odor_coord_ind{odor}(trial) + ((frame-6)*0.0333);
            xTicks(frame) = timePlot(frame);
            xDiff = (trial_data{odor}(frame,1,trial)-head_xcoords(odor_coord_ind{odor}(trial)));
            yDiff = (trial_data{odor}(frame,2,trial)-head_ycoords(odor_coord_ind{odor}(trial)));
            distPlot(frame) = sqrt((xDiff^2)+(yDiff^2));
        end
        bothTrials{trial} = [distPlot; timePlot]; % row 1: dist, row2: time
        figure(1); 
        plot(timePlot,distPlot);
        xlim([odor_coord_ind{odor}(trial)+((1-6)*0.0333) odor_coord_ind{odor}(trial)+((11-6)*0.0333)]);
        xticks(xTicks)
        set(gcf, 'Position', get(0, 'Screensize'));
        fileTitle = ['odor',num2str(odor),'_',num2str(trial),'_AnalysisPlot'];
        title(['Odor: ',num2str(odor),' | Trial: ', num2str(trial)]);
        saveas(figure(1),fileTitle,'png');
        close(figure(1))
        % formatting and naming here
    end
% %     set(gcf, 'Position', get(0, 'Screensize'));
% %     title = ['odor',num2str(odor),'AnalysisPlot'];
% %     saveas(figure(odor),title,'png');
    dataOutput{odor} = bothTrials;
end % output: 1x5 cell, containing 1x2 cell, containing bothTrials
save('analysisData.mat','dataOutput');

%% FUNCTION: TRIAL START & END TIME EXTRACTION
% for in_seq
function [trial_time_start, trial_time_end, time_vals] = trial_time_extract(statMatrix, statMatrixColIDs)

% INPUTS ---  [statMatrix:(*x*, double)] and [statMatrixColIDs:(*x*,struct)]
% Function extracts the trial starting times (poke in) and ending times (poke out)
% of each tetrode. Ouputs two cell arrays , where the sizes of the two cell
% arrays and their respective, corresponding cell contents are the same.
% Column 1 is Odor A, Column 2 is Odor B, etc.
% OUTPUTS --- [trial_time_start:(1xi),cell] and [trial_time_end:(1xi),cell]

% ***_pos = linear index of ***'s values in statMatrix
odor_pos = find(cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'Odor')));
position_pos = find(cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'Position[0-9]+')));

% ***_vals = ***'s values in statMatrix 
time_vals = statMatrix(:,find(cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'TimeBin'))));
poke_vals = statMatrix(:,find(cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'PokeEvents'))));
performance_vals = statMatrix(:,find(cellfun(@(a)~isempty(a), regexp(statMatrixColIDs, 'PerformanceLog'))));
% poke in and poke out values to reference 
poke_in = find(poke_vals == 1);
poke_out = find(poke_vals == -1);

trial_time_start = cell(1);
trial_time_end = cell(1);
for i = 1:length(odor_pos)
    odor_vals = statMatrix(:,odor_pos(i)); 
    position_vals = statMatrix(:,position_pos(i));
    odor_pres_time = find(odor_vals==1 & position_vals==1 & performance_vals==1);
    trial_start_times = zeros(1,length(odor_pres_time));
    trial_end_times = zeros(1,length(odor_pres_time));
    for j = 1:length(odor_pres_time)
        trial_start_times(j) = time_vals(poke_in(find(poke_in<odor_pres_time(j),1,'last')));
        trial_end_times(j) = time_vals(poke_out(find(poke_out>odor_pres_time(j),1))); 
    end
    trial_time_start{1,i} = trial_start_times;
    trial_time_end{1,i} = trial_end_times;
end
   
% --- Executes during object creation, after setting all properties.
function uitable1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uitable1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
