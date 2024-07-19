function addFigureToReport(rpt, width, height)
	import mlreportgen.report.* 
	import mlreportgen.dom.* 
	
	set(gcf, 'units', 'centimeters', 'position', [0 0 width height]);
% 	spaceplots;
	fig = Figure;
	fig.SnapshotFormat = "jpg";
	fig.Scaling = "none";
	add(rpt, fig);
	clf;
end