% close all;
% clear;

[scriptDir, ~] = fileparts( mfilename('fullpath') );

global options;

setOptions(scriptDir);

%%
beforeImagesList = dir(fullfile(options.dataDir, options.beforeRegexp));
afterImagesList = dir(fullfile(options.dataDir, options.afterRegexp));

registeredImages = cell(length(afterImagesList),2);
masks = cell(length(afterImagesList),1);

mbs = cell(length(afterImagesList));
mas = cell(length(afterImagesList));

%%
fprintf(sprintf('Processing of images started.\n'));
for i=1:length(afterImagesList)
    
    fprintf('[%02d/%02d] Processing image pair (%s,%s)\n', i, length(afterImagesList), beforeImagesList(i).name, afterImagesList(i).name);
    
    fprintf('|-[1] Registration of images\n');
    
    % rotation with 180 degrees
    imgBefore = imrotate(imread( fullfile(options.dataDir, beforeImagesList(i).name) ), 180 );
    imgAfter = imrotate(imread( fullfile(options.dataDir, afterImagesList(i).name) ), 180 );
    
    % image registration registration
    [registeredImages{i,1}, registeredImages{i,2}, masks{i}] = registerImages(imgBefore, imgAfter);

    fprintf('|-[2] Segmentation and feature extraction\n');
    
    if strcmp(options.imagingType, 'top')
        [mbs{i}, mas{i}, f, plateMask, segm] = processImagePairTop(registeredImages{i,1}, registeredImages{i,2}, masks{i});
    else
        [mbs{i}, mas{i}, f, plateMask, segm] = processImagePairBottom(registeredImages{i,1}, registeredImages{i,2}, masks{i});
    end
    
    fprintf('|-[3] Saving image results\n');
    
    if options.saveSegmentations == 1
        
        h = figure('Visible','off');
        imshowpair(registeredImages{i,1}, registeredImages{i,2}, 'Scaling', 'joint');
        imwrite(getimage(h), fullfile(options.resultsDir, ['registration_' beforeImagesList(i).name '.png']));
        
%         imwrite(plateMask, fullfile(options.resultsDir, sprintf('mask_%s', beforeImagesList(i).name)));
        imwrite(segm, fullfile(options.resultsDir, sprintf('segm_%s', beforeImagesList(i).name)));
        imwrite(getimage(f), fullfile(options.resultsDir, sprintf('cont_%s', beforeImagesList(i).name)));
    end
    
end
fprintf('Processing finished.\n');


%%
fprintf('Saving measurements to table...\n');
FileName = {};
Well = {};
MeanIntensityBefore = {};
MeanBgIntensityBefore = {};
MeanIntensityAfter = {};
MeanBgIntensityAfter = {};

for i=1:length(afterImagesList)
% for i=1:2
    mb = mbs{i};
    ma = mas{i};
    
    for ii=1:size(mb,1)
        for jj=1:size(mb,2)
            actMb = mb{ii,jj};
            actMa = ma{ii,jj};
            
            FileName{end+1,1} = beforeImagesList(i).name;
            Well{end+1,1} = actMb.well;
            MeanIntensityBefore{end+1,1} = actMb.meanColonyIntensity;
            MeanBgIntensityBefore{end+1,1} = actMb.meanBgIntensity;
            MeanIntensityAfter{end+1,1} = actMa.meanColonyIntensity;
            MeanBgIntensityAfter{end+1,1} = actMa.meanBgIntensity;
        end
    end
end

t = table(FileName, Well, MeanIntensityBefore, MeanBgIntensityBefore, MeanIntensityAfter, MeanBgIntensityAfter,...
          'VariableNames', {'FileName', 'Well', 'MeanIntensityBefore', 'MeanBgIntensityBefore',...
           'MeanIntensityAfter', 'MeanBgIntensityAfter'});

writetable(t, fullfile(options.resultsDir, options.outputFileName));

fprintf('Saving results to file %s finished.\n', fullfile(options.resultsDir, options.outputFileName));