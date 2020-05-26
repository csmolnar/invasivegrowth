function [imgBefore, imgAfterRegistered, mask] = registerImages(inputImgBefore, inputImgAfter)

global options;

imgBefore = rgb2gray(inputImgBefore);
imgAfter = rgb2gray(inputImgAfter);

%%% Extract plate regions

gl1 = graythresh(imgBefore);
bw1 = im2bw(imgBefore, gl1);
gl2 = graythresh(imgAfter);
bw2 = im2bw(imgBefore, gl2);

bw1_filled = imfill(bw1, 'holes');
bw2_filled = imfill(bw2, 'holes');

LRout1=LargestRectangle(bw1_filled,0,0,0,0,0);
LRout2=LargestRectangle(bw1_filled,0,0,0,0,0);

bbox = [ min([LRout1(2:end, 1); LRout2(2:end, 1)]),...
         min([LRout1(2:end, 2); LRout2(2:end, 2)]),...
         max([LRout1(2:end, 1); LRout2(2:end, 1)]),...
         max([LRout1(2:end, 2); LRout2(2:end, 2)])];
mask = uint8(zeros(size(imgBefore)));
mask(bbox(2):bbox(4), bbox(1):bbox(3)) = 1;

ptsOriginal  = detectSURFFeatures(imgBefore(:,:,1).*mask, 'MetricThreshold', 100);
ptsDistorted = detectSURFFeatures(imgAfter(:,:,1).*mask, 'MetricThreshold', 100);

[featuresOriginal,  validPtsOriginal]  = extractFeatures(imgBefore(:,:,1),  ptsOriginal);
[featuresDistorted, validPtsDistorted] = extractFeatures(imgAfter(:,:,1), ptsDistorted);

indexPairs = matchFeatures(featuresOriginal, featuresDistorted);

if ~isempty(indexPairs)
    
    matchedOriginal  = validPtsOriginal(indexPairs(:,1));
    matchedDistorted = validPtsDistorted(indexPairs(:,2));

    if options.popupResults
        figure(1); clf;
        subplot(1,3,1, 'replace');
        showMatchedFeatures(imgBefore(:,:,1),imgAfter(:,:,1),matchedOriginal,matchedDistorted);
        title('Putatively matched points (including outliers)');
        legend('ptsOriginal','ptsDistorted');
    end
        
    [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
            matchedDistorted, matchedOriginal, 'similarity','MaxNumTrials', 5000);

    if options.popupResults
        figure(1); subplot(1,3,2, 'replace');
        showMatchedFeatures(imgBefore,imgAfter,inlierOriginal,inlierDistorted);
        title('Matching points (inliers only)');
        legend('ptsOriginal','ptsDistorted');
    end

    imgAfterRegistered = imwarp(imgAfter,tform,'OutputView',imref2d(size(imgBefore)));
    
    if options.popupResults
        figure(1); subplot(1,3,3, 'replace');
        imshowpair(imgBefore(:,:,1),imgAfterRegistered(:,:,1),'Scaling','joint');
        title('Registered image pair');
    end
    
else
    [optimizer, metric] = imregconfig('monomodal');
%     optimizer.MaximumStepLength = 0.1;
    optimizer.MaximumIterations = 1000;
    imgAfterRegistered = imregister(imgAfter(:,:,1), imgBefore(:,:,1), 'similarity', optimizer, metric);
    
    if options.popupResults
        figure(1); clf;
        imshowpair(imgBefore(:,:,1), imgAfter(:,:,1),'Scaling','joint');
        title('Registered image pair');
    end
end


