function [measurementsBefore, measurementsAfter, outImageBefore, outImageAfter, segmentation] = processImagePairBottom(imBefore, imAfter, plateMask)

global options;

% invert images

imBefore = imcomplement(imBefore);
imAfter  = imcomplement(imAfter);

plateMask = plateMask(:,:,1) > 0;

plateProps = regionprops(plateMask, 'BoundingBox');
bbox = cat(1, plateProps.BoundingBox);
bbox(bbox<1) = 1;

plateImageBefore = imBefore(floor(plateProps(1).BoundingBox(2)): floor(plateProps(1).BoundingBox(2))+plateProps(1).BoundingBox(4),...
                floor(plateProps(1).BoundingBox(1)): floor(plateProps(1).BoundingBox(1))+plateProps(1).BoundingBox(3));
            
plateImageAfter = imAfter(floor(plateProps(1).BoundingBox(2)): floor(plateProps(1).BoundingBox(2))+plateProps(1).BoundingBox(4),...
                floor(plateProps(1).BoundingBox(1)): floor(plateProps(1).BoundingBox(1))+plateProps(1).BoundingBox(3));

%%

tplate = adaptthresh(plateImageBefore, 0.5, 'Statistic', 'mean');
BW = imbinarize(plateImageBefore,tplate);

%% finding centroids with thresholding and filtering

med = medfilt2(BW, [30 30]);

closedPlate = imclose(med, strel('disk', 5, 4));

p = regionprops(closedPlate, 'Area');
areas = [0; cat(1, p.Area)];

medianSize = median(areas(2:end));

areaMap = areas(bwlabel(closedPlate)+1);

areaMap(areaMap>4*medianSize) = 0;
areaMap(areaMap<0.25*medianSize) = 0;

%% 

p = regionprops(areaMap>0, 'Eccentricity');

eccs = [0; cat(1, p.Eccentricity)];
eccentMap = eccs(bwlabel(areaMap>0)+1);

eccentMap(eccentMap>0.6) = 0;

p = regionprops(eccentMap>0, 'Centroid');
centroids = cat(1, p.Centroid);

%% fit grid to initially found colonies

xLocations = centroids(:,1);
yLocations = centroids(:,2);

[~, centersX] = kmeans(xLocations, 12, 'replicates', 5);
centersX = ceil(sort(centersX));
[~, centersY] = kmeans(yLocations, 8, 'replicates', 5);
centersY = ceil(sort(centersY));
distX = ceil(mean( diff(centersX) ));
distY = ceil(mean( diff(centersY) ));

%% extract colonies at grid point (wells) positions

if options.popupResults
    figure(10); imshow(imBefore); hold on;
end

measurementsBefore = cell(12,8);
measurementsAfter = cell(12,8);

[h, w, ~] = size(plateImageBefore);
segmentation = zeros(h,w);

for i=1:12
    for j=1:8
        
        wellCode = [char('A'+j-1) num2str(i)];
        
        if options.popupResults
            figure(10); text(bbox(1)+centersX(i),bbox(2)+centersY(j), wellCode);
        end
        
        %%% segmentation v1 (thresholding)

        top    = int16(max(1, centersY(j)-distY));
        bottom = int16(min(h, centersY(j)+distY));
        left   = int16(max(1, centersX(i)-distX));
        right  = int16(min(w, centersX(i)+distX));
        
        colonyPatchBefore = plateImageBefore(top:bottom, left:right);
        colonyPatchAfter  = plateImageAfter(top:bottom, left:right);

        t = graythresh(colonyPatchBefore);
        segm = imbinarize(colonyPatchBefore, t);
        segm = imfill(segm, 'holes');
        segm = imopen(segm, strel('disk', 10));
        
        L = bwlabel(segm);
        props = regionprops(L, 'Eccentricity');        
        objectRegionId = L(distY, distX);
        
        if objectRegionId==0 || props(objectRegionId).Eccentricity>0.6
            [hh,ww] = size(L);
            xs = 1:ww;
            ys = 1:hh;
            [XS,YS] = meshgrid(xs,ys);
            segm = (XS-distX).^2+(YS-distY).^2<=50^2;
        else
            segm = L == objectRegionId;
        end
        
        propsBoundingBox = regionprops(segm, 'BoundingBox');
        bgMask = zeros(size(segm,1),size(segm,2),'logical');
        bgMask(int32(propsBoundingBox(1).BoundingBox(2)):int32(propsBoundingBox(1).BoundingBox(2))+propsBoundingBox(1).BoundingBox(4)-1,...
               int32(propsBoundingBox(1).BoundingBox(1)):int32(propsBoundingBox(1).BoundingBox(1))+propsBoundingBox(1).BoundingBox(3)-1) = 1;
        bgMask(segm) = 0;
        
        %%% update main segmentation image and measure colony
        
        segmentation(top:bottom, left:right) = segmentation(top:bottom, left:right) | segm;
        
        meanColonyIntensityBefore = mean( colonyPatchBefore(segm) );
        meanBgIntensityBefore     = mean( colonyPatchBefore(bgMask) );
                
        meanColonyIntensityAfter  = mean( colonyPatchAfter(segm) );
        meanBgIntensityAfter      = mean( colonyPatchAfter(bgMask) );
        
        measurementsBefore{i,j}   = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensityBefore, 'meanBgIntensity', meanBgIntensityBefore);
        measurementsAfter{i,j}    = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensityAfter, 'meanBgIntensity', meanBgIntensityAfter);
    end
end

outlinedImage = plateImageBefore;
perim = bwperim(segmentation);
perim = imdilate(perim, strel('disk', 1));
outlinedImage(perim) = 255;
outImageBefore(:,:,2) = outlinedImage;
outlinedImage(perim) = 0;
outImageBefore(:,:,1) = outlinedImage;
outImageBefore(:,:,3) = outlinedImage;

outlinedImage = plateImageAfter;
outlinedImage(perim) = 255;
outImageAfter(:,:,2) = outlinedImage;
outlinedImage(perim) = 0;
outImageAfter(:,:,1) = outlinedImage;
outImageAfter(:,:,3) = outlinedImage;

if options.popupResults
    figure(3); imshow(outImageBefore);
end

