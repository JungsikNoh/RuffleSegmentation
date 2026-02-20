function ruffleSeg_Otsu_imgArray(imgArray, smSig, outputDir, varargin)
% 
%
% 2021/09/13, Jungsik Noh

ip = inputParser;
ip.addParameter('imagesOut', 1);
ip.addParameter('figVisible', 'on');
ip.addParameter('LineWidth', 1);
ip.addParameter('finalRefinementRadius', 1);
ip.parse(varargin{:});
p = ip.Results;

%% -------- Parameters ---------- %%

masksOutDir = fullfile(outputDir, 'Seg_masks');
if ~isdir(masksOutDir); mkdir(masksOutDir); end
    
pString = 'mask_';      %Prefix for saving masks to file 

%% Segmentation

frmax = size(imgArray, 3);
refinedMask = cell(frmax, 1); 

parfor fr = 1:frmax
    fprintf(1, '%g ', fr); 
    if (mod(fr,50) == 0); fprintf('\n'); end   
    currImage = imgArray(:,:,fr);
    
    if (smSig > 0)
        currImage = filterGauss2D(currImage, smSig);
    end
    
    thr = thresholdOtsu(currImage); 
    refinedMask{fr} = (currImage >= thr);

    %Write the refined mask to file
    fname = [sprintf('%04d', fr), '.tif'];
    imwrite(mat2gray(refinedMask{fr}), fullfile(masksOutDir, [pString, fname]) );
end

%% imagesOut

if p.imagesOut == 1
       
    dirName = ['Seg_maskedImages'];
    imOutDir = fullfile(outputDir, dirName);
    if ~isdir(imOutDir); mkdir(imOutDir); end

    allint = imgArray(:);
    intmin = quantile(allint, 0.001);
    intmax = quantile(allint, 0.9999);
    fprintf('\n');
    disp(intmin); disp(intmax);
    %intmin = min(allint); intmax = max(allint);

    ftmp = figure('Visible', p.figVisible);
    for fr = 1:frmax
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

%%

disp('ruffleSeg_simpleThresholding_imgArray is done!')
disp('==:) close all')

end
