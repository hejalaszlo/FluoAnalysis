function plotCellsByWavelet(this)
	if isempty(this.Wavelet)
        warning('ImagingData plotCellsByWavelet: calculate wavelet before calling this function');
        return;
	end
	
	maxcfs = max(this.Wavelet.CfsByFrequency, [], 2);

	rois2d = double(this.ROIs2D);
	for i = 1:this.CellNum
		rois2d(rois2d == i) = maxcfs(i);
	end
	
	figure;
	imagesc(rois2d);
	title("Maximal power in selected frequency range")
	colorbar;
	colormap(jet);
end