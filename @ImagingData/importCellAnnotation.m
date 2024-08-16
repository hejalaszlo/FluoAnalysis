function importCellAnnotation(this)
	measurementDate = strrep(this.MesMetadata(1).MeasurementDate, ":", ".");

	celldata = mysql_query('192.168.1.15', 'imagingdata', sprintf("SELECT * FROM cells JOIN validations ON validations.cellId=cells.id WHERE measurementDate='%s'", measurementDate));
	celldata = sortrows(celldata, 3);
	
% 	load("cd.mat");
% 	celldataAll = this.getCellDataAll;
% 	cd = [cd; [celldata celldataAll(celldata.cellNumber,:)]];
% 	save("cd.mat", 'cd');
	
	changedCounter = 0;
	for i = 1:height(celldata)
		iCell = celldata.cellNumber(i);
		if this.Neuron(iCell)
			autoCellType(i, 1) = "Neuron";
		elseif this.Glia(iCell)
			autoCellType(i, 1) = "astrocyte";
		else
			autoCellType(i, 1) = "not cell";
		end
		
		if celldata.cellType{i} ~= autoCellType(i)
			fprintf("Cell %i type changed from '%s' to '%s'\n", celldata.cellNumber(i), autoCellType(i), celldata.cellType{i});
			changedCounter = changedCounter + 1;
		end
	end

	celldata.autoCellType = autoCellType;
	fprintf("%i cells have changed type\n", changedCounter);
	
	% Update imagingdata
	for i = 1:height(celldata)
		iCell = celldata.cellNumber(i);
		if celldata.cellType{i} == "astrocyte"
			this.Neuron(iCell) = false;
			this.Glia(iCell) = true;
		elseif celldata.cellType{i} == "neuron"
			this.Neuron(iCell) = true;
			this.Glia(iCell) = false;
		else
			this.Neuron(iCell) = false;
			this.Glia(iCell) = false;
		end
	end
end