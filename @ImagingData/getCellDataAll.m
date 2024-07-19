function response = getCellDataAll(this)    
    if isempty(this.ROIs) && isempty(this.ROIs2D)
        warning('ImagingData getCellDataAll: not all required properties set');
        return;
    end
    
    response = table;
	
	for iCell = 1:this.CellNum
		celldata = this.getCellData(iCell);
		response(iCell, :) = struct2table(celldata, 'AsArray', true);
	end

end