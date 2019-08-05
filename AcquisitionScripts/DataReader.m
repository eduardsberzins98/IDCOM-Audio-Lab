%% Read files script
function [video, audio] = DataReader(rectime, numVrec, numArec)
if numArec && numVrec
    disp('Reading timestamps')
    tsloc = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\Timestamps_' , rectime, '.csv'];
    tsMatrix = readmatrix(tsloc);
end

if numVrec
    disp('Reading CFR video files')
    for c=1:numVrec
    vidfiledir = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\VIDEO_', rectime, '\crec' , num2str(c), '.avi'];
    v = VideoReader(vidfiledir);
    framecounter = 0;
        while hasFrame(v)
            framecounter = framecounter+1;
            video(c).frame(framecounter).image = readFrame(v);
            if numArec
                video(c).frame(framecounter).SecondsTimestamp = tsMatrix(framecounter, 2);
                video(c).frame(framecounter).SamplesTimestamp = tsMatrix(framecounter, 3);
            end
        end
    end
end

if numArec
    disp('Reading audio files')
    for a = 1:numArec
        audiofiledir = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\AV_', rectime, '\AUDIO_', rectime, '\arec_',num2str(a),'.wav'];
        audio.recordings(:,a) = audioread(audiofiledir);
    end
end

if numVrec && numArec
    currentFrame = 1;
    currentSample = 1;
    [samplecount, ~] = size(audio.recordings);
    while currentSample <= samplecount
        if (currentFrame <= (framecounter-1))
            while ((currentSample-1) < video(1).frame(currentFrame+1).SamplesTimestamp) && ((currentSample-1) >= video(1).frame(currentFrame).SamplesTimestamp)
            audio.AssociatedVidFrame(currentSample) = currentFrame;
            currentSample = currentSample + 1;
            end
            currentFrame = currentFrame+1;
        else
            break
        end
    end
    audio.AssociatedVidFrame(currentSample+1:samplecount) = framecounter;
end
disp('Finished reading files')
disp('VIDEO: structs video(1), video(2) and video(3) each contain the corresponding cameras video.');
disp('Each video structure has a field frame and each frame has fields: image, SecondsTimestamp, SamplesTimestamp');
disp('AUDIO: struct audio has fields recordings (samples x channel) and AssociatedVidFrame');
