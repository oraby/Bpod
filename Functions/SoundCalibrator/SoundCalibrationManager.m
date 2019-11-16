function varargout = SoundCalibrationManager(varargin)

% SOUNDCALIBRATIONMANAGER MATLAB code for SoundCalibrationManager.fig
%      SOUNDCALIBRATIONMANAGER, by itself, creates a new SOUNDCALIBRATIONMANAGER or raises the existing
%      singleton*.
%
%      H = SOUNDCALIBRATIONMANAGER returns the handle to a new SOUNDCALIBRATIONMANAGER or the handle to
%      the existing singleton*.
%
%      SOUNDCALIBRATIONMANAGER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SOUNDCALIBRATIONMANAGER.M with the given input arguments.
%
%      SOUNDCALIBRATIONMANAGER('Property','Value',...) creates a new SOUNDCALIBRATIONMANAGER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SoundCalibrationManager_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SoundCalibrationManager_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text_Amp_Condition to modify the response to help SoundCalibrationManager

% Last Modified by GUIDE v2.5 14-Nov-2019 12:16:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SoundCalibrationManager_OpeningFcn, ...
                   'gui_OutputFcn',  @SoundCalibrationManager_OutputFcn, ...
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


% --- Executes just before SoundCalibrationManager is made visible.
function SoundCalibrationManager_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SoundCalibrationManager (see VARARGIN)

% UIWAIT makes SoundCalibrationManager wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global BpodSystem %#ok<NUSED>

% Choose default command line output for SoundCalibrationManager
handles.output = hObject;

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
handles.SoundCal.numFreqs         = 0;
handles.SoundCal.scaling          = [];
handles.SoundCal.startFreq        = 0;
handles.SoundCal.stopFreq         = 0;
handles.SoundCal.bandwidth        = 0;

handles.SoundCal.currSpeakerName = 0;
handles.SoundCal.currFrequency   = 0;
handles.SoundCal.currAmplitude   = 0;

handles.SoundCal.toneDuration              = 1;      % Duration of playback
handles.SoundCal.timeToRecord              = 0.5;    % Duration of recording
handles.SoundCal.delayRecording            = 0.1;    % Amount of time after playback started to start recording
handles.SoundCal.samplingFrequncy          = 192000; % Sampling rate of sound card
handles.SoundCal.PSDWindowLength           = 2^16;   % Window length for PSD estimate
handles.SoundCal.initialAmplitude          = 0.2;    % Initial Amplitude 
handles.SoundCal.acceptableTolerance_dBSPL = 0.5;    % Max. tolerable difference
handles.SoundCal.maxInterations            = 15;     % Max. number of iterations per frequency
handles.SoundCal.pressureReference         = 20e-6;  % Pressure reference p0 in Pascal (Pa)

handles.filename = [];
handles.startedBefore = 0;

% Set values for speaker selection
handles.SoundCal.speakerSelectionStrings = {'Channel 1 (left)', 'Channel 2 (right)', 'Both - independent', 'Both - joined'};
set(handles.popupmenu_Speaker,'String', handles.SoundCal.speakerSelectionStrings );

% Create text label for physical unit of edit_TargetSPL (dB_SPL)
handles.dB_SPL_label= javaObjectEDT('javax.swing.JLabel','<HTML><font face="arial" size="4">dB<sub>SPL</sub></font></HTML>');
javacomponent(handles.dB_SPL_label,[477,595,40,16], gcf);

set(handles.ax_Attenuation, 'Visible', 'off');
set(handles.ax_Attenuation_dB, 'Visible', 'off');

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


% --- Outputs from this function are returned to the command line.
function varargout = SoundCalibrationManager_OutputFcn(hObject, eventdata, handles) 
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


function edit_Calibration_Points_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Calibration_Points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Number of calibration points must be a numeric value!', 'Wrong format', 'error');
elseif ( (temp <= 0) || (mod(temp, 1) ~= 0) )
    msgbox('Number of calibration must be a postive integer!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Calibration_Points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Calibration_Points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_Scaling.
function popupmenu_Scaling_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_Scaling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_Scaling contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_Scaling
nan;

% --- Executes during object creation, after setting all properties.
function popupmenu_Scaling_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_Scaling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Start_Frequency_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Start_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Start frequency must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Start frequency must be a postive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Start_Frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Start_Frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Stop_Freqeuncy_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Stop_Freqeuncy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Stop frequency must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Stop frequency must be a postive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Stop_Freqeuncy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Stop_Freqeuncy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_Bandwidth_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Bandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Bandwidth as text
%        str2double(get(hObject,'String')) returns contents of edit_Bandwidth as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Bandwidth must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Bandwidth must be a postive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_Bandwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Bandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_BandLimit_Min_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BandLimit_Min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Min. band limit coefficient must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Min. band limit coefficient must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_BandLimit_Min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BandLimit_Min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_BandLimit_Max_Callback(hObject, eventdata, handles)
% hObject    handle to edit_BandLimit_Max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Repetitions as text_Amp_Condition
%        str2double(get(hObject,'String')) returns contents of edit_Repetitions as a double

% Check value
temp = str2double(strtrim(get(hObject,'String')));
if (isnan(temp))
    msgbox('Max. band limit coefficient must be a numeric value!', 'Wrong format', 'error');
elseif (temp <= 0)
    msgbox('Max. band limit coefficient must be a positive numeric value!', 'Wrong format', 'error');
end

% --- Executes during object creation, after setting all properties.
function edit_BandLimit_Max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_BandLimit_Max (see GCBO)
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

global BpodSystem
BpodSystem.PluginObjects.SoundCal = struct;
BpodSystem.PluginObjects.SoundCal.Abort = 0;

% Create a colormap
colors = colormap;

% Get calibration parameters
% --------------------------------------------------------------------------
handles.DAQ.SamplingRate      = str2double(get(handles.edit_DAQ_Sample_Rate, 'String'));
handles.DAQ.Range             = str2double(get(handles.edit_DAQ_Range, 'String'));
handles.SoundCal.ampCondition = str2double(get(handles.edit_Amplifier_Condition, 'String'));
handles.SoundCal.targetSPL    = str2double(get(handles.edit_TargetSPL, 'String'));
handles.SoundCal.numRepeats   = str2double(get(handles.edit_Repetitions, 'String'));
handles.SoundCal.numFreqs     = str2double(get(handles.edit_Calibration_Points, 'String'));
handles.SoundCal.startFreq    = str2double(get(handles.edit_Start_Frequency, 'String'));
handles.SoundCal.stopFreq     = str2double(get(handles.edit_Stop_Freqeuncy, 'String'));
handles.SoundCal.bandwidth    = str2double(get(handles.edit_Bandwidth, 'String'));
% --------------------------------------------------------------------------
% Check input values - Start
% --------------------------------------------------------------------------
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

if (isnan(handles.SoundCal.numFreqs))
    msgbox('Number of calibration points must be a numeric value!', 'Wrong format', 'error');
    return;
elseif ( (handles.SoundCal.numFreqs <= 0) || (mod(handles.SoundCal.numFreqs, 1) ~= 0) )
    msgbox('Number of calibration must be a postive integer!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.startFreq))
    msgbox('Start frequency must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.startFreq <= 0)
    msgbox('Start frequency must be a postive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.stopFreq))
    msgbox('Stop frequency must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.stopFreq <= 0)
    msgbox('Stop frequency must be a postive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.SoundCal.bandwidth))
    msgbox('Bandwidth must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.SoundCal.bandwidth <= 0)
    msgbox('Bandwidth must be a positive numeric value!', 'Wrong format', 'error');
    return;
end

if (isnan(handles.DAQ.SamplingRate))
    msgbox('DAQ sampling rate must be a numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.DAQ.SamplingRate <= 0)
    msgbox('DAQ sampling rate must be a positive numeric value!', 'Wrong format', 'error');
    return;
elseif (handles.DAQ.SamplingRate > 200)
    msgbox('DAQ sampling rates greater than 200 kHz are not supported!', 'Unsupported value', 'error');
    return;
elseif ( (handles.DAQ.SamplingRate*1000) < (2 * handles.SoundCal.stopFreq) )
    msgbox('DAQ sampling rate must be greater than at least 2 * stop frequency!', 'Unsupported value', 'error');
    return;
end

% Convert Sampling Rate from kHz to Hz
handles.DAQ.SamplingRate = 1000 * handles.DAQ.SamplingRate;

% Get value from sepeaker selection
handles.SoundCal.speakerSelection = handles.SoundCal.speakerSelectionStrings{get(handles.popupmenu_Speaker,'Value')};
% --------------------------------------------------------------------------
% Check input values - End
% --------------------------------------------------------------------------

% Specify calibration file
% ------------------------
OutputFileName = 'SoundCalibration';
[FileName, PathName] = uiputfile('.mat', 'Save Sound Calibration File', OutputFileName);
% Check if user clicked on cancel button
if ( (isnumeric(FileName) & (FileName == 0)) | (isnumeric(PathName) & (PathName == 0)) ) %#ok<OR2,AND2>
    disp('Canceled by user');
    return;
end
% Set full filename into handles structure
handles.filename = fullfile(PathName, FileName);

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

% Reset attenuation plot
% ----------------------
set(handles.ax_Attenuation, 'Visible', 'on');
cla(handles.ax_Attenuation);
hold(handles.ax_Attenuation, 'on');
grid(handles.ax_Attenuation, 'on');
title(handles.ax_Attenuation, 'Attenuation Factor');
ylabel(handles.ax_Attenuation, 'Attenuation Factor');
xlabel(handles.ax_Attenuation, 'Frequency (kHz)')
axis(handles.ax_Attenuation, [handles.SoundCal.startFreq/1000 handles.SoundCal.stopFreq/1000 0 1])

% Reset attenuation dB_SPL plot
% -----------------------------
set(handles.ax_Attenuation_dB, 'Visible', 'on');
cla(handles.ax_Attenuation_dB);
hold(handles.ax_Attenuation_dB, 'on');
grid(handles.ax_Attenuation_dB, 'on');
title(handles.ax_Attenuation_dB, 'Sound Pressure Level');
ylabel(handles.ax_Attenuation_dB, 'Sound Pressure (dB_{SPL})')
xlabel(handles.ax_Attenuation_dB, 'Frequency (kHz)')
axis(handles.ax_Attenuation_dB, [handles.SoundCal.startFreq/1000 handles.SoundCal.stopFreq/1000 0 120])
set(handles.ax_Attenuation_dB, 'XScale', 'log')
legend(handles.ax_Attenuation_dB, 'off')

% Create frequency vector
% -----------------------
% Get value for scaling
tempContents = cellstr(get(handles.popupmenu_Scaling, 'String'));
handles.SoundCal.scaling = tempContents{get(handles.popupmenu_Scaling, 'Value')};
clear tempContents

if strcmp(strtrim(handles.SoundCal.scaling), 'linear')
    frequencies = linspace(handles.SoundCal.startFreq, ...
                           handles.SoundCal.stopFreq, ...
                           handles.SoundCal.numFreqs);
    
elseif strcmp(strtrim(handles.SoundCal.scaling), 'logarithmic')
    frequencies = logspace(log10(handles.SoundCal.startFreq), ...
                           log10(handles.SoundCal.stopFreq), ...
                           handles.SoundCal.numFreqs);
    
else
    tempMsg = sprintf('Unsupported value ''%s'' for frequency scaling', handles.SoundCal.scaling);
    msgbox(tempMsg, 'Unsupported value', 'error');
    clear tempMsg;
    return;
    
end

% Define a struct for passing values to other methods
SoundCal = struct;

% (Re-)Initialize PsychToolbox PortAudio
PsychToolboxSoundServer('init')

% Setup daq device in case this code is being executed on a Windows system
if ispc
    % Create DAQ session
    handles.DAQ.Session = daq.createSession(handles.DAQ.VendorID);
    
    % Set DAQ sampling rate
    handles.DAQ.Session.Rate = handles.DAQ.SamplingRate;
    
    % Set DAQ recording duration
    handles.DAQ.Session.DurationInSeconds = handles.SoundCal.timeToRecord;
    
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
    
    % For compatibility reasons, we have to keep this value. 
    % This value will initialize the size of the resulting atenuation vector
    % etc. If the have just one column, it will be interpreted as just
    % calibrated for channel 1 (left). If the results will have two columns, it
    % will be interpreted as both channels were calibrated... Why not defining
    % another value on how to interprete the data!?!
    handles.SoundCal.numSpeakers = 1;
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Channel 2 (right)')
    speakerCount = 1;
    handles.SoundCal.currSpeakerName = 'right';
    
    % For compatibility reasons, we have to keep this value. 
    % This value will initialize the size of the resulting atenuation vector
    % etc. If the have just one column, it will be interpreted as just
    % calibrated for channel 1 (left). If the results will have two columns, it
    % will be interpreted as both channels were calibrated... Why not defining
    % another value on how to interprete the data!?!
    handles.SoundCal.numSpeakers = 2;
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Both - independent')
    speakerCount = 2;
    
    % For compatibility reasons, we have to keep this value. 
    % This value will initialize the size of the resulting atenuation vector
    % etc. If the have just one column, it will be interpreted as just
    % calibrated for channel 1 (left). If the results will have two columns, it
    % will be interpreted as both channels were calibrated... Why not defining
    % another value on how to interprete the data!?!
    handles.SoundCal.numSpeakers = 2;
    
elseif strcmpi(handles.SoundCal.speakerSelection, 'Both - joined')
    speakerCount = 1;
    handles.SoundCal.currSpeakerName = 'both';
    
    % For compatibility reasons, we have to keep this value. 
    % This value will initialize the size of the resulting atenuation vector
    % etc. If the have just one column, it will be interpreted as just
    % calibrated for channel 1 (left). If the results will have two columns, it
    % will be interpreted as both channels were calibrated... Why not defining
    % another value on how to interprete the data!?!
    handles.SoundCal.numSpeakers = 2;
    
else
    errorStr = sprintf('Unknown speaker selection: %s!', handles.SoundCal.speakerSelection);
    msgbox(errorStr, 'Uknown speaker selection', 'error');
    return;
end

% Create string array for legend dB plot
legendString_dB = cell(1, speakerCount);

% Initialize the attenuation vector for the results
AttenuationVector = zeros(handles.SoundCal.numFreqs,...
                          handles.SoundCal.numSpeakers,...
                          handles.SoundCal.numRepeats);
                      
PowerVector = zeros(handles.SoundCal.numFreqs,...
                    handles.SoundCal.numSpeakers,...
                    handles.SoundCal.numRepeats);
                
InitialPowerVector = zeros(handles.SoundCal.numFreqs,...
                           handles.SoundCal.numSpeakers,...
                           handles.SoundCal.numRepeats);


% Loop through selected speakers
for currSpeaker=1:speakerCount
    % Set symbols for speaker for plotting attenuation
    
    if ( (speakerCount == 2) && (currSpeaker == 1) )
        handles.SoundCal.currSpeakerName = 'left';
    elseif ( (speakerCount == 2) && (currSpeaker == 2) )
        handles.SoundCal.currSpeakerName = 'right';
    end
    
    switch handles.SoundCal.currSpeakerName
        case 'left'
            speakerSymbol = 'o';
            channelName = 'channel 1 (left)';
            speakerMatrixIdx = 1;
            plotIdx = speakerMatrixIdx;
        case 'right'
            speakerSymbol = 'x';
            channelName = 'channel 2 (right)';
            speakerMatrixIdx = 2;
            plotIdx = speakerMatrixIdx;
        case 'both'
            speakerSymbol = 's';
            channelName = 'both channels (left & right) combined';
            plotIdx = 1;
    end
    
    % Let user know to place the microphone
    uiwait(msgbox({['Calibrating ' channelName '.'], 'Position microphone and press OK to continue...'}, 'Sound Calibration', 'modal'));
    
    for currRep=1:handles.SoundCal.numRepeats
        
        if currRep>1
            uiwait(msgbox('Reposition microphone for next repetition and press OK', 'Sound Calibration', 'modal'));
        end
        
        % Loop through frequencies
        for freqCntr=1:handles.SoundCal.numFreqs           
            % Get current frequency
            handles.SoundCal.currFrequency = frequencies(freqCntr);
            
            % Set the amplitude for first iteration
            handles.SoundCal.currAmplitude = handles.SoundCal.initialAmplitude;
            
            % Set dB level to 0 dB_SPL
            bandPower_dBSPL = 0;
            
            % Estimate attenuation
            for currIteration = 1:1:handles.SoundCal.maxInterations
                if BpodSystem.PluginObjects.SoundCal.Abort
                    % User aborted calibration
                    
                    % Delete handle to DAQ session
                    delete(handles.DAQ.Session);
                    
                    % Output a warning...
                    tempMsg = ('Calibration manually aborted.');
                    msgbox(tempMsg, 'Calibration aborted', 'warn');
                    
                    return;
                end
                
                % Calculate dB_SPL for given amplitude
                bandPower_dBSPL = ResponsePureTone(handles);
                
                if (currIteration == 1)
                    if strcmpi(handles.SoundCal.currSpeakerName, 'both')
                        InitialPowerVector(freqCntr, 1, currRep) = bandPower_dBSPL;
                        InitialPowerVector(freqCntr, 2, currRep) = bandPower_dBSPL;
                    else
                        InitialPowerVector(freqCntr, speakerMatrixIdx, currRep) = bandPower_dBSPL;
                    end
                end
                
                % Update text fields
                set(handles.text_ResultsFreqValue,  'String', num2str(handles.SoundCal.currFrequency));
                set(handles.text_ResultsAttnValue,  'String', num2str(handles.SoundCal.currAmplitude));
                set(handles.text_ResultsPowerValue, 'String', num2str(bandPower_dBSPL));
                
                % Calculate difference between current output and target output
                diff_dBSPL = bandPower_dBSPL - handles.SoundCal.targetSPL;
                
                if ( abs(diff_dBSPL) < handles.SoundCal.acceptableTolerance_dBSPL )
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
                AttenuationVector(freqCntr, 1, currRep) = handles.SoundCal.currAmplitude;
                AttenuationVector(freqCntr, 2, currRep) = handles.SoundCal.currAmplitude;
                PowerVector(freqCntr, 1, currRep) = bandPower_dBSPL;
                PowerVector(freqCntr, 2, currRep) = bandPower_dBSPL;
            else
                AttenuationVector(freqCntr, speakerMatrixIdx, currRep) = handles.SoundCal.currAmplitude;
                PowerVector(freqCntr, speakerMatrixIdx, currRep) = bandPower_dBSPL;
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
                
                return;
            end
            
            % Plot attenuation value
            semilogx(handles.ax_Attenuation, ...
                     frequencies(1:freqCntr)/1000, ...
                     AttenuationVector(1:freqCntr, plotIdx, currRep), ...
                     [speakerSymbol '-'], ...
                     'Color', colors(floor(64/handles.SoundCal.numSpeakers/handles.SoundCal.numRepeats)*(currRep-1)+floor(64/handles.SoundCal.numSpeakers)*(plotIdx-1)+1,:));
            New_XTickLabel = get(handles.ax_Attenuation, 'xtick');
            set(handles.ax_Attenuation, 'XTickLabel', New_XTickLabel);
        end
    end
    
    % Plot the values for the attenuations...
    semilogx(handles.ax_Attenuation, ...
             frequencies/1000, ...
             mean(AttenuationVector(:,plotIdx,:),3), ...
             '-', 'Color', ...
             colors(floor(64/handles.SoundCal.numSpeakers)*(plotIdx-1)+1,:), ...
             'linewidth',1.5);
    drawnow;
    
    % Set the color values for the dB values
    if strcmpi(handles.SoundCal.currSpeakerName, 'left')
        dB_color = 'k';
        legendString_dB{1,1} = 'Speaker 1 initial SPL';
        legendString_dB{1,2} = 'Speaker 1 calibrated SPL';
        speakerSymbol = 'o';
        
    elseif strcmpi(handles.SoundCal.currSpeakerName, 'right')
        dB_color = 'r';
        if (speakerCount == 1)
            legendString_dB{1,1} = 'Speaker 2 initial SPL';
            legendString_dB{1,2} = 'Speaker 2 calibrated SPL';
        elseif (speakerCount == 2)
            legendString_dB{1,3} = 'Speaker 2 initial SPL';
            legendString_dB{1,4} = 'Speaker 2 calibrated SPL';
        end
        speakerSymbol = 'x';
        
    elseif strcmpi(handles.SoundCal.currSpeakerName, 'both')
        dB_color = 'g';
        legendString_dB{1,1} = 'Combined speakers initial SPL';
        legendString_dB{1,2} = 'Combined speakers calibrated SPL';
        speakerSymbol = 's';
    end
    
    semilogx(handles.ax_Attenuation_dB, ...
             frequencies/1000, ...
             mean(InitialPowerVector(:, plotIdx, :),3), ...
             '-', 'Color', dB_color, 'linewidth',1);
    
    semilogx(handles.ax_Attenuation_dB, ...
             frequencies/1000, ...
             mean(PowerVector(:, plotIdx, :),3), ...
             speakerSymbol, 'Color', dB_color, 'linewidth',1);
    drawnow;
    
    %axis(handles.ax_Attenuation_dB, [handles.SoundCal.startFreq/1000 handles.SoundCal.stopFreq/1000 0 120])
    
    
    legend(handles.ax_Attenuation_dB, legendString_dB);
    legend(handles.ax_Attenuation_dB, 'Location', 'southeast')
    
    % Store calibration data in struct
    tempDateString = datestr(now);
    
    if ~strcmpi(handles.SoundCal.currSpeakerName, 'both')
        SoundCal(1,speakerMatrixIdx).Table                  = [frequencies' mean(AttenuationVector(:,speakerMatrixIdx,:),3)];
        SoundCal(1,speakerMatrixIdx).CalibrationTargetRange = [handles.SoundCal.startFreq handles.SoundCal.stopFreq];
        SoundCal(1,speakerMatrixIdx).TargetSPL              = handles.SoundCal.targetSPL;
        SoundCal(1,speakerMatrixIdx).LastDateModified       = tempDateString;
        %SoundCal(1,speakerMatrixIdx).Coefficient            = polyfit(frequencies',mean(AttenuationVector(:,speakerMatrixIdx,:),3),1);
        SoundCal(1,speakerMatrixIdx).Coefficient            = pchip(frequencies',mean(AttenuationVector(:,speakerMatrixIdx,:),3));
        SoundCal(1,speakerMatrixIdx).InitialRespose         = [frequencies' mean(InitialPowerVector(:, speakerMatrixIdx, :),3)];
        SoundCal(1,speakerMatrixIdx).CalibratedRespose      = [frequencies' mean(PowerVector(:, speakerMatrixIdx, :),3)];
        SoundCal(1,speakerMatrixIdx).FitMethod              = 'pchip';
        SoundCal(1,speakerMatrixIdx).SpeakerCalSettings     = handles.SoundCal.speakerSelection;
    else
        % Values for left speaker in case of joined calibration
        SoundCal(1,1).Table                  = [frequencies' mean(AttenuationVector(:,1,:),3)];
        SoundCal(1,1).CalibrationTargetRange = [handles.SoundCal.startFreq handles.SoundCal.stopFreq];
        SoundCal(1,1).TargetSPL              = handles.SoundCal.targetSPL;
        SoundCal(1,1).LastDateModified       = tempDateString;
        %SoundCal(1,1).Coefficient            = polyfit(frequencies',mean(AttenuationVector(:,1,:),3),1);
        SoundCal(1,1).Coefficient            = pchip(frequencies',mean(AttenuationVector(:,1,:),3));
        SoundCal(1,1).InitialRespose         = [frequencies' mean(InitialPowerVector(:, 1, :),3)];
        SoundCal(1,1).CalibratedRespose      = [frequencies' mean(PowerVector(:, 1, :),3)];
        SoundCal(1,1).FitMethod              = 'pchip';
        SoundCal(1,1).SpeakerCalSettings     = handles.SoundCal.speakerSelection;
        
        % Values for right speaker in case of joined calibration
        SoundCal(1,2).Table                  = [frequencies' mean(AttenuationVector(:,2,:),3)];
        SoundCal(1,2).CalibrationTargetRange = [handles.SoundCal.startFreq handles.SoundCal.stopFreq];
        SoundCal(1,2).TargetSPL              = handles.SoundCal.targetSPL;
        SoundCal(1,2).LastDateModified       = tempDateString;
        %SoundCal(1,2).Coefficient            = polyfit(frequencies',mean(AttenuationVector(:,2,:),3),1);
        SoundCal(1,2).Coefficient            = pchip(frequencies',mean(AttenuationVector(:,2,:),3));
        SoundCal(1,2).InitialRespose         = [frequencies' mean(InitialPowerVector(:, 2, :),3)];
        SoundCal(1,2).CalibratedRespose      = [frequencies' mean(PowerVector(:, 2, :),3)];
        SoundCal(1,2).FitMethod              = 'pchip';
        SoundCal(1,2).SpeakerCalSettings     = handles.SoundCal.speakerSelection;
    end
        
    
end

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

global BpodSystem
BpodSystem.PluginObjects.SoundCal.Abort = 1;


% --- Executes on button press in pushbutton_Test.
function pushbutton_Test_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_Test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TestSoundManager(handles.filename)
