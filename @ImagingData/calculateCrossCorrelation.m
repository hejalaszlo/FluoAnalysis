function calculateCrossCorrelation(this)
    if isempty(this.F)
        warning('ImagingData calculateCrossCorrelation: not all required properties set');
        return
    end
    
    lagnum = 20;
    this.CrossCorrelationImaging.StepSize = 1;     % in seconds
    this.CrossCorrelationImaging.WindowSize = 59;  % in seconds
    this.CrossCorrelationImaging.MaxR = [];
    this.CrossCorrelationImaging.Lag = [];
    
    indT = 1;
    for iT = 1:round(this.CrossCorrelationImaging.StepSize / this.SamplingInterval):size(this.DeltaFperF0BaselineAdjusted, 1)
        signal = this.DeltaFperF0BaselineAdjusted(iT:min(iT+round(this.CrossCorrelationImaging.WindowSize/this.SamplingInterval)-2, size(this.DeltaFperF0BaselineAdjusted, 1)),:,1);
        
        if size(signal, 1) < round(this.CrossCorrelationImaging.WindowSize / this.SamplingInterval) - 1
            % Do not process shorter signals at the end, because they will have a higher R-value
            break;
        end
        
        normsignal = (signal - repmat(mean(signal), size(signal,1), 1)) ./ repmat(std(signal), size(signal,1), 1);
        [cc, lags] = xcorr(normsignal, lagnum, 'coeff');
        cc = permute(reshape(cc, size(cc,1), this.CellNum, this.CellNum), [2 3 1]);
        lags = lags * this.SamplingInterval;
        
        [this.CrossCorrelationImaging.MaxR(:,:,indT), ind] = max(abs(cc), [], 3);
        this.CrossCorrelationImaging.MaxR(:,:,indT) = this.CrossCorrelationImaging.MaxR(:,:,indT) - diag(diag(this.CrossCorrelationImaging.MaxR(:,:,indT)));
        this.CrossCorrelationImaging.Lag(:,:,indT) = abs(lags(ind));
    
        indT = indT + 1;
    end
end