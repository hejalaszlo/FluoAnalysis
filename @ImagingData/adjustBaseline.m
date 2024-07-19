function adjustBaseline(this, method, showPlot, varargin)
    % Subtract baseline from DF/F0 traces
    disp('Adjusting baseline...');

    % Set default method
    if nargin == 1
        method = 'msbackadj';
    end
    
    % if not set, set default smooth and showPlot parameters
    if nargin <= 2
        showPlot = false;
    end
    
    switch method
        case 'msbackadj'
            if nargin < 4
                disp('windowSize not set, setting it to 1 s');
                windowSize = 1;
            else
                windowSize = varargin{1};
            end
        case 'backcor'
            if nargin < 4
                disp('setting default parameters');
                order = 4;
                threshold = 0.005;
                costFunction = 'ah'; % asymmetric Huber
            else
                order = varargin{1};
                threshold = varargin{2};
                costFunction = varargin{3};
            end
    end
    
    adf = nan(size(this.DeltaFperF0));
    dfs = this.DeltaFperF0Smoothed;
    adfs = nan(size(dfs));
    
    for iCh = 1:this.ChannelNum
        for iCell = 1:this.CellNum
            switch method
                case 'msbackadj'
                    if sum(~isnan(this.DeltaFperF0(:,iCell,iCh))) > 0
                        adf(:,iCell,iCh) = msbackadj(this.Time', this.DeltaFperF0(:,iCell,iCh), 'WINDOWSIZE', windowSize, 'STEPSIZE', windowSize, 'SHOWPLOT', false);
                    end
                    if this.Smooth == 1
                        adfs(:,iCell,iCh) = adf(:,iCell,iCh);
                    elseif sum(~isnan(dfs(:,iCell,iCh))) > 0
                        adfs(:,iCell,iCh) = msbackadj(this.Time', dfs(:,iCell,iCh), 'WINDOWSIZE', windowSize, 'STEPSIZE', windowSize, 'SHOWPLOT', false);
                    end
                case 'backcor'
                    % Polynomial minimizing of the non-quadratic asymmetric Huber cost function with polynomial order of 4 and threshold of 0.05
                    if sum(~isnan(this.DeltaFperF0(:,iCell,iCh))) > 0
                        [z,a,it,ord,s,fct] = backcor(this.Time, this.DeltaFperF0(:,iCell,iCh), order, threshold, costFunction);
                        adf(:,iCell,iCh) = this.DeltaFperF0(:,iCell,iCh) - z;
                    end
                    if this.Smooth == 1
                        adfs(:,iCell,iCh) = adf(:,iCell,iCh);
                    elseif sum(~isnan(dfs(:,iCell,iCh))) > 0
                        [z,a,it,ord,s,fct] = backcor(this.Time, dfs(:,iCell,iCh), order, threshold, costFunction);
                        adfs(:,iCell,iCh) = dfs(:,iCell,iCh) - z;
                    end
            end
        end
    end
    
    if showPlot
        % Sort plots into a grid of 4:3 ratio
        numRow = round(sqrt(this.CellNum / 12)) * 4;
        numCol = ceil(this.CellNum / numRow);
        count = 1;
        figure('Name', 'dF/F0');
        for i = 1:numRow
            for j = 1:numCol
                if count > this.CellNum
                    break;
                end
                
                subplot(numRow, numCol, count);
                plot(this.Time, this.DeltaFperF0(:,count,1), 'b');
                hold on;
                plot(this.Time, this.DeltaFperF0(:,count,1) - adf(:,count,1), 'r');
%                 title(['Cell' num2str(count)]);
                set(gca, 'XTickLabel', [], 'YTickLabel', []);
                
                count = count + 1;
            end
        end
        spaceplots;
        
        count = 1;
        figure('Name', 'Smoothed dF/F0');
        for i = 1:numRow
            for j = 1:numCol
                if count > this.CellNum
                    break;
                end
                
                subplot(numRow, numCol, count);
                plot(this.Time, dfs(:,count,1), 'b');
                hold on;
                plot(this.Time, dfs(:,count,1) - adfs(:,count,1), 'r');
%                 title(['Cell' num2str(count)]);
                set(gca, 'XTickLabel', [], 'YTickLabel', []);
                
                count = count + 1;
            end
        end
        spaceplots;    
    end

    this.DeltaFperF0BaselineAdjusted = adf;
    this.DeltaFperF0SmoothedBaselineAdjusted = adfs;
end