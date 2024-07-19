function calculateCrossCorrelation(this, stepsize, windowsize, samplinginterval, signal1, varargin)
    % stepsize: in seconds
    % windowsize: in seconds
    % samplinginterval: in seconds
    if isempty(signal1)
        warning('CrossCorrelationResult calculateCrossCorrelation: at least one signal should be provided');
        return
    end
    
    if nargin > 5 && ~isempty(varargin{1})
        signal2 = varargin{1};
        if size(signal1, 1) ~= size(signal2, 1)
            warning('CrossCorrelationResult calculateCrossCorrelation: signals should have the same number of rows');
            return
        end
    else
        signal2 = [];
    end
    
    if nargin > 6
        lagnum = varargin{2};
    else
        lagnum = 20;
    end
    
    this.StepSize = stepsize;
    stepsize = round(stepsize / samplinginterval);
    this.WindowSize = windowsize;
    windowsize = round(windowsize / samplinginterval);
    
    this.MaxR = [];
    this.Lag = [];
    this.CrossCorrTotal = [];
    
    normsignal = (signal1 - repmat(mean(signal1), size(signal1,1), 1)) ./ repmat(std(signal1), size(signal1,1), 1);
    [this.CrossCorrTotal, lags] = xcorr(normsignal, lagnum, 'coeff');
    
    indT = 1;
    for iT = 1:stepsize:size(signal1, 1)
        if isempty(signal2)
            s1 = signal1(iT:min(iT+windowsize-2, size(signal1, 1)),:);

            if size(s1, 1) < windowsize - 1
                % Do not process shorter signals at the end, because they will have a higher R-value
                break;
            end

            normsignal = (s1 - repmat(mean(s1), size(s1,1), 1)) ./ repmat(std(s1), size(s1,1), 1);
            [cc, lags] = xcorr(normsignal, lagnum, 'coeff');
            cc = permute(reshape(cc, size(cc,1), size(signal1, 2), size(signal1, 2)), [2 3 1]);
            lags = lags * samplinginterval;

            this.MaxR(:,:,indT) = max(abs(cc), [], 3);
            this.MaxR(:,:,indT) = this.MaxR(:,:,indT) - diag(diag(this.MaxR(:,:,indT)));
            [~, ind] = max(cc, [], 3);
            this.Lag(:,:,indT) = abs(lags(ind));
        end
    
        indT = indT + 1;
    end
end