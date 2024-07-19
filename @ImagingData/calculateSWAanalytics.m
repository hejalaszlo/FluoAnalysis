function calculateSWAanalytics(this)
    if isempty(this.F)
        warning('ImagingData calculateSWAanalytics: not all required properties set');
        return
	end
    
	this.calculateWavelet([4 8]);
	this.SWAanalytics.maxcfs = max(this.Wavelet.CfsByFrequency, [], 2);
	this.SWAanalytics.mincfs = min(this.Wavelet.CfsByFrequency, [], 2);
	this.SWAanalytics.meancfs = mean(this.Wavelet.CfsByFrequency, 2);
	
	this.SWAanalytics.activecellsMaxMinRatio = (this.SWAanalytics.maxcfs ./ this.SWAanalytics.mincfs) > 2.5;
	% this.SWAanalytics.activecellsMaxMinRatio = (this.SWAanalytics.maxcfs ./ this.SWAanalytics.meancfs) > 2;
end