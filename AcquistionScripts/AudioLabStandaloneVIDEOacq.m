%% Audio Lab AV Acquisiton Script

%This script is for recording only standalone VIDEO in the University
%of Edinburgh Audio Lab. It is only compatible with the equipment in that
%lab.

%Plese read the Audio Lab Documentation located
% here: before starting acquistion.
clear all;
close all;
clc;
%% BEFORE RUNNING SET THESE PARAMETERS:
seconds = 10; %Duration of VIDEO recording (in seconds)
fps = 15; %VIDEO frame rate (in frames per second)
vidformat = 'RGB24_640x480'; %VIDEO format, choose one of these formats:
% Y422_1024x768   Y411_640x480	RGB24_1024x768	Y16_1024x768	Y8_1024x768
% Y422_1280x960   Y444_160x120	RGB24_1280x960	Y16_1280x960	Y8_1280x960
% Y422_1600x1200                RGB24_1600x1200	Y16_1600x1200	Y8_1600x1200
% Y422_320x240                  RGB24_640x480	Y16_640x480     Y8_640x480
% Y422_640x480                  RGB24_800x600	Y16_800x600     Y8_800x600
% Y422_800x600

%% Bandwidth and Callibrate
imaqreset;
delete(imaqfind);
camerainfo = imaqhwinfo('dcam');
numcam = numel(camerainfo.DeviceIDs);
disp(['I found ', num2str(numcam), ' cameras and I will record from ', num2str(numcam), ' cameras']);

bandwidth = CalcBandwidth(vidformat,fps,numcam,0,0);
disp(['The required bandwidth is ', num2str(bandwidth*1E-6), ' mbps']);
if bandwidth >= 629E6
    disp('That is too much, in this configuration I can only handle 629mbps');
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

totalframes = fps*seconds;

%% Paralle pool check

if isempty(gcp('nocreate')) %If there is no parallel pool
disp('No pool found, creating one now...');
NewPool = parpool(numcam);
else
OldPool = gcp('nocreate');
    if OldPool.NumWorkers ~= numcam %There is a pool but with an incorrect worker count
        disp('Incorrect worker count, restarting pool with correct count...');
        delete(OldPool);
        NewPool = parpool(numcam);
    else
        disp('Correct number of workers running in pool');
    end
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
spmd(numcam) %Single Programme Multiple Data (spmd), specify to run this only on 4 workers
    if labindex ~= numcam
    delete(imaqfind);
    end
end
disp('Looking for cameras')
spmd(numcam)
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

%% Initialising streams

spmd(numcam)
    triggerconfig(v, 'manual');
end

spmd(numcam)
    start(v);
end

disp('VIDEO Initialised')
%% Recording
disp('PLEASE CHECK CAMERA INDICATOR LIGHTS ARE GREEN BEFORE RECORDING')
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
spmd(numcam)
        trigger(v);
end

disp('DO NOT UNPLUG ANY FIREWIRE CABLES, COMPUTER WILL CRASH')
for timekeep = seconds:-1:1
   disp(['Recording, ' num2str(timekeep), ' seconds left']);
   pause(1);
end
%% VIDEO timeout and VIDEO trigger event info

spmd(numcam)
    % Wait until acquisition is complete and specify wait timeout
    wait(v, 2*seconds);
    disp('Finished Recording. Logging VIDEO frames to files');

    % Wait until all frames are logged
    while (v.FramesAcquired ~= v.DiskLoggerFrameCount) 
        pause(1);
    end
    disp(['Acquired ', num2str(v.FramesAcquired), ' frames, logged ' num2str(v.DiskLoggerFrameCount), ' frames.']);
end
%% VIDEO cleanup and fetch audio
disp('Cleaning up')
spmd(numcam)
    delete(v);
    delete(imaqfind);
end

disp(['All files saved to Recordings/', AVfolder]);

clear v;
