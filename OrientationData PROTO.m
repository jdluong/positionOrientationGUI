%%
portPosX = strcmp(orientMatrixColIDs, 'PortX');
portPosY = strcmp(orientMatrixColIDs, 'PortY');
headPosX = strcmp(orientMatrixColIDs, 'HeadX');
headPosY = strcmp(orientMatrixColIDs, 'HeadY');
tailPosX = strcmp(orientMatrixColIDs, 'TailX');
tailPosY = strcmp(orientMatrixColIDs, 'TailY');

portAngle = nan(size(orientMatrix,1),1);
headAngle = nan(size(orientMatrix,1),1);
tailAngle = nan(size(orientMatrix,1),1);

htVal = nan(size(orientMatrix,1),1);
hpVal = nan(size(orientMatrix,1),1);
ptVal = nan(size(orientMatrix,1),1);

posIndices = find(~isnan(orientMatrix(:,2)));

for pos = 1:length(posIndices)
    curPosNdx = posIndices(pos);
    curPortX = orientMatrix(curPosNdx, portPosX);
    curPortY = orientMatrix(curPosNdx, portPosY);
    curHeadX = orientMatrix(curPosNdx, headPosX);
    curHeadY = orientMatrix(curPosNdx, headPosY);
    curTailX = orientMatrix(curPosNdx, tailPosX);
    curTailY = orientMatrix(curPosNdx, tailPosY);
    
    htVal(curPosNdx) = sqrt((curTailX - curHeadX)^2 + (curTailY - curHeadY)^2);
    hpVal(curPosNdx) = sqrt((curPortX - curHeadX)^2 + (curPortY - curHeadY)^2);
    ptVal(curPosNdx) = sqrt((curTailX - curPortX)^2 + (curTailY - curPortY)^2);
    
    portAngle(curPosNdx) = rad2deg(acos((ptVal(curPosNdx)^2 + hpVal(curPosNdx)^2 - htVal(curPosNdx)^2)/(2*ptVal(curPosNdx)*hpVal(curPosNdx))));
    headAngle(curPosNdx) = rad2deg(acos((htVal(curPosNdx)^2 + hpVal(curPosNdx)^2 - ptVal(curPosNdx)^2)/(2*htVal(curPosNdx)*hpVal(curPosNdx))));
    tailAngle(curPosNdx) = rad2deg(acos((htVal(curPosNdx)^2 + ptVal(curPosNdx)^2 - hpVal(curPosNdx)^2)/(2*htVal(curPosNdx)*ptVal(curPosNdx))));    
end

orientMatrix = [orientMatrix, portAngle, headAngle, tailAngle, htVal, hpVal, ptVal];
orientMatrixColIDs = [orientMatrixColIDs, {'PortAngle'}, {'HeadAngle'}, {'TailAngle'}, {'HeadTailLength'}, {'HeadPortLength'}, {'PortTailLength'}];

%%
preTrialBehavMatrix = OrganizeTrialData_SM(behavMatrix, behavMatrixColIDs, [-0.25 1.2], 'PokeIn');
pokeInTimes = behavMatrix([preTrialBehavMatrix.PokeInIndex],1);
ptOrient = ExtractTrialData_SM(preTrialBehavMatrix, orientMatrix); %#ok<*NODEF>
for trl = 1:length(ptOrient)
    ptOrient{trl}(:,1) = ptOrient{trl}(:,1)-pokeInTimes(trl);
end

corrTrlLog = [preTrialBehavMatrix.Performance];
isLog = [preTrialBehavMatrix.TranspositionDistance]==0;
odorLog = nan(4,length(preTrialBehavMatrix));
for o = 1:4
    odorLog(o,:) = [preTrialBehavMatrix.Odor]==o;
end

%%
portPosX = strcmp(orientMatrixColIDs, 'PortX');
portPosY = strcmp(orientMatrixColIDs, 'PortY');
headPosX = strcmp(orientMatrixColIDs, 'HeadX');
headPosY = strcmp(orientMatrixColIDs, 'HeadY');
tailPosX = strcmp(orientMatrixColIDs, 'TailX');
tailPosY = strcmp(orientMatrixColIDs, 'TailY');

figure;
sps = nan(1,4);
for o = 1:4
    curOrientOdor = cell2mat(ptOrient(odorLog(o,:) & corrTrlLog & isLog)');
    sps(o) = subplot(1,4,o);
    headX = curOrientOdor(~isnan(curOrientOdor(:,headPosX)),headPosX);
    headY = curOrientOdor(~isnan(curOrientOdor(:,headPosY)),headPosY);
    scatter(headX, headY, 'b');
    hold on;
    tailX = curOrientOdor(~isnan(curOrientOdor(:,tailPosX)),tailPosX);
    tailY = curOrientOdor(~isnan(curOrientOdor(:,tailPosY)),tailPosY);
    scatter(tailX, tailY, 'r');
end
linkaxes(sps, 'xy');

%%
portAngleCol = strcmp(orientMatrixColIDs, 'PortAngle');
headAngleCol = strcmp(orientMatrixColIDs, 'HeadAngle');
tailAngleCol = strcmp(orientMatrixColIDs, 'TailAngle');
htCol = strcmp(orientMatrixColIDs, 'HeadTailLength');
hpCol = strcmp(orientMatrixColIDs, 'HeadPortLength');
ptCol = strcmp(orientMatrixColIDs, 'PortTailLength');

figure
sps = nan(1,9);
for angle = 1:3
    switch angle
        case 1
            curAngleData = orientMatrix(:, portAngleCol);
            xLbl = 'Port Angle';
        case 2
            curAngleData = orientMatrix(:, headAngleCol);
            xLbl = 'Head Angle';
        case 3
            curAngleData = orientMatrix(:, tailAngleCol);
            xLbl = 'Tail Angle';
    end
    for side = 1:3
        sps(sub2ind([3,3],angle,side)) = subplot(3,3,sub2ind([3,3],angle,side));
        switch side
            case 1
                curSideData = orientMatrix(:, htCol);
                yLbl = 'Head-Tail Distance';
            case 2
                curSideData = orientMatrix(:, hpCol);
                yLbl = 'Head-Port Distance';
            case 3
                curSideData = orientMatrix(:, ptCol);
                yLbl = 'Tail-Port Distance';
        end
%         curHist = histcounts2(curAngleData, curSideData, 200);
        histogram2(curAngleData, curSideData, 0:3:180, 0:3:140, 'DisplayStyle', 'tile');
        xlabel(xLbl);
        ylabel(yLbl);
    end
end
% cMax = 1;
% for plot = 1:9
%     curLims = get(sps(plot), 'clim');
%     cMax = max([cMax, curLims]);
% end
% for plot = 1:9
%     set(sps(plot), 'clim', [0 cMax]);
% end  
linkaxes(sps, 'xy');
colormap jet        
                
%%
slideWindowSize = 200;
instFRgauss = gausswin(slideWindowSize);
instFRgauss = instFRgauss/(length(instFRgauss)*mode(diff(behavMatrix(:,1))));

uniInstFR = nan(size(ensembleMatrix,1), size(ensembleMatrix,2)-1);
for uni = 2:size(ensembleMatrix,2)
    uniInstFR(:,uni-1) = conv(ensembleMatrix(:,uni), instFRgauss, 'same');
end

portAngleCol = strcmp(orientMatrixColIDs, 'PortAngle');
headAngleCol = strcmp(orientMatrixColIDs, 'HeadAngle');
tailAngleCol = strcmp(orientMatrixColIDs, 'TailAngle');
htCol = strcmp(orientMatrixColIDs, 'HeadTailLength');
hpCol = strcmp(orientMatrixColIDs, 'HeadPortLength');
ptCol = strcmp(orientMatrixColIDs, 'PortTailLength');

for uni = 1:size(uniInstFR,2)
    figure
    sps = nan(1,9);
    for angle = 1:3
        switch angle
            case 1
                curAngleData = orientMatrix(:, portAngleCol);
                xLbl = 'Port Angle';
            case 2
                curAngleData = orientMatrix(:, headAngleCol);
                xLbl = 'Head Angle';
            case 3
                curAngleData = orientMatrix(:, tailAngleCol);
                xLbl = 'Tail Angle';
        end
        for side = 1:3
            sps(sub2ind([3,3],angle,side)) = subplot(3,3,sub2ind([3,3],angle,side));
            switch side
                case 1
                    curSideData = orientMatrix(:, htCol);
                    yLbl = 'Head-Tail Distance';
                case 2
                    curSideData = orientMatrix(:, hpCol);
                    yLbl = 'Head-Port Distance';
                case 3
                    curSideData = orientMatrix(:, ptCol);
                    yLbl = 'Tail-Port Distance';
            end
            curSpkRateMap = nan(60);
            curAngleNdx = 0;
            for curAngle = 0:3:177
                curAngleBin = [curAngle curAngle+3];
                curAngleNdx = curAngleNdx + 1;
                curSideNdx = 0;
                for curSide = 0:3:177
                    curSideBin = [curSide curSide+3];
                    curSideNdx = curSideNdx + 1;
                    
                    curSpkRateMap(curSideNdx, curAngleNdx) = nanmean(uniInstFR((curAngleData>=curAngleBin(1) & curAngleData<curAngleBin(2)) &...
                        (curSideData>=curSideBin(1) & curSideData<curSideBin(2)),uni));
                end
            end     
            imagesc(curSpkRateMap);
            set(gca, 'ydir', 'normal', 'xtick', 0:10:60, 'xticklabel', 0:30:180,...
                'ytick', 0:10:60, 'yticklabel', 0:30:180);
            xlabel(xLbl);
            ylabel(yLbl);
            drawnow
        end
    end
    cMax = 1;
    for plot = 1:9
        curLims = get(sps(plot), 'clim');
        cMax = max([cMax, curLims]);
    end
    for plot = 1:9
        set(sps(plot), 'clim', [0 cMax]);
    end
    colormap jet    
    title(sps(1), ensembleMatrixColIDs(uni+1));
end

