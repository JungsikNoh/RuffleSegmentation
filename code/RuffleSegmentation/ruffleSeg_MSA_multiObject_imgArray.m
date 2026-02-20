function voteScoreImgs = ruffleSeg_MSA_multiObject_imgArray(imgArray, outputDir, varargin)
% 


ip = inputParser;
ip.addParameter('tightness', 0.5, @(x) isnumeric(x) && (x==-1 || x >= 0 || x<=1));
ip.addParameter('numVotes', -1);
ip.addParameter('imagesOut', 1);
ip.addParameter('figVisible', 'on');
ip.addParameter('finalRefinementRadius', 1);
ip.addParameter('MinimumSize', 10);
ip.addParameter('ObjectNumber', 1000);
ip.addParameter('LineWidth', 1);
ip.addParameter('LineAlpha', 0.2);
ip.addParameter('originalImages', []);
ip.addParameter('truncatedOutput', false);
ip.addParameter('movWindSize', []); 

ip.parse(varargin{:});
p = ip.Results;

if (p.numVotes > 0); p.tightness = -1; end

%% -------- Parameters ---------- %%

frmax = size(imgArray, 3);

if p.truncatedOutput
    truncatedPrefix = 'truncated_';
    deltaFr = round((p.movWindSize - 1)/2);
    outFr1 = min(deltaFr + 1, floor((frmax + 1)/2) );
    outFr2 = max(frmax - deltaFr, ceil((frmax + 1)/2) );
else
    truncatedPrefix = [];
    outFr1 = 1;
    outFr2 = frmax;
end

masksOutDir = fullfile(outputDir, [truncatedPrefix, 'Seg_masks']);
if ~isdir(masksOutDir); mkdir(masksOutDir); end
    
pString = 'mask_';      %Prefix for saving masks to file
 
%% Multi Scale Segmentation

refinedMask = cell(frmax, 1);
voteScoreImgs = cell(frmax, 1); 
currTightness = p.tightness;
currNumVotes = p.numVotes;

    parfor fr = outFr1:outFr2
        disp('=====')
        disp(['Frame: ', num2str(fr)])    
        im = imgArray(:, :, fr);
        [refinedMask{fr}, voteScoreImgs{fr}] = multiscaleSeg_multiObject_im(im, ...
            'tightness', currTightness, 'numVotes', currNumVotes, ...
            'finalRefinementRadius', p.finalRefinementRadius, ...
            'MinimumSize', p.MinimumSize, 'ObjectNumber', p.ObjectNumber);

        %Write the refined mask to file
        fname = [sprintf('%04d', fr), '.tif'];
        imwrite(mat2gray(refinedMask{fr}), fullfile(masksOutDir, [pString, fname]) );
    end

%% imagesOut

if p.imagesOut == 1

    if p.numVotes >= 0
        prefname = ['numVotes_', num2str(p.numVotes)];
    elseif p.tightness >= 0
        prefname = ['tightness_', num2str(p.tightness)];
    else 
        prefname = '_';
    end
       
    dName2 = [truncatedPrefix, 'MSASeg_maskedImages_', prefname];
    imOutDir = fullfile(outputDir, dName2);
    if ~isdir(imOutDir); mkdir(imOutDir); end

    allint = imgArray(:);
    intmin = quantile(allint, 0.001);
    intmax = quantile(allint, 0.999);
    fprintf('\n');
    disp(intmin); disp(intmax);

    ftmp = figure('Visible', p.figVisible);
    for fr = outFr1:outFr2
        figure(ftmp)
        imshow(imgArray(:,:,fr), [intmin, intmax])
        hold on
        bdd = bwboundaries(refinedMask{fr});
        
        for k = 1:numel(bdd)
            bdd1 = bdd{k};
            h = plot(bdd1(:,2), bdd1(:,1), 'Color', [1, 0, 0, p.LineAlpha]);
            h.LineWidth = p.LineWidth;
        end
        
        %bdd1 = bdd{1};
        %plot(bdd1(:,2), bdd1(:,1), 'r');
        hold off
        
        h = getframe(gcf);
        fname = [sprintf('%04d', fr), '.tif'];
        imwrite(h.cdata, fullfile(imOutDir, fname), 'tif')        
        fprintf(1, '%g ', fr); 
        if (mod(fr,50) == 0); fprintf('\n'); end 
    end

%  voteScoreImg
    imOutDir2 = fullfile(outputDir, 'MSASeg_voteScoreImgs');
    if ~isdir(imOutDir2); mkdir(imOutDir2); end   

    for fr = outFr1:outFr2
        fname = [sprintf('%04d', fr), '.tif'];
        imwrite(voteScoreImgs{fr}, fullfile(imOutDir2, ['voteScores_', fname]) );
    end
    
end

%% ruffle annotated original images

if ~isempty(p.originalImages)
    
    oriArray = p.originalImages;
    maskRuffles = zeros(size(oriArray));
    
    for fr = outFr1:outFr2
        maskRuffles(:, :, fr) = refinedMask{fr};
    end
    
    outname = [truncatedPrefix, 'ruffle_annotated_Images'];
    imOutDir = fullfile(outputDir, outname);
    if ~isfolder(imOutDir); mkdir(imOutDir); end

    allint = oriArray(:);
    intmin = quantile(allint, 0.001);
    intmax = quantile(allint, 0.999);

    ftmp = figure('Visible', p.figVisible);
    for fr = outFr1:outFr2
        figure(ftmp)
        imshow(oriArray(:,:,fr), [intmin, intmax])
        hold on
        bdd = bwboundaries(maskRuffles(:,:,fr));

        for k = 1:numel(bdd)
            bdd1 = bdd{k};
            h = plot(bdd1(:,2), bdd1(:,1), 'Color', [1, 0, 0, 0.2]);
            h.LineWidth = p.LineWidth;
        end
 
        hold off

        h = getframe(gcf);
        fname = [sprintf('%04d', fr), '.tif'];
        imwrite(h.cdata, fullfile(imOutDir, fname), 'tif')        
        fprintf(1, '%g ', fr); 
        if (mod(fr,50) == 0); fprintf('\n'); end 
    end
end

%%

disp('Multi-Scale Automatic Segmentation is done!')
disp('==:) close all')

end
