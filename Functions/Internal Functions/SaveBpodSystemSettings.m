function SaveBpodSystemSettings
global BpodSystem
BpodSystemSettings = BpodSystem.SystemSettings;
save(fullfile(BpodSystem.BpodUserPath, 'Settings Files', 'BpodSystemSettings.mat'), 'BpodSystemSettings'); % FS MOD