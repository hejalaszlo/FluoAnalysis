function plotCells(this, varargin)
    figure('NumberTitle', 'off', 'Name', strcat(this.PicFileName(1), ' F', num2str(this.MesImageIndex)), 'Pos', [100 100 1000 800]);
    
	iPlot = 1;
	for iCell = 1:this.CellNum
		subplot(this.CellNum+1,8,iPlot);
		imshow(this.ROIs == iCell);
		ax(iCell) = subplot(this.CellNum+1,8,iPlot+1:iPlot+7);
		plot(this.Time, this.DeltaFperF0(:,iCell,1));
        ylabel('\DeltaF/F_0');
		
		iPlot = iPlot + 8;
	end
	
	ax(11) = subplot(this.CellNum+1,8,this.CellNum*8+2:this.CellNum*8+8);
	plot(this.EphysTime, this.Ephys, 'r');
	ylabel('Ephys');
	xlabel('Time (s)');
    
    linkaxes(ax, 'x');
    
    spaceplots;
end