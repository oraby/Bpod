%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function SoundData = CalibratedPureTone(Frequency, Duration, Intensity, Side, RampDuration, SamplingFreq, CalibrationData)
% This function generates a calibrated pure tone for upload to a sound server.
%
% The tone is specified by: Frequency (Hz), Duration (s), Intensity (dB), Side (0=left, 1=right, 2=both).
% A linear intensity ramp is applied to the start and end of the tone,
% defined by RampDuration (s). Use 0 for no ramp.
%
% Additional required arguments are: SamplingFreq (Sampling Frequency of
% the sound server in Hz), and CalibrationData (also stored in BpodSystem.CalibrationTables.SoundCal)
%
% M. Wulf, 2019-11-06: Updated the code to be able to interpolate the amplitudes
%                      with different methods

nChannels  = length(CalibrationData);
timeVector = 0:1/SamplingFreq:Duration;
nSamples   = length(timeVector);

baseSignal = sin(2 * pi * timeVector * Frequency);

% Check if an envelope (ramp) should be used and if its parameters are valid
nRampSamples = RampDuration*SamplingFreq;
if nRampSamples >= nSamples/2
    error('Error: ramp duration (in seconds) cannot exceed half of the sound duration');
end

% Even if no envelope should be applied, preset it here to ones
RampEnvelope = ones(1,nSamples);

% If an envelope should be applied, calculate the values
% ramp up at the beginning and doen at the end
if nRampSamples > 0
    RampEnvelope(1:nRampSamples) = 1/nRampSamples:1/nRampSamples:1;
    RampEnvelope(nSamples-nRampSamples+1:nSamples) = 1:-1/nRampSamples:1/nRampSamples;
end

% Check the speaker side
outputSide = '';

% M. Wulf 2019-11-14: The switch-case based on the numerical value of the
% parameter 'Side' is just in here to keep the code compatible with older
% configuration files...
switch Side
    case 0
        outputSide = 'left';
        if ( (nChannels > 1) && (isempty(CalibrationData(1, 1).Coefficient)) )
            error('Error: Calibration file only has data for the second channel (right speaker).');
        end
        
    case 1
        if nChannels > 1
            outputSide = 'right';
            if ( isempty(CalibrationData(1, 2).Coefficient) )
                error('Error: Calibration file only has data for the first channel (left speaker).');
            end
        else
            error('Error: Calibration file only has data for the first channel (left speaker).')
        end
        
    case 2
        if nChannels > 1
            outputSide = 'both';
            
            if (isempty(CalibrationData(1, 1).Coefficient))
                error('Error: Calibration file only has data for the second channel (right speaker).');
            end
            
            if (isempty(CalibrationData(1, 2).Coefficient))
                error('Error: Calibration file only has data for the first channel (left speaker).');
            end
        else
            error('Error: Calibration file only has data for the first channel (left speaker).')
        end
end

% -------------------------------------------------------------------------

if strcmpi(outputSide, 'left')
    % Estimate (interpolate) the amplitude for a sin-shape signal with the
    % orginal target SPL for the specified frequency
    
    % M. Wulf 20109-11-06: Check for different interpolation methods...
    if isfield(CalibrationData(1, 1), 'FitMethod')
        fitMethod = CalibrationData(1, 1).FitMethod;
        switch(lower(fitMethod))
            case 'pchip'
                amplitude = ppval(CalibrationData(1, 1).Coefficient, Frequency);
                
            otherwise
                error('Unsupported interpolation method ''%s'' being used during calibration', fitMethod);
        end
    else
        amplitude = polyval(CalibrationData(1, 1).Coefficient, Frequency);
    end
    
    % Convert the SPL difference of the calibrated target SPL to the
    % desired SPL from dB_SPL to a linear factor
    attenuation = amplitude * sqrt(10^((Intensity - CalibrationData(1,1).TargetSPL)/10));
    
    % Now generate the correctly attenuated signal...
    SoundData = attenuation .* baseSignal;
    
    %... and apply envelope (even if it consists only of ones)
    SoundData = RampEnvelope .* SoundData;
    
    % Adjust output argument...
    SoundData = [SoundData; zeros(1,nSamples)];
    
    
elseif strcmpi(outputSide, 'right')
    % Estimate (interpolate) the amplitude for a sin-shape signal with the
    % orginal target SPL for the specified frequency
    
    % M. Wulf 20109-11-06: Check for different interpolation methods...
    if isfield(CalibrationData(1, 2), 'FitMethod')
        fitMethod = CalibrationData(1, 2).FitMethod;
        switch(lower(fitMethod))
            case 'pchip'
                amplitude = ppval(CalibrationData(1, 2).Coefficient, Frequency);
                
            otherwise
                error('Unsupported interpolation method ''%s'' being used during calibration', fitMethod);
        end
    else
        amplitude = polyval(CalibrationData(1, 2).Coefficient, Frequency);
    end
    
    % Convert the SPL difference of the calibrated target SPL to the
    % desired SPL from dB_SPL to a linear factor
    attenuation = amplitude * sqrt(10^((Intensity - CalibrationData(1,2).TargetSPL)/10));
    
    % Now generate the correctly attenuated signal...
    SoundData = attenuation .* baseSignal;
    
    %... and apply envelope (even if it consists only of ones)
    SoundData = RampEnvelope .* SoundData;
    
    % Adjust output argument...
    SoundData = [ zeros(1,nSamples); SoundData];
    
    
elseif strcmpi(outputSide, 'both')
    if ( (~isfield(CalibrationData(1, 1), 'SpeakerCalSettings')) || ...
            (~strcmpi(CalibrationData(1, 1).SpeakerCalSettings, 'Both - joined')) )
        warnMsg = sprintf('The speakers'' calibration was performed individually for each \nspeaker so the combined SPL with two speakers will be higher than specified!\n\n');
        warnMsg = sprintf('%sPlease calibrate the speakers again with the latest sound calibration plugin \nand select the the ''joined'' speaker calibration setting!', warnMsg);
        disp(warnMsg); %#ok<DSPS>
    end
    
    % M. Wulf 20109-11-06: Check for different interpolation methods...
    if ( (isfield(CalibrationData(1, 1), 'FitMethod')) && (isfield(CalibrationData(1, 1), 'FitMethod')) )
        fitMethodLeft  = CalibrationData(1, 1).FitMethod;
        fitMethodRight = CalibrationData(1, 2).FitMethod;
        if ( ~strcmpi(fitMethodLeft, fitMethodRight))
            error('Different interpolation methods used during calibration for both sides!');
        end
        switch(lower(fitMethodLeft))
            case 'pchip'
                amplitudeLeft  = ppval(CalibrationData(1, 1).Coefficient, Frequency);
                amplitudeRight = ppval(CalibrationData(1, 2).Coefficient, Frequency);
                
            otherwise
                error('Unsupported interpolation method ''%s'' being used during calibration', fitMethodLeft);
        end
    else
        amplitudeLeft  = polyval(CalibrationData(1, 1).Coefficient, Frequency);
        amplitudeRight = polyval(CalibrationData(1, 2).Coefficient, Frequency);
    end
    
    % Convert the SPL difference of the calibrated target SPL to the
    % desired SPL from dB_SPL to a linear factor
    attenuationLeft  = amplitudeLeft  * sqrt(10^((Intensity - CalibrationData(1,1).TargetSPL)/10));
    attenuationRight = amplitudeRight * sqrt(10^((Intensity - CalibrationData(1,2).TargetSPL)/10));
    
    % Now generate the correctly attenuated signal...
    SoundDataLeft  = attenuationLeft  .* baseSignal;
    SoundDataRight = attenuationRight .* baseSignal;
    
    %... and apply envelope (even if it consists only of ones)
    SoundDataLeft  = RampEnvelope .* SoundDataLeft;
    SoundDataRight = RampEnvelope .* SoundDataRight;
    
    % Adjust output argument...
    SoundData = [SoundDataLeft; SoundDataRight];
end