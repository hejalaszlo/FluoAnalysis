function calculateWavelet(this, frequencyRange)
	% Imaging
	wavelettype = 'cmor1-6';
	dt = this.Time(2) - this.Time(1);
	minscale = centfrq(wavelettype)/(frequencyRange(1)*dt);
	maxscale = centfrq(wavelettype)/(frequencyRange(2)*dt);
	scales = logspace(log10(minscale), log10(maxscale), 100);
	waveletCfs = cell(this.CellNum, 1);
	for iCell = 1:this.CellNum
		data = this.DeltaFperF0(:,iCell,1);
		waveletCfs{iCell} = cwt(data, scales, wavelettype);
		waveletCfs{iCell}(:, this.Time < 3 | this.Time > max(this.Time) - 3) = NaN; % Delete first and last 3 s due to border effect
	end
	
	cfsByTime = cell2mat(cellfun(@(x) nanmax(abs(x)), waveletCfs, 'UniformOutput', false));
	cfsByTime = cfsByTime ./ max(cfsByTime(:));

	cfsByFrequency = cell2mat(cellfun(@(x) nansum(abs(x)'), waveletCfs, 'UniformOutput', false));
	cfsByFrequency = cfsByFrequency ./ max(cfsByFrequency(:));
	
	this.Wavelet.CfsByTime = cfsByTime;
	this.Wavelet.CfsByFrequency = cfsByFrequency;
	this.Wavelet.Frequency = scal2frq(scales, wavelettype, dt);
	this.Wavelet.Time = this.Time;

	% Ephys
	dt = (this.EphysTime(2) - this.EphysTime(1)) * 10;
	minscale = centfrq(wavelettype)/(frequencyRange(1)*dt);
	maxscale = centfrq(wavelettype)/(frequencyRange(2)*dt);
	scales = logspace(log10(minscale), log10(maxscale), max(round(frequencyRange(2) - frequencyRange(1)) * 5, 50));
	data = this.Ephys(1:10:end, 1);
	ephysTime = dt:dt:size(data,1)*dt;
	cfs = cwt(data, scales, wavelettype);
	cfs(:, ephysTime < 3 | ephysTime > max(ephysTime) - 3) = NaN; % Delete first and last 3 s due to border effect
	
	this.Wavelet.CfsEphys = abs(cfs);
	this.Wavelet.FrequencyEphys = scal2frq(scales, wavelettype, dt);
	this.Wavelet.TimeEphys = ephysTime;
end