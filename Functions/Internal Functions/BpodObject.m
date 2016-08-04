classdef BpodObject < handle
    %STATEMACHINEOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        StateMatrix
        Birthdate
        LastTimestamp
        CurrentStateCode
        LastStateCode
        CurrentStateName
        LastStateName
        LastEvent
        LastTrialData
        SessionData
        LastHardwareState
        HardwareState
        BNCOverrideState
        GUIHandles
        GUIData
        Graphics
        EventNames
        OutputActionNames
        BeingUsed
        InStateMatrix
        Live
        CurrentProtocolName
        SerialPort
        Stimuli
        FirmwareBuild
        SplashData
        ProtocolSettings
        Data
        BpodPath
        BpodUserPath % FS MOD
        SettingsPath
        DataPath
        ProtocolPath
        InputConfigPath
        InputsEnabled
        PluginSerialPorts
        PluginFigureHandles
        PluginObjects
        UsesPsychToolbox
        SystemSettings
        SoftCodeHandlerFunction
        ProtocolFigures
        Emulator % A struct with the internal variables of the emulator (mirror of state machine workspace in Arduino)
        EmulatorMode % 0 if actual device, 1 if emulator
        ManualOverrideFlag % Used in the emulator to indicate an override that needs to be handled
        VirtualManualOverrideBytes % Stores emulated event bytes generated by override
        CalibrationTables % Struct for liquid, sound, etc.
        BlankStateMatrix % Holds a blank state matrix for fast initialization of a new state matrix.
        Pause % Holds 1 if the system is paused and 0 if not.
        HostOS % Holds a string naming the host operating system (i.e. 'Microsoft Windows XP')
        ProtocolStartTime % The time when the current protocol was started.
        BonsaiSocket % An object containing a TCP/IP socket for communication with Bonsai
    end
    
    methods
        function obj = BpodObject(BpodPath) %Constructor
            load SplashBGData;
            load SplashMessageData;
            obj.SplashData.BG = SplashBGData;
            obj.SplashData.Messages = SplashMessageData;
            obj.GUIHandles.SplashFig = figure('Position',[400 300 485 300],'name','Bpod','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
            obj.LastTimestamp = 0;
            obj.InStateMatrix = 0;
            obj.BonsaiSocket.Connected = 0;
            obj.BeingUsed = 0;
            obj.Live = 0;
            obj.Pause = 0;
            obj.HardwareState.Valves = zeros(1,8);
            obj.HardwareState.PWMLines = zeros(1,8);
            obj.HardwareState.PortSensors = zeros(1,8);
            obj.HardwareState.BNCInputs = zeros(1,2);
            obj.HardwareState.BNCOutputs = zeros(1,2);
            obj.HardwareState.WireInputs = zeros(1,4);
            obj.HardwareState.WireOutputs = zeros(1,4);
            obj.HardwareState.Serial1Code = 0;
            obj.HardwareState.Serial2Code = 0;
            obj.HardwareState.SoftCode = 0;
            obj.LastHardwareState = obj.HardwareState;
            obj.BNCOverrideState = zeros(1,4);
            obj.EventNames = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out', 'Port4In', 'Port4Out', 'Port5In', 'Port5Out', ...
                'Port6In', 'Port6Out', 'Port7In', 'Port7Out', 'Port8In', 'Port8Out', 'BNC1High', 'BNC1Low', 'BNC2High', 'BNC2Low', ...
                'Wire1High', 'Wire1Low', 'Wire2High', 'Wire2Low', 'Wire3High', 'Wire3Low', 'Wire4High', 'Wire4Low', ...
                'SoftCode1', 'SoftCode2', 'SoftCode3', 'SoftCode4', 'SoftCode5', 'SoftCode6', 'SoftCode7', 'SoftCode8', 'SoftCode9', 'SoftCode10', ...
                'Unused', 'Tup', 'GlobalTimer1_End', 'GlobalTimer2_End', 'GlobalTimer3_End', 'GlobalTimer4_End', 'GlobalTimer5_End', ...
                'GlobalCounter1_End', 'GlobalCounter2_End', 'GlobalCounter3_End', 'GlobalCounter4_End', 'GlobalCounter5_End'};
            obj.OutputActionNames = {'ValveState', 'BNCState', 'WireState', 'Serial1Code', 'Serial2Code', 'SoftCode', ...
                'GlobalTimerTrig', 'GlobalTimerCancel', 'GlobalCounterReset', 'PWM1', 'PWM2', 'PWM3', 'PWM4', 'PWM5', 'PWM6', 'PWM7', 'PWM8'};
            obj.Birthdate = now;
            obj.CurrentProtocolName = '';
            if exist('objSettings.mat') > 0
                load objSettings;
                obj.SystemSettings = objSettings;
            else
                obj.SystemSettings = struct;
            end
            % Generate blank state matrix
            sma.nStates = 0;
            sma.nStatesInManifest = 0;
            sma.Manifest = cell(1,127); % State names in the order they were added by user
            sma.StateNames = {'Placeholder'}; % State names in the order they were referenced
            sma.InputMatrix = ones(1,40);
            sma.OutputMatrix = zeros(1,17);
            sma.GlobalTimerMatrix = ones(1,5);
            sma.GlobalTimers = zeros(1,5);
            sma.GlobalTimerSet = zeros(1,5); % Changed to 1 when the timer is given a duration with SetGlobalTimer
            sma.GlobalCounterMatrix = ones(1,5);
            sma.GlobalCounterEvents = ones(1,5)*255; % Default event of 255 is code for "no event attached".
            sma.GlobalCounterThresholds = zeros(1,5);
            sma.GlobalCounterSet = zeros(1,5); % Changed to 1 when the counter event is identified and given a threshold with SetGlobalCounter
            sma.StateTimers = 0;
            sma.StatesDefined = 1; % Referenced states are set to 0. Defined states are set to 1. Both occur with AddState
            obj.BlankStateMatrix = sma;
            
            obj.HostOS = system_dependent('getos');
            obj.BpodPath = BpodPath;
%% FS MOD
            if ispc 
                import java.lang.*;
                S.BpodUserPath = fullfile(char(System.getProperty('user.home')), 'BpodUser');
                if ~isdir(S.BpodUserPath)
                    mkdir(S.BpodUserPath);
                    disp('*** Bpod User Directories Not Found, Creating them ***');
                end
            elseif ~isdir(fullfile('~', 'BpodUser')) % tilde works on UNIX and MAC platforms to specify user home directory
                mkdir(fullfile('~', 'BpodUser'));
                disp('*** Bpod User Directories Not Found, Creating them ***');                
            end
            obj.BpodUserPath = S.BpodUserPath;
            %%
            dir_calfiles = dir(fullfile(obj.BpodUserPath,'Calibration Files') ); % FS MOD
            if length(dir_calfiles) == 0, %then Cal Folder didn't exist.
                mkdir(fullfile(obj.BpodUserPath,'Calibration Files')); % FS MOD
                obj.CalibrationTables.LiquidCal = [];
                obj.CalibrationTables.SoundCal = [];
            else
                % Liquid
                try
                    LiquidCalibrationFilePath = fullfile(obj.BpodUserPath, 'Calibration Files', 'LiquidCalibration.mat'); % FS MOD
                    load(LiquidCalibrationFilePath);
                    obj.CalibrationTables.LiquidCal = LiquidCal;
                catch
                  obj.CalibrationTables.LiquidCal = [];  
                end
                % Sound
                try
                    SoundCalibrationFilePath = fullfile(obj.BpodUserPath, 'Calibration Files', 'SoundCalibration.mat'); % FS MOD
                    load(SoundCalibrationFilePath);
                    obj.CalibrationTables.SoundCal = SoundCal;
                catch
                  obj.CalibrationTables.SoundCal = [];  
                end
            end
            % Load input channel settings
            obj.InputConfigPath = fullfile(obj.BpodUserPath, 'Settings Files', 'BpodInputConfig.mat'); % FS MOD
            try
                load(obj.InputConfigPath);
            catch
                mkdir(fullfile(obj.BpodUserPath,'Settings Files')); % FS MOD                
                copyfile(fullfile(obj.BpodPath, 'Settings Files', 'BpodInputConfig.mat'), fullfile(obj.BpodUserPath, 'Settings Files'));
                load(obj.InputConfigPath);                
            end
            obj.InputsEnabled = BpodInputConfig;

            % Determine if PsychToolbox is installed. If so, serial communication
            % will proceed through lower latency psychtoolbox IOport serial interface (compiled for each platform).
            % Otherwise, Bpod defaults to MATLAB's Java based serial interface.
            try
                V = PsychtoolboxVersion;
                obj.UsesPsychToolbox = 1;
            catch
                obj.UsesPsychToolbox = 0;
            end
            %Check for Data folder
            dir_data = dir(fullfile(obj.BpodUserPath,'Data')); % FS MOD
            if length(dir_data) == 0, %then Data didn't exist.
                mkdir(fullfile(obj.BpodUserPath, 'Data'));
            end
        end
        function obj = InitializeHardware(obj, portString)
            BaudRate = 115200;
            if ~isempty(obj.SerialPort)
                switch obj.UsesPsychToolbox
                    case 0
                        fclose(obj.SerialPort);
                        delete(obj.SerialPort);
                    case 1
                end
                obj.SerialPort = [];
            end

            if ~ispc && ~ismac
                % Ensure access to serial ports under ubuntu
                if exist(['/usr/local/MATLAB/R' version('-release') '/bin/glnxa64/java.opts']) ~= 2
                    disp(' ');
                    disp('**ALERT**')
                    disp('Linux64 detected. A file must be copied to the MATLAB root, to gain access to virtual serial ports.')
                    disp('This file only needs to be copied once.')
                    input('Bpod will try to copy this file from the repository automatically. Press return... ')
                    try
                        system(['sudo cp ''' BpodPath 'Bpod System Files/Internal Functions/java.opts'' /usr/local/MATLAB/R' version('-release') '/bin/glnxa64']);
                        disp(' ');
                        disp('**SUCCESS**')
                        disp('File copied! Please restart MATLAB and run Bpod again.')
                        return
                    catch
                        disp('File copy error! MATLAB may not have administrative privileges.')
                        disp('Please copy /PulsePal/MATLAB/java.opts to the MATLAB java library path.')
                        disp('The path is typically /usr/local/MATLAB/R2014a/bin/glnxa64, where r2014a is your MATLAB release.')
                        return
                    end
                end
            end

            if ~strcmp(portString, 'AUTO')
                Ports = cell(1,1);
                Ports{1} = portString;
            else
                Ports = FindArduinoPorts;
                if isempty(Ports)
                    error('Unable to auto-detect the Bpod serial port. Please call Bpod with a serial port argument (e.g. ''COM3''.') 
                end

                % Make it search on the last successful port first
                if isfield(obj.SystemSettings, 'LastCOMPort')
                    LastCOMPort = obj.SystemSettings.LastCOMPort;
                    pos = strmatch(LastCOMPort, Ports, 'exact');
                    if ~isempty(pos)
                        Temp = Ports;
                        Ports{1} = LastCOMPort;
                        Ports(2:length(Temp)) = Temp(find(1:length(Temp) ~= pos));
                    end
                end
            end
            Found = 0;
            x = 0;
            switch obj.UsesPsychToolbox
                case 0 % Java serial interface (MATLAB default)
                    disp('Connecting with MATLAB/Java serial interface (high latency).')
                    while (Found == 0) && (x < length(Ports)) && ~isempty(Ports{1})
                        x = x + 1;
                        disp(['Trying port ' Ports{x}])
                        TestPort = serial(Ports{x}, 'BaudRate', BaudRate, 'Timeout', 1, 'DataTerminalReady', 'on');
                        fopen(TestPort);
                        set(TestPort, 'RequestToSend', 'on');
                        if ~strcmp(system_dependent('getos'), 'Microsoft Windows Vista')
                            pause(1);
                        end
                        fprintf(TestPort, char(54));
                        tic
                        g = 0;
                        try
                            g = fread(TestPort, 1);
                        catch
                            % ok
                        end
                        if g == '5'
                            Found = x;
                            fclose(TestPort);
                            delete(TestPort)
                            clear TestSer
                            clc
                        end
                    end
                    pause(.1);
                    if Found ~= 0
                        obj.SerialPort = serial(Ports{Found}, 'BaudRate', BaudRate, 'Timeout', 1, 'DataTerminalReady', 'on');
                    else
                        %error('Could not find a Bpod device.');
                    end
                    set(obj.SerialPort, 'OutputBufferSize', 8000);
                    set(obj.SerialPort, 'InputBufferSize', 8000);
                    fopen(obj.SerialPort);
                    set(obj.SerialPort, 'RequestToSend', 'on');
                    fwrite(obj.SerialPort, char(54));
                    tic
                    while obj.SerialPort.BytesAvailable == 0
                        if toc > 1
                            break
                        end
                    end
                    fread(obj.SerialPort, obj.SerialPort.BytesAvailable);
                    set(obj.SerialPort, 'RequestToSend', 'off')
                case 1 % Psych toolbox serial interface
                    disp('Connecting with PsychToolbox serial interface (low latency).')
                    oldlevel = IOPort('Verbosity', 0);
                     while (Found == 0) && (x < length(Ports)) && ~isempty(Ports{1})
                        x = x + 1;
                        disp(['Trying port ' Ports{x}])
                        try
                            if ispc
                                PortString = ['\\.\' Ports{x}];
                            else
                                PortString = Ports{x};
                            end
                            TestPort = IOPort('OpenSerialPort', PortString, 'BaudRate=115200, OutputBufferSize=8000, DTR=1');
                            pause(.5);
                            IOPort('Write', TestPort, char(54), 0);
                            pause(.1);
                            Byte = IOPort('Read', TestPort, 1, 1);
                            if Byte == 53
                                Found = x;
                            end
                            IOPort('Close', TestPort);

                        catch
                        end
                     end
                     if Found ~= 0
                         if ispc
                             PortString = ['\\.\' Ports{Found}];
                         else
                             PortString = Ports{Found};
                         end
                         obj.SerialPort = IOPort('OpenSerialPort', PortString, 'BaudRate=115200, OutputBufferSize=8000, DTR=1');
                     else
                         error('No valid Bpod serial port detected.')
                     end
                     BpodSerialWrite(char(54), 'uint8');
                     tic
                     while BpodSerialBytesAvailable == 0
                         if toc > 1
                             break
                         end
                     end
                     BpodSerialRead(BpodSerialBytesAvailable, 'uint8');
            end


            disp(['Bpod connected on port ' Ports{Found}])
            obj.SystemSettings.LastCOMPort = Ports{Found};
            SaveBpodSystemSettings;
            if BpodSerialBytesAvailable > 0
                BpodSerialRead(BpodSerialBytesAvailable, 'uint8');
            end
            BpodSerialWrite('F', 'uint8');
            obj.EmulatorMode = 0;
            obj.FirmwareBuild = BpodSerialRead(1, 'uint8');
        end
        function obj = InitializeGUI(obj)
            obj.GUIHandles.MainFig = figure('Position',[80 100 800 400],'name','B-Pod v0.5 beta','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'CloseRequestFcn', 'EndBpod');
            obj.Graphics.GoButton = imread('PlayButton.bmp');
            obj.Graphics.PauseButton = imread('PauseButton.bmp');
            obj.Graphics.PauseRequestedButton = imread('PauseRequestedButton.bmp');
            obj.Graphics.StopButton = imread('StopButton.bmp');
            obj.GUIHandles.RunButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [718 130 60 60], 'Callback', 'RunProtocol(''StartPause'')', 'CData', obj.Graphics.GoButton, 'TooltipString', 'Run selected protocol');
            obj.GUIHandles.EndButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [718 50 60 60], 'Callback', 'RunProtocol(''Stop'')', 'CData', obj.Graphics.StopButton, 'TooltipString', 'End session');


            obj.Graphics.OffButton = imread('ButtonOff.bmp');
            obj.Graphics.OffButtonDark = imread('ButtonOff_dark.bmp');
            obj.Graphics.OnButton = imread('ButtonOn.bmp');
            obj.Graphics.SoftTriggerButton = imread('BpodSoftTrigger.bmp');
            obj.Graphics.SoftTriggerActiveButton = imread('BpodSoftTrigger_active.bmp');
            obj.Graphics.SettingsButton = imread('SettingsButton.bmp');
            obj.Graphics.DocButton = imread('DocButton.bmp');
            obj.Graphics.AddProtocolButton = imread('AddProtocolIcon.bmp');
            obj.GUIHandles.SettingsButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [742 285 29 29], 'Callback', 'BpodSettingsMenu', 'CData', obj.Graphics.SettingsButton, 'TooltipString', 'Settings and calibration');
            obj.GUIHandles.DocButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [695 285 29 29], 'Callback', 'BpodWiki', 'CData', obj.Graphics.DocButton, 'TooltipString', 'Documentation wiki');

            obj.GUIHandles.PortValveButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [188 260 30 30], 'Callback', 'ManualOverride(1,1);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 1 valve');
            obj.GUIHandles.PortValveButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [231 260 30 30], 'Callback', 'ManualOverride(1,2);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 2 valve');
            obj.GUIHandles.PortValveButton(3) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [272 260 30 30], 'Callback', 'ManualOverride(1,3);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 3 valve');
            obj.GUIHandles.PortValveButton(4) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [313 260 30 30], 'Callback', 'ManualOverride(1,4);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 4 valve');
            obj.GUIHandles.PortValveButton(5) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [354 260 30 30], 'Callback', 'ManualOverride(1,5);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 5 valve');
            obj.GUIHandles.PortValveButton(6) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [395 260 30 30], 'Callback', 'ManualOverride(1,6);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 6 valve');
            obj.GUIHandles.PortValveButton(7) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [436 260 30 30], 'Callback', 'ManualOverride(1,7);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 7 valve');
            obj.GUIHandles.PortValveButton(8) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [477 260 30 30], 'Callback', 'ManualOverride(1,8);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 8 valve');

            obj.GUIHandles.PortLEDButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [188 220 30 30], 'Callback', 'ManualOverride(2,1);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 1 LED');
            obj.GUIHandles.PortLEDButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [231 220 30 30], 'Callback', 'ManualOverride(2,2);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 2 LED');
            obj.GUIHandles.PortLEDButton(3) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [272 220 30 30], 'Callback', 'ManualOverride(2,3);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 3 LED');
            obj.GUIHandles.PortLEDButton(4) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [313 220 30 30], 'Callback', 'ManualOverride(2,4);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 4 LED');
            obj.GUIHandles.PortLEDButton(5) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [354 220 30 30], 'Callback', 'ManualOverride(2,5);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 5 LED');
            obj.GUIHandles.PortLEDButton(6) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [395 220 30 30], 'Callback', 'ManualOverride(2,6);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 6 LED');
            obj.GUIHandles.PortLEDButton(7) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [436 220 30 30], 'Callback', 'ManualOverride(2,7);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 7 LED');
            obj.GUIHandles.PortLEDButton(8) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [477 220 30 30], 'Callback', 'ManualOverride(2,8);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle port 8 LED');

            obj.GUIHandles.PortvPokeButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [188 180 30 30], 'Callback', 'ManualOverride(3,1);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 1 virtual photogate');
            obj.GUIHandles.PortvPokeButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [231 180 30 30], 'Callback', 'ManualOverride(3,2);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 2 virtual photogate');
            obj.GUIHandles.PortvPokeButton(3) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [272 180 30 30], 'Callback', 'ManualOverride(3,3);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 3 virtual photogate');
            obj.GUIHandles.PortvPokeButton(4) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [313 180 30 30], 'Callback', 'ManualOverride(3,4);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 4 virtual photogate');
            obj.GUIHandles.PortvPokeButton(5) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [354 180 30 30], 'Callback', 'ManualOverride(3,5);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 5 virtual photogate');
            obj.GUIHandles.PortvPokeButton(6) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [395 180 30 30], 'Callback', 'ManualOverride(3,6);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 6 virtual photogate');
            obj.GUIHandles.PortvPokeButton(7) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [436 180 30 30], 'Callback', 'ManualOverride(3,7);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 7 virtual photogate');
            obj.GUIHandles.PortvPokeButton(8) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [477 180 30 30], 'Callback', 'ManualOverride(3,8);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Port 8 virtual photogate');

            obj.GUIHandles.BNCInputButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [525 243 30 30], 'Callback', 'ManualOverride(4,1);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Spoof BNC Input 1');
            obj.GUIHandles.BNCInputButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [565 243 30 30], 'Callback', 'ManualOverride(4,2);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Spoof BNC Input 2');

            obj.GUIHandles.BNCOutputButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [605 243 30 30], 'Callback', 'ManualOverride(5,1);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle TTL: BNC Output 1');
            obj.GUIHandles.BNCOutputButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [645 243 30 30], 'Callback', 'ManualOverride(5,2);', 'CData', obj.Graphics.OffButton, 'TooltipString', 'Toggle TTL:BNC Output 2');

            obj.GUIHandles.InputWireButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [188 77 30 30], 'Callback', 'ManualOverride(6,1);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Spoof input wire 1');
            obj.GUIHandles.InputWireButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [231 77 30 30], 'Callback', 'ManualOverride(6,2);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Spoof input wire 1');
            obj.GUIHandles.InputWireButton(3) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [272 77 30 30], 'Callback', 'ManualOverride(6,3);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Spoof input wire 1');
            obj.GUIHandles.InputWireButton(4) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [313 77 30 30], 'Callback', 'ManualOverride(6,4);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Spoof input wire 1');


            obj.GUIHandles.OutputWireButton(1) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [188 36 30 30], 'Callback', 'ManualOverride(7,1);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Toggle TTL: output wire 1');
            obj.GUIHandles.OutputWireButton(2) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [231 36 30 30], 'Callback', 'ManualOverride(7,2);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Toggle TTL: output wire 1');
            obj.GUIHandles.OutputWireButton(3) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [272 36 30 30], 'Callback', 'ManualOverride(7,3);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Toggle TTL: output wire 1');
            obj.GUIHandles.OutputWireButton(4) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [313 36 30 30], 'Callback', 'ManualOverride(7,4);', 'CData', obj.Graphics.OffButtonDark, 'TooltipString', 'Toggle TTL: output wire 1');

            obj.GUIHandles.SoftTriggerButton = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [363 32 40 40], 'Callback', 'ManualOverride(8,0);', 'CData', obj.Graphics.SoftTriggerButton, 'TooltipString', 'Send soft event code byte');

            obj.GUIHandles.HWSerialTriggerButton1 = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [414 32 40 40], 'Callback', 'ManualOverride(9,0);', 'CData', obj.Graphics.SoftTriggerButton, 'TooltipString', 'Send byte to hardware serial port 1');
            obj.GUIHandles.HWSerialTriggerButton2 = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [465 32 40 40], 'Callback', 'ManualOverride(10,0);', 'CData', obj.Graphics.SoftTriggerButton, 'TooltipString', 'Send byte to hardware serial port 2');

            obj.GUIHandles.CurrentStateDisplay = uicontrol('Style', 'text', 'String', 'None', 'Position', [12 268 115 20], 'FontWeight', 'bold', 'FontSize', 9);
            obj.GUIHandles.PreviousStateDisplay = uicontrol('Style', 'text', 'String', 'None', 'Position', [12 219 115 20], 'FontWeight', 'bold', 'FontSize', 9);
            obj.GUIHandles.LastEventDisplay = uicontrol('Style', 'text', 'String', 'None', 'Position', [12 169 115 20], 'FontWeight', 'bold', 'FontSize', 9);
            obj.GUIHandles.TimeDisplay = uicontrol('Style', 'text', 'String', '0', 'Position', [12 117 115 20], 'FontWeight', 'bold', 'FontSize', 9);
            obj.GUIHandles.CxnDisplay = uicontrol('Style', 'text', 'String', 'Idle', 'Position', [12 62 115 20], 'FontWeight', 'bold', 'FontSize', 9);
            obj.GUIHandles.ProtocolSelector = uicontrol('Style', 'listbox', 'String', 'None Loaded', 'Position', [520 45 185 150], 'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [.8 .8 .8]);
            obj.GUIHandles.SoftCodeSelector = uicontrol('Style', 'edit', 'String', '0', 'Position', [363 80 40 25], 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', [.8 .8 .8], 'TooltipString', 'Enter byte code here (0-255; 0=no op)');
            obj.GUIHandles.HWSerialCodeSelector1 = uicontrol('Style', 'edit', 'String', '0', 'Position', [414 80 40 25], 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', [.8 .8 .8], 'TooltipString', 'Enter byte code here (0-255; 0=no op)');
            obj.GUIHandles.HWSerialCodeSelector2 = uicontrol('Style', 'edit', 'String', '0', 'Position', [465 80 40 25], 'FontWeight', 'bold', 'FontSize', 12, 'BackgroundColor', [.8 .8 .8], 'TooltipString', 'Enter byte code here (0-255; 0=no op)');

            % Remove all the nasty borders around pushbuttons on platforms besides win7
            if isempty(strfind(obj.HostOS, 'Windows 7'))
                handles = findjobj('class', 'pushbutton');
                set(handles, 'border', []);
            end

            try
                jScrollPane = findjobj(obj.GUIHandles.ProtocolSelector); % get the scroll-pane object
                jListbox = jScrollPane.getViewport.getComponent(0);
                set(jListbox, 'SelectionBackground',java.awt.Color.red); % option #1
            catch
            end

            ha = axes('units','normalized', 'position',[0 0 1 1]);
            uistack(ha,'bottom');
            if obj.EmulatorMode == 0
                BG = imread('ConsoleBG.bmp');
            else
                BG = imread('ConsoleBG_EMU.bmp');
            end
            image(BG); axis off;
            set(ha,'handlevisibility','off','visible','off');
            set(obj.GUIHandles.MainFig,'handlevisibility','off');

            % Load protocols into selector
 %% FS MOD             
            ProtocolPath = fullfile(obj.BpodUserPath,'Protocols');
            if ~isdir(ProtocolPath)
                mkdir(ProtocolPath)
            end
%%            
            Candidates = dir(ProtocolPath);
            ProtocolNames = cell(1);
            nCandidates = length(Candidates)-2;
            nProtocols = 0;
            if nCandidates > 0
                for x = 3:length(Candidates)
                    if Candidates(x).isdir
                        nProtocols = nProtocols + 1;
                        ProtocolNames{nProtocols} = Candidates(x).name;
                    end
                end
            end
            if isempty(ProtocolNames)
                ProtocolNames = {'No Protocols Found'};
            end
            set(obj.GUIHandles.ProtocolSelector, 'String', ProtocolNames);
        end
    end
end

