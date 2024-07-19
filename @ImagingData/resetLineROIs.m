function resetLineROIs(this, filepath, varargin)
    if isempty(this.MesMetadata) || isempty(this.RefImage)
        warning('ImagingData resetLineROIs: not all required properties set');
        return
    end
    
    sizeX = this.MesMetadata(1).DIMS(1);
    line = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).line2RoI;
    line = ceil(line ./ this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).scanspeed);
    ROIs = zeros(1, sizeX, 'uint16');
    for iRoi = 1:size(line, 2)
        roi = line(:,iRoi);
        ROIs(roi(1):min(roi(2), sizeX)) = iRoi;
    end
    
    this.ROIs2D = [];
    this.ROIs = ROIs;
    this.PicBW = zeros(size(this.RefImage(:,:,1)));
end