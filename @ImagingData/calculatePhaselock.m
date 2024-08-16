function calculatePhaselock(this, varargin)
	if isempty(this.DeltaFperF0)
        warning('ImagingData calculatePhaselock: not all required properties set');
        return
	end

	if ~isempty(varargin)
		% Use filtered data
		frequencyRange = varargin{1};
		filterOrder = round(1000 / frequencyRange(end) / this.SamplingFrequency);
		filtPts = fir1(filterOrder, 2 / this.SamplingFrequency * frequencyRange);
		filteredData = filter(filtPts, 1, this.DeltaFperF0(:,:,1), [], 1);
	else
		% Use original data
		filteredData = this.DeltaFperF0(:,:,1);
	end

	% Calculating PLV
	angleData = zeros(size(filteredData));
	for cellCount = 1:this.CellNum
    	angleData(:, cellCount) = angle(hilbert(squeeze(filteredData(:, cellCount))));
	end

	angleData(1:filterOrder,:) = 0;
	angleData(end-filterOrder+1:end,:) = 0;

	result = nan(this.CellNum, this.CellNum);
	for cellCount = 1:this.CellNum-1
    	channelData = squeeze(angleData(:, cellCount));
		for compareCellCount = cellCount+1:this.CellNum
        	compareChannelData = squeeze(angleData(:, compareCellCount));
        	result(cellCount, compareCellCount) = abs(sum(exp(1i*(channelData - compareChannelData)), 1)) / size(filteredData, 1);
			result(compareCellCount, cellCount) = result(cellCount, compareCellCount);
		end
	end
	
	result = squeeze(result);

	this.PhaseLock = result;

	% SWA to theta (4-8 Hz)
	% this.PhaseLock.SWA = calculatePLV(this, [4 8]);
end