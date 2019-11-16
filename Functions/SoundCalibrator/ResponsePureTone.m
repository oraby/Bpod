function [bandPower_dBSPL] = ResponsePureTone(handles)
%RESPONSEPURETONE Generates a pure tone and records the output with a DAQ device
% 
% This function outputs a pure sinusiodal tone with a given amplitude via the
% PsychToolbox, records the output of a connected conditioned amplifier via a
% data acquisition device and calculates sound pressure that is measured by the
% conditioned amplifier in the frequency range of interest (within a given
% bandwidth around the frequency of the pure tone). Afterwards, the power
% spectral density (PSD) is estimated using Welch's method to calculate the
% sound pressure level in dezi-Bell (dB_SPL) in relation to the reference of the
% human auditory threshold (p0 = 20 uPa @ 1 kHz)
%
% Based on the implementation by Santiago Jaramillo, Uri, and Fede
%
% Author: Michael Wulf
%         Cold Spring Harbor Laborator
%         Kepecs Lab
%         wulf@cshl.edu / michael.wulf@gmail.com
%
% Date:    2019-11-14
% Version: 1.00.01
% History:
%  - 1.00.01: Changed audio playback for combined calibration of two speakers
%  - 1.00.00: Initial version combining previously separated functions together
%             and making the code more robust and understandable

% Get parameters to create sound
a0 = handles.SoundCal.currAmplitude;
f0 = handles.SoundCal.currFrequency;
T  = handles.SoundCal.toneDuration;
Fs = handles.SoundCal.samplingFrequncy;
Ts = 1/Fs;
t  = 0:Ts:T;

% Get parameters for spectral analysis
NWindow   = handles.SoundCal.PSDWindowLength;
FsInput   = handles.DAQ.SamplingRate;           % Should be 200 kHz
p0        = handles.SoundCal.pressureReference; % Should be 20 uPa
bandwidth = handles.SoundCal.bandwidth;

% Generate mono-frequent signal
outputSound = a0 * sin(2 * pi * f0 * t);

% Check speaker channel selection for setting values to be played via PsychToolbox
if strcmpi(handles.SoundCal.currSpeakerName, 'left')
    % Only left speaker should be calibrated:
    % Create a stereo signal where right channel is "silent"
    outputSound = [outputSound; zeros(1, length(outputSound))];
    
elseif strcmpi(handles.SoundCal.currSpeakerName, 'right')
    % Only right speaker should be calibrated:
    % Create a stereo signal where left channel is "silent"
    outputSound = [zeros(1, length(outputSound)); outputSound];
    
elseif strcmpi(handles.SoundCal.currSpeakerName, 'both')
    % Both speakers should be calibrated:
    % Create a stereo signal where left and right channel are identical
    outputSound = [outputSound; outputSound];
    
else
    error('Unkown speaker channel selection %s', handles.SoundCal.currSpeakerName);
end
        
% Load the sound vector into sound server's channel 1
PsychToolboxSoundServer('Load', 1, outputSound);

% Start recording using the DAQ device
if ispc
    % Start playing output channel 1
    PsychToolboxSoundServer('Play', 1);
    
    % Wait a bit so that transients will not be recorded
    pause(handles.SoundCal.delayRecording);
    
    % Start recording
    rawSignal = startForeground(handles.DAQ.Session);
    
else
    if ( strncmpi(handles.DAQ.VendorID, 'mcc', 3) )
        % Getnumber of samples to be acquired
        recordLength = handles.SoundCal.timeToRecord * FsInput;
        
        % Start playing output channel 1
        PsychToolboxSoundServer('Play', 1);

        % Wait a bit so that transients will not be recorded
        pause(handles.SoundCal.delayRecording);
        
        % Record in blocking mode (no pause needed)
        data = mcc_daq('n_scan', recordLength,'freq', FsInput, 'n_chan', 1);
        
        % Get first channel
        rawSignal = data(1, :); 
    end
end

% Wait a bit
pause(handles.SoundCal.timeToRecord);

% Stop outputting sound signal
PsychToolboxSoundServer('StopAll');

% Scale the recorded voltage to a pressure signal (based on the values of the
% conditioned amplifier)
pressureSignal = rawSignal/handles.SoundCal.ampCondition;

% Calculate an estimate of the power spectral density of the prsssure signal
[Pxx, f] = pwelch(pressureSignal, NWindow, [], [], FsInput, 'onesided');

% Get frequencies for given bandwidth
fLow  = f0 - (bandwidth/2);
fHigh = f0 + (bandwidth/2);
if (fLow <= 0)
    fLow = 1;
end
if (fHigh >= (FsInput/2))
    fHigh = (FsInput/2);
end

% Find indices for bandwidth range
lowIdx   = find(f <= fLow,  1, 'last');
highIdx  = find(f >= fHigh, 1, 'first');
rangeIdx = lowIdx:highIdx;

% Estimate pressure power for given frequency bandwidth
meanBandPower = mean(Pxx(rangeIdx)) * diff(f(rangeIdx([1,end])));

% Esitmate power in dB_SPL
bandPower_dBSPL = 10*log10(meanBandPower/p0^2);
end