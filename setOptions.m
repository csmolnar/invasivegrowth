function setOptions(scriptDir)

global options;

% options.plateName = '20190403_bub3AvsE_YPD_R1_original';
options.imagingType = 'bottom';

% options.referenceImagePath = 'reference_image.jpg';
% options.referenceMaskPath = 'reference_image_mask.png';

options.beforeRegexp = '*before*.JPG';
options.afterRegexp = '*after*.JPG';

options.popupResults = 0;
options.saveSegmentations = 1; % TODO: change results format

options.outputFileName = sprintf('results_%s_%s.csv', options.plateName, options.imagingType);

options.projectDir = fullfile(scriptDir, '..');
options.dataDir = fullfile(options.projectDir, 'data', options.plateName, options.imagingType);
options.resultsMainDir = fullfile(options.projectDir, 'results');
options.resultsDir = fullfile(options.projectDir, 'results', options.plateName);

if ~exist(options.resultsMainDir, 'dir')
    mkdir(options.resultsMainDir);
end

if ~exist(options.resultsDir, 'dir')
    mkdir(options.resultsDir);
end