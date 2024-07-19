function reportWavelets(this)
	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	rpt = Report(strcat("Wavelets, ", inputname(1)), "docx");

	add(rpt, Heading1("Summary"));
	add(rpt, Paragraph("..."));
	add(rpt, PageBreak);

    % Egyedi sejtek
	for iFile = 1:length(this.Data)
		disp(this.Data(iFile).MesImageIndex);
		add(rpt, Heading1(sprintf("F%u", this.Data(iFile).MesImageIndex)));

		% Frequency bands
		add(rpt, Heading2("SWA (0.5-2 Hz)"));
		this.Data(iFile).calculateWavelet([0.5 2]);
		this.Data(iFile).plotWaveletCells;
		addFigureToReport(rpt, 16, 13);
		this.Data(iFile).plotCellsByWavelet;
		addFigureToReport(rpt, 10, 8);

		add(rpt, Heading2("High delta (2-4 Hz)"));
		this.Data(iFile).calculateWavelet([2 4]);
		this.Data(iFile).plotWaveletCells;
		addFigureToReport(rpt, 16, 13);
		this.Data(iFile).plotCellsByWavelet;
		addFigureToReport(rpt, 10, 8);

		add(rpt, Heading2("Theta (4-8 Hz)"));
		this.Data(iFile).calculateWavelet([4 8]);
		this.Data(iFile).plotWaveletCells;
		addFigureToReport(rpt, 16, 13);
		this.Data(iFile).plotCellsByWavelet;
		addFigureToReport(rpt, 10, 8);

		add(rpt, Heading2("Alpha (8-13 Hz)"));
		this.Data(iFile).calculateWavelet([8 13]);
		this.Data(iFile).plotWaveletCells;
		addFigureToReport(rpt, 16, 13);
		this.Data(iFile).plotCellsByWavelet;
		addFigureToReport(rpt, 10, 8);

		add(rpt, Heading2("Beta (13-30 Hz)"));
		this.Data(iFile).calculateWavelet([13 30]);
		this.Data(iFile).plotWaveletCells;
		addFigureToReport(rpt, 16, 13);
		this.Data(iFile).plotCellsByWavelet;
		addFigureToReport(rpt, 10, 8);

		close all;
	end
		
	close(rpt);
end