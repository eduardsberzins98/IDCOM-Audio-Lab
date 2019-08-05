function trigSamples, = StrobeAnalyser(StrobeSignal)
%% Analysing Strobe
%StrobeSignal = audioread('arec_1.wav');
[samples,channels] = size(StrobeSignal);

med = medfilt1(StrobeSignal, 100, 'truncate');

thresh = 0.007;
for m = 1:(samples-1)
    if (med(m) < thresh)&&(med(m+1) > thresh)
        trig(m) = thresh;
    end
end

trigSamples = find(trig);
%trigMs = (trigSamples/44100)*1000;
%disp(trigMs(1:5));
plot(trig)
xlim([0 8400]);
hold on 
plot(med);
% hold on
% plot(trig)



