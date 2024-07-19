function findROIs(this)
    if isempty(this.RefImage) || isempty(this.CellExtractionMinCellSize) || isempty(this.CellExtractionMaxCellSize) || isempty(this.CellExtractionBoundarySize)
        warning('ImagingData findROIs: not all required properties set');
        return
    end
    if size(this.RawImage, 1) == 1 &&(isempty(this.MesMetadata) || isempty(this.LineSegmentMinPixel))
        warning('ImagingData findROIs: not all required properties set');
        return
    end
    
    progressbar('Cell segmentation');
    
    % Convert image to grayscale and adjust contrast
    if size(this.RefImage, 3) == 3 % truecolor image
        picGray = imadjust(this.RefImage(:,:,2));
    elseif size(this.RefImage, 3) == 1 % grayscale image
        picGray = this.RefImage;
    end
        
    % Subtract unified background
%     background = imopen(picGray, strel('disk', 15));
%     picGray = imsubtract(picGray, background);

    % Subtract non-unified background
	if this.CellExtractionRollingBallRadius > 0
		picGray = imtophat(imfilter(picGray, ones(3,3) / 9), strel('ball', round(this.CellExtractionRollingBallRadius), round(this.CellExtractionRollingBallRadius)));
	else
		picGray = imtophat(imfilter(picGray, ones(3,3) / 9), strel('disk', 4, 4));
	end
    
    % Convert grayscale image to binary image
    if isempty(this.CellExtractionThreshold) || this.CellExtractionThreshold == 0
        this.CellExtractionThreshold = min(0.5, graythresh(picGray));
        % extractCells will be recalled after setting CellExtractionThreshold
        return
    end
    this.PicBW = im2bw(picGray, this.CellExtractionThreshold);
    
    progressbar(0.33);
    
    % Extract objects from image
    [objects, dummy] = bwlabel(this.PicBW, 4);

    % Remove objects that are outside the min and max cell sizes
    stats = regionprops(objects, 'Area');

    idx = find([stats.Area] >= this.CellExtractionMinCellSize & [stats.Area] <= this.CellExtractionMaxCellSize);
    ROIs2D = uint16(bwlabel(ismember(objects, idx), 4));
    
    % Reset valid cells
    this.Neuron = false(max(ROIs2D(:)), 1);
    this.Glia = false(max(ROIs2D(:)), 1);

    % Extend cells by n picels
    if ~isempty(this.CellExtractionBoundarySize) && this.CellExtractionBoundarySize > 0
        s = strel('disk', this.CellExtractionBoundarySize);
        ROIs2D = imdilate(ROIs2D, s);
    end
    
    this.ROIs2D = ROIs2D;
    
	% Show identified cells in pseudo color
    picPseudo = label2rgb(ROIs2D, 'lines', 'k');
    % TODO: notify picPseudo changed
%     figure; imshow(picPseudo);

    progressbar(0.66);
    
    % Convert to line scan positions
    if this.IsLineScan
        ROIs = zeros(1, size(this.RawImage, 2), 'uint16');
        l2 = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).line2;
		l2(1,:) = round((l2(1,:) - this.MesMetadata(3).WidthOrigin) / this.MesMetadata(3).WidthStep);
		l2(2,:) = this.MesMetadata(3).Height - round((l2(2,:) - this.MesMetadata(3).HeightOrigin) / this.MesMetadata(3).HeightStep);
        scanspeed = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).scanspeed;
        scanline = l2(1:2,scanspeed:scanspeed:length(l2));
        for i = 1:size(scanline,2)
            x = scanline(1,i);
            y = scanline(2,i);
            if x > 0 && x <= size(ROIs2D, 2) && y > 0 && y < size(ROIs2D, 1)
                ROIs(i) = ROIs2D(y,x);
            end
        end
        this.ROIs = ROIs;
        
        % Remove objects where too few pixels of the line scan resides
        [c, i] = hist(double(ROIs), 0:max(double(ROIs)));
        this.Neuron(i(c < this.LineSegmentMinPixel)) = 0;
        this.Glia(i(c < this.LineSegmentMinPixel)) = 0;
    else
        this.ROIs = ROIs2D;
    end
    
    progressbar(1);
end