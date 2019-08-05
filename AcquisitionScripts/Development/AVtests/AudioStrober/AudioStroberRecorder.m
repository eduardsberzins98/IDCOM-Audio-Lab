clear all;
clc;
disp('Recording with Playrec');

MicChan = [7 8 9 10 13 14 15 16 17 18 19 20];
seconds = 20; %How long will the recording be%
sampr = 44100; %Sample Rate%
fps = 15;

%% Generating Strobe Signal

frameInSamples = round(sampr/fps);
halfFrameInSamples = round(sampr/(2*fps));

StrobeSignalDuration = round(sampr*seconds);
AudioStrobeSignal = ones(StrobeSignalDuration,1);
TrigPulse = zeros(halfFrameInSamples+1,1);
waitOneSecond = sampr;

TrigCount = floor(StrobeSignalDuration/frameInSamples);
n = 1;
while (n<TrigCount) && ((waitOneSecond + frameInSamples*(n+1))<StrobeSignalDuration)
AudioStrobeSignal(waitOneSecond:waitOneSecond+halfFrameInSamples) = TrigPulse;
NextTrigSample = waitOneSecond + frameInSamples*n;
AudioStrobeSignal(NextTrigSample:NextTrigSample+halfFrameInSamples) = TrigPulse;
n=n+1;
end
TrueTriggerCount = n;

%% Playrec Setup

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

%% Recording
dorec = input(['Should I start recording from the ', num2str(12), ' channels for ', num2str(seconds), ' second?[y,n]'], 's');
if dorec == 'y'
else
    return
end

disp('I will start recording in 3 seconds, counting down:');
for countdown = 3:-1:1
    disp(countdown);
    pause(1);
end

playrec('init', sampr, defaultID, defaultID);
duration = sampr*seconds;
playrec('playrec',AudioStrobeSignal, 1, duration,MicChan);
disp('Recording...')
while (playrec('isFinished') ~= 1)
end
disp('Finished Recording')

%% Fetching data

Recording = playrec('getRec',0);
[~, NumChan] = size(Recording);
timenow = datestr(now,'hhMMss_ddmm');
foldername = ['PlayRec_', timenow];
mkdir(foldername);
for x=1:NumChan
    filename = ['rec_',num2str(x),'.wav'];
    directory = [foldername, '\', filename];
    if x == 1
        StrobeDir = directory;
    end
    audiowrite(directory,Recording(:,x),sampr);
end








