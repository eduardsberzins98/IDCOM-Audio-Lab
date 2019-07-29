%% AV Synchroniser
function [Recording,TimeStampsSamples,FrameDurationSamples, FrameDriftSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds)


%% Getting the Strobe Signal
disp('Looking at Camera trigger Information')
[StrobeLocSamples, FilteredStrobeSignal, StrobeLocPlotterSamples] = StrobeAnalyser(double(Recording(:,1)),sampr,fps,1);
%% Calculating Strobe drift
[StrobeCount,~] = size(StrobeLocSamples);
ExpectedSamplesPerStrobe = round(3*(1/fps)*sampr);

for n = 1:(StrobeCount-1)
    SamplesPerStrobe(n) = (StrobeLocSamples(n+1) - StrobeLocSamples(n));
    SamplesUpToStrobe(n) = StrobeLocSamples(n) - StrobeLocSamples(1);
    ExpectedSamplesUpToStrobe(n) = (n-1)*ExpectedSamplesPerStrobe;
    StrobeDrift(n) = ExpectedSamplesUpToStrobe(n) - SamplesUpToStrobe(n);
    
    if SamplesPerStrobe(n) > 1.5*ExpectedSamplesPerStrobe
        disp(['WARNING: I MIGHT HAVE MISSED STROBE ', num2str(n)])
    end
    
end

%% Initial Trigger Sync Error
%Getting info on which out of 3 frames the recording started
disp('Looking at frame HEX info')
startedOn = FrameAnalyser(viddirectory1, seconds, fps);

%%Comparing to matching frames in other strobe periods, seeing which is
%%closer
SingleStrobeDelaySamples = (1/fps)*sampr;
switch startedOn %Strobes on frame 2
    case 0
        Option0 = StrobeLocSamples(1) - 2*SingleStrobeDelaySamples;
    case 1
        Option0 = StrobeLocSamples(1) - SingleStrobeDelaySamples;
    case 2
        Option0 = StrobeLocSamples(1);
end
OptionPos = Option0 + 3*SingleStrobeDelaySamples;
OptionNeg = Option0 - 3*SingleStrobeDelaySamples;

CompareOptions = [abs(OptionNeg), abs(Option0), abs(OptionPos)];
[~, ClosestOption] = min(CompareOptions);

switch ClosestOption
    case 1
        InitialFrameErrorSamples = OptionNeg;
    case 2
        InitialFrameErrorSamples = Option0;
    case 3
        InitialFrameErrorSamples = OptionPos;
end
disp(['Initial frame error: ', num2str(round((InitialFrameErrorSamples/sampr)*1000)), ' ms']);

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
    disp(['Adjusting AUDIO at INITIAL frame by ', num2str(InitialFrameErrorSamples)]);
    if InitialFrameErrorSamples > 0 %VIDEO events happen before AUDIO events
        %Need to cut out audio data
        Recording(1:abs(InitialFrameErrorSamples),:) = [];
    elseif InitialFrameErrorSamples < 0 %VIDEO events happen after AUDIO events
        %Need to add in some silence
        zeroArray = zeros(abs(InitialFrameErrorSamples),numChan);
        Recording = [zeroArray;Recording];
    end
%Creating Timesatmps
OneFrameSamples = round((1/fps)*sampr);

switch startedOn %Strobes on frame 2
    case 0
        Offset = 2*OneFrameSamples - StrobeLocSamples(1);
    case 1
        Offset = 1*OneFrameSamples - StrobeLocSamples(1);
    case 2
        Offset = 0*OneFrameSamples - StrobeLocSamples(1);
end

StrobeLocSamples(:) = StrobeLocSamples(:) + Offset; %Now the Strobe Locations have been alligned assuming perfect initial sync
TotalFrames = round(fps*seconds);
% Generating All timestamps
switch startedOn %Strobes on frame 2
    case 0
        TimeStampsSamples(1) = 0;
        TimeStampsSamples(2) = StrobeLocSamples(1) - OneFrameSamples;
        currentStrobe = 1;
        currentStamp = 3;
    case 1
        TimeStampsSamples(1) = 0;
        currentStrobe = 1;
        currentStamp = 2;
    case 2
        StrobeLocSamples(1) = 0; %make sure the first strobe is at 0
        currentStrobe = 1;
        currentStamp = 1;
end

while (currentStamp<=TotalFrames) && (currentStrobe<=StrobeCount)
TimeStampsSamples(currentStamp) = StrobeLocSamples(currentStrobe);
TimeStampsSamples(currentStamp+1) = StrobeLocSamples(currentStrobe) + OneFrameSamples;
TimeStampsSamples(currentStamp+2) = StrobeLocSamples(currentStrobe) + 2*OneFrameSamples;
currentStrobe = currentStrobe + 1;
currentStamp = currentStamp + 3;
end
[~, TimeStampCount] = size(TimeStampsSamples);
if TimeStampCount ~= TotalFrames
    disp(['I stopped at the ', num2str(TimeStampCount), ' stamp'])
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

disp('These are the first few timestamps:');
disp(TimeStampsSamples(1:9)./(sampr*1E-3));
disp('These are the first few strobes:');
disp(round(StrobeLocSamples(1:9)./(sampr*1E-3)));



