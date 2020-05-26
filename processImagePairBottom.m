function [measurements, measurementsAfter, f, plateMask, segmentation] = processImagePairBottom(imBefore, imAfter, mask1)

global options;

% invert images
% im = 2^8 - rgb2gray(imBefore);
% imAfter = 2^8 - rgb2gray(imAfter);

im = 2^8 - imBefore;
imAfter = 2^8 - imAfter;

% t = adaptthresh(im, 0.4);
% % figure; imagesc(t);
% 
% BW = imbinarize(im,t);
% % figure; imagesc(BW);
% % title('thresh');
% 
% % BW = medfilt2(BW, [15 15]);
% % figure; imagesc(BW);
% % title('median filtered');
% 
% BW = imclose(BW, strel('disk',10,4));
% % figure; imagesc(BW);
% % title('closed');
% 
% % closedL = bwlabel(BW);
% % closedProps = regionprops(closedL, 'Area');
% % closedAreas = cat(1, closedProps.Area);
% 
% % bwfilled = imfill(BW,'holes');
% % figure; imagesc(bwfilled);
% % title('filled');
% 
% 
% BW = imclose(BW, strel('disk',20,4));
% % figure; imagesc(BW);
% % title('closed');
% % 
% % p = regionprops(BW, 'Area');
% % areas = [0; cat(1, p.Area )];
% % medArea = median( areas(2,end) );
% % 
% % areaMap = areas(bwlabel(BW)+1);
% % areaMap(areaMap>1.5*medArea) = 0;
% % areaMap(areaMap<0.25*medArea) = 0;
% % figure; imagesc(areaMap); title('areaMap');
% % 
% % BW = clearBorderObjects( bwlabel(areaMap>0) , 10) > 0;
% % 
% % p = regionprops(BW, 'Eccentricity');
% % 
% % eccs = [0; cat(1, p.Eccentricity)];
% % eccentMap = eccs(bwlabel(BW)+1);
% % 
% % eccentMap(eccentMap>0.6) = 0;
% % figure; imagesc(eccentMap); title('eccentMap');
% % 
% % plateMask = imdilate(bwconvhull(eccentMap>0), strel('disk',100,4));
% 
% closedL = bwlabel(~BW);
% closedProps = regionprops(closedL, 'Area');
% areas = cat(1, closedProps.Area);
% [~, ind] = max(areas);
% areas(ind) = -Inf;
% [~, maxAreaId] = max(areas);
% % [~, maxAreaId] = max( cat(1, closedProps.Area) );
% 
% BW = closedL == maxAreaId;
% % figure; imagesc(BW); title('plate inside');
% plateMask = bwconvhull(BW, 'objects');
% p = regionprops(plateMask, 'Area');
% 
% [~, maxId] = max( cat(1, p.Area) );
% 
% plateMask = bwlabel(plateMask) == maxId;

% plateMask = mask(:,:,1) > 0;
plateMask = mask1(:,:,1) > 0;

% figure; imagesc(plateMask);
% title('convex hull');

plateProps = regionprops(plateMask, 'BoundingBox');
bbox = cat(1, plateProps.BoundingBox);
bbox(bbox<1) = 1;

plateImage = im(floor(plateProps(1).BoundingBox(2)): floor(plateProps(1).BoundingBox(2))+plateProps(1).BoundingBox(4),...
                floor(plateProps(1).BoundingBox(1)): floor(plateProps(1).BoundingBox(1))+plateProps(1).BoundingBox(3));
            
plateImageAfter = imAfter(floor(plateProps(1).BoundingBox(2)): floor(plateProps(1).BoundingBox(2))+plateProps(1).BoundingBox(4),...
                floor(plateProps(1).BoundingBox(1)): floor(plateProps(1).BoundingBox(1))+plateProps(1).BoundingBox(3));


%%
tplate = adaptthresh(plateImage, 0.5, 'Statistic', 'mean');
BW = imbinarize(plateImage,tplate);

% figure; imagesc(BW);
% title('adaptthresh');


%% finding centroids with thresholding and filtering
med = medfilt2(BW, [30 30]);

closedPlate = imclose(med, strel('disk', 5, 4));

% figure; imagesc(closedPlate);
% title('closed');


p = regionprops(closedPlate, 'Area');
areas = [0; cat(1, p.Area)];

medianSize = median(areas(2:end));

areaMap = areas(bwlabel(closedPlate)+1);
% figure; imagesc(areaMap);

areaMap(areaMap>2.5*medianSize) = 0;
areaMap(areaMap<0.5*medianSize) = 0;
% figure; imagesc(areaMap);

%%
% 
p = regionprops(areaMap>0, 'Eccentricity');

eccs = [0; cat(1, p.Eccentricity)];
eccentMap = eccs(bwlabel(areaMap>0)+1);

eccentMap(eccentMap>0.6) = 0;

% figure; imagesc(eccentMap);

p = regionprops(eccentMap>0, 'Centroid');
centroids = cat(1, p.Centroid);

%% finding most centroids with circle detection

% medianRadius = sqrt(medianSize/pi);
% [centroids, radii] = imfindcircles(BW, [int32(medianRadius*0.5), int32(medianRadius*2.5)]);

%% 

xLocations = centroids(:,1);
yLocations = centroids(:,2);

centersXstart = linspace(min(xLocations), max(xLocations), 12);
centersYstart = linspace(min(yLocations), max(yLocations), 8);

[~, centersX] = kmeans(xLocations, 12, 'start', [centersXstart'], 'replicates', 1);
centersX = ceil(sort(centersX));
[~, centersY] = kmeans(yLocations, 8, 'start', [centersYstart'], 'replicates', 1);
centersY = ceil(sort(centersY));
    
distX = ceil(mean( diff(centersX) ));
distY = ceil(mean( diff(centersY) ));


%% 

% figure;
% imagesc(plateImage);
% hold on;

% segmentationImage = zeros(size(plateImage));

measurements = cell(12,8);
measurementsAfter = cell(12,8);

if options.popupResults
    f = figure(10); imshow(im); hold on;
else
    f =[];
end

measurements = cell(12,8);
measurementsAfter = cell(12,8);

[h, w, ~] = size(plateImage);
segmentation = zeros(h,w);

for i=1:12
    for j=1:8
        wellCode = [char('A'+j-1) num2str(i)];
        
        if options.popupResults
            text(bbox(1)+centersX(i),bbox(2)+centersY(j), wellCode);
        end
            
        top = int16(max(1, centersY(j)-distY/2));
        bottom = int16(min( h, centersY(j)+distY/2));
        left = int16(max(1, centersX(i)-distX/2));
        right = int16(min( w, centersX(i)+distX/2));
        
        colonyPatch = plateImage(top:bottom, left:right);
        colonyPatchAfter = plateImageAfter(top:bottom, left:right);
        
%         figure; 
%         subplot(1,3,1);
%         imagesc(colonyPatch); title('image');
        
%         t = adaptthresh(colonyPatch, 0.5, 'NeighborhoodSize', 51);
%         segm = imbinarize(colonyPatch, t);

        t = graythresh(colonyPatch);
        segm = imbinarize(colonyPatch, t);
%         
%         subplot(1,3,2);
%         imagesc(segm); title('segmentation');
        
        segm = imfill(segm, 'holes');
        
        
        L = bwlabel(segm);
        props = regionprops(L, 'Area', 'Eccentricity');
        [~, maxRegionId] = max( cat(1,props.Area) );
        
        if props(maxRegionId).Eccentricity>0.6
            [hh,ww] = size(L);
            xs = 1:ww;
            ys = 1:hh;
            [XS,YS] = meshgrid(xs,ys);
            segm = (XS-distX/2).^2+(YS-distY/2).^2<50^2;
        else
            segm = L == maxRegionId;
        end
        
        segmentation(top:bottom, left:right) = segm;
        
%         segmentationImage(centersY(j)-distY/2:centersY(j)+distY/2,...
%                           centersX(i)-distX/2:centersX(i)+distX/2) = segm;
%         subplot(1,3,3);
%         imagesc(segm); title('maxregion');
        
        meanColonyIntensity = mean( colonyPatch(segm) );
        meanBgIntensity = mean( colonyPatch(~segm) );
                
        meanColonyIntensityAfter = mean( colonyPatchAfter(segm) );
        meanBgIntensityAfter = mean( colonyPatchAfter(~segm) );
        
%         normalizedColonyIntensity = meanColonyIntensity-meanBgIntensity;
        
        measurements{i,j} = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensity, 'meanBgIntensity', meanBgIntensity);
        measurementsAfter{i,j} = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensityAfter, 'meanBgIntensity', meanBgIntensityAfter);
    end
end

if options.popupResults
    outlinedImage = plateImage;
    perim = bwperim(segmentation);
    outlinedImage(perim) = 255;
    outImage(:,:,2) = outlinedImage;
    outlinedImage(perim) = 0;
    outImage(:,:,1) = outlinedImage;
    outImage(:,:,3) = outlinedImage;
    figure(3); imshow(outImage);
end
