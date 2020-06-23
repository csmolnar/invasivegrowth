function mask = segmentPlateArea(plateImage)

% find inner part of the plate
plateImage = im2double(plateImage);

[~,~,d] = size(plateImage);

if d>1
    plateImage = rgb2gray(plateImage);
end

threshold = graythresh(plateImage);
BW = im2bw(plateImage, threshold);
BW = imfill(BW, 'holes');

% fit largest embedded rectangle in both images
LRout=LargestRectangle(BW,0,0,0,0,0);

% define area which contains both rectangles
bbox = [ min([LRout(2:end, 1)]),...
         min([LRout(2:end, 2)]),...
         max([LRout(2:end, 1)]),...
         max([LRout(2:end, 2)])];
     
mask = uint8(zeros(size(plateImage)));
mask(bbox(2):bbox(4), bbox(1):bbox(3)) = 1;
