%% Audio Lab AV Synchroniser
clear all;
close all;
clc;
             
%% CHANGE THESE:
%All of these values can be manipulated by the user

numcam = 3; %How many cameras are being recorded from
MicChan = [7 8]; %Which microphones will be recorded
% [7 8 9 10 13 14 15 16 17 18 19 20]
seconds = 10; %Length of recording (in seconds)
sampr = 44100; %AUDIO sample Rate (in Hz)
fps = 15; %VIDEO frame rate (in frames per second)
vidformat = 'RGB24_640x480'; 
%VIDEO format, choose one of these formats:
% Y422_1024x768   Y411_640x480	RGB24_1024x768	Y16_1024x768	Y8_1024x768
% Y422_1280x960   Y444_160x120	RGB24_1280x960	Y16_1280x960	Y8_1280x960
% Y422_1600x1200                RGB24_1600x1200	Y16_1600x1200	Y8_1600x1200
% Y422_320x240                  RGB24_640x480	Y16_640x480     Y8_640x480
% Y422_640x480                  RGB24_800x600	Y16_800x600     Y8_800x600
% Y422_800x600
%% Bandwidth and Callibrate

bandwidth = CalcBandwidth(vidformat,fps,numcam,sampr,1);
disp(['The required bandwidth is ', num2str(bandwidth*1E-6), ' mbps']);
if bandwidth >= 400000000
    disp('That is too much, in this configuration I can only handle 400mbps');
    return
end
doband = input('Do you wish to continue? [y/n]', 's');
if doband == 'y'
else
    return
end

docalib = input('Do you wish to calibrate the cameras? [y/n]', 's');
if docalib == 'y'
CallibrateCameras(vidformat, fps, numcam);
end

duration = sampr*seconds;
totalframes = fps*seconds;

%% Paralle pool check
if isempty(gcp('nocreate')) %If there is no parallel pool
disp('No pool found, creating one now...');
NewPool = parpool(numcam+1);
else
OldPool = gcp('nocreate');
    if OldPool.NumWorkers ~= numcam+1 %There is a pool but with an incorrect worker count
        disp('Incorrect worker count, restarting pool with correct count...');
        delete(OldPool);
        NewPool = parpool(numcam+1);
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
spmd(numcam+1) %Single Programme Multiple Data (spmd), specify to run this only on 4 workers
    if labindex ~= numcam+1
    delete(imaqfind);
    end
end
disp('Looking for cameras')
spmd(numcam+1)
    
        for idx = 1:numcam %Cycle through the first 3 workers - cameras
            if idx == labindex%labindex is the index of current worker%
                imaqreset
                % Detect cameras
                camerainfo = imaqhwinfo('dcam');
                numCamerasFound = numel(camerainfo.DeviceIDs);
                fprintf('Worker %d detected %d cameras.\n', ...
                labindex, numCamerasFound);
            end
        labBarrier %Blocks execution in parallel until worker reaches this point%
        end
  if labindex ~= numcam+1
    
    cameraID = labindex;
    
    % Configure properties common for ALL cameras
    v = videoinput('dcam', cameraID, vidformat);
    s = v.Source;
    s.FrameRate = num2str(fps);
    v.FramesPerTrigger = totalframes;
    v.LoggingMode = 'disk';
    
     if cameraID == 1       
        logfile1 = VideoWriter(viddirectory1,'Uncompressed AVI');
        logfile1.FrameRate = fps;
        v.DiskLogger = logfile1;
        
    elseif cameraID == 2
        logfile2 = VideoWriter(viddirectory2,'Uncompressed AVI');
        logfile2.FrameRate = fps;
        v.DiskLogger = logfile2;
        
    elseif cameraID == 3
        logfile3 = VideoWriter(viddirectory3,'Uncompressed AVI');
        logfile3.FrameRate = fps;
        v.DiskLogger = logfile3;
     end
    end
end

%% Initialising streams

spmd(numcam+1)
 if labindex ~= numcam+1
    triggerconfig(v, 'manual');
 end
end

spmd(numcam+1)
    if labindex ~= numcam+1
        if labindex == 1
            disp('Starting to strobe dcam 1');
            s.Strobe2 = 'on';
            s.Strobe2Polarity = 'inverted';
        end
    start(v);
    
    end
    if labindex == numcam+1
     
    playrec('init', sampr, -1, defaultID);

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
spmd(numcam+1)
    if labindex ~= numcam+1

        trigger(v);

    end
    if labindex == numcam+1

       playrec('rec',duration,MicChan);

    end
end

%% VIDEO timeout and VIDEO trigger event info

spmd(numcam+1)
    if labindex ~= numcam+1
    % Wait until acquisition is complete and specify wait timeout
    wait(v, 2*seconds);
    disp('Finished Recording. Logging VIDEO frames to files');

    % Wait until all frames are logged
    while (v.FramesAcquired ~= v.DiskLoggerFrameCount) 
        pause(1);
    end
    disp(['Acquired ', num2str(v.FramesAcquired), ' frames, logged ' num2str(v.DiskLoggerFrameCount), ' frames.']);
    events = v.EventLog;
    startdata = events(1).Data;
    trigdata = events(2).Data;
    stopdata = events(3).Data;
    end
    
    if labindex == numcam+1
       for timekeep = seconds:-1:1
           disp(['Recording, ' num2str(timekeep), ' seconds left']);
           pause(1);
       end
    end
end
%% VIDEO cleanup and fetch audio
disp('Fetching recorded AUDIO data')
spmd(numcam+1)
    if labindex ~= numcam+1
    delete(v);
    delete(imaqfind);
    end
    if labindex == numcam+1
        ATPlay = playrec('getStreamStartTime');
        RecinSPMD = playrec('getRec',0);
    end
end
%% Getting strobe signal data
Recording = RecinSPMD{numcam+1};

[Recording, TimeStampsSamples,FrameDurationSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds);


disp('Logging AUDIO into files')
foldername = ['audio_', timenow];
mkdir([AVfolder, '\',foldername]);
[q,numChan] = size(Recording);
for x=1:numChan
    filename = ['arec_',num2str(x),'.wav'];
    directory = [AVfolder, '\',foldername, '\', filename];
    audiowrite(directory,Recording(:,x),sampr);
end

disp('Creating txt file for FFMPEG')
ffmpegWriter(FrameDurationSamples, sampr, fps, seconds, timenow, AVfolder);

disp(['All files saved to ',AVfolder]);

clear v;
clear playrec;
