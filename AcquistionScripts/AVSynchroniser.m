%% AV Synchroniser Function
%That takes in the frame HEX info and Strobe Signal, calculates the initial
%frame to initial sample error and adjusts the audio accordingly and passes it
%back to the master script. It also creates the timestamps from the strobe signal
function [Recording,TimeStampsSamples,FrameDurationSamples, FrameDriftSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds, SPATERN)

%% Getting the Strobe Signal
disp('Looking at Camera trigger Information')
%Call strobe analyser, returns arrays with each strobe's location, the
%filtered strobe signal, array with nonzero values at the insances of
%strobes
[StrobeLocSamples, FilteredStrobeSignal, StrobeLocPlotterSamples] = StrobeAnalyser(double(Recording(:,1)),sampr,fps,1, SPATERN);
%% Calculating Strobe drift
[StrobeCount,~] = size(StrobeLocSamples);
ExpectedSamplesPerStrobe = round(SPATERN*(1/fps)*sampr);
%Calculate strobe drift
for n = 1:(StrobeCount-1)
    SamplesPerStrobe(n) = (StrobeLocSamples(n+1) - StrobeLocSamples(n));
    SamplesUpToStrobe(n) = StrobeLocSamples(n) - StrobeLocSamples(1);
    ExpectedSamplesUpToStrobe(n) = (n-1)*ExpectedSamplesPerStrobe;
    StrobeDrift(n) = ExpectedSamplesUpToStrobe(n) - SamplesUpToStrobe(n);

    if SamplesPerStrobe(n) > 1.5*ExpectedSamplesPerStrobe %Drift shouldn't be bigger than 1.5 x expected strobe duration
        warning(['I MIGHT HAVE MISSED STROBE ', num2str(n)])
    end

end

%% Initial Trigger Sync Error
%Gettning Strobe Pattern Number information for first frame
disp('Looking at frame HEX info')
startedOn = FrameAnalyser(viddirectory1, seconds, fps, SPATERN);

%% OPTION CREATOR
SingleStrobeDelaySamples = (1/fps)*sampr;

%SPATERN is the period of the strobe pattern, in this case 4
%Find last frame prior to strobe signal with same correct startedOn
Option0 = StrobeLocSamples(1) - (SPATERN - startedOn - 1)*SingleStrobeDelaySamples;
%Generate options one strobe ahead and behind
OptionPos = Option0 + SPATERN*SingleStrobeDelaySamples;
OptionNeg = Option0 - SPATERN*SingleStrobeDelaySamples;
disp('These were the options:')
disp([OptionNeg/(sampr*1E-3), Option0/(sampr*1E-3), OptionPos/(sampr*1E-3)]);

CompareOptions = [abs(OptionNeg), abs(Option0), abs(OptionPos)];
[~, ClosestOption] = min(CompareOptions);
%Find likeliest option
switch ClosestOption
    case 1
        InitialFrameErrorSamples = OptionNeg;
    case 2
        InitialFrameErrorSamples = Option0;
    case 3
        InitialFrameErrorSamples = OptionPos;
end

disp(['Initial frame error: ', num2str(((InitialFrameErrorSamples/sampr)*1000)), ' ms (', num2str(InitialFrameErrorSamples*fps/sampr), ' frames)']);
disp(['I would have found this with strobe pattern ', num2str(ceil(abs(2*InitialFrameErrorSamples*fps/sampr)))]);
%%
figure;
subplot(1,2,1);
[~, SamplesPerStrobeSize] = size(SamplesPerStrobe);
SamplesPerStrobeMS = (SamplesPerStrobe./sampr)*1000;
ExpectedSamplesPerStrobeMS = (ExpectedSamplesPerStrobe./sampr)*1000;

plot(SamplesPerStrobeMS), hold on
plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS ExpectedSamplesPerStrobeMS], 'k--'), hold on
plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS-15 ExpectedSamplesPerStrobeMS-15], 'r--'), hold on
plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS+15 ExpectedSamplesPerStrobeMS+15], 'r--')
title('Strobe duration'),xlabel('Strobe'), ylabel('Time (ms)')

subplot(1,2,2);
[~, SizeTotalDrift] = size(StrobeDrift);
AbsoluteDriftMS = (StrobeDrift./sampr)*1000;

plot(AbsoluteDriftMS), hold on
plot([0 SizeTotalDrift], [0 0], 'k--'), hold on
plot([0 SizeTotalDrift], [15 15], 'r--'), hold on
plot([0 SizeTotalDrift], [-15 -15], 'r--')
title('Strobe drift'), xlabel('Strobe'), ylabel('Drift (ms)')

%% Visualise delay of each strobe
% StrobeLocPlotterSamplesSize = numel(StrobeLocPlotterSamples);
% SamplesPerStrobeSize = numel(SamplesPerStrobeMS);
% m = 1;
% SiginficantDriftFlag = 0;
% for n = 1:(StrobeLocPlotterSamplesSize)
%     if m<=SamplesPerStrobeSize
%     if StrobeLocPlotterSamples(n)
%         StrobeDelayVisualiser(n) = (SamplesPerStrobeMS(m) - ExpectedSamplesPerStrobe/(sampr*1E-3))*1E-3;
%         if StrobeDelayVisualiser(n) >= 1E-3
%             SiginficantDriftFlag = 1;
%         end
%         m = m+1;
%     else
%         StrobeDelayVisualiser(n) = 0;
%     end
%     end
% end
% if SiginficantDriftFlag
% disp('There was significant drift for particular strobes')
% figure;
% z=1:numel(StrobeDelayVisualiser);
% [Peak, PeakIdx] = findpeaks(StrobeDelayVisualiser, 'MinPeakHeight', 1E-3);
% isNZ=(StrobeDelayVisualiser>=1E-3);
% plot(FilteredStrobeSignal, 'b'), hold on
% plot(z(isNZ), StrobeDelayVisualiser(isNZ),'r*'),
% for p=1:numel(PeakIdx)
% text(z(PeakIdx(p)), Peak(p), sprintf('%3.2f ms', Peak(p)*1E3))
% end
% title('Strobe Signal With Duration'),xlabel('Sample')
% end
%% Initial Frame Sync Error adjusting
[~,numChan] = size(Recording);
    disp(['Adjusting AUDIO at INITIAL frame by ', num2str(InitialFrameErrorSamples/(sampr*1E-3))]);
    if InitialFrameErrorSamples > 0 %VIDEO events happen before AUDIO events
        %Need to cut out audio data
        Recording(1:abs(InitialFrameErrorSamples),:) = [];
    elseif InitialFrameErrorSamples < 0 %VIDEO events happen after AUDIO events
        %Need to add in some silence
        zeroArray = zeros(abs(InitialFrameErrorSamples),numChan);
        Recording = [zeroArray;Recording];
    end

%% CREATING TIMESTAMPS
OneFrameSamples = round((1/fps)*sampr);

Offset = (SPATERN - startedOn - 1)*OneFrameSamples - StrobeLocSamples(1);
StrobeLocSamples(:) = StrobeLocSamples(:) + Offset; %Now the Strobe Locations have been alligned assuming perfect initial sync

TotalFrames = round(fps*seconds);

%ADD STAMPS UP TO FIRST STROBE
TimeStampsSamples(1) = 0;%make sure the first strobe is at 0
currentStrobe = 1;
currentStamp = SPATERN - startedOn;
if startedOn < (SPATERN - 2) %Didn't start on the pulse frame
    for s=2:(currentStamp - 1)
        TimeStampsSamples(s) = (s-1)*OneFrameSamples;
    end
end
%ADD STAMPS BETWEEN FIRST AND LAST STROBE
while (currentStamp<=TotalFrames) && (currentStrobe<=StrobeCount)
    for q=0:(SPATERN-1)
        TimeStampsSamples(currentStamp + q) = StrobeLocSamples(currentStrobe) + q*OneFrameSamples;
    end
    currentStrobe = currentStrobe + 1;
    currentStamp = currentStamp + SPATERN;
end
%ADD OR REMOVE STAMPS AFTER LAST STROBE
[~, TimeStampCount] = size(TimeStampsSamples);
if TimeStampCount ~= TotalFrames
    AdditionalStamps = TotalFrames - TimeStampCount;
    if AdditionalStamps > 0
    for t=TimeStampCount+1:1:TotalFrames
        TimeStampsSamples(t) = TimeStampsSamples(t-1) + OneFrameSamples;
    end
    elseif AdditionalStamps < 0
        TimeStampsSamples(TotalFrames+1:end) = [];
    end
end

[~, TimeStampCount] = size(TimeStampsSamples);
disp(['Generated ', num2str(TimeStampCount), ' time stamps'])

%% Calculate Frame length and drift
for c=1:(TimeStampCount-1)
FrameDurationSamples(c) = TimeStampsSamples(c+1) - TimeStampsSamples(c);
ExpectedSamplesUpToFrame(c) = (c-1)*OneFrameSamples;
FrameDriftSamples(c) = ExpectedSamplesUpToFrame(c) - TimeStampsSamples(c);
end
FrameDurationSamples(TimeStampCount) = OneFrameSamples;
ExpectedSamplesUpToFrame(TimeStampCount) = (TimeStampCount-1)*OneFrameSamples;
FrameDriftSamples(TimeStampCount) = ExpectedSamplesUpToFrame(TimeStampCount) - TimeStampsSamples(TimeStampCount);

OneFrameMS = OneFrameSamples/(sampr*1E-3);
figure;
subplot(1,2,1);
    plot(FrameDurationSamples./(sampr*1E-3)), hold on
    plot([0 numel(FrameDurationSamples)], [OneFrameMS OneFrameMS], 'k--'), hold on
    plot([0 numel(FrameDurationSamples)], [OneFrameMS-15 OneFrameMS-15], 'r--'), hold on
    plot([0 numel(FrameDurationSamples)], [OneFrameMS+15 OneFrameMS+15], 'r--')
    title('Frame Duration'),  xlabel('Frame'), ylabel('Time (ms)')
    ylim([0.8/(fps*1E-3) 1.2/(fps*1E-3)]);
subplot(1,2,2);
    plot(FrameDriftSamples./(sampr*1E-3)), hold on
    plot([0 numel(FrameDriftSamples)], [0 0], 'k--'), hold on
    plot([0 numel(FrameDriftSamples)], [15 15], 'r--'), hold on
    plot([0 numel(FrameDriftSamples)], [-15 -15], 'r--')
    title('Frame Drift'), xlabel('Frame'), ylabel('Drift (ms)')
format shortG
disp('These are the first few timestamps:');
disp(TimeStampsSamples(1:2*SPATERN)./(sampr*1E-3));
disp('These are the first few strobes:');
disp(((StrobeLocSamples(1:2*SPATERN)./(sampr*1E-3))).');
format short
