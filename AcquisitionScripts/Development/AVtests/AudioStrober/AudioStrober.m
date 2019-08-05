function [ ] = AudioStrober( fileName, playDeviceID, chanList)


Fs = 44100;
fileSize = size(audioread(fileName));
fileLength = fileSize(1);
fileChanCount = fileSize(2);

 playrec('init', Fs, playDeviceID, -1);
 fprintf('Playing');
 y = audioread(fileName);
playrec('play', y, chanList);



            while(playrec('isFinished') == 0)
            end

disp('End')