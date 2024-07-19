function reportSWA(this)
	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	if (~isempty(this.MesImageIndex) && this.MesImageIndex > 0)
		filename = strcat(this.PicFileName, " " , num2str(this.MesImageIndex));
	else
		filename = this.PicFileName;
	end
	rpt = Report(strcat("SWA, ", filename), "docx");

	add(rpt, Heading1("Summary"));
	add(rpt, Paragraph("..."));
	add(rpt, PageBreak);
	
	% Power spectrum
	figure('units', 'centimeters', 'position', [0 0 16 8]);
	
	this.calculateWavelet([0.5 2]);
	
	cfsAstrocyte = this.Wavelet.Cfs;
	cfsAstrocyte(this.Neuron,:) = NaN;
	imagesc('XData', this.Wavelet.Frequency, 'YData', 1:size(this.Wavelet.Cfs, 1), 'CData', cfsAstrocyte);
	colormap copper;
	xlim([min(this.Wavelet.Frequency) max(this.Wavelet.Frequency)]);
	ylim([1 this.CellNum]);
	set(gca,'YDir','reverse');
	xlim([0.5 2]);
	set(gca,'XScale','log');
	xticks([0.5 0.6 0.7 0.8 0.9 1 1.2 1.5 2]);
	title('Imaging power spectrum (astrocytes)');
	xlabel('Frequency (Hz)');
	ylabel('Cell number');
	addFigureToReport(rpt, 16, this.CellNum / 10 + 2.5);

	if ~isempty(this.Ephys)
		dtE = (this.EphysTime(2) - this.EphysTime(1));
		wavelettype = 'cmor10-1';
		minscale = centfrq(wavelettype)/(0.5*dtE);
		maxscale = centfrq(wavelettype)/(2*dtE);
		scales = logspace(log10(minscale), log10(maxscale), 100);
		data = this.Ephys;
		ephysWaveletCfs = cwt(data, scales, wavelettype);
		ephysWaveletFrequency = scal2frq(scales, wavelettype, dtE);
		cfs = nansum(abs(ephysWaveletCfs)');
		plot(ephysWaveletFrequency, cfs);
		xlim([0.5 2]);
		set(gca,'XScale','log');
		xticks([0.5 0.6 0.7 0.8 0.9 1 1.2 1.5 2]);
		title('Ephys power spectrum');
		xlabel('Frequency (Hz)');
		ylabel('Sum power');
		addFigureToReport(rpt, 16, 4);
	end
	
	cfsNeuron = this.Wavelet.Cfs;
	cfsNeuron(this.Glia,:) = NaN;
	imagesc('XData', this.Wavelet.Frequency, 'YData', 1:size(this.Wavelet.Cfs, 1), 'CData', cfsNeuron);
	colormap copper;
	xlim([min(this.Wavelet.Frequency) max(this.Wavelet.Frequency)]);
	ylim([1 this.CellNum]);
	set(gca,'YDir','reverse');
	xlim([0.5 2]);
	set(gca,'XScale','log');
	xticks([0.5 0.6 0.7 0.8 0.9 1 1.2 1.5 2]);
	title('Imaging power spectrum (neurons)');
	xlabel('Frequency (Hz)');
	ylabel('Cell number');
	addFigureToReport(rpt, 16, this.CellNum / 10 + 2.5);

	if ~isempty(this.Ephys)
		dtE = (this.EphysTime(2) - this.EphysTime(1)) * 10;
		wavelettype = 'cmor10-1';
		minscale = centfrq(wavelettype)/(0.5*dtE);
		maxscale = centfrq(wavelettype)/(2*dtE);
		scales = logspace(log10(minscale), log10(maxscale), 50);
		data = this.Ephys(1:10:end,1);
		ephysWaveletCfs = cwt(data, scales, wavelettype);
		ephysWaveletFrequency = scal2frq(scales, wavelettype, dtE);
		cfs = nansum(abs(ephysWaveletCfs)');
		plot(ephysWaveletFrequency, cfs);
		xlim([0.5 2]);
		set(gca,'XScale','log');
		xticks([0.5 0.6 0.7 0.8 0.9 1 1.2 1.5 2]);
		title('Ephys power spectrum');
		xlabel('Frequency (Hz)');
		ylabel('Sum power');
		addFigureToReport(rpt, 16, 4);
	end
	
	% Active cells
	activecells = (max(this.Wavelet.Cfs, [], 2) ./ min(this.Wavelet.Cfs, [], 2)) > 2.5;
	maxcfs = max(this.Wavelet.Cfs, [], 2);

	% Active astrocytes
	add(rpt, PageBreak);
	add(rpt, Heading1("Active astrocytes"));

	rois2d = double(this.ROIs2D);
	for i = 1:this.CellNum
		if this.Glia(i)
			rois2d(rois2d == i) = maxcfs(i);
		else
			rois2d(rois2d == i) = 0;
		end
	end
	imagesc(rois2d);
	title("Maximal imaging power in 0.5-2 Hz")
	colorbar;
	colormap(jet);
	addFigureToReport(rpt, 16, 14);
	
	% Active neurons
	add(rpt, PageBreak);
	add(rpt, Heading1("Active neurons"));

	rois2d = double(this.ROIs2D);
	for i = 1:this.CellNum
		if this.Neuron(i)
			rois2d(rois2d == i) = maxcfs(i);
		else
			rois2d(rois2d == i) = 0;
		end
	end
	imagesc(rois2d);
	title("Maximal imaging power in 0.5-2 Hz")
	colorbar;
	colormap(jet);
	addFigureToReport(rpt, 16, 14);
	
	close(gcf);
	close(rpt);
end