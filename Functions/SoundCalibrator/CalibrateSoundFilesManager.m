function varargout = CalibrateSoundFilesManager(varargin)

% CALIBRATESOUNDFILESMANAGER MATLAB code for CalibrateSoundFilesManager.fig
%      CALIBRATESOUNDFILESMANAGER, by itself, creates a new CALIBRATESOUNDFILESMANAGER or raises the existing
%      singleton*.
%
%      H = CALIBRATESOUNDFILESMANAGER returns the handle to a new CALIBRATESOUNDFILESMANAGER or the handle to
%      the existing singleton*.
%
%      CALIBRATESOUNDFILESMANAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALIBRATESOUNDFILESMANAGER.M with the given input arguments.
%
%      CALIBRATESOUNDFILESMANAGER('Property','Value',...) creates a new CALIBRATESOUNDFILESMANAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CalibrateSoundFilesManager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CalibrateSoundFilesManager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text_Amp_Condition to modify the response to help CalibrateSoundFilesManager

% Last Modified by GUIDE v2.5 21-Nov-2019 17:08:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CalibrateSoundFilesManager_OpeningFcn, ...
    'gui_OutputFcn',  @CalibrateSoundFilesManager_OutputFcn, ...
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


% --- Executes just before CalibrateSoundFilesManager is made visible.
function CalibrateSoundFilesManager_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CalibrateSoundFilesManager (see VARARGIN)

% UIWAIT makes CalibrateSoundFilesManager wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Choose default command line output for CalibrateSoundFilesManager
handles.output = hObject;

global abortCalibration;
abortCalibration = 0;

% Predefine additional fields accessible using handles structure
%---------------------------------------------------------------
% DAQ-related variables
handles.DAQDevicesAvailable = [];
handles.DAQ.Session         = [];
handles.DAQ.VendorID        = [];
handles.DAQ.DeviceID        = [];
handles.DAQ.InputChannel    = [];
handles.DAQ.SamplingRate    = [];
handles.DAQ.Range           = [];

handles.SoundCal.speakerSelection = [];
handles.SoundCal.ampCondition     = 0;
handles.SoundCal.targetSPL        = 0;
handles.SoundCal.numRepeats       = 0;

handles.SoundCal.currSpeakerName = 0;
handles.SoundCal.currAmplitude   = 0;

handles.SoundCal.delayPlayback             = 0.25;   % Amount of time before and after the actual stimulus so that recording system has enough time to acquire everything
handles.SoundCal.samplingFrequency_kHz     = [];     % Sampling rate of sound card in kHz
handles.SoundCal.samplingFrequency_Hz      = [];     % Sampling rate of sound card in Hz
handles.SoundCal.initialAmplitude          = 0.2;    % Initial Amplitude
handles.SoundCal.acceptableTolerance_dBSPL = 0.5;    % Max. tolerable difference
handles.SoundCal.maxInterations            = 15;     % Max. number of iterations per frequency
handles.SoundCal.pressureReference         = 20e-6;  % Pressure reference p0 in Pascal (Pa)
handles.SoundCal.monoChannel               = 0;

handles.SoundCal.filterOrder               = 9;
handles.SoundCal.filterCuttOff             = 200;
handles.SoundCal.windowLength              = 0.05;
handles.SoundCal.overlapLength             = 0.01;

handles.InputAudioFile.Filename = '';
handles.InputAudioFile.FilePath = '';
handles.InputAudioFile.Signal   = [];
handles.InputAudioFile.Fs       = [];
handles.InputAudioFile.Channels = [];

handles.InputAudioFile.axSignalLeft       = [];
handles.InputAudioFile.axSignalRight      = [];
handles.InputAudioFile.axSpectrogramLeft  = [];
handles.InputAudioFile.axSpectrogramRight = [];

handles.OutputAudioFile.axPressureSignal  = [];


handles.startedBefore = 0;

% Set values for speaker selection
handles.SoundCal.speakerSelectionStrings = {'Channel 1 (left)', 'Channel 2 (right)', 'Both - independent', 'Both - joined'};
set(handles.popupmenu_Speaker,'String', handles.SoundCal.speakerSelectionStrings );

% Create text label for physical unit of edit_TargetSPL (dB_SPL)
handles.dB_SPL_label= javaObjectEDT('javax.swing.JLabel','<HTML><font face="arial" size="4">dB<sub>SPL</sub></font></HTML>');
javacomponent(handles.dB_SPL_label,[477,595,40,16], gcf);

% Making the uipannels for the spectrogram etc invisible
set(handles.uipanel_Input_Audio_File, 'Visible', 'off');
set(handles.uipanel_Output_Audio_File, 'Visible', 'off');

handles.OutputAudioFile.axPressureSignal = axes(handles.uipanel_Output_Audio_File);

% Deactivate calibration button
set(handles.pushbutton_Calibrate, 'Enable', 'off');

% since the Data Acquisition Toolbox is only available on Windows, we have to
% distinguish between the different OS versions...
if ispc
    if (license('test','Data_Acq_Toolbox') ~= 1)
        msgbox('No Data Acquisition Toolbox available on this system!', ...
            'No Data Acquisition Toolbox found...', 'error');
        error('No Data Acquisition Toolbox available on this system!');
    end
    % Get a list of all connected data acquisition devices
    handles.DAQDevicesAvailable = daq.getDevices();
    if (isempty(handles.DAQDevicesAvailable))
        msgbox('No Data Acquisition Systems found on this system! Connect DAQ device and restart MATLAB.', ...
            'No DAQ devices found...', 'error');
        error('No Data Acquisition Systems found on this system!');
    end
    devNames = cell(1, length(handles.DAQDevicesAvailable));
    for devCntr = 1:1:length(handles.DAQDevicesAvailable)
        currDev = handles.DAQDevicesAvailable(devCntr);
        devNames{1, devCntr} = sprintf('%s - %s', currDev.Vendor.ID, currDev.ID);
    end
    
    % Set values for DAQ Device popupmenu
    handles.popupmenu_DAQ_Device.String = devNames;
    
else
    % If this code is executed on a Linux or macOSX system, we can't access the
    % Data Acquisition Toolbox...
    %
    % M. Wulf, 2019-11-04:
    % This code needs to be tested on Linux and Mac!!!
    handles.DAQ.VendorID = 'mcc';
    handles.DAQ.DeviceID = 'Board0';
    handles.popupmenu_DAQ_Device.String = {sprintf('%s - %s', handles.DAQ.VendorID, handles.DAQ.DeviceID)};
end

% Update handles structure
guidata(hObject, handles);

% Execute callback for DAQ Device selection
popupmenu_DAQ_Device_Callback(handles.popupmenu_DAQ_Device, [], handles);

% Retrieve handles structure
handles = guidata(hObject);

% Update handles structure
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = CalibrateSoundFilesManager_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu_DAQ_Device.
function popupmenu_DAQ_Device_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_DAQ_Device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_DAQ_Device contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_DAQ_Device

% Get selected value from popupmenu
contents      = cellstr(get(hObject,'String'));
selectedEntry = get(hObject,'Value');
selectedItem  = contents{selectedEntry};

% Take the item as a string to get vendor ID and device ID for DAQ device
parts = strsplit(selectedItem, '-');
if (length(parts) ~= 2)
    error('string in popupmenu for DAQ device has an invalid structure!');
end
handles.DAQ.VendorID = strtrim(parts{1});
handles.DAQ.DeviceID = strtrim(parts{2});

% Set values for analog input channel based on selected DAQ device
if ispc
    handles.popupmenu_DAQ_Input_Ch.String = handles.DAQDevicesAvailable(selectedEntry).Subsystems(1).ChannelNames;
else
    if ( strcmpi(handles.DAQ.VendorID, 'mcc') && strncmpi(handles.DAQ.DeviceID, 'Board', 5) )
        popupItemsNums = 16;
        popupItems = cell(1, popupItemsNums);
        for inputCntr = 1:1:popupItemsNums
            popupItems{inputCntr} = sprintf('Ai%d', inputCntr-1);
        end
        
        handles.popupmenu_DAQ_Input_Ch.String = popupItems;
    end
end

% Update handles structure
guidata(hObject, handles);

% Invoke callback for input channel selection
popupmenu_DAQ_Input_Ch_Callback(handles.popupmenu_DAQ_Input_Ch, [], handles);

% Retrieve handles structure
handles = guidata(hObject);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_DAQ_Device_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% hObject    handle to popupmenu_DAQ_Device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_DAQ_Input_Ch.
function popupmenu_DAQ_Input_Ch_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_DAQ_Input_Ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_DAQ_Input_Ch contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_DAQ_Input_Ch

% Get selected value from popupmenu
contents      = cellstr(get(hObject,'String'));
selectedEntry = get(hObject,'Value');
selectedItem  = contents{selectedEntry};

% Take the item as a string to get vendor ID and device ID for DAQ device
handles.DAQ.InputChannel = strtrim(selectedItem);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_DAQ_Input_Ch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_DAQ_Input_Ch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_DAQ_Sample_Rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_DAQ_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_DAQ_Sample_Rate as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_DAQ_Sample_Rate as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Sample rate must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Sample rate must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_DAQ_Sample_Rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_DAQ_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_DAQ_Range_Callback(hObject, eventdata, handles)
% hObject    handle to edit_DAQ_Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_DAQ_Range as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_DAQ_Range as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Input range must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Input range must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_DAQ_Range_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_DAQ_Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Speaker.
function popupmenu_Speaker_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Speaker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Speaker contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Speaker

% Change value for Mono checkbox
currValue = handles.SoundCal.speakerSelectionStrings{get(hObject,'Value')};
if ( (~isempty(currValue)) && (strcmpi(currValue, 'Both - joined')) )
    set(handles.checkbox_File_Mono, 'Value', 1);
elseif ( (~isempty(currValue)) && (~strcmpi(currValue, 'Both - joined')) )
    set(handles.checkbox_File_Mono, 'Value', 0);
    
end


% --- Executes during object creation, after setting all properties.
function popupmenu_Speaker_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Speaker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Amplifier_Condition_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Amplifier_Condition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Amplifier_Condition as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Amplifier_Condition as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Amplifier condition must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Amplifier condition must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Amplifier_Condition_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Amplifier_Condition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_TargetSPL_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Num_Speakers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Target sound level (dB_SPL) must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Target sound level (dB_SPL) must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_TargetSPL_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_TargetSPL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Repetitions_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Repetitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Number of repetitions must be a numeric value!', 'Wrong format', 'error');
elseif ( (temp <= 0) || (mod(temp, 1) ~= 0) )
    msgbox('Number of repetitions must be a postive integer!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Repetitions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Repetitions (see GCBO)
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

% Show file open dialoge
[audioFilename, audioFilepath] = uigetfile('*.*', 'Select Audio File');

if ( (isnumeric(audioFilename)) && (audioFilename == 0) )
    % user canceled
    return;
end

% Try to open selcted audio file
try
    [audioSignal, audioFs] = audioread(fullfile(audioFilepath, audioFilename));
catch ME
    errMsg = sprintf('Error while trying to read audiofile %s! Error message: %s', audioFilename, ME.message);
    msgbox(errMsg, 'Loading audio file failed', 'error');
    return;
end

% Check number of channels in the audio file
numCh = size(audioSignal, 2);

if ( (numCh == 0) || (numCh > 2) )
    errMsg = sprintf('Error loading audio file %s! Unsupported number of audio channels (channels = %d)', audioFilename, numCh);
    msgbox(errMsg, 'Loading audio file failed', 'error');
    return;
end

% If we come to this point, we should have a valid audio file...

% Get number of samples in the audio file (per channel)
numSamples = size(audioSignal, 1);

% Get length of the audio file in seconds
audioLength = (numSamples-1) * 1/audioFs;

% Create the time vector for plotting
timeVector = (0:1:(numSamples-1)) * 1/audioFs;

% Create subplots depending on the number of channels in the audio file
if numCh == 1
    handles.InputAudioFile.axSignalLeft      = subplot(2,1,1, 'Parent', handles.uipanel_Input_Audio_File);
    handles.InputAudioFile.axSpectrogramLeft = subplot(2,1,2, 'Parent', handles.uipanel_Input_Audio_File);
elseif numCh == 2
    handles.InputAudioFile.axSignalLeft      = subplot(2,2,1, 'Parent', handles.uipanel_Input_Audio_File);
    handles.InputAudioFile.axSignalRight     = subplot(2,2,2, 'Parent', handles.uipanel_Input_Audio_File);
    handles.InputAudioFile.axSpectrogramLeft = subplot(2,2,3, 'Parent', handles.uipanel_Input_Audio_File);
    handles.InputAudioFile.axSpectrogramRight= subplot(2,2,4, 'Parent', handles.uipanel_Input_Audio_File);
end

% Set text fields with correct values
set(handles.text_Filename,         'String', audioFilename);
set(handles.text_File_Channels,    'String', num2str(numCh));
set(handles.text_File_Length,      'String', num2str(audioLength));
set(handles.text_File_Sample_Rate, 'String', num2str(audioFs/1000));

% Plot waveform for left channel or mono signal...
plot(handles.InputAudioFile.axSignalLeft, ...
    timeVector,...
    audioSignal(:, 1));
grid(handles.InputAudioFile.axSignalLeft, 'on');
tempAxis = [0 audioLength -1.1 1.1];
axis(handles.InputAudioFile.axSignalLeft, tempAxis);
if numCh == 1
    tempTitle = 'Waveform';
else
    tempTitle = 'Waveform (left ch.)';
end
title(handles.InputAudioFile.axSignalLeft, tempTitle, 'FontSize', 10);
xlabel(handles.InputAudioFile.axSignalLeft, 'Time (s)', 'FontSize', 10);
ylabel(handles.InputAudioFile.axSignalLeft, 'Amplitude', 'FontSize', 10);

% Plot waveform for right channel (if audio file is a stereo file)
if numCh == 2
    plot(handles.InputAudioFile.axSignalRight, ...
        timeVector,...
        audioSignal(:, 2));
    grid(handles.InputAudioFile.axSignalRight, 'on');
    tempAxis = [0 audioLength -1.1 1.1];
    axis(handles.InputAudioFile.axSignalRight, tempAxis);
    tempTitle = 'Waveform (right ch.)';
    title(handles.InputAudioFile.axSignalRight, tempTitle, 'FontSize', 10);
    xlabel(handles.InputAudioFile.axSignalRight, 'Time (s)', 'FontSize', 10);
    ylabel(handles.InputAudioFile.axSignalRight, 'Amplitude', 'FontSize', 10);
end

% Calculate spectrogram for left/mono channel and plot it into the corresponding axes
[~, f, t, ps] = spectrogram(audioSignal(:, 1), 256, 250, 256, audioFs, 'yaxis');
imagesc(handles.InputAudioFile.axSpectrogramLeft, t, f/1000, 10*log10(ps));
set(handles.InputAudioFile.axSpectrogramLeft,'YDir','normal');
xlabel(handles.InputAudioFile.axSpectrogramLeft, 'Time (s)', 'FontSize', 10);
ylabel(handles.InputAudioFile.axSpectrogramLeft, 'Frequency (kHz)', 'FontSize', 10);
if numCh == 1
    tempTitle = 'Spectrogram';
else
    tempTitle = 'Spectrogram (left ch.)';
end
title(handles.InputAudioFile.axSpectrogramLeft, tempTitle, 'FontSize', 10);

% Calculate spectrogram for right channel and plot it into the corresponding axes
if numCh == 2
    [~, f, t, ps] = spectrogram(audioSignal(:, 2), 256, 250, 256, audioFs, 'yaxis');
    imagesc(handles.InputAudioFile.axSpectrogramRight, t, f/1000, 10*log10(ps));
    set(handles.InputAudioFile.axSpectrogramRight,'YDir','normal');
    xlabel(handles.InputAudioFile.axSpectrogramRight, 'Time (s)', 'FontSize', 10);
    ylabel(handles.InputAudioFile.axSpectrogramRight, 'Frequency (kHz)', 'FontSize', 10);
    tempTitle = 'Spectrogram (right ch.)';
    title(handles.InputAudioFile.axSpectrogramRight, tempTitle, 'FontSize', 10);
end

% Store data in handles structure
handles.InputAudioFile.Filename = audioFilename;
handles.InputAudioFile.FilePath = audioFilepath;
handles.InputAudioFile.Signal   = audioSignal;
handles.InputAudioFile.Fs       = audioFs;
handles.InputAudioFile.Channels = numCh;

% Making uipanel for waveform and spectrogram visible
set(handles.uipanel_Input_Audio_File, 'Visible', 'on');

% Activate calibration button
set(handles.pushbutton_Calibrate, 'Enable', 'on');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in checkbox_File_Mono.
function checkbox_File_Mono_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_File_Mono (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox_File_Mono
nan;


function edit_File_Target_Sample_Rate_Callback(hObject, eventdata, handles)
% hObject    handle to edit_File_Target_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_File_Target_Sample_Rate as text
%        str2double(get(hObject,'String')) returns contents of edit_File_Target_Sample_Rate as a double
% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Target sample rate must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Target sample rate must be a positive numeric value!', 'Wrong format', 'error');
elseif (temp > 192)
    msgbox('Target sample rates higher than 192 kHz are not supported!', 'Wrong format', 'error');
elseif (temp ~= 192)
    msgbox('Target sample rates other than 192 kHz are not supported!', 'Wrong format', 'error');
end


% --- Executes during object creation, after setting all properties.
function edit_File_Target_Sample_Rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_File_Target_Sample_Rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_Calibrate.
function pushbutton_Calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global abortCalibration;

abortCalibration = 0;

% Get calibration parameters
% --------------------------------------------------------------------------
handles.DAQ.SamplingRate               = str2double(get(handles.edit_DAQ_Sample_Rate, 'String'));
handles.DAQ.Range                      = str2double(get(handles.edit_DAQ_Range, 'String'));
handles.SoundCal.ampCondition          = str2double(get(handles.edit_Amplifier_Condition, 'String'));
handles.SoundCal.targetSPL             = str2double(get(handles.edit_TargetSPL, 'String'));
handles.SoundCal.numRepeats            = str2double(get(handles.edit_Repetitions, 'String'));
handles.SoundCal.monoChannel           = get(handles.checkbox_File_Mono, 'Value');
handles.SoundCal.samplingFrequency_kHz = str2double(get(handles.edit_File_Target_Sample_Rate, 'String'));
% --------------------------------------------------------------------------
% Check input values - Start
% --------------------------------------------------------------------------
if (isnan(handles.DAQ.SamplingRate))
    msgbox('DAQ sampling rate must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.DAQ.SamplingRate <= 0)
    msgbox('DAQ sampling rate must be a positive numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.DAQ.SamplingRate > 200)
    msgbox('DAQ sampling rates greater than 200 kHz are not supported!', 'Unsupported value', 'error');
    return;
else
    % Convert Sampling Rate from kHz to Hz
    handles.DAQ.SamplingRate = 1000 * handles.DAQ.SamplingRate;
end

if (isnan(handles.DAQ.Range))
    msgbox('Input range must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.DAQ.Range <= 0)
    msgbox('Input range must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.ampCondition))
    msgbox('Amplifier condition must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.ampCondition <= 0)
    msgbox('Amplifier condition must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.targetSPL))
    msgbox('Target sound level (dB_SPL) must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.targetSPL <= 0)
    msgbox('Target sound level (dB_SPL) must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.numRepeats))
    msgbox('Number of repetitions must be a numeric value!', 'Wrong format', 'error');
    return;
elseif ( (handles.SoundCal.numRepeats <= 0) || (mod(handles.SoundCal.numRepeats, 1) ~= 0) )
    msgbox('Number of repetitions must be a postive integer!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.samplingFrequency_kHz))
    msgbox('Target sample rate of calibration points must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.samplingFrequency_kHz <= 0)
    msgbox('Target sample rate must be a positive numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.samplingFrequency_kHz > 192)
    msgbox('Target sample rates higher than 192 kHz are not supported!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.samplingFrequency_kHz ~= 192)
    msgbox('Target sample rates other than 192 kHz are not supported!', 'Wrong format', 'error');
    return;
else
    handles.SoundCal.samplingFrequency_Hz = handles.SoundCal.samplingFrequency_kHz * 1000;
end

% Get value from sepeaker selection
handles.SoundCal.speakerSelection = handles.SoundCal.speakerSelectionStrings{get(handles.popupmenu_Speaker,'Value')};

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------------
% Check input values - End
% --------------------------------------------------------------------------

% Specify calibration file
% ------------------------
OutputFileName = 'SoundFileCalibration';
[FileName, PathName] = uiputfile('.mat', 'Save Sound Calibration File', OutputFileName);
% Check if user clicked on cancel button
if ( (isnumeric(FileName) & (FileName == 0)) | (isnumeric(PathName) & (PathName == 0)) ) %#ok<OR2,AND2>
    disp('Canceled by user');
    return;
end

% Give out a notification that the user should make sure that the
% calibration setup is connected and turned on. Depending on the sound
% geerating setup (amplifier and speaker etc.) it could be possible to
% destroy the speakers in case the acquisition system is not measuring
% anything. The soundcard's output would go to maximum (1 V peak amplitude)
% and that could destroy especially high frequency tweeters when the
% calibration should be performed for low frequencies.
if (handles.startedBefore == 0)
    tempDaq = sprintf('%s - %s, Input: %s', handles.DAQ.VendorID, handles.DAQ.DeviceID, handles.DAQ.InputChannel);
    msg = sprintf('Before starting the calibration, make sure the acquisition system (conditioned amplifier and data acquisition interface) is turned on!');
    msg = sprintf('%s If the data acquisition system (%s) is not able to measure correctly, the soundcard would output a signal with a peak voltage of 1 V that could cause harm to the speakers!', msg, tempDaq);
    uiwait(msgbox(msg, 'Check setup', 'warn', 'modal'));
end
handles.startedBefore = 1;

% Check sample rates
if (handles.InputAudioFile.Fs ~= handles.SoundCal.samplingFrequency_Hz)
    [P,Q] = rat(handles.SoundCal.samplingFrequency_Hz/handles.InputAudioFile.Fs);
    audioSignal = resample(handles.InputAudioFile.Signal, P, Q);
else
    audioSignal = handles.InputAudioFile.Signal;
end

% Transpose it to row vectors
audioSignal = audioSignal';

% If audio signal is mono, just copy the channel... That will make life easier
if ( size(audioSignal, 1) == 1)
    % Mono signal;
    audioSignal = repmat(audioSignal, 2, 1);
end

if (handles.SoundCal.monoChannel)
    audioSignal = repmat(mean(audioSignal), 2, 1);
end

% Initialize vector for output
% ------------------------------------------------------------------------------
% Get length of (resampled) audio file
audioLength     = size(audioSignal, 2);
% Add a delay so the sound card will have enough time and the acquisitions sytem will not miss something
numDelaySamples = handles.SoundCal.delayPlayback * handles.SoundCal.samplingFrequency_Hz;

outputLength    = numDelaySamples + size(audioSignal, 2) + numDelaySamples;
outputLengthSec = outputLength/handles.SoundCal.samplingFrequency_Hz;
outputStart     = numDelaySamples + 1;
outputEnd       = outputStart + audioLength - 1;

outputSound     = zeros(2, outputLength);

% (Re-)Initialize PsychToolbox PortAudio
PsychToolboxSoundServer('init');

% Setup daq device in case this code is being executed on a Windows system
if ispc
    % Create DAQ session
    handles.DAQ.Session = daq.createSession(handles.DAQ.VendorID);
    
    % Set DAQ sampling rate
    handles.DAQ.Session.Rate = handles.DAQ.SamplingRate;
    
    % Set DAQ recording duration
    handles.DAQ.Session.DurationInSeconds = outputLengthSec;
    
    % Attach input channel to DAQ session
    handles.DAQ.ChIn = addAnalogInputChannel(handles.DAQ.Session, handles.DAQ.DeviceID, handles.DAQ.InputChannel, 'Voltage');
    
    % Set input range of input channel
    handles.DAQ.ChIn.Range   = [-handles.DAQ.Range handles.DAQ.Range];
else
    if (~strncmpi(handles.DAQ.VendorID, 'mcc', 3))
        errorStr = sprintf('Unsupported DAQ device for non-Windows operating systems! Vendor: %s', handles.DAQ.VendorID);
        msgbox(errorStr, 'Unsupported DAQ device', 'error');
        return;
    end
end

% Get value from sepeaker selection
if strcmpi(handles.SoundCal.speakerSelection, 'Channel 1 (left)')
    speakerCount = 1;
    handles.SoundCal.currSpeakerName = 'left';
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Channel 2 (right)')
    speakerCount = 1;
    handles.SoundCal.currSpeakerName = 'right';
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Both - independent')
    speakerCount = 2;
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Both - joined')
    speakerCount = 1;
    handles.SoundCal.currSpeakerName = 'both';
    
else
    errorStr = sprintf('Unknown speaker selection: %s!', handles.SoundCal.speakerSelection);
    msgbox(errorStr, 'Uknown speaker selection', 'error');
    return;
end

% Create subplots depending on the number of channels in the audio file
set(handles.uipanel_Output_Audio_File, 'Visible', 'off');
cla(handles.OutputAudioFile.axPressureSignal);

% Define a struct for passing values to other methods
SoundCal = struct;

% Initialize vector for attenuation values
AttenuationVector = zeros(2, handles.SoundCal.numRepeats);

% Pre-calculate the values for RMS calculation
winLength     = (handles.SoundCal.windowLength  * handles.SoundCal.samplingFrequency_Hz) + 1;
overlapLength = (handles.SoundCal.overlapLength * handles.SoundCal.samplingFrequency_Hz) + 1;

% Intialize high-pass filter
[z,p,k] = butter(handles.SoundCal.filterOrder, handles.SoundCal.filterCuttOff/(handles.SoundCal.samplingFrequency_Hz/2), 'high');
[sos, g] = zp2sos(z,p,k);

% Loop through selected speakers
for currSpeaker=1:speakerCount
    
    if ( (speakerCount == 2) && (currSpeaker == 1) )
        handles.SoundCal.currSpeakerName = 'left';
    elseif ( (speakerCount == 2) && (currSpeaker == 2) )
        handles.SoundCal.currSpeakerName = 'right';
    end
    
    if ( strcmpi(handles.SoundCal.currSpeakerName, 'left') )
        % Set value for indexing
        speakerMatrixIdx = 1;
        
        % Generate output signal
        outputSound(1, outputStart:outputEnd) = audioSignal(1, :);
        outputSound(2, :) = zeros(1, outputLength);
        
        % Set name for user interface
        channelName = 'channel 1 (left)';
        
    elseif ( strcmpi(handles.SoundCal.currSpeakerName, 'right') )
        % Set value for indexing
        speakerMatrixIdx = 2;
        
        % Generate output signal
        outputSound(1, :) = zeros(1, outputLength);
        outputSound(2, outputStart:outputEnd) = audioSignal(2, :);
        
        % Set name for user interface
        channelName = 'channel 2 (right)';
        
    elseif  ( strcmpi(handles.SoundCal.currSpeakerName, 'both') )
        % Generate output signal
        outputSound(1, outputStart:outputEnd) = audioSignal(1, :);
        outputSound(2, outputStart:outputEnd) = audioSignal(2, :);
        
        % Set name for user interface
        channelName = 'both channels (left & right) combined';
    end
    
    % Let user know to place the microphone
    uiwait(msgbox({['Calibrating ' channelName '.'], 'Position microphone and press OK to continue...'}, 'Sound Calibration', 'modal'));
    
    for currRep=1:handles.SoundCal.numRepeats
        
        if currRep>1
            uiwait(msgbox('Reposition microphone for next repetition and press OK', 'Sound Calibration', 'modal'));
        end
        
        % Set the amplitude for first iteration
        handles.SoundCal.currAmplitude = handles.SoundCal.initialAmplitude;
        
        % Estimate attenuation
        for currIteration = 1:1:handles.SoundCal.maxInterations
            
            if (abortCalibration ~= 0)
                % User aborted calibration
                
                % Delete handle to DAQ session
                delete(handles.DAQ.Session);
                
                % Output a warning...
                tempMsg = ('Calibration manually aborted.');
                msgbox(tempMsg, 'Calibration aborted', 'warn');
                
                return;
            end
            
            % Load the sound vector into sound server's channel 1
            PsychToolboxSoundServer('Load', 1, handles.SoundCal.currAmplitude * outputSound);
            
            % Start recording using the DAQ device
            if ispc
                % Start playing output channel 1
                PsychToolboxSoundServer('Play', 1);
                                
                % Start recording
                rawSignal = startForeground(handles.DAQ.Session);
                
            else
                if ( strncmpi(handles.DAQ.VendorID, 'mcc', 3) )
                    % Getnumber of samples to be acquired
                    recordLength = outputLengthSec * handles.DAQ.SamplingRate;
                    
                    % Start playing output channel 1
                    PsychToolboxSoundServer('Play', 1);
                    
                    % Record in blocking mode (no pause needed)
                    data = mcc_daq('n_scan', recordLength,'freq', FsInput, 'n_chan', 1);
                    
                    % Get first channel
                    rawSignal = data(1, :);
                    
                    % Wait for recording to be finished
                    pause(outputLengthSec);
                end
            end
            
            % Wait a bit
            pause(0.5);
            
            % Stop outputting sound signal
            PsychToolboxSoundServer('StopAll');
            
            % Scale the recorded voltage to a pressure signal (based on the values of the
            % conditioned amplifier)
            pressureSignal = rawSignal/handles.SoundCal.ampCondition;
            
            % Filter the signal to avoid influence of noise being picked up
            % by the acquisition system (especially powerline interferences)
            pressureSignal = filtfilt(sos, g, pressureSignal);
            % RMS calculation and windowing etc...
            % ------------------------------------------------------------------
            % ------------------------------------------------------------------
            windowed_RMS = windowedRMS(pressureSignal, winLength, overlapLength);
            
            % Get the peak windowed RMS value ...
            maxRMS = max(windowed_RMS);
            
            % ... and calculate the SPL value in dB
            % Attention: since we are calculating with amplitudes, the factor
            % must either be 20 or the argument of the log10 must be squared!
            current_dBSPL = 20*log10(maxRMS/handles.SoundCal.pressureReference);
            
            % ------------------------------------------------------------------
            % ------------------------------------------------------------------
            
            % Update text fields
            set(handles.text_ResultsAttnValue,  'String', num2str(handles.SoundCal.currAmplitude));
            set(handles.text_ResultsPowerValue, 'String', num2str(current_dBSPL));
            
            % Calculate difference between current output and target output
            diff_dBSPL = current_dBSPL - handles.SoundCal.targetSPL;
            
            if ( abs(diff_dBSPL) < handles.SoundCal.acceptableTolerance_dBSPL )
                % Plot the recordins
                temp_time = (0:1:(outputEnd-outputStart))/handles.SoundCal.samplingFrequency_Hz;
                plot(handles.OutputAudioFile.axPressureSignal, temp_time, pressureSignal(outputStart:outputEnd));
                hold(handles.OutputAudioFile.axPressureSignal, 'on');
                title(handles.OutputAudioFile.axPressureSignal, 'Recorded Pressure Signal', 'FontSize', 10);
                ylabel(handles.OutputAudioFile.axPressureSignal, 'Pressure (Pa)', 'FontSize', 10);
                xlabel(handles.OutputAudioFile.axPressureSignal, 'Time (s)', 'FontSize', 10);
                tempAxis = axis(handles.OutputAudioFile.axPressureSignal);
                tempAxis(2) = temp_time(end);
                tempAxis(3) = -max(abs(tempAxis(3:4)));
                tempAxis(4) = max(abs(tempAxis(3:4)));
                axis(handles.OutputAudioFile.axPressureSignal, tempAxis);
                grid(handles.OutputAudioFile.axPressureSignal, 'on');
                set(handles.uipanel_Output_Audio_File, 'Visible', 'on');
                
                % Leave the loop
                break;
                
            elseif ( currIteration < handles.SoundCal.maxInterations )
                AmpFactor = 10^(diff_dBSPL/20);
                handles.SoundCal.currAmplitude = handles.SoundCal.currAmplitude/AmpFactor;
                
                % If it cannot find the right level, set 1
                if (handles.SoundCal.currAmplitude > 1)
                    handles.SoundCal.currAmplitude = 1;
                end
            end
        end
        
        % Store values in results vector
        if strcmpi(handles.SoundCal.currSpeakerName, 'both')
            AttenuationVector(1, currRep) = handles.SoundCal.currAmplitude;
            AttenuationVector(2, currRep) = handles.SoundCal.currAmplitude;
        else
            AttenuationVector(speakerMatrixIdx, currRep) = handles.SoundCal.currAmplitude;
        end
        
        % Check if amplitude was not too high
        if (handles.SoundCal.currAmplitude == 1)
            msgbox('The sound recorded was not loud enough to calibrate. Please manually increase the speaker volume and restart.', ...
                'Sound pressure too low', 'error');
            
            % If this code is being executed on a Windows system, we should
            % close the DAQ session...
            if ispc
                delete(handles.DAQ.Session);
            end
            
            % Leave function
            return;
        end
    end
end

hold(handles.OutputAudioFile.axPressureSignal, 'off');

% Store calibration data in struct
tempDateString = datestr(now);
SoundCal.AudioFilename      = handles.InputAudioFile.Filename;
SoundCal.LastDateModified   = tempDateString;
SoundCal.audioSignal        = audioSignal;
SoundCal.SamplingRate       = handles.SoundCal.samplingFrequency_Hz;
SoundCal.TargetSPL          = handles.SoundCal.targetSPL;
SoundCal.Attenuation        = mean(AttenuationVector, 2);
SoundCal.SpeakerCalSettings = handles.SoundCal.speakerSelection; %#ok<STRNU>

% Save sound calibration file
save(fullfile(PathName, FileName), 'SoundCal');

% Let user know that calibration file was created
uiwait(msgbox({'The Sound Calibration file has been saved in: ', fullfile(PathName,FileName)},'Sound Calibration','modal'));

% If this code is being executed on a Windows system, we should close the DAQ
% session...
if ispc
    delete(handles.DAQ.Session);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton_Abort.
function pushbutton_Abort_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Abort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global abortCalibration;
abortCalibration = 1;



