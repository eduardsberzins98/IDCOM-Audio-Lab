%% Audio Lab AV Synchroniser
clear all;
close all;
clc;
             
%% CHANGE THESE:
%All of these values can be manipulated by the user
adaptor = 'pointgrey';
numcam = 2; %How many cameras are being recorded from
MicChan = [7 8]; %Which microphones will be recorded
seconds = 10; %Length of recording (in seconds)
sampr = 44100; %AUDIO sample Rate (in Hz)
fps = 15; %VIDEO frame rate (in frames per second)
vidformat = 'RGB_640x480'; % 'RGB_640x480' 'RGB24_640x480'
%VIDEO format, choose one of these formats:
% Y422_1024x768   Y411_640x480	RGB24_1024x768	Y16_1024x768	Y8_1024x768
% Y422_1280x960   Y444_160x120	RGB24_1280x960	Y16_1280x960	Y8_1280x960
% Y422_1600x1200                RGB24_1600x1200	Y16_1600x1200	Y8_1600x1200
% Y422_320x240                  RGB24_640x480	Y16_640x480     Y8_640x480
% Y422_640x480                  RGB24_800x600	Y16_800x600     Y8_800x600
% Y422_800x600

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

% docalib = input('Do you wish to calibrate the cameras? [y/n]', 's');
% if docalib == 'y'
% CallibrateCameras(vidformat, fps, numcam);
% end

duration = sampr*seconds;
totalframes = fps*seconds;

%% Paralle pool check
if isempty(gcp('nocreate')) %If there is no parallel pool
disp('No pool found, creating one now...');
NewPool = parpool(2);
else
OldPool = gcp('nocreate');
    if OldPool.NumWorkers ~= 2 %There is a pool but with an incorrect worker count
        disp('Incorrect worker count, restarting pool with correct count...');
        delete(OldPool);
        NewPool = parpool(2);
    else
        disp('Correct number of workers running in pool');
    end
end
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
vidfoldername = ['video_', timenow];
mkdir([AVfolder, '\',vidfoldername]);
vidfilename1 = 'crec1.avi';
vidfilename2 = 'crec2.avi';
vidfilename3 = 'crec3.avi';
viddirectory1 = [AVfolder, '\',vidfoldername, '\', vidfilename1];
viddirectory2 = [AVfolder, '\',vidfoldername, '\', vidfilename2];
viddirectory3 = [AVfolder, '\',vidfoldername, '\', vidfilename3];

%% Parallel Pool Setup

delete(imaqfind);
spmd(2) %Single Programme Multiple Data (spmd), specify to run this only on 4 workers
    if labindex == 1
    delete(imaqfind);
    end
end
disp('Looking for cameras')
spmd(2)
  if labindex == 1
        %Configure video 1
        v1 = videoinput(adaptor, 1, vidformat);
        s1 = v1.Source;

        v1.FramesPerTrigger = 1;
        v1.TriggerRepeat = TrueTriggerCount - 1;
        v1.LoggingMode = 'disk';

        logfile1 = VideoWriter(viddirectory1,'Uncompressed AVI');
        logfile1.FrameRate = fps;
        v1.DiskLogger = logfile1;
        
        triggerconfig(v1,'hardware','fallingEdge','externalTriggerMode14-Source0');

        %Configure video 2

        v2 = videoinput(adaptor, 2, vidformat);
        s2 = v2.Source;

        v2.FramesPerTrigger = 1;
        v2.TriggerRepeat = TrueTriggerCount - 1;
        v2.LoggingMode = 'disk';

        logfile2 = VideoWriter(viddirectory2,'Uncompressed AVI');
        logfile2.FrameRate = fps;
        v2.DiskLogger = logfile2;
        
        triggerconfig(v2,'hardware','fallingEdge','externalTriggerMode14-Source0');
    end
end

%% Initialising streams

% spmd(2)
%  if labindex ~= numcam+1
%     %triggerconfig(v,'hardware','fallingEdge','externalTriggerMode14-Source3');
%     triggerconfig(v,'hardware','fallingEdge','externalTriggerMode14-Source0');
%  end
% end

spmd(2)
%     if labindex ~= numcam+1
%             s.Strobe2 = 'on';
%             s.Strobe2Polarity = 'inverted';
%     end
    if labindex == 2
     
    playrec('init', sampr, defaultID, defaultID);

    end
end

disp('AUDIO and VIDEO Initialised')
%% Recording

dorec = input(['Should I start recording for ', num2str(seconds), ' seconds?[y,n]'], 's');
if dorec == 'y'
else
    return
end

disp('I will start recording in 3 seconds, counting down:');
for countdown = 3:-1:1
    disp(countdown);
    pause(1);
end
spmd(2)
    if labindex == 1

    start(v1);
    start(v2);

    end
    if labindex == 2

       playrec('playrec',AudioStrobeSignal, 1, duration,MicChan);

    end
end
% pause(5);
% spmd(numcam+1)
% if labindex ~= numcam+1
% %% VIDEO timeout and VIDEO trigger event info
%     events = v.EventLog;
%     startdata = events(1).Data;
%     trigdata = events(2).Data;
% end
% end
spmd(2)
    if labindex == 1
    % Wait until acquisition is complete and specify wait timeout
    wait(v1,2*seconds);
    wait(v2,2*seconds);
    
    disp('Finished Recording. Logging VIDEO frames to files');

    % Wait until all frames are logged
    while (v1.FramesAcquired ~= v1.DiskLoggerFrameCount) 
        pause(1);
    end
    
      while (v2.FramesAcquired ~= v2.DiskLoggerFrameCount) 
        pause(1);
    end
    disp(['Acquired ', num2str(v1.FramesAcquired), ' frames, logged ' num2str(v1.DiskLoggerFrameCount), ' frames.']);
    disp(['Acquired ', num2str(v2.FramesAcquired), ' frames, logged ' num2str(v2.DiskLoggerFrameCount), ' frames.']);
    end
    
    if labindex == 2
       for timekeep = seconds:-1:1
           disp(['Recording, ' num2str(timekeep), ' seconds left']);
           pause(1);
       end
    end
end
%% VIDEO cleanup and fetch audio
disp('Fetching recorded AUDIO data')
spmd(2)
    if labindex == 1
    delete(v1);
    delete(v2);
    delete(imaqfind);
    end
    if labindex == 2
        ATPlay = playrec('getStreamStartTime');
        RecinSPMD = playrec('getRec',0);
    end
end
%% Getting strobe signal data
Recording = RecinSPMD{2};

disp('Logging AUDIO into files')
foldername = ['audio_', timenow];
mkdir([AVfolder, '\',foldername]);
[q,numChan] = size(Recording);
for x=1:numChan
    filename = ['arec_',num2str(x),'.wav'];
    directory = [AVfolder, '\',foldername, '\', filename];
    audiowrite(directory,Recording(:,x),sampr);
end

% %% Comparing strobe signals
% Recording(1:sampr) = [];
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
