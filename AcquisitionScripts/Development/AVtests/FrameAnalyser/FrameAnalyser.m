function hexinfo = FrameAnalyser(filelocation)


pixelrow = 1;
bytesread = 10; %how many bytes are we reading

counter = 1;
video = VideoReader(filelocation);
while hasFrame(video) && (counter < 10) 
    currentframe = readFrame(video);
    unint8info = currentframe(pixelrow,1:bytesread); %Read in first x bytes(8bits)
    for z = 1:bytesread
        binaryinfo = decimalToBinaryVector(unint8info(z),8); %Convert the int to 8 bits
        hexinfo1 = binaryVectorToHex(binaryinfo(1:4));
        hexinfo2 = binaryVectorToHex(binaryinfo(5:8));
        hexinfo(counter, 2*z-1:2*z) = [hexinfo1 hexinfo2];
    end
    counter = counter + 1;
end

