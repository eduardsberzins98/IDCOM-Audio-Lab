%% AV Synchroniser
function [Recording,TimeStampsSamples,FrameDurationSamples] = AVSynchroniser(Recording, sampr, viddirectory1, fps, seconds)


%% Getting the Strobe Signal
disp('Looking at Camera trigger Information')
StrobeLocSamples = StrobeAnalyser(double(Recording(:,1)),sampr,fps,1);

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


%% Initial Frame Sync Error adjusting
[~,numChan] = size(Recording);
dosync = input('Do you want me to adjust the AUDIO [y/n]', 's');
if dosync == 'y'
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

if currentStamp ~= TotalFrames
    AdditionalStamps = TotalFrames - (currentStamp-3);
    for t=currentStamp+1:1:AdditionalStamps
        TimeStampsSamples(t) = TimeStampsSamples(t-1) + OneFrameSamples;
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
%% AV drift compensation
% From this point onward assume perfect initial sync
% tic;
% NewRecording = Recording(1:StrobeLocSamples(1),1:numChan);
% EndRecording = Recording(StrobeLocSamples(StrobeCount)+1:end,1:numChan);
% 
% for a = 1:(StrobeCount-1)
%     disp(['Please wait, adjusting: ' , num2str(round(100*(a/StrobeCount))), '%']);
%     
%     SplitRecording = Recording(StrobeLocSamples(a)+1:StrobeLocSamples(a+1),1:numChan);
% %     halfpoint = round((StrobeLocSamples(a+1) - StrobeLocSamples(a)+1)/2);
% %     FirstHalfSplitRecording = Recording(StrobeLocSamples(a)+1:halfpoint,1:numChan);
% %     SecondHalfSplitRecording = Recording(halfpoint:StrobeLocSamples(a+1),1:numChan);
%     if DriftPerStrobeSamples(a) < 0 %There should have been more samples in that strobe, add 0s
%        zeroArray = zeros(abs(DriftPerStrobeSamples(a)),numChan);
%        SplitRecording = [zeroArray;SplitRecording];
%     elseif DriftPerStrobeSamples(a) > 0 %There should have been less samples in that strobe, delete rows
%         SplitRecording(1:DriftPerStrobeSamples(a),:) = [];
%     end
%         
%     NewRecording = [NewRecording;SplitRecording];
%     clear zeroArray SplitRecording; 
% end
% Recording = [NewRecording;EndRecording];
% adjTime = toc;
% disp(['I adjusted in: ', num2str(adjTime), ' s']);
    
% for n = 1:(StrobeCount-1)
%     disp(['Please wait, adjusting: ' , num2str(round(100*(n/StrobeCount))), '%']);
%     FirstHalfRecording = Recording(1:StrobeLocSamples(n),:);
%     SecondHalfrecording = Recording(StrobeLocSamples(n)+1:end,:);
%     if DriftPerStrobeSamples(n) < 0 %There should have been more samples in that strobe, add 0s
%        zeroArray = zeros(abs(DriftPerStrobeSamples(n)),numChan);
%        Recording = [FirstHalfRecording;zeroArray;SecondHalfrecording];
%     elseif DriftPerStrobeSamples(n) > 0 %There should have been less samples in that strobe, delete rows
%         SecondHalfrecording(1:DriftPerStrobeSamples(n),:) = [];
%         Recording = [FirstHalfRecording;SecondHalfrecording];
%     end
%     clear FirstHalfRecording;
%     clear SecondHalfrecording;
%     clear zeroArray;
% end

%% Looking at new AV drift
% disp('Looking at NEW AV drift')
% clear StrobeLocSamples SamplesPerStrobe DriftPerStrobeSamples SamplesUpToStrobe ExpectedSamplesUpToStrobe AbsoluteDrift
% StrobeLocSamples = StrobeAnalyser(double(Recording(:,1)),sampr,fps,1);
% 
% [StrobeCount,~] = size(StrobeLocSamples);
% ExpectedSamplesPerStrobe = (3*(1/fps)*sampr);
% 
% for n = 1:(StrobeCount-1)
%     SamplesPerStrobe(n) = (StrobeLocSamples(n+1) - StrobeLocSamples(n));
%     DriftPerStrobeSamples(n) = SamplesPerStrobe(n) - ExpectedSamplesPerStrobe;
%     SamplesUpToStrobe(n) = StrobeLocSamples(n) - StrobeLocSamples(1);
%     ExpectedSamplesUpToStrobe(n) = (n-1)*ExpectedSamplesPerStrobe;
%     AbsoluteDrift(n) = ExpectedSamplesUpToStrobe(n) - SamplesUpToStrobe(n);
% end
% 
% figure;
% subplot(1,2,1);
% [~, SamplesPerStrobeSize] = size(SamplesPerStrobe);
% SamplesPerStrobeMS = (SamplesPerStrobe./sampr)*1000;
% ExpectedSamplesPerStrobeMS = (ExpectedSamplesPerStrobe./sampr)*1000;
% 
% plot(SamplesPerStrobeMS), hold on
% plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS ExpectedSamplesPerStrobeMS], 'k--'), hold on
% plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS-15 ExpectedSamplesPerStrobeMS-15], 'r--'), hold on
% plot([0 SamplesPerStrobeSize], [ExpectedSamplesPerStrobeMS+15 ExpectedSamplesPerStrobeMS+15], 'r--')
% title('Post-Sync AV drift (per strobe)'),xlabel('Strobe Count'), ylabel('Drift (ms)')
% 
% subplot(1,2,2);
% [~, SizeTotalDrift] = size(AbsoluteDrift);
% AbsoluteDriftMS = (AbsoluteDrift./sampr)*1000;
% 
% plot(AbsoluteDriftMS), hold on
% plot([0 SizeTotalDrift], [0 0], 'k--'), hold on
% plot([0 SizeTotalDrift], [15 15], 'r--'), hold on
% plot([0 SizeTotalDrift], [-15 -15], 'r--')
% title('Post-Sync drift (absolute)'), xlabel('Strobe Count'), ylabel('Drift (ms)')

end



