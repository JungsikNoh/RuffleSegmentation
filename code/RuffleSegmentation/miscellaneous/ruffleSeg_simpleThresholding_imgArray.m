function ruffleSeg_simpleThresholding_imgArray(imgArray, smSig, thr, outputDir, varargin)
% 
%
% 2021/09/13, Jungsik Noh

ip = inputParser;
ip.addParameter('imagesOut', 1);
ip.addParameter('figVisible', 'on');
ip.addParameter('finalRefinementRadius', 1);
ip.addParameter('LineWidth', 1);
ip.addParameter('originalImages', []);
ip.addParameter('truncatedOutput', false);
ip.addParameter('movWindSize', []);

ip.parse(varargin{:});
p = ip.Results;

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

%% Segmentation


refinedMask = cell(frmax, 1); 

parfor fr = outFr1:outFr2
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end   
    currImage = imgArray(:,:,fr);
    
    if (smSig > 0)
        currImage = filterGauss2D(currImage, smSig);
    end
    
    refinedMask{fr} = (currImage >= thr);

    %Write the refined mask to file
    fname = [sprintf('%04d', fr), '.tif'];
    imwrite(mat2gray(refinedMask{fr}), fullfile(masksOutDir, [pString, fname]) );
end

%% imagesOut

if p.imagesOut == 1
       
    dirName = [truncatedPrefix, 'Seg_maskedImages'];
    imOutDir = fullfile(outputDir, dirName);
    if ~isdir(imOutDir); mkdir(imOutDir); end

    allint = imgArray(:);
    intmin = quantile(allint, 0.001);
    intmax = quantile(allint, 0.999);
    fprintf('\n');
    disp(intmin); disp(intmax);
    %intmin = min(allint); intmax = max(allint);

    ftmp = figure('Visible', p.figVisible);
    for fr = outFr1:outFr2
        figure(ftmp)
        imshow(imgArray(:,:,fr), [intmin, intmax])
        hold on
        bdd = bwboundaries(refinedMask{fr});
        
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

disp('ruffleSeg_simpleThresholding_imgArray is done!')
disp('==:) close all')

end
