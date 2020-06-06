[scriptDir, ~] = fileparts( mfilename('fullpath') );

global options;

plateList = dir(fullfile(scriptDir, '..', 'data'));
for i = length(plateList):-1:1
    
    if strcmp(plateList(i).name,'.') || strcmp(plateList(i).name,'..')
        plateList(i) = [];
    end
    
end

for i = 1:length(plateList)
    
    options.plateName = plateList(i).name;
    close all;
    processPlateMainScript;
    
end