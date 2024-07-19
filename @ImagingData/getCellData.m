function response = getCellData(this, cellnum)
    if isempty(this.ROIs) && isempty(this.ROIs2D)
        warning('ImagingData getCellData: not all required properties set');
        return;
	end
    
    response = struct;
	
	% Get cell coordinates
	if ~isempty(this.MesMetadata) && this.IsLineScan % mes file, we need to convert the ROIs to real 2D coordinates
        if isempty(this.ROIs2D) % 1D ROIs
            obj = find(this.ROIs == cellnum) * this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).scanspeed;
            l = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).line2(:,obj);
            if isempty(l)
				warning('1D ROI could not be identified');
                return;
            end
            l(1,:) = round((l(1,:) - this.MesMetadata(3).WidthOrigin) / this.MesMetadata(3).WidthStep);
            l(2,:) = this.MesMetadata(3).Height - round((l(2,:) - this.MesMetadata(3).HeightOrigin) / this.MesMetadata(3).HeightStep);
            rect = [min(l(1,:))-10 min(l(2,:))-10 max(l(1,:))-min(l(1,:))+20 max(l(2,:))-min(l(2,:))+20];
			roiPerim = false(size(this.RefImage(:,:,1)));
            roiPerim(max(1, rect(2)):rect(2)+rect(4)-1, max(1, rect(1)):rect(1)+rect(3)-1) = 1;
            roiPerim = bwperim(roiPerim);
       else % 2D ROIs
            objectStats = regionprops(this.ROIs2D, 'Centroid');
            width = 40/this.PixelHeight;
            top = max(0, objectStats(cellnum).Centroid(1) - width/2/this.PixelWidth);
            left = max(0, objectStats(cellnum).Centroid(2) - width/2/this.PixelHeight);
            rect = [top left width width];
            roi = logical(this.ROIs2D == cellnum);
            roiPerim = logical(bwperim(this.ROIs2D == cellnum));
        end
	else % tiff files
		objectStats = regionprops(this.ROIs, 'Centroid');
        width = 40;
        top = max(0, objectStats(cellnum).Centroid(1) - width/2);
        left = max(0, objectStats(cellnum).Centroid(2) - width/2);
        rect = [top left width width];
        roi = logical(this.ROIs2D == cellnum);
        roiPerim = logical(bwperim(this.ROIs2D == cellnum));
	end
	response.rect = rect;
	response.roi = imcrop(roi, rect);
	response.roiPerim = imcrop(roiPerim, rect);
	
	% Get image
	response.image = imcrop(this.RefImage, rect);
	
	% Get wavelet
	wavelettype = 'cmor1-2';
	dt = this.SamplingInterval;
    fmin = 0.1;
    fn = this.SamplingFrequency / 2;
	minscale = centfrq(wavelettype)/(fmin*dt);
	maxscale = centfrq(wavelettype)/(fn*dt);
	scales = logspace(log10(minscale), log10(maxscale), fn*5);
	data = this.DeltaFperF0(:,cellnum,1);
	response.waveletFrequency = scal2frq(scales, wavelettype, dt);
	response.waveletCfs = cwt(data, scales, wavelettype);
	response.waveletTime = dt:dt:size(data,1)*dt;
end