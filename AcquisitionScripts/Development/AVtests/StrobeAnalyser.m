%% Analysing Strobe
function [StrobeLocSamples, StrobeLocPlotterSamples] = StrobeAnalyser(StrobeSignal,sampr,fps,plotStrobe)
%StrobeAnalyser(double(Recording(:,1)),sampr,fps);

[samples, ~] = size(StrobeSignal);
FilteredStrobeSignal = medfilt1(StrobeSignal, 400, 'truncate');
%FilteredStrobeSignal = StrobeSignal;
%risetime(FilteredStrobeSignal,'StateLevels', [0 0.014]);
[~,~, crossHigh] = risetime(FilteredStrobeSignal,'StateLevels', [0 0.014]);
%StrobeLocSamples = round(crossLow + (crossHigh - crossLow)./2);
StrobeLocSamples = round(crossHigh);
if plotStrobe
figure;
ms = ((1:samples)./sampr).*1000;
plot(ms,FilteredStrobeSignal),hold on
m = 1;
[StrobeLocSamplesSize, ~] = size(StrobeLocSamples);
for n = 1:samples
    if (m <= StrobeLocSamplesSize)
        if (n == StrobeLocSamples(m))
            StrobeLocPlotterSamples(n) = 0.014;
            m = m+1;
        else
            StrobeLocPlotterSamples(n) = 0;
        end
    end
end

StrobeLocPlotterSamples(numel(StrobeSignal)) = 0;

plot(ms,StrobeLocPlotterSamples,'LineWidth',1.5)
RangeMS = 3*3*(1/fps)*1000;
%RangeSamples = 3*3*(1/fps)*sampr;
xlim([0 RangeMS]);
title('Strobe Signal'), xlabel('Time (ms)'), ylabel('Amplitude')
end



