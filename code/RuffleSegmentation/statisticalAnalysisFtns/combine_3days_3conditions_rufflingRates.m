%% combine_3days_3conditions_rufflingRates.m
% for ruffleSegmentation
% 7/12/2023, J Noh


%% params

%palette = ["#F72585", "#7209B7", "#3A0CA3", "#4361EE", "#4CC9F0"];

rootDir = fullfile('/archive/bioinformatics/Danuser_lab/Ras/ImagesandData', ...
    '/analysis/jungsik/20230502_ActinPerturbations/Tractin-mRuby2', ...
    '/CK666/SU8686');

d1name = '06092023';
d2name = '06182023';
d3name = '06192023';
d1Dir = fullfile(rootDir, d1name, 'ML_compare_05052023');
d2Dir = fullfile(rootDir, d2name, 'ML_compare_05052023');
d3Dir = fullfile(rootDir, d3name, 'ML_compare_05052023');

outputname = '3daysCombined_06091819';
outputDir = fullfile(rootDir, outputname);
if ~isfolder(outputDir); mkdir(outputDir); end

condName{1} = 'DMSO';
condName{2} = 'CK689';
condName{3} = 'CK666'; 

meanCells = cell(3, 1);

input1 = load(fullfile(d1Dir, 'allConditions_meanRatesCell.mat'));
meanCells{1} = input1.meanRatesCell;
input2 = load(fullfile(d2Dir, 'allConditions_meanRatesCell.mat'));
meanCells{2} = input2.meanRatesCell;
input3 = load(fullfile(d3Dir, 'allConditions_meanRatesCell.mat'));
meanCells{3} = input3.meanRatesCell;


%% Combine mean ruffling rates

combinedMeanRates = cell(1, 3);
combinedDayId = cell(1, 3);

for cond = 1:3
    tmp1 = [];
    dayVec1 = [];
    for dayId = 1:3
       tmp = meanCells{dayId}{cond}; 
       tmp1 = [tmp1; tmp]; 
       dayVec = repmat(dayId, size(tmp));
       dayVec1 = [dayVec1; dayVec];
    end
    combinedMeanRates{cond} = tmp1;
    combinedDayId{cond} = dayVec1;
end

% All ruffling rate means
save(fullfile(outputDir, 'combinedMeanRates.mat'), 'combinedMeanRates', 'combinedDayId', 'meanCells')

%%  t-testing

mycell = combinedMeanRates;

disp('ttest2 1 vs 2')
[~, p12] = ttest2(mycell{1}, mycell{2})
disp('ttest2 1 vs 3')
[~, p13] = ttest2(mycell{1}, mycell{3})
disp('ttest2 2 vs 3')
[~, p23] = ttest2(mycell{2}, mycell{3})

pvalueTable = table(p12, p13, p23, 'VariableNames', {'ttest2 1 vs 2', 'ttest2 1 vs 3', 'ttest2 2 vs 3'});
disp(pvalueTable)

% save
save(fullfile(outputDir, 'ttest_pvalues.mat'), 'pvalueTable');
writetable(pvalueTable, fullfile(outputDir, 'ttest_pvalues.csv'))


%% Boxploting (1)

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

%title(['mean ruffling rates per FOV'])
ylabel('Mean ruffling rates (%)')
ax = gca;
ax.FontSize = 14;

title({  ['ttest2 1 vs 2: ', num2str(round(p12, 6))], 
    ['ttest2 1 vs 3: ', num2str(round(p13, 6))],
    ['ttest2 2 vs 3: ', num2str(round(p23, 6))]  })

% save
saveas(fb, fullfile(outputDir, ['Boxplot_', outputname, '.png']), 'png')
saveas(fb, fullfile(outputDir, ['Boxplot_', outputname, '.fig']), 'fig')


%% Boxploting (2) - per-day coloring

mycell = combinedMeanRates;

% my1byRcell2mat
lengths = cellfun(@numel, mycell);
matOut = nan(max(lengths), size(mycell, 2));
for i = 1:numel(lengths)
    matOut(1:lengths(i), i) = mycell{i};
end
disp(matOut)

% per-day matrixes
matOutDay = cell(3, 1);

for dayId = 1:3
    mycell = meanCells{dayId};
    
    lengths = cellfun(@numel, mycell);
    matOutDay{dayId} = nan(max(lengths), size(mycell, 2));
    for i = 1:numel(lengths)
        matOutDay{dayId}(1:lengths(i), i) = mycell{i};
    end
    disp(matOutDay{dayId})    
end

% myBoxplot

mycolors = ['b', 'g', 'r'];

fb = figure;
condNames = condName;

f1 = boxplot(matOut, 'Whisker', Inf, 'Labels', condNames);
hold on

legend0 = {'Day1', 'Day2', 'Day3'};

for dayId = 1:3
    mattmp = 0.1*randn(size(matOutDay{dayId}));
    mat2 = mattmp + [1:size(matOutDay{dayId}, 2)];
    s = scatter(mat2(:), matOutDay{dayId}(:));

    s.LineWidth = 0.6;
    s.MarkerEdgeColor = 'w';
    s.MarkerFaceColor = mycolors(dayId);
end


%legend();

meanVec = nanmean(matOut, 1);
s2 = scatter(1:size(matOut,2), meanVec, 72, 'r+');

title(['Mean ruffling rates per FOV'])
ylabel('Mean ruffling rates (%)')
ax = gca;
ax.FontSize = 14;

ylim0 = ax.YLim;
ax.YLim = [ylim0(1), ylim0(2) * 1.5];


%% Indicate significance

hold on

y1 = ylim0(2) * 1.1;
l1 = plot([1, 2], [y1, y1], 'k');

y2 = ylim0(2) * 1.3;
l1 = plot([1, 3], [y2, y2], 'k');

x0 = 1.4;
y0 = ylim0(2) * 1.15;
if (p12 < 0.01)
    text(x0, y0, '**', 'FontSize',14);
elseif (p12 < 0.05)
    text(x0, y0, '*', 'FontSize',14);
else
    text(x0, y0, 'n.s.', 'FontSize',14);
end

x0 = 1.9;
y0 = ylim0(2) * 1.35;
if (p13 < 0.01)
    text(x0, y0, '**', 'FontSize',14);
elseif (p13 < 0.05)
    text(x0, y0, '*', 'FontSize',14);
else
    text(x0, y0, 'n.s.', 'FontSize',14);
end

legend({'Day1', 'Day2', 'Day3'}, 'Location', 'eastoutside');
    
%% save

saveas(fb, fullfile(outputDir, ['Boxplot2_', outputname, '.png']), 'png')
saveas(fb, fullfile(outputDir, ['Boxplot2_', outputname, '.fig']), 'fig')

%%
disp('==== combine_3days_3conditions_rufflingRates is completed! ====')



%% EOF