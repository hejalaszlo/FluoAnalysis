function send2gephi(this)
    if isempty(this.CellCoordinates)
        warning('ImagingData send2gephi: not all required properties set');
        return
    end
    
    bound = 0.4; %1.96/sqrt(this.CrossCorrelationImaging.WindowSize/this.SamplingInterval); % 95 % confidence interval bound for R-value
    
    % Nodes
    comm = cell(this.CellNum, 1);
    for iCell = 1:this.CellNum
        maxr = this.CrossCorrelationImaging.MaxR(iCell,:,1);
        comm{iCell} = sprintf('"%d":{"label":"%s","x":%0.2f,"y":%0.2f,"Cell type":"%s","size":%.0f}', iCell, this.CellNames{iCell}, this.CellCoordinates(iCell,1), this.CellCoordinates(iCell,2), this.CellType{iCell}, sum(maxr(maxr > bound))/4+2);
    end
    comm = strcat('{"an":{', strjoin(comm, ', '), '}}');
    webwrite('http://localhost:6680/workspace1?operation=updateGraph',comm);

    while true
        for iT = 1:size(this.CrossCorrelationImaging.MaxR, 3)
            % Nodes
            comm = cell(this.CellNum, 1);
            for iCell = 1:this.CellNum
                maxr = this.CrossCorrelationImaging.MaxR(iCell,:,iT);
                value = sum(maxr(maxr > bound))/4+2; % Total R-value of high R-value coupling
    %             value = sum(maxr > bound)/8+2; % Number of cells coupled with high R-value
                comm{iCell} = sprintf('"%d":{"size":%.0f}', iCell, value);
            end
            comm = strcat('{"cn":{', strjoin(comm, ', '), '}}');
            webwrite('http://localhost:6680/workspace1?operation=updateGraph',comm);

            % Edges
    %         edgeid = 1;
    %         comm  = {};
    %         for i = 1:this.CellNum
    %             for j = i+1:this.CellNum
    %                 if this.CrossCorrelationImaging.MaxR(i,j,iT) > bound
    %                     comm{edgeid} = sprintf('"%d":{"source":%d,"target":%d,"directed":false,"start":%d,"end":%d,"Max R-value":%0.2f,"Lag":%0.2f}', edgeid, i, j, (iT-1)*this.CrossCorrelationImaging.Interval, iT*this.CrossCorrelationImaging.Interval-1, this.CrossCorrelationImaging.MaxR(i,j,iT), this.CrossCorrelationImaging.Lag(i,j,iT));
    %                     edgeid = edgeid + 1;
    %                 end
    %             end
    %         end
    %         comm = strcat('{"ae":{', strjoin(comm, ', '), '}}');
    %         webwrite('http://localhost:6680/workspace1?operation=updateGraph',comm);
        end
    end
end