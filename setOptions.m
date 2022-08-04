function setOptions(scriptDir)

global options;

options.plateName         = '20220703_NAT1011INV-pilot';
options.imagingType       = 'bottom';
options.plateType         = 384;

options.beforeRegexp      = '*before*.JPG';
options.afterRegexp       = '*after*.JPG';

options.popupResults      = 1;
options.saveSegmentations = 1;
options.storeResults      = 1;

options.outputFileName    = sprintf('results_%s_%s.csv', options.plateName, options.imagingType);

options.projectDir        = fullfile(scriptDir, '..');
options.dataDir           = fullfile(options.projectDir, 'data', options.plateName, options.imagingType);
options.resultsMainDir    = fullfile(options.projectDir, 'results');
options.resultsDir        = fullfile(options.projectDir, 'results', options.plateName);

if ~exist(options.resultsMainDir, 'dir')
    mkdir(options.resultsMainDir);
end

if ~exist(options.resultsDir, 'dir')
    mkdir(options.resultsDir);
end

% options.referenceImagePath = 'reference_image.jpg';
% options.referenceMaskPath = 'reference_image_mask.png';
