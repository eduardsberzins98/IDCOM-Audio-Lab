%% Analysing Strobe
function [StrobeLocSamples, StrobeSignal, StrobeLocPlotterSamples] = StrobeAnalyser(StrobeSignal,sampr,fps,plotStrobe)
%test
[samples, ~] = size(StrobeSignal);
%% Plot Strobe Signal Spectrum
% Spectrum = fft(StrobeSignal);
% P2 = abs(Spectrum/2);
% P1 = P2(1:round(samples/2+1));
% P1(2:end-1) = 2*P1(2:end-1);
% f = sampr*(0:(round(samples/2)))/samples;
% figure;
% plot(f,P1)
%xlim([0 60])

%% Find Strobe Times
[~,crossLow, crossHigh] = risetime(StrobeSignal,'StateLevels', [0.01 0.02]);
[~,~, crossHighFall] = falltime(StrobeSignal,'StateLevels', [0.01 0.02]);

StrobeLocSamples = round(crossLow + (crossHigh - crossLow)./2);
%testing for false pulses, too which are shorter than 20ms
if crossHighFall(1) > crossHigh(1)
    for e=1:numel(crossLow)
        if (crossHighFall(e) - crossHigh(e)) < (sampr*20E-3) %strobe pulse is less than 20ms
            disp(['False pulse at ' , num2str(round(crossHigh(e)/(sampr*1E-3))), ' sample for ', num2str((crossHighFall(e) - crossHigh(e))/(sampr*1E-3)), ' ms']);
            StrobeLocSamples(e) = [];
        end
    end
elseif crossHighFall(1) < crossHigh(1)
    for e=1:(numel(crossLow)-1)
        if (crossHighFall(e+1) - crossHigh(e)) < (sampr*20E-3) %strobe pulse is less than 20ms
            disp(['False pulse at ' , num2str(round(crossHigh(e)/(sampr*1E-3))), ' ms for ', num2str((crossHighFall(e+1) - crossHigh(e))/(sampr*1E-3)), ' ms']);
            StrobeLocSamples(e) = [];
        end
    end 
end

if plotStrobe
figure;
ms = ((1:samples)./sampr).*1000;
plot(ms,StrobeSignal),hold on
m = 1;
[StrobeLocSamplesSize, ~] = size(StrobeLocSamples);
for n = 1:samples
    if (m <= StrobeLocSamplesSize)
        if (n == StrobeLocSamples(m))
            StrobeLocPlotterSamples(n) = 0.015;
            m = m+1;
        else
            StrobeLocPlotterSamples(n) = 0;
        end
    end
end

StrobeLocPlotterSamples(numel(StrobeSignal)) = 0;

plot(ms,StrobeLocPlotterSamples,'LineWidth',1.5)
RangeMS = 5*3*(1/fps)*1000;
%RangeSamples = 3*3*(1/fps)*sampr;
xlim([0 RangeMS]);
title('Strobe Signal'), xlabel('Time (ms)'), ylabel('Amplitude')
end



