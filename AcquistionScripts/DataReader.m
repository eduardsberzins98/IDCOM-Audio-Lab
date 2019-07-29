%% Read files script
function [video, audio] = DataReader(rectime, numVrec, numArec)
disp('Reading timestamps')
tsloc = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\Timestamps_' , rectime, '.csv'];
tsMatrix = readmatrix(tsloc);
disp('Reading CFR video files')
for c=1:numVrec
vidfiledir = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\VIDEO_', rectime, '\crec' , num2str(c), '.avi'];
v = VideoReader(vidfiledir);
framecounter = 0;
    while hasFrame(v)
        framecounter = framecounter+1;
        video(c).frame(framecounter).image = readFrame(v);
        video(c).frame(framecounter).SecondsTimestamp = tsMatrix(framecounter, 2);
        video(c).frame(framecounter).SamplesTimestamp = tsMatrix(framecounter, 3);
    end
end

disp('Reading audio files')
for a = 1:numArec
    audiofiledir = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\AUDIO_', rectime, '\arec_',num2str(a),'.wav'];
    audio.recordings(:,a) = audioread(audiofiledir);
end

currentFrame = 1;
currentSample = 1;
[samplecount, ~] = size(audio.recordings);
while currentSample <= samplecount
    if (currentFrame <= (framecounter-1))
        while ((currentSample-1) < video(1).frame(currentFrame+1).SamplesTimestamp) && ((currentSample-1) >= video(1).frame(currentFrame).SamplesTimestamp)
        audio.AssocietedVidFrame(currentSample) = currentFrame;
        currentSample = currentSample + 1;
        end
        currentFrame = currentFrame+1;
    else
        break
    end
end
audio.AssocietedVidFrame(currentSample+1:samplecount) = framecounter;

disp('VIDEO: structs video(1), video(2) and video(3) each contain the corresponding cameras video.');
disp('Each video structure has a field frame and each frame has fields: image, SecondsTimestamp, SamplesTimestamp');
disp('AUDIO: struct audio has fields recording (samples x channel) and AssocietedVidFrame');




