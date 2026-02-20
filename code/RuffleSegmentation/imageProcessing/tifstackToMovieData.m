%% tifstackToMovieData.m
% for ruffleSegmentation
% 5/2023


%% params

inputDir = fullfile('/endosome/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
    '/analysis/jungsik_raw/Tractin-mRuby2-CK666-COR-L23', ...
    '/02152024-downsampled-scale0p5-bilinear/CK666');

analysisDir = fullfile('/endosome/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
    '/analysis/jungsik/20230502_ActinPerturbations/Tractin-mRuby2', ...
    '/CK666/COR-L23/02152024/CK666');

fileReads = dir(inputDir);
ind = arrayfun(@(x) (x.isdir == 0), fileReads);     % only file index
fileNames = {fileReads(ind).name};                  % cell 
nFiles = numel(fileNames);
disp(nFiles)

%% Make MDs

MDs = cell(1);

for i = 1:nFiles
    
    %idstr = fileNames{i}((end-6):(end-4));
    [~, name, ~] = fileparts(fileNames{i});
    
    chantif = fullfile(inputDir, fileNames{i});
    mdDir = fullfile(analysisDir, name);
    if ~isfolder(mdDir); mkdir(mdDir); end

    % Construct md with 'importMetadata' == false
    mdnew = MovieData(chantif, false, mdDir);
    
    % Set the path where to store the MovieData object.
    mdnew.setPath(mdDir);
    mdnew.pixelSize_ = 220;
    mdnew.timeInterval_= 2; % in sec
    
    % to save to md.mat
    mdnew.sanityCheck; 
    MDs{i} = mdnew;
end

%% Create a movie list

mlDir = fullfile(analysisDir, 'MLmovies');
if ~isfolder(mlDir); mkdir(mlDir); end

ML = MovieList(MDs, mlDir);

% Set path properties
ML.setPath(mlDir);
ML.setFilename('movieList.mat');

% Save list
ML.save();
fprintf(1, 'Movie list saved under: %s\n', ML.getFullPath());

%% EOF
