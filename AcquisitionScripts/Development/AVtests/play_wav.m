
%PLAY_WAV Play a wav file
%
%play_wav( fileName, playDeviceID, chanList, startPoint, endPoint )
%   Plays the file fileName on Playrec device playDeviceID.  chanList
%   specifices the channels on which speakers are connected and must be a
%   row vector.  startPoint and endPoint are optional, and can be used to 
%   limit playback to a particular range of samples.
playDeviceID = 32
chanList = [1];
seconds = 10; %How long will the recording be%
sampr = 44100; %Sample Rate%
fps = 15;



%% Create the write signal
numChan = 1;
frameInSamples = round(sampr/fps);
msInSamples = round(sampr/1E3);
StrobeSignalDuration = round(1.5*sampr*seconds);
AudioStrobeSignal = ones(StrobeSignalDuration,numChan);
TrigPulse = zeros(msInSamples+1,numChan);

TrigCount = floor(StrobeSignalDuration/frameInSamples);

for n=1:TrigCount
TrigSample = frameInSamples*n;
AudioStrobeSignal(TrigSample:TrigSample+msInSamples,:) = TrigPulse;
end

Fs = AudioStrobeSignal;
fileSize = size(Fs);
fileLength = fileSize(1);
fileChanCount = fileSize(2);

startPoint = 1;
endPoint = fileLength;

pageSize = 4096;    %size of each page processed
pageBufCount = 5;   %number of pages of buffering

runMaxSpeed = false; %When true, the processor is used much more heavily 
                     %(ie always at maximum), but the chance of skipping is 
                     %reduced


if ~isreal(chanList) || length(chanList) < 1 || length(chanList) > 2 ...
    || ndims(chanList)~=2 || size(chanList, 1)~=1

    error ('chanList must be a real row vector with 1 or 2 elements');
end

%Test if current initialisation is ok
if(playrec('isInitialised'))
    if(playrec('getSampleRate')~=Fs)
        fprintf('Changing playrec sample rate from %d to %d\n', playrec('getSampleRate'), Fs);
        playrec('reset');
    elseif(playrec('getPlayDevice')~=playDeviceID)
        fprintf('Changing playrec play device from %d to %d\n', playrec('getPlayDevice'), playDeviceID);
        playrec('reset');
    elseif(playrec('getPlayMaxChannel')<max(chanList))
        fprintf('Resetting playrec to configure device to use more output channels\n');
        playrec('reset');
    end
end

%Initialise if not initialised
if(~playrec('isInitialised'))
    fprintf('Initialising playrec to use sample rate: %d, playDeviceID: %d and no record device\n', Fs, playDeviceID);
    playrec('init', Fs, playDeviceID, -1);
    
    % This slight delay is included because if a dialog box pops up during
    % initialisation (eg MOTU telling you there are no MOTU devices
    % attached) then without the delay Ctrl+C to stop playback sometimes
    % doesn't work.
    pause(0.1);
end
    
if(~playrec('isInitialised'))
    error ('Unable to initialise playrec correctly');
elseif(playrec('getPlayMaxChannel')<max(chanList))
    error ('Selected device does not support %d output channels\n', max(chanList));
end

if(playrec('pause'))
    fprintf('Playrec was paused - clearing all previous pages and unpausing.\n');
    playrec('delPage');
    playrec('pause', 0);
end

pageNumList = [];

fprintf('Playing from sample %d to sample %d with a sample rate of %d samples/sec\n', startPoint, endPoint, Fs);

for startSample = startPoint:pageSize:endPoint
    endSample = min(startSample + pageSize - 1, endPoint);
    
    y = wavread(fileName, [startSample endSample]);
    
    if length(chanList) == 1 && fileChanCount == 2
        y = (y(:, 1) + y(:, 2)) / 2;
    end

    if length(chanList) == 2 && fileChanCount == 1
        y = [y, y];
    end
    
    pageNumList = [pageNumList playrec('play', y, chanList)];

    if(startSample==startPoint)
        %This is the first time through so reset the skipped sample count
        playrec('resetSkippedSampleCount');
    end
    
    % runMaxSpeed==true means a very tight while loop is entered until the
    % page has completed whereas when runMaxSpeed==false the 'block'
    % command in playrec is used.  This repeatedly suspends the thread
    % until the page has completed, meaning the time between page
    % completing and the 'block' command returning can be much longer than
    % that with the tight while loop
    if(length(pageNumList) > pageBufCount)
        if(runMaxSpeed)
            while(playrec('isFinished', pageNumList(1)) == 0)
            end
        else        
            playrec('block', pageNumList(1));
        end

        pageNumList = pageNumList(2:end);
    end
end

fprintf('Playback complete with %d samples worth of glitches\n', playrec('getSkippedSampleCount'));
    