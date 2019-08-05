
function bandwidth = CalcBandwidth(format, fps, numcam, sampr,audio)

if strcmp(format,'RGB24_1024x768')
bpf = 24*1024*768;
elseif strcmp(format,'RGB24_1280x960')
bpf = 24*1280*960;
elseif strcmp(format,'RGB24_1600x1200')
bpf = 24*1600*1200;  
elseif strcmp(format,'RGB24_640x480')
bpf = 24*640*480;
elseif strcmp(format,'RGB24_800x600')
bpf = 24*800*600;
elseif strcmp(format,'Y16_1024x768')
bpf = 16*1024*768;
elseif strcmp(format,'Y16_1280x960')
bpf = 16*1280*960;
elseif strcmp(format,'Y16_1600x1200')
bpf = 16*1600*1200;
elseif strcmp(format,'Y16_640x480')
bpf = 16*640*480;
elseif strcmp(format,'Y16_800x600')
bpf = 16*800*600;
elseif strcmp(format,'Y411_640x480')
bpf = 12*640*480;
elseif strcmp(format,'Y422_1024x768')
bpf = 16*1024*768;
elseif strcmp(format,'Y422_1280x960')
bpf = 16*1280*960;
elseif strcmp(format,'Y422_1600x1200')
bpf = 16*1600*1200;
elseif strcmp(format,'Y422_320x240')
bpf = 16*320*240;
elseif strcmp(format,'Y422_640x480')
bpf = 16*640*480;
elseif strcmp(format,'Y422_800x600')
bpf = 16*800*600;
elseif strcmp(format,'Y444_160x120')
bpf = 24*160*120
elseif strcmp(format,'Y8_1024x768')
bpf = 8*1024*768;
elseif strcmp(format,'Y8_1280x960')
bpf = 8*1280*960;
elseif strcmp(format,'Y8_1600x1200')
bpf = 8*1600*1200;
elseif strcmp(format,'Y8_640x480')
bpf = 8*640*480;
elseif strcmp(format,'Y8_800x600')
bpf = 8*800*600;    
end

bandwidth = (bpf*fps*numcam) + (audio*sampr*28*24);
