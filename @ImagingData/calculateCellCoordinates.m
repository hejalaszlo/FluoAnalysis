function calculateCellCoordinates(this)
    if ~isempty(this.ROIs2D)
        obj = regionprops(this.ROIs2D);
        value = cat(1, obj.Centroid);
        value(:,2) = size(this.ROIs2D, 2) - value(:,2);
    else
        centers = round(mean(this.MesMetadata(1).ScanLine.roi));
        value = this.MesMetadata(1).ScanLine.Data1(:,centers)';
    end
    
    this.CellCoordinates = value;
end