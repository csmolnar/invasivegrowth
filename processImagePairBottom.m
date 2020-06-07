function [measurements, measurementsAfter, f, plateMask, segmentation] = processImagePairBottom(imBefore, imAfter, mask1)

global options;

im = 2^8 - imBefore;
imAfter = 2^8 - imAfter;

plateMask = mask1(:,:,1) > 0;

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
    figure(10); imshow(im); hold on;
end

measurements = cell(12,8);
measurementsAfter = cell(12,8);

[h, w, ~] = size(plateImage);
segmentation = zeros(h,w);

for i=1:12
    for j=1:8
        
        wellCode = [char('A'+j-1) num2str(i)];
        
        if options.popupResults
            figure(10); text(bbox(1)+centersX(i),bbox(2)+centersY(j), wellCode);
        end
            
        top = int16(max(1, centersY(j)-distY/2));
        bottom = int16(min( h, centersY(j)+distY/2));
        left = int16(max(1, centersX(i)-distX/2));
        right = int16(min( w, centersX(i)+distX/2));
        
        colonyPatch = plateImage(top:bottom, left:right);
        colonyPatchAfter = plateImageAfter(top:bottom, left:right);

        t = graythresh(colonyPatch);
        segm = imbinarize(colonyPatch, t);
        
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
        
        
        meanColonyIntensity = mean( colonyPatch(segm) );
        meanBgIntensity = mean( colonyPatch(~segm) );
                
        meanColonyIntensityAfter = mean( colonyPatchAfter(segm) );
        meanBgIntensityAfter = mean( colonyPatchAfter(~segm) );
        
        measurements{i,j} = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensity, 'meanBgIntensity', meanBgIntensity);
        measurementsAfter{i,j} = struct('well', wellCode, 'meanColonyIntensity', meanColonyIntensityAfter, 'meanBgIntensity', meanBgIntensityAfter);
    end
end

if options.popupResults
    outlinedImage = plateImage;
    perim = bwperim(segmentation);
    perim = imdilate(perim, strel('disk', 1));
    outlinedImage(perim) = 255;
    outImage(:,:,2) = outlinedImage;
    outlinedImage(perim) = 0;
    outImage(:,:,1) = outlinedImage;
    outImage(:,:,3) = outlinedImage;
    f = figure(3); imshow(outImage);
else
    f =[];
end

end
