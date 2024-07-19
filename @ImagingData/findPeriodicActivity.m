function findPeriodicActivity(this, frequencyRange, windowSize, showPlot)
    % Use auto-correlation to detect periodic activity
    
    % IMAGING
    if isempty(this.DeltaFperF0BaselineAdjusted)
        this.adjustBaseline('msbackadj', false);
    end
    df = this.DeltaFperF0BaselineAdjusted;

%     indWin = round(windowSize/this.SamplingInterval/4)*2; % Make sure indWin is even
%     cp = nan(length(df), 1);
%     ch = nan(length(df), 1);
%     f = nan(size(df));
    f = nan(ceil(max(this.Time)), this.CellNum, this.ChannelNum);
    fTime = floor(this.Time(1)):ceil(this.Time(end)) - 1;
    
    progressbar('Looking for periodic activity in imaging data');
    for iCh = 1:this.ChannelNum
        for iCell = 1:this.CellNum
%             for i = indWin/2+1:length(df)-indWin/2
            for i = floor(this.Time(1)+windowSize/2):ceil(this.Time(end)-windowSize/2)
%                 [autocor, lags] = xcorr(df(i-indWin/2:i+indWin/2, iCell, iCh), round(1/frequencyRange(1)/this.SamplingInterval), 'coeff');
                [autocor, lags] = xcorr(df(this.Time >= i-windowSize/2 & this.Time < i+windowSize/2, iCell, iCh), round(1/frequencyRange(1)/this.SamplingInterval), 'coeff');
                lagTime = lags*this.SamplingInterval;
                [pks, locs, widths, proms] = findpeaks(autocor, 'MinPeakProminence', 0.2);
                peakLoc = find(lagTime(locs) >= frequencyRange(1) & lagTime(locs) <= frequencyRange(2), 1);
                if ~isempty(peakLoc)
        %             cp(i) = proms(peakLoc);
        %             ch(i) = pks(peakLoc);
                    f(i, iCell, iCh) = 1/lagTime(locs(peakLoc));
                end
                fTime(i) = i;
            end
            
            progressbar(((iCh - 1) * this.CellNum + iCell) / this.CellNum / this.ChannelNum);
        end
    end
    progressbar(1);
  
    if showPlot
        % Sort plots into a grid of 4:3 ratio
        numRow = round(sqrt(this.CellNum / 12)) * 4;
        numCol = ceil(this.CellNum / numRow);
        count = 1;
        figure;
        for i = 1:numRow
            for j = 1:numCol
                if count > this.CellNum
                    break;
                end
                
                subplot(numRow, numCol, count);
                plot(this.Time, df(:,count,1));
                hold on;
%                 plot(this.Time, f(:,count,1) ./ f(:,count,1) * max(df(:,count,1)) * 1.2, 'ro');
                plot(fTime, f(:,count,1) ./ f(:,count,1) * max(df(:,count,1)) * 1.2, 'ro');
%                 title(['Cell' num2str(count)]);
                set(gca, 'XTickLabel', [], 'YTickLabel', []);
                
                count = count + 1;
            end
        end
        spaceplots;   
    end

    this.PeriodicActivityFrequency = f;
    this.PeriodicActivityTime = fTime;
    
    % EPHYS
    if ~isempty(this.Ephys)
        df = this.Ephys;
        df = msbackadj(this.EphysTime, df, 'WINDOWSIZE', 1, 'STEPSIZE', 1, 'SHOWPLOT', false);
        f = nan(ceil(max(this.EphysTime)), size(this.Ephys, 2));
        fTime = nan(size(f,1), 1);
        ephysSamplingInterval = this.EphysTime(2) - this.EphysTime(1);

        progressbar('Looking for periodic activity in electrophysiological data');
        for iCh = 1:size(this.Ephys, 2)
            for i = floor(this.EphysTime(1)+windowSize/2):ceil(this.EphysTime(end)-windowSize/2)
                [autocor, lags] = xcorr(df(this.EphysTime >= i-windowSize/2 & this.EphysTime < i+windowSize/2, iCh), round(1/frequencyRange(1)/ephysSamplingInterval), 'coeff');
                lagTime = lags*ephysSamplingInterval;
                [pks, locs, widths, proms] = findpeaks(autocor, 'MinPeakProminence', 0.2);
                peakLoc = find(lagTime(locs) >= frequencyRange(1) & lagTime(locs) <= frequencyRange(2), 1);
                if ~isempty(peakLoc)
                    f(i, iCh) = 1/lagTime(locs(peakLoc));
                end
                fTime(i) = i;
            end

            progressbar(0.5);
        end
        progressbar(1);

        this.PeriodicActivityEphysFrequency = f;
        this.PeriodicActivityEphysTime = fTime;    
    end
end