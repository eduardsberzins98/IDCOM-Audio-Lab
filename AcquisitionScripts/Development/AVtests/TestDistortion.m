%% Audio Lab AV Synchroniser
clear all;
close all;
clc;
             
%% CHANGE THESE:
%All of these values can be manipulated by the user
numcam = 1; %How many cameras are being recorded from
MicChan = [6 7 8 9 10 13 14 15 16 17 18 19 20 21 22]; %Which microphones will be recorded
seconds = 10; %Length of recording (in seconds)
sampr = 44100; %AUDIO sample Rate (in Hz)
fps = 15; %VIDEO frame rate (in frames per second)

%% Generating Strobe Signal
frameInSamples = round(sampr/fps);
halfFrameInSamples = round(sampr/(2*fps));

StrobeSignalDuration = round(sampr*seconds);
AudioStrobeSignal = 0.1*ones(StrobeSignalDuration,1);
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

%% Bandwidth and Callibrate

% bandwidth = CalcBandwidth(vidformat,fps,numcam,sampr,1);
% disp(['The required bandwidth is ', num2str(bandwidth*1E-6), ' mbps']);
% if bandwidth >= 400000000
%     disp('That is too much, in this configuration I can only handle 400mbps');
%     return
% end
% doband = input('Do you wish to continue? [y/n]', 's');
% if doband == 'y'
% else
%     return
% end

docalib = input('Do you wish to calibrate the cameras? [y/n]', 's');
if docalib == 'y'
CallibrateCameras(vidformat, fps, numcam);
end

duration = sampr*seconds;
totalframes = fps*seconds;

%% Non-parallel AUDIO setup
disp('Looking for AUDIO devices')
if (playrec('isInitialised')) == 1
    playrec('reset');
end

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

%% Non-Parallel VIDEO setup

disp('Setting video logging parameters')
namenow = now;
timenow = datestr(namenow,'hhMMss_ddmm');
AVfolder = ['AV_', timenow];
mkdir(AVfolder);

%% Parallel Pool Setup

%% Initialising streams


    playrec('init', sampr, defaultID, defaultID);

disp('AUDIO and VIDEO Initialised')
%% Recording

disp('I will start recording in 3 seconds, counting down:');
for countdown = 3:-1:1
    disp(countdown);
    pause(1);
end

       playrec('playrec',AudioStrobeSignal, 1, duration,MicChan);
pause(seconds);

%% VIDEO cleanup and fetch audio
disp('Fetching recorded AUDIO data')

        Recording = playrec('getRec',0);
%% Getting strobe signal data
Recording(1:sampr,:) = [];%Remove first second
disp('Logging AUDIO into files')
foldername = ['audio_', timenow];
mkdir([AVfolder, '\',foldername]);
[q,numChan] = size(Recording);
for x=1:numChan
    filename = ['arec_',num2str(x),'.wav'];
    directory = [AVfolder, '\',foldername, '\', filename];
    audiowrite(directory,Recording(:,x),sampr);
end

plot(Recording(:,1));
% %% Comparing strobe signals
% AudioStrobeSignal(1:sampr) = [];
% [StrobeLocSamples, StrobeLocPlotterSamples] = StrobeAnalyser(double(Recording(:,1)),sampr,fps,1);
% disp('Looking at frame HEX info')
% startedOn = FrameAnalyser(viddirectory1);
% %%Comparing to matching frames in other strobe periods, seeing which is
% %%closer
% SingleStrobeDelaySamples = (1/fps)*sampr;
% switch startedOn %Strobes on frame 2
%     case 0
%         Option0 = StrobeLocSamples(1) - 2*SingleStrobeDelaySamples;
%     case 1
%         Option0 = StrobeLocSamples(1) - SingleStrobeDelaySamples;
%     case 2
%         Option0 = StrobeLocSamples(1);
% end
% OptionPos = Option0 + 3*SingleStrobeDelaySamples;
% OptionNeg = Option0 - 3*SingleStrobeDelaySamples;
% 
% CompareOptions = [abs(OptionNeg), abs(Option0), abs(OptionPos)];
% [~, ClosestOption] = min(CompareOptions);
% 
% switch ClosestOption
%     case 1
%         InitialFrameErrorSamples = OptionNeg;
%     case 2
%         InitialFrameErrorSamples = Option0;
%     case 3
%         InitialFrameErrorSamples = OptionPos;
% end
% disp(['Initial frame error: ', num2str(round((InitialFrameErrorSamples/sampr)*1000)), ' ms']);
% if InitialFrameErrorSamples > 0 %VIDEO events happen before AUDIO events
%         %Need to cut out audio data
%         StrobeLocPlotterSamples(1:abs(InitialFrameErrorSamples)) = [];
%     elseif InitialFrameErrorSamples < 0 %VIDEO events happen after AUDIO events
%         %Need to add in some silence
%         zeroArray = zeros(abs(InitialFrameErrorSamples),1);
%         StrobeLocPlotterSamples = [zeroArray;Recording];
% end
% 
% figure;
% plot(StrobeLocPlotterSamples, 'r'), hold on
% plot(AudioStrobeSignal./100', 'k--');
% xlim([0 6*frameInSamples]);

disp(['All files saved to ',AVfolder]);

clear v;
clear playrec;
