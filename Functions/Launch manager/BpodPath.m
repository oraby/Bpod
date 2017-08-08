function BpodPath(Name)
%%Changes the BpodUserPath, registered users are 'Ada', 'Quentin'. 
%%Use 'ini' as an input argument to use the default bpod folder.
%%New user should be add in the BpodPath function file inside the switch
%%command
%%The BpodUserPath should contain protocol, calibration and data folders
%%
%% Designed by Quentin 2017 for killerscript version of Bpod

%% User specific
try
switch Name
    case 'Quentin'
        Path='C:\Users\Kepecs\Documents\Data\Quentin\Bpod';
    case 'Ada'
        Path='C:\Users\Kepecs\Documents\Data\Ada\Bpod';
    case 'Tzvia'
        Path='C:\Users\Kepecs\Documents\Data\Tzvia\Bpod';
    case 'ini'
        Path='C:\Users\Kepecs\Documents\MATLAB\Bpod';
end

%% Overwritting the txt file
cd('C:\Users\Kepecs\Documents\Bpod');
BpodUserPathTXT=fopen('BpodUserPath.txt','w');
fprintf(BpodUserPathTXT,'%c',Path);
fclose(BpodUserPathTXT);
disp(Path)

catch
    disp('Cannot find the bpod path -- Recorded Users are - Ada - Quentin - Tzvia -- Use ini to use the default bpod folder');
end
end