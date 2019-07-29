%% Audio Lab AV Acquisiton Script

%This script is for recording simultanous AUDIO and VIDEO in the University
%of Edinburgh Audio Lab. It is only compatible with the equipment in that
%lab.

%Plese read the Audio Lab Documentation located
% here: before starting acquistion.
clear all;
close all;
clc;
%% BEFORE RUNNING SET THESE PARAMETERS:
MicChan = [5 6 9 10 13 14 15 16 17 18 19 20 21 22]; %Recorded AUDIO channel index (ASIO driver index)
seconds = 60; %Duration of AUDIO and VIDEO recording (in seconds)
sampr = 44100; %AUDIO sample Rate (in Hz)
fps = 15; %VIDEO frame rate (in frames per second)
vidformat = 'RGB24_640x480'; %VIDEO format, choose one of these formats:
% RGB24_1024x768
% RGB24_1280x960
% RGB24_1600x1200
% RGB24_640x480
% RGB24_800x600	

%% Bandwidth and Callibrate
imaqreset;
delete(imaqfind);
camerainfo = imaqhwinfo('dcam');
numcam = numel(camerainfo.DeviceIDs);
disp(['I found ', num2str(numcam), ' cameras and I will record from ', num2str(numcam), ' cameras']);
disp(['Recording duration: ', num2str(seconds), ' seconds']);
disp(['Camera framerate: ', num2str(fps), ' FPS']);
disp(['Video format: ', vidformat]);
disp(['Audio channels: ' num2str(MicChan)]);
disp(['Audio sample rate: ', num2str(sampr*1E-3), ' kHz']);

bandwidth = CalcBandwidth(vidformat,fps,numcam,sampr,1);
disp(['The required bandwidth is ', num2str(bandwidth*1E-6), ' mbps (max: 400mbps)']);
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
MicChan = [1 MicChan];

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
        defaultID = foundDevices;
        disp(['Setting ', num2str(defaultID),' as the default recording device'])
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
mkdir ('../Recordings', AVfolder);
vidfoldername = ['VIDEO_', timenow];
mkdir('../Recordings',[AVfolder, '\',vidfoldername]);
vidfilename1 = 'crec1.avi';
vidfilename2 = 'crec2.avi';
vidfilename3 = 'crec3.avi';
viddirectory1 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename1];
viddirectory2 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename2];
viddirectory3 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename3];

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
            s.Strobe2Duration = 3584; %0xE00, 32ms
        end
    start(v);
    
    end
    if labindex == numcam+1
     
    playrec('init', sampr, -1, defaultID);

    end
end

disp('AUDIO and VIDEO Initialised')
%% Recording
disp('PLEASE CHECK CAMERA INDICATOR LIGHTS ARE GREEN BEFORE RECORDING')
dorec = input(['Should I start recording for ', num2str(seconds), ' seconds?[y,n]'], 's');
if dorec == 'y'
else
    spmd(numcam+1)
        if labindex ~= numcam+1
            delete(v);
            delete(imaqfind);
        end
    end
	clear all;
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

disp('DO NOT UNPLUG ANY FIREWIRE CABLES, COMPUTER WILL CRASH')
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

dosync = input('Do you want me to allign the initial frame and show drift info? [y/n]', 's');
if dosync == 'y'
[Recording, TimeStampsSamples,FrameDurationSamples, FrameDriftSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds);
tsfilename=tsWriter(TimeStampsSamples, sampr, fps, seconds, timenow, AVfolder);
end

disp('Logging AUDIO into files')
foldername = ['AUDIO_', timenow];
mkdir('../Recordings',[AVfolder, '\',foldername]);
strobefiledir = ['../Recordings\', AVfolder, '\',foldername, '\strobesignal.wav'];%name strobe signal something else
audiowrite(strobefiledir,Recording(:,1),sampr);
[q,numChan] = size(Recording);
for x=1:(numChan-1) %Don't save the strobe signal like this
    filename = ['arec_',num2str(x),'.wav'];
    directory = ['../Recordings\', AVfolder, '\',foldername, '\', filename];
    audiowrite(directory,Recording(:,(x+1)),sampr);
end

if dosync == 'y'
    doVFR = input('Do you want me to create Variable Frame Rate video files? [y/n]', 's');
    if doVFR == 'y'
        disp('Creating txt file for FFMPEG')
        tsfilename = ffmpegWriter(FrameDurationSamples, sampr, fps, seconds, timenow, AVfolder);
        disp('Creating VFR files');
        for VFRcam=1:numcam
            disp(['Creating VFR from camera ', num2str(VFRcam)]);
            VFRcreator(AVfolder, vidfoldername, tsfilename, VFRcam);
        end
        ffmpegFrameDriftSeconds = PostFFMPEGtsPlotter(fps, AVfolder, vidfoldername);
        figure;
        subplot(1,2,1);
        plot(FrameDriftSamples./(sampr*1E-3)), hold on
        plot([0 numel(FrameDriftSamples)], [0 0], 'k--'), hold on
        plot([0 numel(FrameDriftSamples)], [15 15], 'r--'), hold on
        plot([0 numel(FrameDriftSamples)], [-15 -15], 'r--')
        title('AV drift of CFR video'), xlabel('Frame'), ylabel('Drift (ms)')
        subplot(1,2,2);
        plot(ffmpegFrameDriftSeconds.*1E3), hold on
        plot([0 numel(ffmpegFrameDriftSeconds)], [0 0], 'k--'), hold on
        plot([0 numel(ffmpegFrameDriftSeconds)], [15 15], 'r--'), hold on
        plot([0 numel(ffmpegFrameDriftSeconds)], [-15 -15], 'r--')
        title('Timestamp drift of VFR video'), xlabel('Frame'), ylabel('Drift (ms)')
    end
end

disp(['All files saved to Recordings/', AVfolder]);
appost = '''';
timewithappost= strcat(appost, timenow, appost);
disp(['To read all data into structure array run [video, audio] = DataReader(',timewithappost, ',' num2str(numcam),',',num2str(numChan-1), ')']); 

clear v;
clear playrec;
