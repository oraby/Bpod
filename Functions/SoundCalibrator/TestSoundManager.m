function varargout = TestSoundManager(varargin)
% TESTSOUNDMANAGER MATLAB code for TestSoundManager.fig
%      TESTSOUNDMANAGER, by itself, creates a new TESTSOUNDMANAGER or raises the existing
%      singleton*.
%
%      H = TESTSOUNDMANAGER returns the handle to a new TESTSOUNDMANAGER or the handle to
%      the existing singleton*.
%
%      TESTSOUNDMANAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TESTSOUNDMANAGER.M with the given input arguments.
%
%      TESTSOUNDMANAGER('Property','Value',...) creates a new TESTSOUNDMANAGER or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TestSoundManager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TestSoundManager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TestSoundManager

% Last Modified by GUIDE v2.5 06-Nov-2019 16:04:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TestSoundManager_OpeningFcn, ...
                   'gui_OutputFcn',  @TestSoundManager_OutputFcn, ...
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


% --- Executes just before TestSoundManager is made visible.
function TestSoundManager_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TestSoundManager (see VARARGIN)

% Choose default command line output for SoundCalibrationManager
handles.output = hObject;

% Predefine additional fields accessible using handles structure
%---------------------------------------------------------------
handles.calibrationFile = [];
handles.SoundCal        = [];

% Disable play button
set(handles.pushbutton_Play, 'Enable', 'off');

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = TestSoundManager_OutputFcn(hObject, eventdata, handles) %#ok<*STOUT>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
nan;


% --- Executes when selected object changed in unitgroup.
function unitgroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in unitgroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (hObject == handles.radiobutton_speaker1)
    handles.speaker=1;
else
    handles.speaker=2;
end
guidata(hObject,handles)


function edit_Sample_Rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Sample_Rate as text
%        str2double(get(hObject,'String')) returns contents of edit_Sample_Rate as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Sample rate must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Sample rate must be a positive numeric value!', 'Wrong format', 'error');
elseif (temp > 192)
    msgbox('Sample rate must not be higher than 192 kHz!', 'Unsupported value', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Sample_Rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Frequency_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Frequency as text
%        str2double(get(hObject,'String')) returns contents of edit_Frequency as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Frequency must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Frequency must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Volume_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Volume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Volume as text
%        str2double(get(hObject,'String')) returns contents of edit_Volume as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Volume must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Volume must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Volume_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Volume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Duration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Duration as text
%        str2double(get(hObject,'String')) returns contents of edit_Duration as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Duration must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Duration must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Duration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Duration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Browse.
function pushbutton_Browse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Show file open dialog
[fileName, pathName] = uigetfile;

% Check if user canceled dialog
if ( isnumeric(fileName) && (fileName == 0) )
    return;
end

% Creat fully qualified filename...
tempFullFile = fullfile(pathName, fileName);

% ... and copy it into edit_Filename
set(handles.edit_Filename, 'String', tempFullFile);

% Update handles structure
guidata(hObject, handles);

% Invoke callback for edit_Filename
edit_Filename_Callback(handles.edit_Filename, [], handles);

% Retrieve handles structure
handles = guidata(hObject);

% Update handles structure
guidata(hObject, handles);


function edit_Filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Filename as text
%        str2double(get(hObject,'String')) returns contents of edit_Filename as a double

% Check value
temp = strtrim(get(hObject,'String'));

if (isempty(temp))
    % Reset values
    set(handles.text_Cal_File_Value, 'String', '-');
    set(handles.textCal_Date_Value,  'String', '-');
    set(handles.text_Target_Value,   'String', '-');
    handles.calibrationFile = [];
    handles.SoundCal        = [];
    
    % Disable play button
    set(handles.pushbutton_Play, 'Enable', 'off');
    
    % Update handles structure
    guidata(hObject, handles);
    
    % Leave callback function
    return;
else
    [tempPath, tempFileName, tempExtension] = fileparts(temp);
    
    if (exist(temp, 'file') == 2)
        % Try to open the sound calibration file
        load(temp); %#ok<LOAD>
        
        if ( exist('SoundCal', 'var') == 1 )
            
            % Define necessary fields in SoundCal struct
            necessaryFields = {'Table', 'CalibrationTargetRange', 'TargetSPL', 'LastDateModified', 'Coefficient'};
            
            % Check for those fields
            fields = isfield(SoundCal, necessaryFields);
            wrongFields = find(fields == 0); 
            
            if (~isempty(wrongFields))
                tempMsg = sprintf('%s field in sound calibration file %s%s is missing!', necessaryFields{wrongFields(1)}, tempFileName, tempExtension);
                msgBox(tempMsg, 'Wrong file format', 'error');
                return;
            end
            
            % Store calibration data in handles structure
            handles.SoundCal = SoundCal;
            
            % Delete SoundCal struct from workspace
            clear SoundCal;
            
        else
            % Output error message
            tempMsg = sprintf('Calibration file ''%s%s'' contains an incompatible format!', tempFileName, tempExtension);
            msgbox(tempMsg, 'Error loading file', 'error');
            
            % Leave callback function
            return;
        end
        
    else
        % Output error message
        tempMsg = sprintf('Calibration file ''%s.%s'' could not be found in path %s!', tempFileName, tempExtension, tempPath);
        msgbox(tempMsg, 'Error loading file', 'error');
        
        % Leave callback function
        return;
    end
end

% Update text fields
set(handles.text_Cal_File_Value, 'String', [tempFileName tempExtension]);
set(handles.textCal_Date_Value,  'String', handles.SoundCal.LastDateModified);
set(handles.text_Target_Value,   'String', [num2str(handles.SoundCal.TargetSPL) ' dB_SPL']);

% Enable play button
set(handles.pushbutton_Play, 'Enable', 'on');

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function edit_Filename_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to edit_Filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Play.
function pushbutton_Play_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (isempty(handles.SoundCal))
    % Output error message
    msgbox('No sound calibration file loaded!', 'No file ', 'error');
    return;
end

% Get parameters
% --------------
Fs   = str2double(get(handles.edit_Sample_Rate, 'String'));
f0   = str2double(get(handles.edit_Frequency, 'String'));
a_dB = str2double(get(handles.edit_Volume, 'String'));
T0   = str2double(get(handles.edit_Duration, 'String'));

% --------------------------------------------------------------------------
% Check input values - Start
% --------------------------------------------------------------------------
% Check Sample Rate
if (isnan(Fs))
    msgbox('Sample rate must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (Fs <= 0)
    msgbox('Sample rate must be a positive numeric value!', 'Wrong format', 'error');
    return;
elseif (Fs > 192)
    msgbox('Sample rate must not be higher than 192 kHz!', 'Unsupported value', 'error');
    return;
end

% Check Frequency
if (isnan(f0))
    msgbox('Frequency must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (f0 <= 0)
    msgbox('Frequency must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

% Check Volume
if (isnan(a_dB))
    msgbox('Volume must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (a_dB <= 0)
    msgbox('Volume must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

% Check Duration
if (isnan(T0))
    msgbox('Duration must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (T0 <= 0)
    msgbox('Duration must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

% Check selected speaker
if get(handles.radiobutton_speaker1, 'Value')
    handles.speaker = 1;
elseif get(handles.radiobutton_speaker2, 'Value')
    handles.speaker = 2;
else
    msgBox('Invalid speaker selection!', 'Error', 'error');
    return;
end
% --------------------------------------------------------------------------
% Check input values - End
% --------------------------------------------------------------------------

if (size(handles.SoundCal, 2) < handles.speaker)
    msgbox('Selected sound calibration file has only calibration values for speaker 1 (left)', ...
           'No calibration for speaker', 'error');
    return;
end


if isfield(handles.SoundCal(1, handles.speaker), 'FitMethod')
    fitMethod = handles.SoundCal(1, handles.speaker).FitMethod;
    switch(lower(fitMethod))
        case 'pchip'
            att = ppval(handles.SoundCal(1, handles.speaker).Coefficient, f0);
            
        otherwise
            tempMsg = sprintf('Unsupported interpolation method ''%s'' being used during calibration', fitMethod);
            msgBox(tempMsg, 'Unknown interpolation', 'error');
            return;
    end
else
    att = polyval(handles.SoundCal(1, handles.speaker).Coefficient, f0);
end

% Get the difference between the calibrated sound pressure level and the
% currently desired sound pressure level
diff_dB_SPL = a_dB - handles.SoundCal(1, handles.speaker).TargetSPL;

% Convert this difference into an amplidute correction factor (that's why
% deviding by 20 - or taking sqrt of the result if deviding by 10)
% If difference is positive, the correction factor will be > 1 otherwise < 1
corrFactor = 10^(diff_dB_SPL/20);

% correct the amplitude
a = att * corrFactor;

% Generate time vecotr for creating sound
t = 0:1/Fs:T0;

% Generate sound - pure tone
soundOutput = a * sin(2 * pi * f0 * t);

if handles.speaker==1
    soundOutput = [soundOutput; zeros(1,length(soundOutput))];
end
if handles.speaker==2
    soundOutput = [zeros(1,length(soundOutput)); soundOutput];
end

% Load the sound vector into sound server's channel 1
PsychToolboxSoundServer('Load', 1, soundOutput);

% Start playing output channel 1
PsychToolboxSoundServer('Play', 1);


% --- Executes on button press in pushbutton_Close.
function pushbutton_Close_Callback(hObject, eventdata, handles) %#ok<*INUSL,*DEFNU>
% hObject    handle to pushbutton_Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.TestSoundGUI)
