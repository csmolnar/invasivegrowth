function [imgBefore, imgAfterRegistered] = registerImages(inputImgBefore, inputImgAfter)

global options;

imgBefore = rgb2gray(inputImgBefore);
imgAfter = rgb2gray(inputImgAfter);

ptsOriginal  = detectSURFFeatures(imgBefore(:,:,1), 'MetricThreshold', 100);
ptsDistorted = detectSURFFeatures(imgAfter(:,:,1), 'MetricThreshold', 100);

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
        title({'Putatively matched points', '(including outliers)'});
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


