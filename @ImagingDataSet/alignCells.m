function alignCells(this)
    shiftX = zeros(size(this.FileName, 1), 1);
    shiftY = zeros(size(this.FileName, 1), 1);
    for iFile = 2:size(this.FileName, 1)
        % Determine view shift
        shift = dftregistration(fft2(this.Data(iFile-1).RefImage(:,:,2)), fft2(this.Data(iFile).RefImage(:,:,2)), 10);
        shiftX(iFile) = -shift(4);
        shiftY(iFile) = -shift(3);
        
        % Shift ROI map
        sumshiftX = floor(sum(shiftX));
        rois2D = this.Data(iFile).ROIs2D;
        rois2D = circshift(rois2D, -sumshiftX, 1);
        if sumshiftX < 0
            rois2D(:,1:sumshiftX) = 0;
        else
            rois2D(:,end-sumshiftX+1:end) = 0;
        end
        sumshiftY = floor(sum(shiftY));
        rois2D = circshift(rois2D, -sumshiftY, 2);
        if sumshiftY < 0
            rois2D(1:sumshiftY,:) = 0;
        else
            rois2D(end-sumshiftY+1:end,:) = 0;
        end
        figure;
        imshowpair(this.Data(iFile-1).ROIs2D, rois2D, "Scaling", "joint")
    end
end 