%% Time Stamp txt file writer

function tsfilename=tsWriter(TimeStampsSamples, sampr, fps, seconds, timenow, AVfolder)
format long;
TotalFrames = fps*seconds;
tsfilename = ['Timestamps_', timenow];
tsfileloc = ['../Recordings\',AVfolder,'/', tsfilename, '.txt'];
fileID = fopen(tsfileloc,'w');
TimeStampsSeconds = TimeStampsSamples./sampr;
for f=1:TotalFrames
    fprintf(fileID,'%4d %18.15f %9d \r\n',f,TimeStampsSeconds(f),TimeStampsSamples(f));
    tsMatrix(f, 1) = f;
    tsMatrix(f, 2) = TimeStampsSeconds(f);
    tsMatrix(f, 3) = TimeStampsSamples(f);
end
fclose(fileID);

tsfileCSV = ['../Recordings\',AVfolder,'/', tsfilename, '.csv'];
writematrix(tsMatrix, tsfileCSV);

format short;