function calculateDeltaFperF0(this)
    if isempty(this.F)
        warning('ImagingData calculateDeltaFperF0: not all required properties set');
        return
    end
    if isempty(this.F0Range)
        this.F0Range = [1 floor(this.FrameNum / 10)];
    end
    if strcmp(this.SubtractBackgroundLevelMode, 'auto')
        this.autoSubtractBackgroundLevel();
    end
    
    frameNum = this.FrameNum;
    cellNum = this.CellNum;
    
    % Calculate dF/F0
    deltaFperF0 = zeros(size(this.F));
    for iCh = 1:this.ChannelNum
        f = this.F(:,:,iCh) - repmat(this.SubtractBackgroundLevel(iCh), frameNum, cellNum, 1);
        f0 = squeeze(nanmean(f(this.F0Range(1):this.F0Range(2),:)));
        deltaFperF0(:,:,iCh) = bsxfun(@rdivide, bsxfun(@minus, f, f0), f0);
    end
    
    % Calculate dG/R
    deltaGperR = zeros(this.FrameNum, max(this.ROIs(:)));
    if this.ChannelRed > 0 && size(this.F, 3) >= this.ChannelRed
        fg = this.F(:,:,this.ChannelGreen) - repmat(this.SubtractBackgroundLevel(this.ChannelGreen), frameNum, cellNum, 1);
        f0g = squeeze(nanmean(fg(this.F0Range(1):this.F0Range(2),:)));
        fr = this.F(:,:,this.ChannelRed) - repmat(this.SubtractBackgroundLevel(this.ChannelRed), frameNum, cellNum, 1);
        deltaGperR = bsxfun(@minus, fg, f0g) ./ fr;
    end
    
    this.DeltaGperR = deltaGperR;
    this.DeltaFperF0 = deltaFperF0; % Should be the last one, because this will trigger displaying
end