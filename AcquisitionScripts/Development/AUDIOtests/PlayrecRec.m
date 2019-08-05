
clear all;

%Before executing this script please double check the channels that you
%will be using. You can do this by launching the spectrum analyser with the
%first argumen tbeing the device ID and the second being the channel list. 
%Which Microphones are you using%
MicChan = [7 8 9 10 13 14 15 16 17 18 19 20];
seconds = 10; %How long will the recording be%
sampr = 44100; %Sample Rate%



if (playrec('isInitialised')) == 1
    playrec('reset');
end
disp('First let us look for some ASIO devices')
devices = playrec('getDevices');
[q,N] = size(devices);

asioFound = 0;
for n=1:N
    if strcmp(devices(n).hostAPI, 'ASIO')
        foundDevices(asioFound + 1) = devices(n).deviceID;
        disp('I found this:')
        disp(devices(n))
        asioFound = asioFound + 1;
    end
end

switch asioFound
    case 0
        disp('I could not find any ASIO devices')
        return
    case 1
        disp('I found exactly one ASIO device')
        setdevice = input('Do you want me to set this as the device? [y,n]', 's');
        switch setdevice
            case 'y'
                defaultID = foundDevices;
                disp(['Setting ', num2str(defaultID),' as the default recording device'])
            otherwise
                defaultID = input('Which device ID do you want to use:');
        end
    otherwise
        disp('I found multiple ASIO devices, please choose which one to use')
        disp(foundDevices)
        defaultID = input('Which device ID do you want to use:');
end
dorec = input(['Should I start recording from the ', num2str(12), ' channels for ', num2str(seconds), ' second?[y,n]'], 's');
if dorec == 'y'
else
    return
end

disp('I will start recording in 10 seconds, counting down:');
for countdown = 10:-1:1
    disp(countdown);
    pause(1);
end
T1 = posixtime(datetime('now'));
playrec('init', sampr, -1, defaultID);
duration = sampr*seconds;
T2 = posixtime(datetime('now'));
playrec('rec',duration,MicChan);
disp('Recording...')
TPlay = playrec('getStreamStartTime') + 3600;
while (playrec('isFinished') ~= 1)
end
disp('Finished Recording')
Recording = playrec('getRec',0);

% disp('Saving files');
%timenow = datestr(now,'hhMMss_ddmm');
%     foldername = ['PlayRec_', timenow];
%     mkdir(foldername);
%     for x=1:12
%         filename = ['plrec_',num2str(x),'.wav'];
%         directory = [foldername, '\', filename];
%         audiowrite(directory,Recording(:,x),sampr);
%     end


% disp('Calculating Sync Error');
% n=1;
% m = 2;
% for n=1:12
%     while m < 13
%     %Calculate the cross-cor at each lag%
%     [Cross(n,m,:),Lag(n,m,:)] = xcorr(Recording(:,n), Recording(:,m));
%     Cross(n,m,:) = Cross(n,m,:)/max(Cross(n,m,:));
%     %Where in the matrix is the max cross-cor%
%     [MaxCross(n,m),MaxLagCell(n,m)] = max(Cross(n,m,:));
%     SyncError(n,m) = Lag(n,m, MaxLagCell(n,m)); %sample error%
%     m = m+1;
%     end
%     m = n+2;
%     disp([num2str(n),' of 12 processed']);
% end
% n = 1;
% m = 2;
% for n=1:12
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
%     disp([num2str(n),' of 12 processed']);
% end
% 
% % warning('off', 'MATLAB:xlswrite:AddSheet');
% % SpatialError =(SyncError/sampr)*343*100; %in cm
% % rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
% % cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
% % table = array2table(SpatialError,'RowNames',rNames,'VariableNames',cNames);
% % xfilename = ['PlaySync', timenow,'.xlsx'];
% % writetable(table, xfilename,'Sheet', 1)
% 
% SpatialErrorRev =(SyncErrorRev/sampr)*343*100; %in cm
% rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
% cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
% tableRev = array2table(SpatialErrorRev,'RowNames',rNames,'VariableNames',cNames);
% writetable(tableRev, xfilename,'Sheet', 2)
% 