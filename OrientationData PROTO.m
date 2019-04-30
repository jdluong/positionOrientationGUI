preTrialBehavMatrix = OrganizeTrialData_SM(behavMatrix, behavMatrixColIDs, [-0.25 1.2], 'PokeIn');
ptOrient = ExtractTrialData_SM(preTrialBehavMatrix, orientMatrix(:,2:end)); %#ok<*NODEF>

corrTrlLog = [preTrialBehavMatrix.Performance];
isLog = [preTrialBehavMatrix.TranspositionDistance]==0;
odorLog = nan(4,length(preTrialBehavMatrix));
for o = 1:4
    odorLog(o,:) = [preTrialBehavMatrix.Odor]==o;
end

%%
figure;
sps = nan(1,4);
for o = 1:4
    curOrientOdor = cell2mat(ptOrient(odorLog(o,:) & corrTrlLog & isLog)');
    sps(o) = subplot(1,4,o);
    headX = curOrientOdor(~isnan(curOrientOdor(:,3)),3);
    headY = curOrientOdor(~isnan(curOrientOdor(:,4)),4);
    scatter(headX, headY, 'b');
    hold on;
    tailX = curOrientOdor(~isnan(curOrientOdor(:,5)),5);
    tailY = curOrientOdor(~isnan(curOrientOdor(:,6)),6);
    scatter(tailX, tailY, 'r');
end
linkaxes(sps, 'xy');

%%
xMax = max(get(sps(1), 'xlim'));
headXcol = strcmp(orientMatrixColIDs, 'HeadX');
tailXcol = strcmp(orientMatrixColIDs, 'TailX');
yMax = max(get(sps(1), 'ylim'));
headYcol = strcmp(orientMatrixColIDs, 'HeadY');
tailYcol = strcmp(orientMatrixColIDs, 'TailY');

numUnis = length(ensembleUnitSummaries);
% Gaussian used for calculating instantaneous firing rate
slideWindowSize = 200;
instFRgauss = gausswin(slideWindowSize);
instFRgauss = instFRgauss/(length(instFRgauss)*mode(diff(behavMatrix(:,1))));

uniInstFR = nan(size(ensembleMatrix,1), size(ensembleMatrix,2)-1);
for uni = 2:size(ensembleMatrix,2)
    uniInstFR(:,uni-1) = conv(ensembleMatrix(:,uni), instFRgauss, 'same');
end

headFRmap = nan(yMax, xMax, numUnis);
tailFRmap = nan(yMax, xMax, numUnis);

orientMatrix = round(orientMatrix);
xPosS = unique([orientMatrix(~isnan(orientMatrix(:,headXcol)),headXcol), orientMatrix(~isnan(orientMatrix(:,tailXcol)),tailXcol)]);
yPosS = unique([orientMatrix(~isnan(orientMatrix(:,headYcol)),headYcol), orientMatrix(~isnan(orientMatrix(:,tailYcol)),tailYcol)]);

for uni = 9:numUnis
    tic
    for x = 1:length(xPosS)
        curX = xPosS(x);
        for y = 1:length(yPosS)
            curY = yPosS(y);
            headPosMask = orientMatrix(:,headXcol)==curX & orientMatrix(:,headYcol)==curY;
            headFRmap(curY,curX,uni) = mean(uniInstFR(headPosMask, uni));
            tailPosMask = orientMatrix(:,tailXcol)==curX & orientMatrix(:,tailYcol)==curY;
            tailFRmap(curY,curX,uni) = mean(uniInstFR(tailPosMask, uni));
        end
    end
    
    figure;
    sp1 = subplot(1,2,1);
    imagesc(headFRmap(:,:,uni), [0 max([max(max(headFRmap(:,:,uni))), max(max(tailFRmap(:,:,uni)))])]);
    set(sp1, 'xlim', get(sps(1), 'xlim'), 'ylim', get(sps(1), 'ylim'), 'ydir', 'normal');
    title(sprintf('%s Head', ensembleMatrixColIDs{uni+1}));
    sp2 = subplot(1,2,2);
    imagesc(tailFRmap(:,:,uni), [0 max([max(max(headFRmap(:,:,uni))), max(max(tailFRmap(:,:,uni)))])]);
    set(sp2, 'xlim', get(sps(1), 'xlim'), 'ylim', get(sps(1), 'ylim'), 'ydir', 'normal');
    title(sprintf('%s Tail', ensembleMatrixColIDs{uni+1}));
    cmap = jet;
    cmap(1,:) = [1 1 1];
    colormap(cmap);
    toc
    drawnow
end
        