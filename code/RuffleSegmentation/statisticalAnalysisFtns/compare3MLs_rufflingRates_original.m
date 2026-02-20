%% compare3MLs_rufflingRates.m
% for ruffleSegmentation
% 5/2023

%dir1 = fullfile('/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
%    '/analysis/jungsik/20230502_ActinPerturbations/Tractin-mRuby2/CK666/COR-L23/01102024/DMSO/MLmovies');

%ML.relocate(dir1, ...
%    fullfile('/endosome', dir1), 1)
%%
%ML.save()
%xxx
%ML.getMovies()
%ML.sanityCheck()


%% params

rootDir = fullfile('/endosome/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
    '/analysis/jungsik/20230502_ActinPerturbations/Tractin-mRuby2/CK666/COR-L23/02152024');

outputname = 'ML_compare';
outputDir = fullfile(rootDir, 'ML_compare_02232024');
if ~isfolder(outputDir); mkdir(outputDir); end

condName{1} = 'DMSO';
condName{2} = 'CK689';
condName{3} = 'CK666';

cond1MLdir = fullfile(rootDir, condName{1}, 'MLmovies');
cond2MLdir = fullfile(rootDir, condName{2}, 'MLmovies');
cond3MLdir = fullfile(rootDir, condName{3}, 'MLmovies');

MLs = cell(3, 1);

s1 = load(fullfile(cond1MLdir, 'movieList.mat'));
MLs{1} = s1.ML;
s2 = load(fullfile(cond2MLdir, 'movieList.mat'));
MLs{2} = s2.ML;
s3 = load(fullfile(cond3MLdir, 'movieList.mat'));
MLs{3} = s3.ML;


%% Get ruffling rates

ncond = numel(MLs);
meanRatesCell = cell(1, ncond);
medianRatesCell = cell(1, ncond);

for c = 1:ncond
    ML = MLs{c};
    numMDs = numel(ML.movieDataFile_);
    
    % load ML, example MD
    ML.getMovies();
    md1 = ML.getMovie(1);
    [~, cellLab0, ~] = fileparts(md1.outputDirectory_);

    % define output data
    cellLabels = cell(numMDs, 1);
    meanRate = nan(numMDs, 1);
    medianRate = nan(numMDs, 1);
    IDs = 1:numMDs;
    IDs = IDs(:);
    rufflingRatesTS = struct();
    
    for i = 1:numMDs
        mdi = ML.getMovie(i);
        [~, cellLabi, ~] = fileparts(mdi.outputDirectory_);
        cellLabels{i} = cellLabi;
        rateDir = fullfile(mdi.outputDirectory_, 'truncated_rufflingRates');
        S = load(fullfile(rateDir, 'rufflingStats.mat'));
        meanRate(i) = mean(S.rufflingRates, 'omitnan');
        medianRate(i) = median(S.rufflingRates, 'omitnan');
        rufflingRatesTS(i).cellLabels = cellLabi;
        rufflingRatesTS(i).rufflingRates = S.rufflingRates;
    end
    
    tab1 = cell2table(cellLabels);
    rufflingStatsTable = [table(IDs), tab1, table(meanRate, medianRate)];
    disp(rufflingStatsTable)
    
    % output
    meanRatesCell{c} = meanRate;
    medianRatesCell{c} = medianRate;
    save(fullfile(outputDir, [condName{c}, '_table.mat']), 'rufflingStatsTable');
    writetable(rufflingStatsTable, fullfile(outputDir, [condName{c}, '_table.csv']))
    
    save(fullfile(outputDir, [condName{c}, '_rufflingRatesTS.mat']), 'rufflingRatesTS')
end

% All ruffling rate means
save(fullfile(outputDir, ['allConditions_meanRatesCell.mat']), 'meanRatesCell')
save(fullfile(outputDir, ['allConditions_medianRatesCell.mat']), 'medianRatesCell')

%% Boxploting

mycell = meanRatesCell;

% my1byRcell2mat
lengths = cellfun(@numel, mycell);
matOut = nan(max(lengths), size(mycell, 2));
for i = 1:numel(lengths)
    matOut(1:lengths(i), i) = mycell{i};
end
disp(matOut)

% myBoxplot
fb = figure;
condNames = condName;

f1 = boxplot(matOut, 'Whisker', Inf, 'Labels', condNames);
hold on
mattmp = 0.05*randn(size(matOut));
mat2 = mattmp + [1:size(matOut, 2)];
s = scatter(mat2(:), matOut(:));
s.LineWidth = 0.6;
s.MarkerEdgeColor = 'w';
s.MarkerFaceColor = 'b';
%s.MarkerFaceColor = [0 0.5 0.5];
meanVec = nanmean(matOut, 1);
s2 = scatter(1:size(matOut,2), meanVec, 72, 'r+');

title(['mean ruffling rates per FOV'])
ylabel('Mean ruffling rates (%)')
ax = gca;
ax.FontSize = 14;

% save
saveas(fb, fullfile(outputDir, ['Boxplot_meanRates_', outputname, '.png']), 'png')
saveas(fb, fullfile(outputDir, ['Boxplot_meanRates_', outputname, '.fig']), 'fig')

%%  t-testing

disp('ttest2 1 vs 2')
[~, p12] = ttest2(mycell{1}, mycell{2})
disp('ttest2 1 vs 3')
[~, p13] = ttest2(mycell{1}, mycell{3})
disp('ttest2 2 vs 3')
[~, p23] = ttest2(mycell{2}, mycell{3})

pvalueTable = table(p12, p13, p23, 'VariableNames', {'ttest2 1 vs 2', 'ttest2 1 vs 3', 'ttest2 2 vs 3'});

% save
save(fullfile(outputDir, 'meanRates_ttest_pvalues.mat'), 'pvalueTable');
writetable(pvalueTable, fullfile(outputDir, 'meanRates_ttest_pvalues.csv'))

%% Boxplot + p-value

fb2 = figure(fb);
title({  ['ttest2 1 vs 2: ', num2str(round(p12, 6))], 
    ['ttest2 1 vs 3: ', num2str(round(p13, 6))],
    ['ttest2 2 vs 3: ', num2str(round(p23, 6))]  })

% save
saveas(fb2, fullfile(outputDir, ['Boxplot_wPval_meanRates_', outputname, '.png']), 'png')
saveas(fb2, fullfile(outputDir, ['Boxplot_wPval_meanRates_', outputname, '.fig']), 'fig')

%% Boxploting

mycell = medianRatesCell;

% my1byRcell2mat
lengths = cellfun(@numel, mycell);
matOut = nan(max(lengths), size(mycell, 2));
for i = 1:numel(lengths)
    matOut(1:lengths(i), i) = mycell{i};
end
disp(matOut)

% myBoxplot
fb = figure;
condNames = condName;

f1 = boxplot(matOut, 'Whisker', Inf, 'Labels', condNames);
hold on
mattmp = 0.05*randn(size(matOut));
mat2 = mattmp + [1:size(matOut, 2)];
s = scatter(mat2(:), matOut(:));
s.LineWidth = 0.6;
s.MarkerEdgeColor = 'w';
s.MarkerFaceColor = 'b';
%s.MarkerFaceColor = [0 0.5 0.5];
meanVec = nanmean(matOut, 1);
s2 = scatter(1:size(matOut,2), meanVec, 72, 'r+');

title(['median ruffling rates per FOV'])
ylabel('Median ruffling rates (%)')
ax = gca;
ax.FontSize = 14;

% save
saveas(fb, fullfile(outputDir, ['Boxplot_medianRates_', outputname, '.png']), 'png')
saveas(fb, fullfile(outputDir, ['Boxplot_medianRates_', outputname, '.fig']), 'fig')

%%  t-testing

disp('ttest2 1 vs 2')
[~, p12] = ttest2(mycell{1}, mycell{2})
disp('ttest2 1 vs 3')
[~, p13] = ttest2(mycell{1}, mycell{3})
disp('ttest2 2 vs 3')
[~, p23] = ttest2(mycell{2}, mycell{3})

pvalueTable = table(p12, p13, p23, 'VariableNames', {'ttest2 1 vs 2', 'ttest2 1 vs 3', 'ttest2 2 vs 3'});

% save
save(fullfile(outputDir, 'medianRates_ttest_pvalues.mat'), 'pvalueTable');
writetable(pvalueTable, fullfile(outputDir, 'medianRates_ttest_pvalues.csv'))

%% Boxplot + p-value

fb2 = figure(fb);
title({  ['ttest2 1 vs 2: ', num2str(round(p12, 6))], 
    ['ttest2 1 vs 3: ', num2str(round(p13, 6))],
    ['ttest2 2 vs 3: ', num2str(round(p23, 6))]  })

% save
saveas(fb2, fullfile(outputDir, ['Boxplot_wPval_medianRates_', outputname, '.png']), 'png')
saveas(fb2, fullfile(outputDir, ['Boxplot_wPval_medianRates_', outputname, '.fig']), 'fig')

%%
disp('==== compare3MLs_rufflingRates is completed! ====')

%% EOF