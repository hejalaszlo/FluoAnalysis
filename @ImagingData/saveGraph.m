function saveGraph(this)
    if isempty(this.CellCoordinates)
        warning('ImagingData saveGraph: not all required properties set');
        return
    end
    
    bound = 0.3;
    
    startdate = datenum(this.MesMetadata(1).MeasurementDate, 'yyyy.mm.dd. HH:MM:SS,FFF');
    time = startdate:datenum(seconds(this.CrossCorrelation.StepSize)):startdate+datenum(seconds(this.CrossCorrelation.StepSize))*(size(this.CrossCorrelation.MaxR, 3)-1);
    timecell = cellstr(datestr(time,'yyyy-mm-ddTHH:MM:ss.fff'));
    maxR = cell(this.CellNum, 1);
    lags = cell(this.CellNum, 1);
    for iCell = 1:this.CellNum
        maxR{iCell} = '';
        lags{iCell} = '';
        for iT = 1:size(this.CrossCorrelation.MaxR, 3)
            r = this.CrossCorrelation.MaxR(iCell,:,iT);
            l = this.CrossCorrelation.Lag(iCell,:,iT);
            maxR{iCell} = strcat(maxR{iCell}, sprintf('[%s,%0.2f]', timecell{iT}, sum(r(r > bound))), ',');
            lags{iCell} = strcat(lags{iCell}, sprintf('[%s,%0.2f]', timecell{iT}, mean(l(r > bound))), ',');
        end
    end

    % Nodes
    nodes = table;
    nodes.id = (1:this.CellNum)';
    nodes.label = this.CellNames;
    nodes.x = this.CellCoordinates(:,1);
    nodes.y = this.CellCoordinates(:,2);
    nodes.celltype = this.CellType;
    nodes.timeset = repmat(strjoin(timecell, ','), this.CellNum, 1);
    writetable(nodes,'nodes.csv','Delimiter',';');

    % Edges
    edges = {};
    id = 1;
    for i = 1:this.CellNum
        for j = i+1:this.CellNum
            if max(this.CrossCorrelation.MaxR(i,j,:)) > bound
                edges{id,1} = id;                               % Id
                edges{id,2} = i;                                % Source
                edges{id,3} = j;                                % Target

                edges{id,4} = '';
                for iT = 1:size(this.CrossCorrelation.MaxR, 3)
                    if this.CrossCorrelation.MaxR(i,j,iT) > bound
                        edges{id,4} = strcat(edges{id,4}, timecell{iT}, ',');
                    end
                end
                
                id = id + 1;
            end
        end
    end
    t = table;
    t.id = edges(:,1);
    t.source = edges(:,2);
    t.target = edges(:,3);
    t.timeset = edges(:,4);
    writetable(t,'edges.csv','Delimiter',';');
end        
