function [] = gsetdir( x1, x2, handle, property )
%GSETDIR Gets a directory path and sets handle.property to it.
%
%	gsetdir( x1, x2, handle, ['String'])
%	gsetdir( x1, x2, handle, property )
%
%   To be used as a GUI callback. First two arguments contain data about
%   the GUI where the callback is called from (a MATLAB standard.)
%   *handle* is the handle of an object whose property *handle.property*
%   will be set to the path of a directory picked by hand via the
%   *uigetdir* function. The optional input *property* is a string
%   variable; if not input, standard 'String' is used.
%
%   See also UIGETDIR.

narginchk(3,4)
if nargin < 4
    property = 'String';
end

pathdir = uigetdir('Choose location:');
pathdir = fullfile(pathdir,'BpodUser');
set(handle,property,pathdir)

% set(textHandle,'String',uigetdir('Choose location:'))
end

