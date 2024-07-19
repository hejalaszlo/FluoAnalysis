function findActiveROIs(this, method)
    if isempty(this.RefImage) || isempty(this.RawImage)
        warning('ImagingData findROIs: not all required properties set');
        return
    end
    
    if this.IsLineScan == 1
        varIndex = zeros(1, size(this.RawImage, 2));
        lagnum = round(2 / this.SamplingInterval);
        for iCol = 1:size(this.RawImage, 2)
            col = double(squeeze(this.RawImage(1,iCol,:,1)));
            if strcmp(method, 'oscillation') == 1
                [c, lags] = xcorr(col - mean(col), lagnum);
                c(lagnum + 1) = NaN;
                varIndex(1, iCol) = max(c) - min(c);
%                 fh = figure;
%                 subplot 211;plot(lags,c);subplot 212;periodogram(col, rectwin(length(col)), linspace(0.1, 4, 100), this.Frequency);
%                 waitfor(fh);
            elseif strcmp(method, 'deviation') == 1
                varIndex(1, iCol) = std(col - mean(col));
            end
        end
        
        % Adjust threshold value for ROI segmentation
        l = length(varIndex);
        varIndex = msbackadj((1:l)', varIndex', 'WINDOWSIZE', l / 10, 'STEPSIZE', l / 10, 'SHOWPLOT', false);
        th = median(varIndex) * 2;
        
        % Mark ROIs
        iROI = 1;
        ROIs = zeros(size(this.ROIs));
        for iCol = 1:size(this.RawImage, 2)
            if varIndex(iCol) >= th
                ROIs(1, iCol) = iROI;
            elseif iCol > 1 && varIndex(iCol - 1) > th
                iROI = iROI + 1;
            end
        end

        this.ROIs = ROIs;
    else
        % Calculate average shift of the image
        shifted = zeros(this.CellNum, 1);
        for i = 1:this.FrameNum
            shifted(i) = mean2(this.RawImage(:,:,i));
        end
        windowSize = 100;
        trace = msbackadj(this.Time, shifted, 'WINDOWSIZE', windowSize, 'STEPSIZE', windowSize, 'SHOWPLOT', false);
        shift = shifted - trace;
        
        imActive1 = zeros(size(this.RawImage, 1), size(this.RawImage, 2));
        imActive2 = zeros(size(this.RawImage, 1), size(this.RawImage, 2));
        imActive3 = zeros(size(this.RawImage, 1), size(this.RawImage, 2));
        progressbar(0);
        numRow = size(this.RawImage, 1);
        for iY = 1:numRow
            for iX = 1:size(this.RawImage, 2)
                trace = msbackadj(this.Time', double(squeeze(this.RawImage(iY,iX,:,1))), 'WINDOWSIZE', windowSize, 'STEPSIZE', windowSize, 'SHOWPLOT', false);
                imActive1(iY, iX) = sum(trace(103:175));
                imActive2(iY, iX) = sum(trace(176:244));
                imActive3(iY, iX) = sum(trace(363:end));
            end
            progressbar(iY / numRow);
        end
    end
end