function tsfilename=ffmpegWriter(FrameDurationSamples, sampr, fps, seconds, timenow, AVfolder)
format long;
TotalFrames = fps*seconds;
formatImagePath = 'file frameimg/frame_%03d.bmp\r\n';
formatDuration = 'duration %16.15f\r\n';
tsfilename = ['TS_', timenow];
fileID = fopen(['../Recordings\',AVfolder,'/', tsfilename, '.txt'],'w');
FrameDurationSeconds = FrameDurationSamples./sampr;
for f=1:TotalFrames
    fprintf(fileID,formatImagePath,f);
    fprintf(fileID,formatDuration,FrameDurationSeconds(f));
end
fclose(fileID);
format short;