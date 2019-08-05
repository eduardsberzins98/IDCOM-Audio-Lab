for repeat = 1:3


clear all;
clc;
disp('Audio Toolbox Recording Script');
%% 1) Audio Input Setup
clear deviceReader dspAudioDeviceInfo %Clear all found devices in this seesion
MicChan = [7 8 9 10 13 14 15 16 17 18 19 20];
seconds = 10; %How long will the recording be%
sampr = 44100; %Sample Rate%


dr = audioDeviceReader; %Device reader input object
dr.Driver = 'ASIO';
%getAudioDevices(dr) %What sort of devices are available
dr.Device = 'ASIO Fireface'; %Set the correct device
%info(dr) %See what is the current setup
dr.ChannelMappingSource = 'Property'; %Enable to set the channel mapping as you want to%
dr.ChannelMapping = MicChan;%Set the channel mapping the way you want to%

%% File writer setup
timenow = datestr(now,'hhMMss_ddmm');
foldername = ['AuTo_', timenow];
mkdir(foldername);
fwall = dsp.AudioFileWriter([foldername, '\aurec_ALL.wav']); %First write to one wav file
%% Audio Processing
setup(dr);
dorec = input('Should I start recording?[y,n]', 's');
if dorec == 'y'
else
    return
end
disp('I will start recording in 10 seconds, counting down:');
for countdown = 10:-1:1
    disp(countdown);
    pause(1);
end
tic;
disp('Recording...');
while toc <= 10
    [acquiredAudio, over] = dr(); %Returns samples up to single buffer
    fwall(acquiredAudio(:,:));
end
disp('Finished Recording');
%% Storing it in WAV files
release(fwall);
Recording(:,:) = audioread([foldername, '\aurec_ALL.wav']);
disp(['All channels recorded to ',foldername, '\aurec_ALL.wav as well as in the matrix "Recording".']);
% dosplit = input('Should I split the channels into seperate files?[y,n]', 's');
% if dosplit == 'y'
% else
%     return
% end
%     for x=1:12
%         filename = ['aurec_',num2str(x),'.wav'];
%         directory = [foldername, '\', filename];
%         audiowrite(directory,Recording(:,x),sampr);
%     end
disp('Calculating Sync Error');
n=1;
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
n = 1;
m = 2;
for n=1:12
    while m < 13
    %Calculate the cross-cor at each lag%
    [CrossRev(n,m,:),LagRev(n,m,:)] = xcorr(Recording(:,m), Recording(:,n));
    CrossRev(n,m,:) = CrossRev(n,m,:)/max(CrossRev(n,m,:));
    %Where in the matrix is the max cross-cor%
    [MaxCrossRev(n,m),MaxLagCellRev(n,m)] = max(CrossRev(n,m,:));
    SyncErrorRev(n,m) = LagRev(n,m, MaxLagCellRev(n,m)); %sample error%
    m = m+1;
    end
    m = n+2;
    disp([num2str(n),' of 12 processed']);
end

warning('off', 'MATLAB:xlswrite:AddSheet');
SpatialError =(SyncError/sampr)*343*100; %in cm
rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
table = array2table(SpatialError,'RowNames',rNames,'VariableNames',cNames);
xfilename = ['AuToSync', timenow,'.xlsx'];
writetable(table, xfilename,'Sheet', 1)

SpatialErrorRev =(SyncErrorRev/sampr)*343*100; %in cm
rNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11'};
cNames = {'Ch1','Ch2','Ch3','Ch4','Ch5','Ch6','Ch7','Ch8','Ch9','Ch10','Ch11', 'Ch12'};
tableRev = array2table(SpatialErrorRev,'RowNames',rNames,'VariableNames',cNames);
writetable(tableRev, xfilename,'Sheet', 2)    
end
