 classdef ImagingDataSet < handle
    properties (SetObservable)
        Data ImagingData
    end
    properties (SetAccess = private, SetObservable)
        FilePath string
        FileName string
    end
    properties (Dependent)
		MeasurementDate string
		SamplingFrequency double
		SWActiveCellRatio double
    end
    properties (Transient, SetObservable)
    end
    
    methods
        % Set methods
        
        % Get methods
		function value = get.MeasurementDate(this)
			if ~isempty(this.Data)
				value = string(cellfun(@(x) x.MeasurementDate, {this.Data.MesMetadata}, 'UniformOutput', false)');
			end
		end

		function value = get.SamplingFrequency(this)
			if ~isempty(this.Data)
				value = [this.Data.SamplingFrequency]';
			end
		end
        
		function value = get.SWActiveCellRatio(this)
			if ~isempty(this.Data) && ~isempty([this.Data.SWAanalytics])
				timefromstart = nan(length(this.Data), 1);
				activecellratio = nan(length(this.Data), 1);
				activecellratioNeuron = nan(length(this.Data), 1);
				activecellratioGlia = nan(length(this.Data), 1);
				averageMaxCfs = nan(length(this.Data), 1);
				averageMaxCfsNeuron = nan(length(this.Data), 1);
				averageMaxCfsGlia = nan(length(this.Data), 1);
				measurementstart = datetime(this.Data(1).MesMetadata(1).MeasurementDate, 'InputFormat', 'yyyy.MM.dd. HH:mm:ss,SSS');
				for i = 1:length(this.Data)
					measurementtime = datetime(this.Data(i).MesMetadata(1).MeasurementDate, 'InputFormat', 'yyyy.MM.dd. HH:mm:ss,SSS');
					timefromstart(i) = minutes(measurementtime - measurementstart);
					
					activecellratio(i) = sum(this.Data(i).SWAanalytics.activecellsMaxMinRatio) / length(this.Data(i).SWAanalytics.activecellsMaxMinRatio) * 100;
					activecellratioNeuron(i) = sum(this.Data(i).SWAanalytics.activecellsMaxMinRatio(this.Data(i).Neuron)) / length(this.Data(i).SWAanalytics.activecellsMaxMinRatio(this.Data(i).Neuron)) * 100;
					activecellratioGlia(i) = sum(this.Data(i).SWAanalytics.activecellsMaxMinRatio(this.Data(i).Glia)) / length(this.Data(i).SWAanalytics.activecellsMaxMinRatio(this.Data(i).Glia)) * 100;
					averageMaxCfs(i) = mean(this.Data(i).SWAanalytics.maxcfs);
					averageMaxCfsNeuron(i) = mean(this.Data(i).SWAanalytics.maxcfs(this.Data(i).Neuron));
					averageMaxCfsGlia(i) = mean(this.Data(i).SWAanalytics.maxcfs(this.Data(i).Glia));
				end
				value = table(timefromstart, activecellratio, activecellratioNeuron, activecellratioGlia, averageMaxCfs, averageMaxCfsNeuron, averageMaxCfsGlia);
			end
		end
        
        % Simple methods
		function autoClassifyCells(this)
            if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).autoClassifyCells;
				end
            end
		end
		
		function calculateCrossCorrelation(this)
			if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).calculateCrossCorrelation;
				end
			end
		end
		
		function calculateSWAanalytics(this)
			if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).calculateSWAanalytics;
				end
			end
		end
		
		function exportCells2DB(this)
            if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).exportCells2DB;
				end
            end
		end
		
		function importCellAnnotation(this)
            if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).importCellAnnotation;
				end
            end
		end
		
        function showRefImages(this)
            if ~isempty(this.Data)
				figure;
                montage(cat(4, this.Data.RefImage));
                spaceplots;
            end
        end
                
		function reportCellData(this)
            if ~isempty(this.Data)
				for iFile = 1:size(this.Data, 1)
					disp(this.Data(iFile).MesImageIndex);
					this.Data(iFile).reportCellData;
				end
            end
		end
		
        % Complex methods
        alignCells(thish)
        loadDataFromFolder(this, folderpath)
		reportFrequencyDistribution(this)
		reportWavelets(this)
    end
end 