%AUDIO SYNC ERROR CALCULATER

%Feed in audio recordings and automatically cross-correlate the
%synchronisation error between each 2 channels. Outputs and xcel file of
%all the sync spatial sync errors in cm.
clear all;
clc;

numrec = 12;
sampr = 44100;
soundspeed = 343;

%% Specifying file to be read
for x = 1:numrec
    Recording(:,x) = audioread(['rec (',num2str(x),').wav']);
end

%% Cross Correlate
disp('Calculating Sync Error');
n=1;
m = 2;
for n=1:numrec
    while m < numrec+1
    %Calculate the cross-cor at each lag%
    [Cross(n,m,:),Lag(n,m,:)] = xcorr(Recording(:,n), Recording(:,m));
    Cross(n,m,:) = Cross(n,m,:)/max(Cross(n,m,:));
    %Where in the matrix is the max cross-cor%
    [MaxCross(n,m),MaxLagCell(n,m)] = max(Cross(n,m,:));
    SyncError(n,m) = Lag(n,m, MaxLagCell(n,m)); %sample error%
    m = m+1;
    end
    m = n+2;
    disp([num2str(n),' processed']);
end
%Calculate the reverse to make sure cross correltate is running fine
% n = 1;
% m = 2;
% for n=1:numrec
%     while m < 13
%     %Calculate the cross-cor at each lag%
%     [CrossRev(n,m,:),LagRev(n,m,:)] = xcorr(Recording(:,m), Recording(:,n));
%     CrossRev(n,m,:) = CrossRev(n,m,:)/max(CrossRev(n,m,:));
%     %Where in the matrix is the max cross-cor%
%     [MaxCrossRev(n,m),MaxLagCellRev(n,m)] = max(CrossRev(n,m,:));
%     SyncErrorRev(n,m) = LagRev(n,m, MaxLagCellRev(n,m)); %sample error%
%     m = m+1;
%     end
%     m = n+2;
%     disp([num2str(n),' processed']);
% end

warning('off', 'MATLAB:xlswrite:AddSheet');
SpatialError =(SyncError/sampr)*soundspeed*100; %in cm
% rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
% cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
% table = array2table(SpatialError,'RowNames',rNames,'VariableNames',cNames)
table = array2table(SpatialError)
xfilename = 'SampSync.xlsx';
writetable(table, xfilename,'Sheet', 1)

%Check the reverse to see if crosscorreltaion gives accurate results for
%same 2 signals. 
% SpatialErrorRev =(SyncErrorRev/sampr)*343*100; %in cm
% rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
% cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
% tableRev = array2table(SpatialErrorRev,'RowNames',rNames,'VariableNames',cNames);
% writetable(tableRev, xfilename,'Sheet', 2) 