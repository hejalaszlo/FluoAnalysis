function convert1DTo2D(this)
    if isempty(this.RawImage) || isempty(this.RefImage) || isempty(this.MesMetadata)
        warning('ImagingData convert1DTo2D: not all required properties set');
        return
    end
    if ~this.IsLineScan
        warning('ImagingData convert1DTo2D: this is not a line scan');
        return
    end
    
    % Image to hold the converted video
    im = zeros(size(this.RefImage, 1), size(this.RefImage, 1), this.FrameNum);
    
    % Line scan coordinates converted to pixels
    l2 = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).line2;
    l2(1,:) = round((l2(1,:) - this.MesMetadata(3).WidthOrigin) / this.MesMetadata(3).WidthStep);
    l2(2,:) = this.MesMetadata(3).Height - round((l2(2,:) - this.MesMetadata(3).HeightOrigin) / this.MesMetadata(3).HeightStep);
    scanspeed = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).scanspeed;
    scanline = l2(1:2,scanspeed:scanspeed:length(l2));
    
    % 
    x = scanline(1,:);
    y = scanline(2,:);
    f0g = repmat(mean(this.RawImage(1, :, this.F0Range(1):this.F0Range(2), 1), 3), [1 1 this.FrameNum]);
    dfperf0 = squeeze((double(this.RawImage(1,:,:,1)) - f0g) ./ f0g);
    f0r = repmat(mean(this.RawImage(1, :, this.F0Range(1):this.F0Range(2), 2), 3), [1 1 this.FrameNum]);
    dgperr = squeeze((double(this.RawImage(1,:,:,1)) - f0g) ./ f0r);
    progressbar('Converting 1D image to 2D');
    for iPoint = 1:length(x)
        if x(iPoint) > 0 && x(iPoint) <= size(im, 2) && y(iPoint) > 0 && y(iPoint) < size(im, 1)
            for iFrame = 1:this.FrameNum
                im(y(iPoint), x(iPoint), iFrame) = dgperr(iPoint, iFrame);
            end
            
            progressbar(iPoint / length(x));
        end
    end
    
    VideoController(im, this);
end