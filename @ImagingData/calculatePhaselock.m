function calculatePhaselock(this)
	if isempty(this.DeltaFperF0)
        warning('ImagingData calculatePhaselock: not all required properties set');
        return
	end
	
	for iCell = 25:35%this.CellNum
		% Decompose signal
		dataSWA = bandpass(this.DeltaFperF0(:,iCell,1), [0.5 2], this.SamplingFrequency);
		dataHigh = highpass(this.DeltaFperF0(:,iCell,1), 4, this.SamplingFrequency);

		% Is higher frequency component phase-locked to SWA?
		phase = angle(hilbert(dataSWA));
		[counts, edges, idx] = histcounts(phase, 100);
		t = accumarray(idx, abs(dataHigh));
		figure;bar(linspace(-pi, pi, 100 )', t);
	end
end