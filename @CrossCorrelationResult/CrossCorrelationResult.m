classdef CrossCorrelationResult < handle
    properties (SetObservable)
        % Step size and window size of the ranges at which cross-correlations are calculated
        StepSize
        WindowSize
        % Maximum of absolute R-value of cross-correlations, calculated for each segments of the signal
        MaxR
        % Lag of maximum R-value of cross-correlations, calculated for each segments of the signal
        Lag
        % Cross correlation data, calculated for the entire duration of the signal
        CrossCorrTotal
    end
    properties (SetAccess = private, SetObservable)
        % 
    end
    properties (Dependent)
    end
    properties (Transient, SetObservable)
    end
    
    methods
        % Set methods
        
        % Get methods
       
        % Complex methods
        calculateCrossCorrelation(this, signal1, varargin)
    end
end