function VFRcreator(AVfolder, vidfoldername, tsfilename, VFRcam)

%ffmpegpath = 'C:\Users\LOCOBOT\Desktop\FFMPEG\ffmpeg-20190610-b124327-win64-static\bin';
cd C:\Users\LOCOBOT\Desktop\FFMPEG\ffmpeg-20190610-b124327-win64-static\bin;
system('mkdir frameimg');
videofilepath = ['"C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\', AVfolder, '\', vidfoldername, '\crec', num2str(VFRcam), '.avi"'];
tsfilepath = ['"C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\', AVfolder, '\', tsfilename, '.txt"'];
outputfilepath = ['"C:\Users\LOCOBOT\Desktop\AudioLab\Recordings\', AVfolder, '\', vidfoldername, '\VFR', num2str(VFRcam), '.mp4"'];
splitImgages = ['ffmpeg -i ', videofilepath, ' frameimg/frame_%03d.bmp'];
system(splitImgages);
createSlideShow = ['ffmpeg -f concat -i ',  tsfilepath, ' -vsync vfr -c:v libx264rgb -crf 0 -preset ultrafast ', outputfilepath];
system(createSlideShow);
rmdir('frameimg', 's');
cd C:\Users\LOCOBOT\Desktop\AudioLab\AcquistionScripts;