function startedOn = FrameAnalyser(filelocation, seconds, fps)

pixelrow = 1;%1
bytesread = 10; %5 %how many bytes are we reading
framegrab = 5;% 5

counter = 1;
video = VideoReader(filelocation);
while hasFrame(video) && (counter < framegrab) 
    currentframe = readFrame(video);
    unint8infoR = currentframe(pixelrow,1:bytesread,1); %Read in first x bytes(8bits)
    unint8infoG = currentframe(pixelrow,1:bytesread,2); 
    unint8infoB = currentframe(pixelrow,1:bytesread,3); 
    for z = 1:bytesread
        binaryinfoR = decimalToBinaryVector(unint8infoR(z),8); %Convert the int to 8 bits
        hexinfo1R = binaryVectorToHex(binaryinfoR(1:4));
        hexinfo2R = binaryVectorToHex(binaryinfoR(5:8));
        hexinfo(counter, 6*z-5:6*z-4) = [hexinfo1R hexinfo2R];
        
        binaryinfoG = decimalToBinaryVector(unint8infoG(z),8); %Convert the int to 8 bits
        hexinfo1G = binaryVectorToHex(binaryinfoG(1:4));
        hexinfo2G = binaryVectorToHex(binaryinfoG(5:8));
        hexinfo(counter, 6*z-3:6*z-2) = [hexinfo1G hexinfo2G];
        
        binaryinfoB = decimalToBinaryVector(unint8infoB(z),8); %Convert the int to 8 bits
        hexinfo1B = binaryVectorToHex(binaryinfoB(1:4));
        hexinfo2B = binaryVectorToHex(binaryinfoB(5:8));
        hexinfo(counter, 6*z-1:6*z) = [hexinfo1B hexinfo2B];   
        
    end
    counter = counter + 1;
end
startedOn = str2num(hexinfo(1,16));
disp('This was the HEX info from the first few frames:')
 disp(hexinfo(1:3,1:16));
if ~strcmp(hexinfo(1,9:15), '8000030')
    disp('WARNIGN: CANNOT FIND STROBE PATTERN HEX INFO IN VIDEO');
end


%% timsestamp info grabber
% for a=1:(framegrab-1)
%     binTimeStamp(a,1:32) = hexToBinaryVector(hexinfo(a,1:8), 32);
%     DecTimeStampCycles(a,1) = binaryVectorToDecimal(binTimeStamp(a,1:7));
%     DecTimeStampCycles(a,2) = binaryVectorToDecimal(binTimeStamp(a,8:20));
%     TimeStamp(a) = ((DecTimeStampCycles(a,2)).*(125E-6) + DecTimeStampCycles(a,1))*(1E3);
% end
% 
% ExpectedMSPerFrame = (1/fps)*1E3;
% for b=1:(framegrab-2)
%     FrameL(b) = TimeStamp(b+1)- TimeStamp(b);
%     ExpectedMSUpToFrame(b) = (b-1)*ExpectedMSPerFrame;
%     MSUpToFrame(b) = TimeStamp(b) - TimeStamp(1);
%     AbsoluteDriftMS(b) = ExpectedMSUpToFrame(b) - MSUpToFrame(b);
% end
% ExpectedFrameLMS = (1/15)*1E3;
% [~, SizeFrameL] = size(FrameL);
% figure;
% subplot(1,2,1);
% plot(FrameL), hold on
% plot([0 SizeFrameL], [ExpectedFrameLMS ExpectedFrameLMS], 'k--'), hold on
% title('Frame Duration (IMG Time Stamps)'), xlabel('Frame'), ylabel('Frame Duration (ms)')
% subplot(1,2,2);
% plot(AbsoluteDriftMS), hold on
% plot([0 SizeFrameL], [0 0], 'k--'), hold on
% title('Frame Drift (IMG Time Stamps)'), xlabel('Frame'), ylabel('Drift (ms)')



% if ~strcmp(hexinfo(1,1),'8')
%     disp('WARNING: CAN NOT FIND STROBE DATA IN FRAME HEX');
% end

% videoFReader = vision.VideoFileReader(filelocation);
% %videoFReader.ImageColorSpace = 'YCbCr 4:2:2';
% videoFReader.VideoOutputDataType = 'uint8';
% currentframe = videoFReader();
% unint8info = currentframe(pixelrow,1:bytesread); %Read in first x bytes(8bits)
% for z = 1:bytesread
%     binaryinfo = decimalToBinaryVector(unint8info(z),8); %Convert the int to 8 bits
%     hexinfo1 = binaryVectorToHex(binaryinfo(1:4));
%     hexinfo2 = binaryVectorToHex(binaryinfo(5:8));
%     hexinfo(2*z-1:2*z) = [hexinfo1 hexinfo2];
% end
