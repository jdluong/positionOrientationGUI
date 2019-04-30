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
figure;
sps = nan(1,4);
for o = 1:4
    curOrientOdor = cell2mat(ptOrient(odorLog(o,:) & corrTrlLog & isLog)');
    sps(o) = subplot(1,4,o);
    headX = curOrientOdor(~isnan(curOrientOdor(:,4)),4);
    headY = curOrientOdor(~isnan(curOrientOdor(:,5)),5);
    scatter(headX, headY, 'b');
    hold on;
    tailX = curOrientOdor(~isnan(curOrientOdor(:,6)),6);
    tailY = curOrientOdor(~isnan(curOrientOdor(:,7)),7);
    scatter(tailX, tailY, 'r');
end
linkaxes(sps, 'xy');
