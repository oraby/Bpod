function [rms] = windowedRMS(signal, window, overlap)
%WINDOWEDRMS Calculate the RMS per window
%
%WINDOWEDRMS(signal, window) caculates the RMS of per number of samples in
%signal specified by window
%
%Arguments:
%window: The length of the window in number of samples
%overlap: The number of samples the windows should overlap
%
%Author: Michael Wulf
%        Cold Spring Harbor Laborator
%        Kepecs Lab
%        wulf@cshl.edu / michael.wulf@gmail.com
%
%Date:    2019-11-21
%Version: 1.00.00
%
%History:
% - 1.00.00: Initial version 

if nargin < 2
    error('Not enough input arguments!');
end

if nargin == 2
    overlap = 0;
end

if nargin > 2
    if (overlap > (window/2))
        error('number of samples to overlap must be smaller than window/2!');
    end
end

% Get length of the signal
signalLength = length(signal);

if (signalLength < window)
    error('The number of samples in the signal is smaller than the window length!');
end

% Get the offset to jump through the signal/windows
offset = window-overlap;

% Get all the start indices for the windows
windowStartIdx = 1:offset:signalLength;

% Get number of windows
numWindows = length(windowStartIdx);

% Initialize the outpur argument (RMS values)
rms = zeros(1, numWindows);

% Calculate the squared signal
signal = signal.^2;

for wndCntr = 1:1:(numWindows-1)
    startIdx = windowStartIdx(wndCntr);
    endIdx   = startIdx + window - 1;
    
    if (endIdx <= signalLength)
        rms(wndCntr) = sqrt(mean(signal(startIdx:endIdx)));
    else
        rms(wndCntr) = sqrt(mean(signal(startIdx:end)));
    end
end

% Since the last window might be shorter than the window length, let treat it
% separately...
startIdx = windowStartIdx(end);
endIdx   = signalLength;
rms(end) = sqrt(mean(signal(startIdx:endIdx)));
end