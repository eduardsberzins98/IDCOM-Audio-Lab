function FrameDriftSeconds = PostFFMPEGtsPlotter(fps, AVfolder, vidfoldername)
ffmpeg_path = 'C:\Users\LOCOBOT\Desktop\FFMPEG\ffmpeg-20190610-b124327-win64-static\bin';
videofile = 'C:\Users\LOCOBOT\Desktop\FFMPEG\ffmpeg-20190610-b124327-win64-static\bin\slideshow.mp4';
videofile = ['C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\', AVfolder, '\', vidfoldername, '\VFR1.mp4'];
TimeStampsSeconds = videoframets(ffmpeg_path,videofile);
OneFrameSeconds = 1/fps;
%% Calculate Frame length and drift
for c=1:(numel(TimeStampsSeconds)-1)
FrameDurationSeconds(c) = TimeStampsSeconds(c+1) - TimeStampsSeconds(c);
ExpectedSecondsUpToFrame(c) = (c-1)*OneFrameSeconds;
FrameDriftSeconds(c) = ExpectedSecondsUpToFrame(c) - TimeStampsSeconds(c);
end
FrameDurationSeconds(numel(TimeStampsSeconds)) = OneFrameSeconds;
ExpectedSecondsUpToFrame(numel(TimeStampsSeconds)) = (numel(TimeStampsSeconds)-1)*OneFrameSeconds;
FrameDriftSeconds(numel(TimeStampsSeconds)) = ExpectedSecondsUpToFrame(numel(TimeStampsSeconds)) - TimeStampsSeconds(numel(TimeStampsSeconds));

FrameDriftSeconds = medfilt1(FrameDriftSeconds);
