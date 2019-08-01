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
%Duration of AUDIO and VIDEO recording (in seconds). Consult documentation
%for maximum duration
seconds =15;

%VIDEO frame rate (in frames per second). Not all FPS are supported,
%consult documentation
fps = 15; 

%VIDEO format, choose one of these formats:
% RGB24_1024x768
% RGB24_1280x960
% RGB24_1600x1200
% RGB24_640x480
% RGB24_800x600
vidformat = 'RGB24_640x480'; 

%Recorded AUDIO channel index (ASIO driver index). Only these channels and
%channel 1 (for STROBE) will be recorded:                                                  
MicChan = [5 6 13 20]; 

%AUDIO sample Rate (in Hz). Choose one of these:
%32000
%44100
%48000
sampr = 44100;

%% Strobe pattern set:
SPATERN = 4;
%% Bandwidth and Callibrate
seconds = ceil(seconds); %to make sure it's a whole number
imaqreset; %Reset image acqusition toolbox
delete(imaqfind);
camerainfo = imaqhwinfo('dcam');
numcam = numel(camerainfo.DeviceIDs); %How many cameras were found on DCAMs adaptor
disp(['I found ', num2str(numcam), ' cameras and I will record from ', num2str(numcam), ' cameras']);
disp(['Recording duration: ', num2str(seconds), ' seconds']);
disp(['Camera framerate: ', num2str(fps), ' FPS']);
disp(['Video format: ', vidformat]);
disp(['Audio channels: ' num2str(MicChan)]);
disp(['Audio sample rate: ', num2str(sampr*1E-3), ' kHz']);

bandwidth = CalcBandwidth(vidformat,fps,numcam,sampr,1);%Call bandwidth calculation function
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
CallibrateCameras(vidformat, fps, numcam); %Call camera calibration function
end

duration = sampr*seconds; %AUDIO recording duration in samples
totalframes = fps*seconds; %VIDEO recording duration in frames
%% Paralle pool check
if isempty(gcp('nocreate')) %If there is no parallel pool
disp('No pool found, creating one now...');
NewPool = parpool(numcam+1); %Create one pool per camera and one for audio
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
%% Looking for the audio interface
MicChan = [1 MicChan]; %Append channel 1 to be also recorded, STROBE signal will be recorded on this channel

disp('Looking for AUDIO devices')

if (playrec('isInitialised')) == 1 %Reset playrec if it was running
    playrec('reset');
end

devices = playrec('getDevices'); %Will find all audio devices connected to the computer
[q,N] = size(devices);

asioFound = 0;
for n=1:N
    if strcmp(devices(n).hostAPI, 'ASIO') %Find all devices with ASIO host API
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

%% Video logging setup
disp('Setting video logging parameters')
namenow = now; %Get current system time
timenow = datestr(namenow,'hhMMss_ddmm'); %String to be used in all data folders
AVfolder = ['AV_', timenow]; %Master AV folder name
mkdir ('../Recordings', AVfolder); %Create master AV folder
vidfoldername = ['VIDEO_', timenow]; %Video folder name
mkdir('../Recordings',[AVfolder, '\',vidfoldername]); %Create video folder
vidfilename1 = 'crec1.avi'; %names for each AVI video file that could be created
vidfilename2 = 'crec2.avi';
vidfilename3 = 'crec3.avi';
viddirectory1 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename1]; %directroy for each video file that could be created
viddirectory2 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename2];
viddirectory3 = ['../Recordings\', AVfolder, '\',vidfoldername, '\', vidfilename3];

%% Parallel Pool Setup
delete(imaqfind); %stop looking for new devices on all workers
spmd(numcam+1) %Single Programme Multiple Data (spmd), specify to run this only on all of pools workers
    if labindex ~= numcam+1 %All workers except audio worker
    delete(imaqfind);
    end
end
disp('Looking for cameras')
spmd(numcam+1)
        for idx = 1:numcam %Cycle through the camera workers, audio is numcam+1
            if idx == labindex %labindex is the index of current worker%
                imaqreset %reset image acquistion toolbox
                % Detect cameras
                camerainfo = imaqhwinfo('dcam');
                numCamerasFound = numel(camerainfo.DeviceIDs);
                fprintf('Worker %d detected %d cameras.\n', ...
                labindex, numCamerasFound);
            end
        labBarrier %Blocks execution in parallel until worker reaches this point%
        end
  if labindex ~= numcam+1
    
    cameraID = labindex; %Current worker number is also current camera ID
    
    % Configure properties common for ALL cameras
    v = videoinput('dcam', cameraID, vidformat); %create video input object for each camera (ID) on the DCAM adaptor at a particular video format
    s = v.Source; %video source ibject (just one for these cameras, no need to specify)
    s.FrameRate = num2str(fps); %set frame rate, it is a string paramter
    v.FramesPerTrigger = totalframes; %after first manual trigger acquire seconds*fps frames
    v.LoggingMode = 'disk'; %log all frames to disk, not memory for longer recordings
    
    %Logging paramters for each camera seperately
     if cameraID == 1       
        logfile1 = VideoWriter(viddirectory1,'Uncompressed AVI'); %Video writer object to write uncomp AVI in prespecified video directory
        logfile1.FrameRate = fps; %log in prespecified framerate, defaults to 30
        v.DiskLogger = logfile1; %assign video writer object to log to video input disk logger. 
        
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
 if labindex ~= numcam+1 %On all camera workers, not the audio worker
    triggerconfig(v, 'manual'); %Set trigger mode to manual software trigger, not immediate (default).
 end
end

spmd(numcam+1)
    if labindex ~= numcam+1
        if labindex == 1 %Strobe only on the black camera
            disp('Starting to strobe dcam 1');
            s.Strobe2 = 'on';
            s.Strobe2Polarity = 'inverted'; %By default is active low
            s.Strobe2Duration = 3584; % Default duration is shutter length, specify hex number: 0xE00 (32ms, see hardware manual)
        end
    start(v); %Initialise all cameras, but don't yet trigger
    
    end
    if labindex == numcam+1
     
    playrec('init', sampr, -1, defaultID); %Initialise audio at given sample rate, -1 means no play device, defaultID ir rec device

    end
end

disp('AUDIO and VIDEO Initialised')
%% Recording
disp('PLEASE CHECK CAMERA INDICATOR LIGHTS ARE GREEN BEFORE RECORDING')
dorec = input(['Should I start recording for ', num2str(seconds), ' seconds?[y,n]'], 's');
if dorec == 'y'
else %User doesn't want to record, clean up all input objects
    spmd(numcam+1)
        if labindex ~= numcam+1
            delete(v);
            delete(imaqfind);
        end
    end
	clear all; %Also removes playrec ad audio device
    return
end

disp('I will start recording in 3 seconds, counting down:');
for countdown = 3:-1:1
    disp(countdown);
    pause(1);
end
spmd(numcam+1)
    if labindex ~= numcam+1

        trigger(v); %Manual softare trigger to start acquistion on all cameras

    end
    if labindex == numcam+1

       playrec('rec',duration,MicChan); %Start recording audio, from microphone channels for samples*seconds 

    end
end

disp('DO NOT UNPLUG ANY FIREWIRE CABLES, COMPUTER WILL CRASH')
%% VIDEO timeout and VIDEO trigger event info

spmd(numcam+1)
    if labindex ~= numcam+1
    % Wait until acquisition is complete and specify wait timeout
    wait(v, 2*seconds); %Timeoutt checker, is after 2*seconds all prespecified frames haven't been acquired, kill video input
    disp('Finished Recording. Logging VIDEO frames to files');

    % Wait until all frames are logged
    while (v.FramesAcquired ~= v.DiskLoggerFrameCount) 
        pause(1);
    end
    disp(['Acquired ', num2str(v.FramesAcquired), ' frames, logged ' num2str(v.DiskLoggerFrameCount), ' frames.']);
    events = v.EventLog; %In case something goes bad, event log for all camera events that happened after video input object was created.
    startdata = events(1).Data;
    trigdata = events(2).Data;
    stopdata = events(3).Data;
    end
    
    if labindex == numcam+1 %Audio workers is free so use it to count seconds remaining
       for timekeep = seconds:-1:1
           disp(['Recording, ' num2str(timekeep), ' seconds left']);
           pause(1);
       end
    end
end
%% VIDEO cleanup and fetch audio
disp('Fetching recorded AUDIO data')
spmd(numcam+1)
    if labindex ~= numcam+1 %Clean up all video input objects on all camera workers
    delete(v);
    delete(imaqfind);
    end
    if labindex == numcam+1
        RecinSPMD = playrec('getRec',0); %Playrec records in 'pages', get 0th page, the only one we used
    end
end
disp('Cleaning up');
clear v;
clear playrec;
%% Getting strobe signal data
Recording = RecinSPMD{numcam+1}; %Get recorded audio data matrix out from parpool's audio worker

dosync = input('Do you want me to allign the initial frame and show drift info? [y/n]', 's');
if dosync == 'y'
%Call synchroniser, return alligned audio, timestamps in audio samples,
%each video frame's duration in samples and each video frames drift in
%samples
[Recording, TimeStampsSamples,FrameDurationSamples, FrameDriftSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds, SPATERN);
%Create time stamp files, return file name
tsfilename=tsWriter(TimeStampsSamples, sampr, fps, seconds, timenow, AVfolder);
end

disp('Logging AUDIO into files')
foldername = ['AUDIO_', timenow]; %Audio folder name
mkdir('../Recordings',[AVfolder, '\',foldername]); %Create audio folder directory
strobefiledir = ['../Recordings\', AVfolder, '\',foldername, '\strobesignal.wav'];%Strobe signal direcotry
audiowrite(strobefiledir,Recording(:,1),sampr); %strobe signal is the first column in Recording matrix
[q,numChan] = size(Recording);
for x=1:(numChan-1) %Don't save the strobe signal like this
    filename = ['arec_',num2str(x),'.wav'];
    directory = ['../Recordings\', AVfolder, '\',foldername, '\', filename];
    audiowrite(directory,Recording(:,(x+1)),sampr); %Skip first column, strobe
end

if dosync == 'y'
    doVFR = input('Do you want me to create Variable Frame Rate video files? [y/n]', 's');
    if doVFR == 'y'
        disp('Creating txt file for FFMPEG')
        %Create txt file with each frames duration in seconds and frame
        %name
        tsfilename = ffmpegWriter(FrameDurationSamples, sampr, fps, seconds, timenow, AVfolder);
        disp('Creating VFR files');
        for VFRcam=1:numcam
            disp(['Creating VFR from camera ', num2str(VFRcam)]);
            %Call VFR creator function
            VFRcreator(AVfolder, vidfoldername, tsfilename, VFRcam);
        end
        %Return read timestamps from the new VFR file
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
disp([num2str(numChan-1), ' wav files created']);
disp([num2str(numcam), ' CFR AVI files created']);
if doVFR == 'y'
    disp([num2str(numcam), ' VFR MPEG4 files created']);
else
    disp('0 VFR MPEG4 files created');
end
disp('Timestamp CSV and TXT files created')
disp(['All files saved to Recordings/', AVfolder]);
appost = '''';
timewithappost= strcat(appost, timenow, appost);
disp(['To read all data into structure array run [video, audio] = DataReader(',timewithappost, ',' num2str(numcam),',',num2str(numChan-1), ')']); 
