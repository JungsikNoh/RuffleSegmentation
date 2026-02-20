function ruffleSegmentation(MD, varargin)
% ruffleSegmentation segments ruffles and cell bodies from 2D time lapse images. Input is a
% movieData (MD). Output includes a ruffling rate time series and a mean
% ruffling rate per movie.
%
% Usage:
%   ruffleSegmentation(MD)      % using default parameters
%   or 
%   ruffleSegmentation(MD, 'movWindSize', 31, 'normalizedImages_MSA_numVotes', 40, 'rawImages_MSA_numVotes', 25)
%
% Options:
%       movWindSize         
%           - moving window size in frames to compute moving medians. Default 31 frames.
%       normalizedImages_MSA_numVotes
%           - numVotes parameter for MSA to segment moving median normalized images. 
%           - 0< numVotes <= 42, default = 40.
%       rawImages_MSA_numVotes
%           - numVotes parameter for MSA to get cell masks from raw images.
%           - Default = 21.
%
% Updates:
% 10/2023, Noh: Remove small objects (debris) from mask segmentation by
% setting  'MinimumSize' = 1000
%
% Jungsik Noh, 5/2023

%% Parse parameters

ip = inputParser;
ip.addParameter('movWindSize', 31);
ip.addParameter('normalizedImages_MSA_numVotes', 40);
ip.addParameter('rawImages_MSA_numVotes', 22);
ip.parse(varargin{:});
p = ip.Results;

% save parameters
rawImages_MSA_numVotes = p.rawImages_MSA_numVotes;
save(fullfile(MD.movieDataPath_, 'ruffleSegmentation_par.mat'), 'p', 'rawImages_MSA_numVotes');

%% Load raw images

imgArray = uint16(zeros(MD.imSize_(1), MD.imSize_(2), MD.nFrames_));

disp('======')
disp('Loading frames:')

parfor fr=1:MD.nFrames_
    currImage = uint16(MD.channels_(1).loadStack(fr));
    imgArray(:,:,fr) = currImage;
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end    
end
fprintf(1, '\n')

%% plot mean image

meanImg = mean(imgArray, 3);
fmean = figure; imagesc(meanImg); colormap(jet)
% save
saveas(fmean, fullfile(MD.outputDirectory_, 'meanImage.png'), 'png')
saveas(fmean, fullfile(MD.outputDirectory_, 'meanImage.fig'), 'fig')

%% Compute (temporal) moving medians 
 
movmedianArray = movmedian(imgArray, p.movWindSize, 3);

%% Save movmedianImages

outtmp = fullfile(MD.outputDirectory_, 'movmedianImages');
if ~isfolder(outtmp); mkdir(outtmp); end

for fr = 1:size(imgArray, 3)
    tmpim = movmedianArray(:,:,fr);
    imwrite(tmpim, fullfile(outtmp, ['movmedianImages_', sprintf('%04d', fr), '.tif']), 'tif')
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end 
end
fprintf('\n')

%% Compute movmed normalized images

normedArray = uint16(round((double(imgArray) ./ double(movmedianArray)) * 100));

%% Save normalizedImages

outtmp = fullfile(MD.outputDirectory_, 'movMedian_normalizedImages');
if ~isfolder(outtmp); mkdir(outtmp); end

for fr = 1:size(imgArray, 3)
    tmpim = normedArray(:,:,fr);
    imwrite(tmpim, fullfile(outtmp, ['normalizedImages_', sprintf('%04d', fr), '.tif']), 'tif')
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end 
end
fprintf('\n')

%% Segment ruffles using MSA

outputDir = fullfile(MD.outputDirectory_, 'normalizedImages_MSA');

ruffleSeg_MSA_multiObject_imgArray(normedArray, outputDir, ...
                                    'numVotes', p.normalizedImages_MSA_numVotes, ...
                                    'MinimumSize', 5, ...
                                    'finalRefinementRadius', 0, ...
                                    'LineWidth', 2, ...
                                    'originalImages', imgArray, ...
                                    'truncatedOutput', true, ...
                                    'movWindSize', p.movWindSize)

%% Log-transform images

logImgArray = log(double(1 + imgArray));
m0 = mean(imgArray(:));
m1 = mean(logImgArray(:));

logImgArray2 = uint16(logImgArray .* m0/m1);

%% BG substraction

bg = imgArray;
for fr = 1:size(imgArray, 3)
    bg(:,:,fr) = imgaussfilt(logImgArray2(:,:,fr), 100);
end
%figure, imagesc(bg(:,:,1)), colormap(jet)

%logImgArray3 = logImgArray2 - bg + mean(double(bg(:)));
logImgArray3 = logImgArray2 - bg + mean(double(bg(:)));
%figure, imagesc(logImgArray3(:,:,1)), colormap(jet)

%% Save raw_transformed images

outtmp = fullfile(MD.outputDirectory_, 'raw_transformed');
if ~isfolder(outtmp); mkdir(outtmp); end

for fr = 1:size(imgArray, 3)
    tmpim = logImgArray3(:,:,fr);
    imwrite(tmpim, fullfile(outtmp, ['raw_transformed_', sprintf('%04d', fr), '.tif']), 'tif')
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end 
end
fprintf('\n')                                
                                
%% Segment cell masks to quantify ruffling rates

outputDir = fullfile(MD.outputDirectory_, 'raw_transformed_MSA');

voteScoreImgs = ruffleSeg_MSA_multiObject_imgArray(logImgArray3, outputDir, ...
                                    'numVotes', p.rawImages_MSA_numVotes, ...
                                    'MinimumSize', 1000, ...
                                    'finalRefinementRadius', 3, ...
                                    'LineWidth', 0.5, ...
                                    'LineAlpha', 1, ...
                                    'ObjectNumber', 100, ...
                                    'truncatedOutput', true, ...
                                    'movWindSize', p.movWindSize);

%% Compute ruffling rate time series

cellSegOutDir = fullfile(MD.outputDirectory_, 'raw_transformed_MSA', 'truncated_Seg_masks');
ruffleSegOutDir = fullfile(MD.outputDirectory_, 'normalizedImages_MSA', 'truncated_Seg_masks');

% read cellMasks
fileReads = dir(cellSegOutDir);
ind = arrayfun(@(x) (x.isdir == 0), fileReads);
fileNames = {fileReads(ind).name};
frmax = numel(fileNames);
cellMasks = [];
for fr = 1:frmax
    tmp = imread(fullfile(cellSegOutDir, fileNames{fr}));
    cellMasks = cat(3, cellMasks, tmp);
    fprintf(1, '%g ', fr);
    if (mod(fr,50) == 0); fprintf('\n'); end 
end

% read ruffleMasks
fileReads = dir(ruffleSegOutDir);
ind = arrayfun(@(x) (x.isdir == 0), fileReads);
fileNames = {fileReads(ind).name};
frmax = numel(fileNames);
ruffleMasks = [];
for fr = 1:frmax
    tmp = imread(fullfile(ruffleSegOutDir, fileNames{fr}));
    ruffleMasks = cat(3, ruffleMasks, tmp);
    fprintf(1, '%g ', fr);
    if (mod(fr,50) == 0); fprintf('\n'); end 
end

if any(size(cellMasks) ~= size(ruffleMasks)) 
    error('Error: Dimensions of cellMasks and ruffleMasks are different!')
end
% convert to logical
cellMasks = (cellMasks > 0);
ruffleMasks = (ruffleMasks > 0);
intersect1 = cellMasks .* ruffleMasks;

rufflingRates = zeros(1, frmax);
tmpcell = reshape(cellMasks, [], frmax);
cellAreaTS = sum(tmpcell, 1);
tmpruffleIntersect = reshape(intersect1, [], frmax);
ruffleAreaTS = sum(tmpruffleIntersect, 1);
rufflingRates = ruffleAreaTS ./ cellAreaTS * 100;
f1 = figure;
plot(rufflingRates)
xlabel('Frame'); ylabel('Ruffling Rate (%)')
m1 = mean(rufflingRates, 'omitnan'); med1 = median(rufflingRates, 'omitnan');
title(['mean: ', num2str(m1), ' median: ', num2str(med1)])

%% Save rufflingRates stats

outDir = fullfile(MD.outputDirectory_, 'truncated_rufflingRates');
if ~isfolder(outDir); mkdir(outDir); end   

saveas(f1, fullfile(outDir, 'rufflingRates_TS.png'), 'png')
saveas(f1, fullfile(outDir, 'rufflingRates_TS.fig'), 'fig')
save(fullfile(outDir, 'rufflingStats.mat'), ...
            'cellMasks', 'ruffleMasks', 'intersect1', ...
            'cellAreaTS', 'ruffleAreaTS', 'rufflingRates')

%
disp(' ')
disp('==== ruffleSegmentation is completed! ====')        
        
end