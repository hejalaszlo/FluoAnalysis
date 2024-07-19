function autoClassifyCells(this)
%     ratio = this.GRRatio;
    
    % Auto validate cells
%     s = strel('disk', this.CellExtractionBoundarySize);
%     ROIs2DInner = imerode(this.ROIs2D, s);
%     propsInner = regionprops(ROIs2DInner, this.RefImage(:,:,2), 'MeanIntensity');
%     s = strel('disk', 7);
%     ROIs2DOuter = imdilate(ROIs2DInner, s);
%     propsOuter = regionprops(ROIs2DOuter - ROIs2DInner, this.RefImage(:,:,2), 'MeanIntensity');
%     ioRatio = [propsInner.MeanIntensity] ./ [propsOuter.MeanIntensity];
    
    % Auto classify cells
%     this.Neuron(this.ValidCell ~= 0 & ratio' > 2) = 1;
%     this.Glia(this.ValidCell ~= 0 & ratio' > 2) = 0;
%     this.Glia(this.ValidCell ~= 0 & ratio' <= 2) = 1;
%     this.Neuron(this.ValidCell ~= 0 & ratio' <= 2) = 0;
    
%     this.Neuron(ratio' > 2) = 1;
%     this.Glia(ratio' > 2) = 0;
%     this.Glia(ratio' <= 2) = 1;
%     this.Neuron(ratio' <= 2) = 0;
% 	fprintf("Cells are auto classified: %d astrocytes, %d neurons, %d not cells\n", nansum(this.Glia), nansum(this.Neuron), nansum(~this.Glia & ~this.Neuron));

	if isempty(this.ROIs2D)
		this.Glia = false(this.CellNum, 1);
		this.Neuron = false(this.CellNum, 1);
		return
	end
	
	objectStats = regionprops(this.ROIs2D, {'Area', 'Eccentricity'});
	area = [objectStats.Area];
	eccentricity = [objectStats.Eccentricity];
	r = regionprops(this.ROIs2D, this.RefImage(:,:,1), {'MeanIntensity', 'MaxIntensity'});
	g = regionprops(this.ROIs2D, this.RefImage(:,:,2), {'MeanIntensity', 'MaxIntensity'});
	raround = regionprops(imdilate(this.ROIs2D, strel('disk', 7)) - imerode(this.ROIs2D, strel('disk', this.CellExtractionBoundarySize)), this.RefImage(:,:,1), 'MeanIntensity');
	garound = regionprops(imdilate(this.ROIs2D, strel('disk', 7)) - imerode(this.ROIs2D, strel('disk', this.CellExtractionBoundarySize)), this.RefImage(:,:,2), 'MeanIntensity');
	rperg = [r.MeanIntensity] ./ [g.MeanIntensity];
	rmax = [r.MaxIntensity];
	gmax = [g.MaxIntensity];
	gpergaround = [g.MeanIntensity] ./ [garound.MeanIntensity];
	rperraround = [r.MeanIntensity] ./ [raround.MeanIntensity];
	
	this.Glia = area > 100 & (eccentricity < 0.85 | rperraround > 2) & rperraround > 1.3;
	this.Neuron = area > 100 & (eccentricity < 0.85 | gpergaround > 2) & rperg < 0.65 & rmax < 1 & gpergaround > 1.3;
	this.Glia(this.Neuron) = false;
	fprintf("Cells are auto classified: %d astrocytes, %d neurons, %d not cells\n", sum(this.Glia), sum(this.Neuron), sum(~this.Glia & ~this.Neuron));
end