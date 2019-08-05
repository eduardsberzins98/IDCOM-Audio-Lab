clear all;
clc;

seconds = 10; %How long will the recording be%
sampr = 44100; %Sample Rate%
fps = 15;

%% Create the write signal
numChan = 1;
frameInSamples = round(sampr/fps);
msInSamples = 2*round(sampr/1E3);
StrobeSignalDuration = round(1.5*sampr*seconds);
AudioStrobeSignal = 0.5*ones(StrobeSignalDuration,numChan);
TrigPulse = zeros(msInSamples+1,numChan);

TrigCount = floor(StrobeSignalDuration/frameInSamples);

for n=1:TrigCount
TrigSample = frameInSamples*n;
AudioStrobeSignal(TrigSample:TrigSample+msInSamples,:) = TrigPulse;
end

playrec('init', sampr, 32, -1);
fprintf('Playing');
playrec('play', AudioStrobeSignal, 1);

while(playrec('isFinished') == 0)
end

plot(AudioStrobeSignal)
xlim([0 5*frameInSamples]);
ylim([-1 2]);


