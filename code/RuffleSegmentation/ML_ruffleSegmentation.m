function ML_ruffleSegmentation(ML, MDindex, varargin)
% ML_ruffleSegmentation segments ruffles and cell bodies from 2D time lapse
% images. This is a wrapper function of ruffleSegmentation() to process a
% list of movies. 
%
% Usage:
%   for i = 1:numel(ML.movieDataFile_);ML_ruffleSegmentation(ML, i); end
%   Or with specified parameters
%   for i = 1:numel(ML.movieDataFile_);ML_ruffleSegmentation(ML, i, 'movWindSize', 31, 'normalizedImages_MSA_numVotes', 40, 'rawImages_MSA_numVotes', 25); end

%% Parse parameters

ip = inputParser;
ip.addParameter('movWindSize', 31);
ip.addParameter('normalizedImages_MSA_numVotes', 40);
ip.addParameter('rawImages_MSA_numVotes', 22);
ip.parse(varargin{:});
p = ip.Results;

%% Load movie data

disp(ML.movieListPath_) 
disp(['MDindex:', num2str(MDindex)])
disp(ML.movieDataFile_{MDindex})
load(ML.movieDataFile_{MDindex})    % movieData.mat -> MD

% save parameters
rawImages_MSA_numVotes = p.rawImages_MSA_numVotes;
save(fullfile(ML.movieListPath_, 'ML_ruffleSegmentation_par.mat'), 'p', 'rawImages_MSA_numVotes');

%% Run ruffleSegmentation for each MD 

ruffleSegmentation(MD, 'movWindSize', p.movWindSize, ...
                        'normalizedImages_MSA_numVotes', p.normalizedImages_MSA_numVotes, ...
                        'rawImages_MSA_numVotes', p.rawImages_MSA_numVotes)

end
