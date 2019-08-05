function CallibrateCameras(format, fps, numcam)
				
if numcam == 3
    v1 = videoinput('dcam', 1, format);
    s1 = v1.Source;
    s1.FrameRate = num2str(fps);
    v2 = videoinput('dcam', 2, format);
    s2 = v2.Source;
    s2.FrameRate = num2str(fps);
    v3 = videoinput('dcam', 3, format);
    s3 = v3.Source;
    s3.FrameRate = num2str(fps);
    
    preview(v1);
    preview(v2);
    preview(v3);
    
    stopprev3 = input('Stop preview? [y/n]', 's');
    if  stopprev3 == 'y'
    stoppreview(v1);
    stoppreview(v2);
    stoppreview(v3);
    closepreview(v1);
    closepreview(v2);
    closepreview(v3);
    delete(v1);
    delete(v2);
    delete(v3);
    clear v1 v2 v3;
    delete(imaqfind);
    end  
elseif numcam == 2
    v1 = videoinput('dcam', 1, format);
    s1 = v1.Source;
    s1.FrameRate = num2str(fps);
    v2 = videoinput('dcam', 2, format);
    s2 = v2.Source;
    s2.FrameRate = num2str(fps);
    
    preview(v1);
    preview(v2);
    
    stopprev2 = input('Stop preview? [y/n]', 's');
    if  stopprev2 == 'y'
    stoppreview(v1);
    stoppreview(v2);
    closepreview(v1);
    closepreview(v2);
    delete(v1);
    delete(v2);
    clear v1 v2;
    delete(imaqfind);
    end
elseif numcam == 1
    v1 = videoinput('dcam', 1, format);
    s1 = v1.Source;
    s1.FrameRate = num2str(fps);

    preview(v1);
    
    stopprev1 = input('Stop preview? [y/n]', 's');
    if  stopprev1 == 'y'
    stoppreview(v1);
    closepreview(v1);
    delete(v1);
    clear v1;
    delete(imaqfind);
    end
end
    
