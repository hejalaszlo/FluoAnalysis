function exportCells2DB(this)
	folder = "y:\imagingdata\cells";
	
	measurementDate = strrep(this.MesMetadata(1).MeasurementDate, ":", ".");
	
	% Cells
	celldata = this.getCellDataAll;
	for iCell = 1:this.CellNum
		% Reference image
		imwrite(insertShape(this.RefImage, "rectangle", celldata.rect(iCell,:)), fullfile(folder, strcat(measurementDate, ", Cell ", num2str(iCell), "_ref.jpg")))
	
		% Cell, green
		im = celldata.image{iCell};
		im(:,:,1) = 0;
		imwrite(im, fullfile(folder, strcat(measurementDate, ", Cell ", num2str(iCell), "_g.jpg")))

		% Cell, red
		im = celldata.image{iCell};
		im(:,:,2) = 0;
		imwrite(im, fullfile(folder, strcat(measurementDate, ", Cell ", num2str(iCell), "_r.jpg")))

		% Cell, RGB
		im = celldata.image{iCell};
		imwrite(im, fullfile(folder, strcat(measurementDate, ", Cell ", num2str(iCell), "_rgb.jpg")))
		
		% Cell, RGB with ROI
		imwrite(imoverlay(im, celldata.roiPerim{iCell,:}), fullfile(folder, strcat(measurementDate, ", Cell ", num2str(iCell), "_rgb_roi.jpg")))
		
		% MySQL
		mysql_query('192.168.1.20', 'imagingdata', sprintf("INSERT IGNORE INTO cells VALUES (NULL, '%s', %d)", measurementDate, iCell));
	end
end