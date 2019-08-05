%% Strobe Signal Checker
function StrobeCheck(defaultID, sampr, fps)

playrec('init', sampr, -1, defaultID);
playrec('rec',5,[1 2]);
disp('Checking Strobe Signal')
pause(5);
StrobeCheckRec = playrec('getRec',0);
figure;
plot(StrobeCheckRec)

%StrobeAnalyser(double(StrobeCheckRec),sampr,fps,1);

clear playrec;