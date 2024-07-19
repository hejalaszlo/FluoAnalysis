function reportFrequencyDistribution(this)
	wavelettype = 'cmor10-1';

	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	figure('units', 'centimeters', 'position', [0 0 16 8]);

	rpt = Report(strcat("Frequency distribution, ", inputname(1)), "docx");

	add(rpt, Heading1("Summary"));
	add(rpt, Paragraph("..."));
	
	c(:,1) = [ones(127,1); linspace(1, 0, 128)'];
	c(:,2) = [linspace(0, 1, 127)'; 1; linspace(1, 0, 127)'];
	c(:,3) = [linspace(0, 1, 128)'; ones(127,1)];

	frequencies = [0.5 4; 4 8; 8 13; 13 30];
% 	frequencies = [0.5 min(20, min([this.Data.SamplingFrequency]) / 2)];
	for iF = 1:size(frequencies, 1)
		fmin = frequencies(iF, 1);
		fn = min([this.Data.SamplingFrequency]) / 2;
		fn = frequencies(iF, 2);
		add(rpt, Heading1(sprintf("%0.1f-%0.1f Hz", round(fmin), fn)));
		for iFile = 1:length(this.Data)
			disp(iFile);
			add(rpt, PageBreak);
			add(rpt, Heading2(this.FileName(iFile)));
			add(rpt, Paragraph(this.MeasurementDate(iFile)));

			dt = this.Data(iFile).Time(2) - this.Data(iFile).Time(1);
			minscale = centfrq(wavelettype)/(fmin*dt);
			maxscale = centfrq(wavelettype)/(fn*dt);
			scales = logspace(log10(minscale), log10(maxscale), 100);
			waveletCfs = [];
			for iCell = 1:this.Data(iFile).CellNum
				data = this.Data(iFile).DeltaFperF0(:,iCell,1);
				waveletCfs{iCell, 1} = cwt(data, scales, wavelettype);
			end
			waveletFrequency = scal2frq(scales, wavelettype, dt);

			subplot(3,1,[1 2]);
			cfs = cell2mat(cellfun(@(x) nansum(abs(x)'), waveletCfs, 'UniformOutput', false));
			cfs = cfs ./ max(cfs(:));
			cfsg = cfs(this.Data(iFile).Glia, :);
			cfsn = cfs(this.Data(iFile).Neuron, :);
			cfsnc = cfs(~this.Data(iFile).Glia & ~this.Data(iFile).Neuron, :);
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
			imagesc('XData', waveletFrequency, 'YData', 1:size(cfs, 1), 'CData', cfs);
			xlim([min(waveletFrequency) max(waveletFrequency)]);
			ylim([1 this.Data(iFile).CellNum]);
			set(gca,'YDir','reverse');
			set(gca,'XScale','log');
			xticks([1 2 3 4 5 10 20 30 40 50 100]);
			title('Imaging power spectrum: astrocytes (red), neurons (green), not cell (blue)');
			xlabel('Frequency (Hz)');
			ylabel('Cell number');

			if ~isempty(this.Data(iFile).Ephys)
				dtE = (this.Data(iFile).EphysTime(2) - this.Data(iFile).EphysTime(1));
				minscale = centfrq(wavelettype)/(max(fmin,0.5)*dtE);
				maxscale = centfrq(wavelettype)/(fn*dtE);
				scales = logspace(log10(minscale), log10(maxscale), 100);
				data = this.Data(iFile).Ephys;
				ephysWaveletCfs = cwt(data, scales, wavelettype);
				ephysWaveletFrequency = scal2frq(scales, wavelettype, dtE);

				subplot(3,1,3);
				cfs = nansum(abs(ephysWaveletCfs)');
				plot(ephysWaveletFrequency, cfs);
				xlim([fmin fn]);
				set(gca,'XScale','log');
				% xticks([0.5 1 2 3 4 5 10 20 30 40 50 100]);
				title('Ephys power spectrum');
				xlabel('Frequency (Hz)');
				ylabel('Sum power');
			end

			spaceplots;
			addFigureToReport(rpt, 16, 20);
		end
	end
		
	close(gcf);
	close(rpt);
end