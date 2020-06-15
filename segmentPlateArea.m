function mask = segmentPlateArea(plateImageBefore, plateImageAfter)

% find inner part of the plate
plateImageBefore = im2double(plateImageBefore);

[~,~,d] = size(plateImageBefore);

if d>1
    plateImageBefore = rgb2gray(plateImageBefore);
end

threshold = graythresh(plateImageBefore);
BWBefore = im2bw(plateImageBefore, threshold);
BWBefore = imfill(BWBefore, 'holes');

plateImageAfter = im2double(plateImageAfter);

[~,~,d] = size(plateImageAfter);

if d>1
    plateImageAfter = rgb2gray(plateImageAfter);
end

threshold = graythresh(plateImageAfter);
BWAfter = im2bw(plateImageAfter, threshold);
BWAfter = imfill(BWAfter, 'holes');

% fit largest embedded rectangle in both images
LRoutBefore=LargestRectangle(BWBefore,0,0,0,0,0);
LRoutAfter=LargestRectangle(BWAfter,0,0,0,0,0);

% define area which contains both rectangles
bbox = [ min([LRoutBefore(2:end, 1); LRoutAfter(2:end, 1)]),...
         min([LRoutBefore(2:end, 2); LRoutAfter(2:end, 2)]),...
         max([LRoutBefore(2:end, 1); LRoutAfter(2:end, 1)]),...
         max([LRoutBefore(2:end, 2); LRoutAfter(2:end, 2)])];
     
mask = uint8(zeros(size(plateImageBefore)));
mask(bbox(2):bbox(4), bbox(1):bbox(3)) = 1;
