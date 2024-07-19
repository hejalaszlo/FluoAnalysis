function reportWavelets(this)
	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	figure('units', 'centimeters', 'position', [0 0 16 8]);
	
	if (~isempty(this.MesImageIndex) && this.MesImageIndex > 0)
		filename = strcat(this.PicFileName, " " , num2str(this.MesImageIndex));
	else
		filename = this.PicFileName;
	end
	rpt = Report(strcat("Wavelets, ", filename), "docx");

	add(rpt, Heading1("Summary"));
	add(rpt, Paragraph("..."));
	add(rpt, PageBreak);
	
	% Frequency bands
	add(rpt, Heading1("SWA (0.5-2 Hz)"));
	this.calculateWavelet([0.5 2]);
	this.plotWaveletCells;
	addFigureToReport(rpt, 16, 13);
	this.plotCellsByWavelet;
	addFigureToReport(rpt, 10, 8);

	add(rpt, Heading1("High delta (2-4 Hz)"));
	this.calculateWavelet([2 4]);
	this.plotWaveletCells;
	addFigureToReport(rpt, 16, 13);
	this.plotCellsByWavelet;
	addFigureToReport(rpt, 10, 8);

	add(rpt, Heading1("Theta (4-8 Hz)"));
	this.calculateWavelet([4 8]);
	this.plotWaveletCells;
	addFigureToReport(rpt, 16, 13);
	this.plotCellsByWavelet;
	addFigureToReport(rpt, 10, 8);

	add(rpt, Heading1("Alpha (8-13 Hz)"));
	this.calculateWavelet([8 13]);
	this.plotWaveletCells;
	addFigureToReport(rpt, 16, 13);
	this.plotCellsByWavelet;
	addFigureToReport(rpt, 10, 8);

	add(rpt, Heading1("Beta (13-30 Hz)"));
	this.calculateWavelet([13 30]);
	this.plotWaveletCells;
	addFigureToReport(rpt, 16, 13);
	this.plotCellsByWavelet;
	addFigureToReport(rpt, 10, 8);
	
	close all;
		
	close(gcf);
	close(rpt);
end