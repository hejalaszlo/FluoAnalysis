function calculateCellCoordinates(this)
    if ~isempty(this.ROIs2D)
        obj = regionprops(this.ROIs2D, "Centroid", "Area", "Eccentricity", "BoundingBox");
        value = cat(1, obj.Centroid);
        value(:,2) = size(this.ROIs2D, 2) - value(:,2);
		value(:,3) = cat(1, obj.Area);
		value(:,4) = cat(1, obj.Eccentricity);
    else
        centers = round(mean(this.MesMetadata(1).ScanLine.roi));
        value = this.MesMetadata(1).ScanLine.Data1(:,centers)';
	end

	centerX = value(:,1);
	centerY = value(:,2);
	if size(value, 2) >= 3
		area = value(:,3);
	else
		area = zeros(size(value, 1));
	end
	if size(value, 2) >= 4
		eccentricity = value(:,4);
	else
		eccentricity = zeros(size(value, 1));
	end

    this.CellCoordinates = table(centerX, centerY, area, eccentricity);

	% Cell distances
	dist = nan(this.CellNum, this.CellNum);
	for iCell1 = 1:this.CellNum
		for iCell2 = iCell1+1:this.CellNum
			dist(iCell1, iCell2) = sqrt(((centerX(iCell1) - centerX(iCell2)) * this.PixelWidth)^2 + ((centerY(iCell1) - centerY(iCell2)) * this.PixelHeight)^2);
			dist(iCell2, iCell1) = dist(iCell1, iCell2);
		end
	end

	this.CellDistance = dist;
end