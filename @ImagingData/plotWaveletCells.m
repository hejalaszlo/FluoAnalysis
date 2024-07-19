function plotWaveletCells(this, varargin)
	% figure;

	% Maximal power within a band vs. time for all cells
	ax(1) = subplot(3,1,1);
    pcolor(this.Wavelet.Time, 1:this.CellNum, this.Wavelet.CfsByTime);
	xlim([min(this.Time) max(this.Time)]);
	c(:,1) = ones(255,1)';
	c(:,2) = linspace(1, 0, 255)';
	c(:,3) = linspace(1, 0, 255)';
	colormap(ax(1), c);
	shading flat;
	xlabel('Time (s)');
	ylabel('Cell #');
	
	% Frequency distribution for all cells
	ax(2) = subplot(3,1,2);
    pcolor(this.Wavelet.Frequency, 1:this.CellNum, this.Wavelet.CfsByFrequency);
	xlim([min(this.Wavelet.Frequency) max(this.Wavelet.Frequency)]);
	c(:,1) = linspace(1, 0, 255)';
	c(:,2) = linspace(1, 0, 255)';
	c(:,3) = ones(255,1)';
	colormap(ax(2), c);
	shading flat;
	xlabel('Frequency (Hz)');
	ylabel('Cell #');

	% Ephys
	ax(3) = subplot(3,1,3);
    pcolor(this.Wavelet.TimeEphys, this.Wavelet.FrequencyEphys, this.Wavelet.CfsEphys);
	colormap(ax(3), jet);
	shading flat;
	xlabel('Time (s)');
	ylabel('Ephys frequency (Hz)');

	spaceplots;
end