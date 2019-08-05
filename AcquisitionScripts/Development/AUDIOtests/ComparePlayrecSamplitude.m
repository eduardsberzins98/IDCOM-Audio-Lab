%Compare Playrec's synchronisation error with Samplitude's synchronisation
%error

clear all;
clc;

%% Samplitude Sync Error
Recording(:,1) = audioread('NEW_01_M24.wav');
Recording(:,2) = audioread('NEW_02_M24.wav');
Recording(:,3) = audioread('NEW_03_M24.wav');
Recording(:,4) = audioread('NEW_04_M24.wav');
Recording(:,5) = audioread('NEW_05_M24.wav');
Recording(:,6) = audioread('NEW_06_M24.wav');
Recording(:,7) = audioread('NEW_07_M24.wav');
Recording(:,8) = audioread('NEW_08_M24.wav');
Recording(:,9) = audioread('NEW_09_M24.wav');
Recording(:,10) = audioread('NEW_10_M24.wav');
Recording(:,11) = audioread('NEW_11_M24.wav');
Recording(:,12) = audioread('NEW_12_M24.wav');
sampr = 44100;
m = 2;
for n=1:12
    while m < 13
    %Calculate the cross-cor at each lag%
    [Cross(n,m,:),Lag(n,m,:)] = xcorr(Recording(:,n), Recording(:,m));
    Cross(n,m,:) = Cross(n,m,:)/max(Cross(n,m,:));
    %Where in the matrix is the max cross-cor%
    [MaxCross(n,m),MaxLagCell(n,m)] = max(Cross(n,m,:));
    SyncError(n,m) = Lag(n,m, MaxLagCell(n,m)); %sample error%
    m = m+1;
    end
    m = n+2;
    disp([num2str(n),' of 12 processed']);
end
SpatialErrorSamp = abs((SyncError/sampr)*343*100); %in cm
%% Record my audio
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
playrec('init', sampr, -1, defaultID);
duration = sampr*seconds;
playrec('rec',duration,MicChan);
disp('Recording...')
while (playrec('isFinished') ~= 1)
end
disp('Finished Recording')
MyRecording = playrec('getRec',0);
 %% My recording errors
m = 2;
for n=1:12
    while m < 13
    %Calculate the cross-cor at each lag%
    [MyCross(n,m,:),MyLag(n,m,:)] = xcorr(MyRecording(:,n), MyRecording(:,m));
    MyCross(n,m,:) = MyCross(n,m,:)/max(MyCross(n,m,:));
    %Where in the matrix is the max cross-cor%
    [MyMaxCross(n,m),MyMaxLagCell(n,m)] = max(MyCross(n,m,:));
    MySyncError(n,m) = MyLag(n,m, MyMaxLagCell(n,m)); %sample error%
    m = m+1;
    end
    m = n+2;
    disp([num2str(n),' of 12 processed']);
end

MySpatialError = abs(((MySyncError/sampr)*343*100)); %in cm

%% Calculate the difference

SampAndMe = SpatialErrorSamp - MySpatialError;
rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
table = array2table(SampAndMe,'RowNames',rNames,'VariableNames',cNames);
disp('The spatial error (cm) of the recording is:');
disp(table);


