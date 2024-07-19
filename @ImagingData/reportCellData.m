function reportCellData(this)
	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	figure('units', 'centimeters', 'position', [0 0 16 8]);
	
	if (~isempty(this.MesImageIndex) && this.MesImageIndex > 0)
		filename = strcat(this.PicFileName, " " , num2str(this.MesImageIndex));
	else
		filename = this.PicFileName;
	end
	rpt = Report(strcat("Cell data, ", filename), "docx");

	add(rpt, Heading1("Summary"));
	add(rpt, Paragraph("..."));
	add(rpt, PageBreak);
	
	stats = regionprops(this.ROIs2D, 'Orientation', 'BoundingBox', 'Circularity', 'Extent', 'Eccentricity');
	celldata = this.getCellDataAll;
	for iCell = 1:this.CellNum
		celldata.waveletCfs{iCell}(:, celldata.waveletTime(iCell,:) < 3 | celldata.waveletTime(iCell,:) > max(celldata.waveletTime(iCell,:)) - 3) = NaN; % Delete first and last 3 s due to border effect
	end
	
	c(:,1) = [ones(127,1); linspace(1, 0, 128)'];
	c(:,2) = [linspace(0, 1, 127)'; 1; linspace(1, 0, 127)'];
	c(:,3) = [linspace(0, 1, 128)'; ones(127,1)];

	% Parameters
	add(rpt, Heading1("Parameters"));
	
	para = Paragraph;
	para.WhiteSpace = 'preserve';
	if ~isempty(this.MesMetadata)
		append(para, sprintf("Date: %s\r\n", this.MesMetadata(1).MeasurementDate));
		append(para, sprintf("Experiment id: %u\r\n", this.MesImageIndex));
		append(para, sprintf("Comment: %s\r\n", this.MesMetadata(1).Comment));
		append(para, sprintf("PMT power: %u %% UG, %u %% UR\r\n", this.MesMetadata(1).DevicePosition.UG, this.MesMetadata(1).DevicePosition.UR));
		append(para, sprintf("Objective: %s\r\n", this.MesMetadata(1).HardwareState.Objective));
	end
	append(para, sprintf("Sampling frequency: %0.1f Hz\r\n", this.SamplingFrequency));
	append(para, sprintf("Resolution: %0.3f x %0.3f um/pixel\r\n", this.PixelWidth, this.PixelHeight));
	append(para, sprintf("Cells: %u astrocytes, %u neurons, %u not cells (total: %u)\r\n", sum(this.Glia), sum(this.Neuron), sum(~this.Glia & ~this.Neuron), this.CellNum));
	add(rpt, para);
	
	% Ephys
	if ~isempty(this.Ephys)
		add(rpt, PageBreak);
		add(rpt, Heading1("Electrophysiology"));
        plot(this.EphysTime, this.Ephys);
        xlim([min(this.EphysTime) max(this.EphysTime)]);
        xlabel('Time (s)');
        ylabel('Ephys');
        title('Raw electrophysiological signal');
        addFigureToReport(rpt, 16, 10);
		
		% Wavelet
		wavelettype = 'cmor1-2';
		dt = (this.EphysTime(2) - this.EphysTime(1)) * 10;
		fmin = 0.5;
		fn = this.SamplingFrequency / 2;
		minscale = centfrq(wavelettype)/(fmin*dt);
		maxscale = centfrq(wavelettype)/(fn*dt);
		scales = logspace(log10(minscale), log10(maxscale), fn*5);
		data = this.Ephys(1:10:end,1);
		ephysWaveletFrequency = scal2frq(scales, wavelettype, dt);
		ephysWaveletCfs = cwt(data, scales, wavelettype);
		ephysWaveletTime = dt:dt:size(data,1)*dt;
		ephysWaveletCfs(:, ephysWaveletTime < 3 | ephysWaveletTime > max(ephysWaveletTime) - 3) = NaN; % Delete first and last 3 s due to border effect
		
		pcolor(ephysWaveletTime, ephysWaveletFrequency, abs(ephysWaveletCfs));
		xlim([min(this.Time) max(this.Time)]);
		ylim([min(ephysWaveletFrequency) max(ephysWaveletFrequency)]);
		colormap jet;
		shading interp;
		xlabel('Time (s)');
		ylabel('Frequency (Hz)');
        title('Ephys wavelet');
        addFigureToReport(rpt, 16, 10);
	end
	
	% Összes sejt
	add(rpt, Heading1("Imaging - All cells"));
	subplot(2,2,1);
	imagesc(this.RefImage);
	axis image;
	subplot(2,2,2);
	imagesc(label2rgb(this.ROIs2D, 'hsv', 'k', 'shuffle'));
	axis image;
	subplot(2,2,3);
	g = this.RefImage;
	g(:,:,[1 3]) = 0;
	imagesc(g);
	axis image;
	subplot(2,2,4);
	r = this.RefImage;
	r(:,:,[2 3]) = 0;
	imagesc(r);
	axis image;
	spaceplots;
	addFigureToReport(rpt, 16, 16);
	add(rpt, Paragraph("Top left: green and red labeling, superimposed. Top right: identified cells in pseudo color. Bottom left: green labeling. Bottom right: red labeling."));

	add(rpt, Heading1("Astrocytes"));
	montage(celldata.image(this.Glia));
	spaceplots;
	addFigureToReport(rpt, 16, 16);

	add(rpt, Heading1("Neurons"));
	montage(celldata.image(this.Neuron));
	spaceplots;
	addFigureToReport(rpt, 16, 16);

	add(rpt, Heading1("Not cells"));
	montage(celldata.image(~this.Glia & ~this.Neuron));
% 	spaceplots;
	addFigureToReport(rpt, 16, 16);
	
	% dF/F0
	add(rpt, PageBreak);
	add(rpt, Heading2("dF/F0"));
	add(rpt, Paragraph("dF/F0 traces of identified neurons and astrocytes."));
	
	if sum(this.Glia) > 0
		plot(this.Time, this.DeltaFperF0(:,this.Glia,1));
		xlabel('Time (s)');
		ylabel('dF/F0');
		title(sprintf('Astrocytes (n = %u)', sum(this.Glia)));
		addFigureToReport(rpt, 16, 6);
	end
	
	if sum(this.Neuron) > 0
		plot(this.Time, this.DeltaFperF0(:,this.Neuron,1));
		xlabel('Time (s)');
		ylabel('dF/F0');
		title(sprintf('Neurons (n = %u)', sum(this.Neuron)));
		addFigureToReport(rpt, 16, 6);
	end
	
	if sum(~this.Glia & ~this.Neuron) > 0
		plot(this.Time, this.DeltaFperF0(:,~this.Glia & ~this.Neuron,1));
		xlabel('Time (s)');
		ylabel('dF/F0');
		title(sprintf('Not cell (n = %u)', sum(~this.Glia & ~this.Neuron)));
		addFigureToReport(rpt, 16, 6);
	end
	
	% Wavelet max (0.1-2 Hz)
	add(rpt, PageBreak);
	add(rpt, Heading2("Wavelet"));
	add(rpt, Paragraph("Wavelet analysis of frequency components of the imaging signals of individual cells."));
	ind = celldata.waveletFrequency(1,:) >= 0.1 & celldata.waveletFrequency(1,:) < 2;
	w = zeros(this.CellNum, size(celldata.waveletCfs{1}, 2));
	for i = 1:this.CellNum
		w(i,:) = nanmax(abs(celldata.waveletCfs{i}(ind,:)));
	end
	w = w ./ nanmax(w(:));
	wg = w(this.Glia, :);
	wn = w(this.Neuron, :);
	wnc = w(~this.Glia & ~this.Neuron, :);
	w = zeros(size(w, 1), size(w, 2), 3);
	if ~isempty(wg)
		wg(isnan(wg)) = 0;
		w(1:size(wg, 1),:,1) = 1;
		w(1:size(wg, 1),:,2) = 1 - wg;
		w(1:size(wg, 1),:,3) = 1 - wg;
	end
	if ~isempty(wn)
		wn(isnan(wn)) = 0;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,1) = 1 - wn;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,2) = 1;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,3) = 1 - wn;
	end
	if ~isempty(wnc)
		wnc(isnan(wnc)) = 0;
		w(size(wg, 1)+size(wn, 1)+1:end,:,1) = 1 - wnc;
		w(size(wg, 1)+size(wn, 1)+1:end,:,2) = 1 - wnc;
		w(size(wg, 1)+size(wn, 1)+1:end,:,3) = 1;
	end
	
	imagesc('XData', [min(this.Time) max(this.Time)], 'YData', 1:size(w, 1), 'CData', w);
	xlim([min(this.Time) max(this.Time)]);
	ylim([1 size(w, 1)]);
	set(gca,'YDir','reverse');
	xlabel('Time (s)');
	ylabel('Cell number');
	title('Max wavelet cfs per cell (0.1-2 Hz): astrocytes (red), neurons (green), not cell (blue)');
	addFigureToReport(rpt, 16, 20);
	add(rpt, Paragraph("Maximum power of individual cells in the 0.1-2 Hz frequency range. Each line represents a single cell."));
	
	% Wavelet max (2+ Hz)
	ind = celldata.waveletFrequency(1,:) >= 2;
	if sum(ind) > 0
		w = zeros(this.CellNum, size(celldata.waveletCfs{1}, 2));
		for i = 1:this.CellNum
			w(i,:) = nanmax(abs(celldata.waveletCfs{i}(ind,:)));
		end
		w = w ./ nanmax(w(:));
		wg = w(this.Glia, :);
		wn = w(this.Neuron, :);
		wnc = w(~this.Glia & ~this.Neuron, :);
		w = zeros(size(w, 1), size(w, 2), 3);
		if ~isempty(wg)
			wg(isnan(wg)) = 0;
			w(1:size(wg, 1),:,1) = 1;
			w(1:size(wg, 1),:,2) = 1 - wg;
			w(1:size(wg, 1),:,3) = 1 - wg;
		end
		if ~isempty(wn)
			wn(isnan(wn)) = 0;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,1) = 1 - wn;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,2) = 1;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,3) = 1 - wn;
		end
		if ~isempty(wnc)
			wnc(isnan(wnc)) = 0;
			w(size(wg, 1)+size(wn, 1)+1:end,:,1) = 1 - wnc;
			w(size(wg, 1)+size(wn, 1)+1:end,:,2) = 1 - wnc;
			w(size(wg, 1)+size(wn, 1)+1:end,:,3) = 1;
		end
		
		imagesc('XData', [min(this.Time) max(this.Time)], 'YData', 1:size(w, 1), 'CData', w);
		xlim([min(this.Time) max(this.Time)]);
		ylim([1 size(w, 1)]);
		set(gca,'YDir','reverse');
		xlabel('Time (s)');
		ylabel('Cell number');
		title('Max wavelet cfs per cell (2+ Hz): astrocytes (red), neurons (green), not cell (blue)');
		addFigureToReport(rpt, 16, 20);
		add(rpt, Paragraph("Maximum power of individual cells in the >2 Hz frequency range. Each line represents a single cell."));
	end
	
	% Wavelet sum (0.1-2 Hz)
	ind = celldata.waveletFrequency(1,:) >= 0.1 & celldata.waveletFrequency(1,:) < 2;
	w = zeros(this.CellNum, size(celldata.waveletCfs{1}, 2));
	for i = 1:this.CellNum
		w(i,:) = nansum(abs(celldata.waveletCfs{i}(ind,:)));
	end
	w = w ./ nanmax(w(:));
	wg = w(this.Glia, :);
	wn = w(this.Neuron, :);
	wnc = w(~this.Glia & ~this.Neuron, :);
	w = zeros(size(w, 1), size(w, 2), 3);
	if ~isempty(wg)
		wg(isnan(wg)) = 0;
		w(1:size(wg, 1),:,1) = 1;
		w(1:size(wg, 1),:,2) = 1 - wg;
		w(1:size(wg, 1),:,3) = 1 - wg;
	end
	if ~isempty(wn)
		wn(isnan(wn)) = 0;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,1) = 1 - wn;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,2) = 1;
		w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,3) = 1 - wn;
	end
	if ~isempty(wnc)
		wnc(isnan(wnc)) = 0;
		w(size(wg, 1)+size(wn, 1)+1:end,:,1) = 1 - wnc;
		w(size(wg, 1)+size(wn, 1)+1:end,:,2) = 1 - wnc;
		w(size(wg, 1)+size(wn, 1)+1:end,:,3) = 1;
	end
	
	imagesc('XData', [min(this.Time) max(this.Time)], 'YData', 1:size(w, 1), 'CData', w);
	xlim([min(this.Time) max(this.Time)]);
	ylim([1 size(w, 1)]);
	set(gca,'YDir','reverse');
	xlabel('Time (s)');
	ylabel('Cell number');
	title('Sum wavelet cfs per cell (0.1-2 Hz): astrocytes (red), neurons (green), not cell (blue)');
	addFigureToReport(rpt, 16, 20);
	add(rpt, Paragraph("Total power of individual cells in the 0.1-2 Hz frequency range. Each line represents a single cell."));
	
	% Wavelet sum (2+ Hz)
	ind = celldata.waveletFrequency(1,:) >= 2;
	if sum(ind) > 0
		w = zeros(this.CellNum, size(celldata.waveletCfs{1}, 2));
		for i = 1:this.CellNum
			w(i,:) = nansum(abs(celldata.waveletCfs{i}(ind,:)));
		end
		w = w ./ nanmax(w(:));
		wg = w(this.Glia, :);
		wn = w(this.Neuron, :);
		wnc = w(~this.Glia & ~this.Neuron, :);
		w = zeros(size(w, 1), size(w, 2), 3);
		if ~isempty(wg)
			wg(isnan(wg)) = 0;
			w(1:size(wg, 1),:,1) = 1;
			w(1:size(wg, 1),:,2) = 1 - wg;
			w(1:size(wg, 1),:,3) = 1 - wg;
		end
		if ~isempty(wn)
			wn(isnan(wn)) = 0;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,1) = 1 - wn;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,2) = 1;
			w(size(wg, 1)+1:size(wg, 1)+size(wn, 1),:,3) = 1 - wn;
		end
		if ~isempty(wnc)
			wnc(isnan(wnc)) = 0;
			w(size(wg, 1)+size(wn, 1)+1:end,:,1) = 1 - wnc;
			w(size(wg, 1)+size(wn, 1)+1:end,:,2) = 1 - wnc;
			w(size(wg, 1)+size(wn, 1)+1:end,:,3) = 1;
		end
		
		imagesc('XData', [min(this.Time) max(this.Time)], 'YData', 1:size(w, 1), 'CData', w);
		xlim([min(this.Time) max(this.Time)]);
		ylim([1 size(w, 1)]);
		set(gca,'YDir','reverse');
		xlabel('Time (s)');
		ylabel('Cell number');
		title('Sum wavelet cfs per cell (2+ Hz): astrocytes (red), neurons (green), not cell (blue)');
		colormap(c);
		addFigureToReport(rpt, 16, 20);
		add(rpt, Paragraph("Total power of individual cells in the >2 Hz frequency range. Each line represents a single cell."));
	end
	
	% Frequency distributions
	cfs = cell2mat(cellfun(@(x) nansum(abs(x)'), celldata.waveletCfs, 'UniformOutput', false));
	cfs = cfs ./ max(cfs(:));
	cfsg = cfs(this.Glia, :);
	cfsn = cfs(this.Neuron, :);
	cfsnc = cfs(~this.Glia & ~this.Neuron, :);
	cfs = zeros(size(cfs, 1), size(cfs, 2), 3);
	if ~isempty(cfsg)
		cfsg(isnan(cfsg)) = 0;
		cfs(1:size(cfsg, 1),:,1) = 1;
		cfs(1:size(cfsg, 1),:,2) = 1 - cfsg;
		cfs(1:size(cfsg, 1),:,3) = 1 - cfsg;
	end
	if ~isempty(cfsn)
		cfsn(isnan(cfsn)) = 0;
		cfs(size(cfsg, 1)+1:size(cfsg, 1)+size(cfsn, 1),:,1) = 1 - cfsn;
		cfs(size(cfsg, 1)+1:size(cfsg, 1)+size(cfsn, 1),:,2) = 1;
		cfs(size(cfsg, 1)+1:size(cfsg, 1)+size(cfsn, 1),:,3) = 1 - cfsn;
	end
	if ~isempty(cfsnc)
		cfsnc(isnan(cfsnc)) = 0;
		cfs(size(cfsg, 1)+size(cfsn, 1)+1:end,:,1) = 1 - cfsnc;
		cfs(size(cfsg, 1)+size(cfsn, 1)+1:end,:,2) = 1 - cfsnc;
		cfs(size(cfsg, 1)+size(cfsn, 1)+1:end,:,3) = 1;
	end
	imagesc('XData', celldata.waveletFrequency(1,:), 'YData', 1:size(cfs, 1), 'CData', cfs);
	xlim([min(celldata.waveletFrequency(1,:)) max(celldata.waveletFrequency(1,:))]);
	ylim([1 this.CellNum]);
	set(gca,'YDir','reverse');
	set(gca,'XScale','log');
	xticks([1 2 3 4 5 10 20 30 40 50 100]);
    title('Imaging power spectrum: astrocytes (red), neurons (green), not cell (blue)');
	xlabel('Frequency (Hz)');
	ylabel('Cell number');
	addFigureToReport(rpt, 16, 20);
	add(rpt, Paragraph("Frequency power distribution of individual cells. Each line represents a single cell."));

    % Individual cells
	add(rpt, PageBreak);
	add(rpt, Heading1("Imaging - Individual cells"));
	for iCell = 1:this.CellNum
		if iCell > 1
			add(rpt, PageBreak);
		end
		add(rpt, Heading2(sprintf("Cell %u (%s)", iCell, this.CellType{iCell})));
			
		% Stats
		para = Paragraph;
		para.WhiteSpace = 'preserve';
		append(para, sprintf("Bounding box size:%u x %u\t\tExtent: %0.3f\t\tEccentricity: %0.3f", stats(iCell).BoundingBox(3), stats(iCell).BoundingBox(4), stats(iCell).Extent, stats(iCell).Eccentricity));
		add(rpt, para);
		
		% Image
		subplot(2,4,[1 2 5 6]);
		imagesc(this.RefImage);
		axis image;
		hold on;
		rectangle('Position', celldata.rect(iCell,:), 'EdgeColor', 'w');
		title('Position');
		subplot(2,4,3);
		imagesc(celldata.image{iCell});
		axis image;
		title('RGB');
		subplot(2,4,4);
		imagesc(imoverlay(celldata.image{iCell}, celldata.roiPerim{iCell}));
		axis image;
		set(gca, 'YTickLabel', [])
		title('RGB with ROI');
		subplot(2,4,7);
		im = celldata.image{iCell};
		im(:,:,1) = 0;
		imagesc(im);
		axis image;
		title('Green');
		subplot(2,4,8);
		im = celldata.image{iCell};
		im(:,:,2) = 0;
		imagesc(im);
		axis image;
		set(gca, 'YTickLabel', [])
		title('Red');
		addFigureToReport(rpt, 16, 8);
		
		% dF/F0 and wavelet
		subplot(6,1,1);
		plot(this.Time, this.DeltaFperF0(:,iCell,1), 'Color', [0 0.6 0]);
		if size(this.DeltaFperF0, 3) > 1
			hold on;
			plot(this.Time, this.DeltaFperF0(:,iCell,2), 'r');
		end
		ylabel('dF/F0');
		set(gca, 'XTickLabel', []);
		subplot(6,1,[2 3]);
		pcolor(celldata.waveletTime(iCell,:), celldata.waveletFrequency(iCell,:), abs(celldata.waveletCfs{iCell}));
		xlim([min(this.Time) max(this.Time)]);
		ylim([min(celldata.waveletFrequency(iCell,:)) max(celldata.waveletFrequency(iCell,:))]);
		colormap jet;
		shading interp;
		xlabel('Time (s)');
		ylabel('Frequency (Hz)');
		
		if ~isempty(this.Ephys)
			subplot(6,1,4);
			plot(this.EphysTime, this.Ephys(:,1));
			ylabel('Ephys');
			set(gca, 'XTickLabel', []);
			subplot(6,1,[5 6]);
			pcolor(ephysWaveletTime, ephysWaveletFrequency, abs(ephysWaveletCfs));
			xlim([min(this.Time) max(this.Time)]);
			ylim([min(ephysWaveletFrequency) max(ephysWaveletFrequency)]);
			colormap jet;
			shading interp;
			xlabel('Time (s)');
			ylabel('Frequency (Hz)');
		end
		
		addFigureToReport(rpt, 16, 11);
		add(rpt, Paragraph("Top: green and red channel dF/F0 traces. Bottom: Wavelet analysis of the green channel trace between 0.1 Hz and the Nyquist frequency."));
		
		% Detailed wavelet analysis
		wavelettype = 'cmor1-2';
		dt = this.SamplingInterval;

		fmin = 0.5;
		fmax = 4;
		minscale = centfrq(wavelettype)/(fmin*dt);
		maxscale = centfrq(wavelettype)/(fmax*dt);
		scales = logspace(log10(minscale), log10(maxscale), 100);
		data = this.DeltaFperF0(:,iCell,1);
		waveletFrequency = scal2frq(scales, wavelettype, dt);
		waveletCfs = cwt(data, scales, wavelettype);
		waveletTime = dt:dt:size(data,1)*dt;
		pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		xlim([min(this.Time) max(this.Time)]);
		ylim([min(waveletFrequency) max(waveletFrequency)]);
		colormap jet;
		shading flat;
		xlabel('Time (s)');
		ylabel('Frequency (Hz), green channel');
		addFigureToReport(rpt, 16, 6);

		% fmin = 0.5;
		% fmax = 4;
		% minscale = centfrq(wavelettype)/(fmin*dt);
		% maxscale = centfrq(wavelettype)/(fmax*dt);
		% scales = logspace(log10(minscale), log10(maxscale), 100);
		% data = this.DeltaFperF0(:,iCell,2);
		% waveletFrequency = scal2frq(scales, wavelettype, dt);
		% waveletCfs = cwt(data, scales, wavelettype);
		% waveletTime = dt:dt:size(data,1)*dt;
		% pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		% xlim([min(this.Time) max(this.Time)]);
		% ylim([min(waveletFrequency) max(waveletFrequency)]);
		% colormap jet;
		% shading flat;
		% xlabel('Time (s)');
		% ylabel('Frequency (Hz), red channel');
		% addFigureToReport(rpt, 16, 6);

		fmin = 4;
		fmax = 10;
		minscale = centfrq(wavelettype)/(fmin*dt);
		maxscale = centfrq(wavelettype)/(fmax*dt);
		scales = logspace(log10(minscale), log10(maxscale), 100);
		data = this.DeltaFperF0(:,iCell,1);
		waveletFrequency = scal2frq(scales, wavelettype, dt);
		waveletCfs = cwt(data, scales, wavelettype);
		waveletTime = dt:dt:size(data,1)*dt;
		pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		xlim([min(this.Time) max(this.Time)]);
		ylim([min(waveletFrequency) max(waveletFrequency)]);
		colormap jet;
		shading flat;
		xlabel('Time (s)');
		ylabel('Frequency (Hz), green channel');
		addFigureToReport(rpt, 16, 6);

		% fmin = 4;
		% fmax = 10;
		% minscale = centfrq(wavelettype)/(fmin*dt);
		% maxscale = centfrq(wavelettype)/(fmax*dt);
		% scales = logspace(log10(minscale), log10(maxscale), 100);
		% data = this.DeltaFperF0(:,iCell,2);
		% waveletFrequency = scal2frq(scales, wavelettype, dt);
		% waveletCfs = cwt(data, scales, wavelettype);
		% waveletTime = dt:dt:size(data,1)*dt;
		% pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		% xlim([min(this.Time) max(this.Time)]);
		% ylim([min(waveletFrequency) max(waveletFrequency)]);
		% colormap jet;
		% shading flat;
		% xlabel('Time (s)');
		% ylabel('Frequency (Hz), red channel');
		% addFigureToReport(rpt, 16, 6);

		fmin = 10;
		fmax = this.SamplingFrequency / 2;
		minscale = centfrq(wavelettype)/(fmin*dt);
		maxscale = centfrq(wavelettype)/(fmax*dt);
		scales = logspace(log10(minscale), log10(maxscale), 100);
		data = this.DeltaFperF0(:,iCell,1);
		waveletFrequency = scal2frq(scales, wavelettype, dt);
		waveletCfs = cwt(data, scales, wavelettype);
		waveletTime = dt:dt:size(data,1)*dt;
		pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		xlim([min(this.Time) max(this.Time)]);
		ylim([min(waveletFrequency) max(waveletFrequency)]);
		colormap jet;
		shading flat;
		xlabel('Time (s)');
		ylabel('Frequency (Hz), green channel');
		addFigureToReport(rpt, 16, 6);

		% fmin = 10;
		% fmax = this.SamplingFrequency / 2;
		% minscale = centfrq(wavelettype)/(fmin*dt);
		% maxscale = centfrq(wavelettype)/(fmax*dt);
		% scales = logspace(log10(minscale), log10(maxscale), 100);
		% data = this.DeltaFperF0(:,iCell,2);
		% waveletFrequency = scal2frq(scales, wavelettype, dt);
		% waveletCfs = cwt(data, scales, wavelettype);
		% waveletTime = dt:dt:size(data,1)*dt;
		% pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
		% xlim([min(this.Time) max(this.Time)]);
		% ylim([min(waveletFrequency) max(waveletFrequency)]);
		% colormap jet;
		% shading flat;
		% xlabel('Time (s)');
		% ylabel('Frequency (Hz), red channel');
		% addFigureToReport(rpt, 16, 6);
	end
		
	close(gcf);
	close(rpt);
end