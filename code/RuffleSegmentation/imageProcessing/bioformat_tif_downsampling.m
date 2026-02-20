%% bioformat_tif_downsampling.m
% for ruffleSegmentation
% 5/2023

%% params

inputDir = fullfile('/archive/bioinformatics/Danuser_lab/Ras', ...
    '/ImagesandData/Dataanalysis/DataForRuggleQuantificationIn2D', ...
    '/ActinPerturbations/Tractin-mRuby2/CK666/SU8686/NikonLiveEpifluorescence/06192023/CK666');

outputDir = fullfile('/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
    '/analysis/jungsik_raw/Tractin-mRuby2-CK666-SU8686', ...
    '/06192023-downsampled-scale0p5-bilinear/CK666');

if ~isfolder(outputDir); mkdir(outputDir); end

fileReads = dir(inputDir);
ind = arrayfun(@(x) (x.isdir == 0), fileReads);     % only file index
fileNames = {fileReads(ind).name};                  % cell 
nFiles = numel(fileNames);

%% read bioformat tifs - locate to the input folder

for i = 1:nFiles
    
    imFilename = fileNames{i};
    imInfo = imfinfo(imFilename);
    frmax = numel(imInfo);
    imgArray = [];
    for fr = 1:frmax
        tmp = imread(imFilename, fr);
        imgArray = cat(3, imgArray, tmp);
        fprintf(1, '%g', fr);
        if (mod(fr, 50) == 0); fprintf('\n'); end
    end
    fprintf('\n');

    %% downsampling

    imgArray2 = [];
    for fr = 1:frmax
        tmp = imresize(imgArray(:,:,fr), 0.5, 'bilinear');
        imgArray2 = cat(3, imgArray2, tmp);
    end

    %% write images

    fpath = fullfile(outputDir, imFilename);
    tmp = imgArray2(:,:,1);
    imwrite(tmp, fpath);
    for fr = 2:frmax
       tmp = imgArray2(:,:,fr);
       imwrite(tmp, fpath, "WriteMode","append");
    end

end

%
disp('====')
disp('==== downsampling finished')


%% EOF