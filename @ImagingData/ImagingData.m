classdef ImagingData < handle
    properties (SetObservable)
        % Path of the image file
        FilePath
        % Image file name
        PicFileName
        % Reference image file name used for cell identification (path expected to be the same as for image file)
        RefFileName

        % Metadata for .mes or .mesc files
        MesMetadata
        % Image index in .mes or .mesc file
        MesImageIndex

        % Time points for intensity values (sec)
        Time

        % 2D reference image used for cell identification
        RefImage
        
        % Radius of the rolling ball used to subtract non-unified background from reference image
        CellExtractionRollingBallRadius = 10
        % Intensity threshold used for converting reference image to binary image
        CellExtractionThreshold
        % Minimum cell size (in pixels) for identified cells
        CellExtractionMinCellSize
        % Maximum cell size (in pixels) for identified cells
        CellExtractionMaxCellSize
        % Extension of identified cells (in pixels) to define ROIs
        CellExtractionBoundarySize
        % Minimum length (in pixels) for line scan segments within a cell-based ROI 
        LineSegmentMinPixel

        % Identified ROIs (frame scan) or line segments (line scan)
        ROIs
        % Identified cell-based ROIs fo line scan measurements (otherwise empty)
        ROIs2D
        % Average intensity in ROIs
        F
        % Range (in frames) to calculate baseline F0
        F0Range

        % Identified cells classified as neurons (NaN: non-classified, 0: classified, not neuron, 1: neuron)
        Neuron logical
        % Identified cells classified as glia (NaN: non-classified, 0: classified, not glia, 1: glia)
        Glia logical
        
        % Index of main green channel used for DF/F0 analysis
        ChannelGreen = 1
        % Index of main red channel used for DG/R analysis
        ChannelRed = 2
        % Background level intensity for all channels subtracted from F values before DF/F0 calculation
        SubtractBackgroundLevel
        % Whether background level intensity is calculated from F values or set manually
        SubtractBackgroundLevelMode = 'auto'
        % Parameter for smoothing DF/F0 traces
        Smooth = 1

        % Identified peaks on the DF/F0 traces
        Peaks
        
        % Frequency of periodic activity found by autocorrelation and corresponding time values
        PeriodicActivityFrequency
        PeriodicActivityTime
        PeriodicActivityEphysFrequency
        PeriodicActivityEphysTime
        
        % Corresponding ephys traces and time
        Ephys
        EphysTime
    end
    properties (Transient, SetObservable)
        % Raw experimental image (not saved)
        RawImage
        % Binary image made from RefImage for cell segmentation
        PicBW
        % Reduction factor for large data files used to average loaded frames
        ReductionFactor = 1
        % Set to true if you don't want to run calculateF()
        Updating = false;
    end
    properties (SetAccess = private, SetObservable)
        % Calculated DF/F0 traces (cannot be set directly. use calculateDeltaFperF0 method)
        DeltaFperF0
        % Calculated DG/R traces (cannot be set directly. set ChannelRed and use calculateDeltaFperF0 method)
        DeltaGperR
        % Remove baseline from the DF/F0 traces (cannot be set directly. use adjustBaseline method)
        DeltaFperF0BaselineAdjusted
        % Remove baseline from the smoothed version of DF/F0 traces (cannot be set directly. use adjustBaseline method)
        DeltaFperF0SmoothedBaselineAdjusted
        % Cell coordinates
        CellCoordinates
        % Distance matrix between cells
        CellDistance
		% Wavelet
		Wavelet
		% SWA analytics
		SWAanalytics
		% PhaseLock
		PhaseLock
        % Cross-correlation between imaging signals at specified intervals
        CrossCorrelationImaging CrossCorrelationResult = CrossCorrelationResult
        % Cross-correlation between ephys and imaging signals at specified intervals
        CrossCorrelationEphysImaging CrossCorrelationResult = CrossCorrelationResult
    end
    properties (Dependent)
        % Image file type
        PicFileType
		% Smoothed version of DF/F0 traces
        DeltaFperF0Smoothed
        % Smoothed version of  DG/R traces
        DeltaGperRSmoothed
        % Ratio of green and red fluorescence in ROIs
        GRRatio
        % (Dependent) Number of channels
        ChannelNum
        % (Dependent) Number of frames
        FrameNum
        % (Dependent) Number of identified cells, neurons, astrocytes
        CellNum
		NeuronNum
		GliaNum
        % (Dependent) Cell type (string)
        CellType
        % (Dependent) Identified ROIs classified as cell (NaN: non-classified, 0: not cell, 1: cell)
        ValidCell
        % Cell names
        CellNames
        % (Dependent) Sampling frequency
        SamplingFrequency
        % (Dependent) Sampling interval
        SamplingInterval
        % (Dependent) Lower LUT values for all channels
        LUTLower
        % (Dependent) Upper LUT values for all channels
        LUTUpper
        % (Dependent) Whether it is a line scan
        IsLineScan
        % (Dependent) Whether it is a frame scan
        IsFrameScan
        % Width and height of a pixel on the first XY image in the measurement
        PixelWidth
        PixelHeight
    end
    
    % Initialize instance when loaded from .mat file
    methods (Static)
        function obj = loadobj(this)
            recalculated = false;
            if isempty(this.DeltaFperF0BaselineAdjusted)
                this.adjustBaseline();
                recalculated = true;
            end
            if isempty(this.CellCoordinates)
                this.calculateCellCoordinates();
                recalculated = true;
            end
            if isempty(this.CrossCorrelation)
                this.calculateCrossCorrelation();
                recalculated = true;
            end
            
            obj = this;
            
            if recalculated
                disp('Some data were recalculated. Please, save the file in order to avoid time-consuming calulcation at file opening.');
            end
        end
    end
   
    methods
        % Set methods
        function set.RawImage(this, value)
            this.ROIs = [];
            this.RawImage = value;
        end
        
        function set.RefImage(this, value)
            this.RefImage = value;            
            if size(this.RawImage, 1) > 1 || ~isempty(this.ROIs2D)
                this.findROIs();
            elseif size(this.RawImage, 1) == 1
                this.resetLineROIs();
            end
        end
        
        function set.ROIs(this, value)
            this.ROIs = value;
            if ~isempty(this.ROIs)
                % Reset valid cells
                this.Neuron = false(max(this.ROIs(:)), 1);
                this.Glia = false(max(this.ROIs(:)), 1);
%                 this.calculateF();
            else
                this.F = [];
            end
        end
        
        function set.F(this, value)
            this.F = value;
            if ~isempty(this.F)
                this.calculateDeltaFperF0();
            else
                this.DeltaFperF0 = [];
                this.DeltaGperR = [];
            end
        end
        
        function set.MesMetadata(this, value)
            if ~isempty(value) && strcmp(value(1).Type, 'Line2') == 1
                this.resetLineROIs();
            end
            this.MesMetadata = value;
        end
        
        function set.CellExtractionRollingBallRadius(this, value)
            this.CellExtractionRollingBallRadius = value;
            this.findROIs();
        end
        
        function set.CellExtractionThreshold(this, value)
            this.CellExtractionThreshold = value;
            this.findROIs();
        end
        
        function set.CellExtractionMinCellSize(this, value)
            this.CellExtractionMinCellSize = value;
            this.findROIs();
        end
        
        function set.CellExtractionMaxCellSize(this, value)
            this.CellExtractionMaxCellSize = value;
            this.findROIs();
        end
        
        function set.CellExtractionBoundarySize(this, value)
            this.CellExtractionBoundarySize = value;
            this.findROIs();
        end
        
        function set.LineSegmentMinPixel(this, value)
            this.LineSegmentMinPixel = value;
            this.findROIs();
        end
        
        function set.F0Range(this, value)
            this.F0Range = value;
            if ~isempty(this.F)
                this.calculateDeltaFperF0();
            end
        end
     
        % Get methods        
        function value = get.PicFileType(this)
            value = [];
            if ~isempty(this.PicFileName)
				[filepath, name, ext] = fileparts(this.PicFileName);
                value = ext;
            end
        end
        
        function value = get.DeltaFperF0Smoothed(this)
            value = [];
            if ~isempty(this.DeltaFperF0)
                window = this.Smooth;
            % 	w = hann(window);
                w = ones(1, window) ./ window;
            %     w = gausswin(window) / sum(gausswin(window));
                s = zeros(size(this.DeltaFperF0));
                for iCh = 1:size(this.DeltaFperF0, 3)
                    for iCell = 1:size(this.DeltaFperF0, 2)
                        s(:,iCell,iCh) = conv(this.DeltaFperF0(:,iCell,iCh), w, 'same');
                    end
                end
                
                value = s;
            end
        end
        
        function value = get.DeltaGperRSmoothed(this)
            value = [];
            if ~isempty(this.DeltaGperR)
                window = this.Smooth;
            % 	w = hann(window);
                w = ones(1, window) ./ window;
            %     w = gausswin(window) / sum(gausswin(window));
                s = zeros(size(this.DeltaGperR));
                for iCell = 1:size(this.DeltaGperR, 2)
                    s(:,iCell) = conv(this.DeltaGperR(:,iCell), w, 'same');
                end
                
                value = s;
            end
        end
        
        function value = get.ChannelNum(this)
            value = [];
            if ~isempty(this.RawImage)
                value = size(this.RawImage, 4);
            elseif ~isempty(this.F)
                value = size(this.F, 3);
            end
        end
        
        function value = get.FrameNum(this)
            value = [];
            if ~isempty(this.Time)
                value = length(this.Time);
            else
                value = size(this.RawImage, 3);
            end
        end
        
        function value = get.CellNum(this)
            value = [];
            if ~isempty(this.F)
                value = size(this.F, 2);
            end
        end

		function value = get.GliaNum(this)
            value = sum(this.Glia);
		end
		
		function value = get.NeuronNum(this)
            value = sum(this.Neuron);
		end
		
		function value = get.CellType(this)
            value = [];
            celltype = cell(this.CellNum, 1);
            for i = 1:this.CellNum
                celltype{i} = 'not cell';
                if this.Glia(i) == 1
                    celltype{i} = 'Glia';
                elseif this.Neuron(i) == 1
                    celltype{i} = 'Neuron';
                end
            end
            value = celltype;
        end
        
        function value = get.ValidCell(this)
            value = [];
            if ~isempty(this.Neuron) && ~isempty(this.Glia)
                value = this.Neuron + this.Glia;
            end
        end

        function value = get.CellNames(this)
            value = [];
            if ~isempty(this.CellType)
                cn = cell(this.CellNum, 1);
				for i = 1:length(cn)
                    cn{i} = ['Cell ' num2str(i) ' (' this.CellType{i} ')'];
				end
	            value = cn;
            end
		end

        function value = get.SamplingFrequency(this)
            value = []; 
            if ~isempty(this.Time)
                value = 1/(this.Time(2) - this.Time(1));
            end
        end
        
        function value = get.SamplingInterval(this)
            value = [];
            if ~isempty(this.Time)
                value = this.Time(2) - this.Time(1);
            end
        end
        
        function value = get.LUTLower(this)
            value = [0 0 0];
            if ~isempty(this.MesMetadata)
                temp = [this.MesMetadata.LUTstruct];
                value = [temp.lower];
            end
        end
        
        function value = get.LUTUpper(this)
            value = [4096 4096 4096];
            if ~isempty(this.MesMetadata)
                temp = [this.MesMetadata.LUTstruct];
                value = [temp.upper];
            end
        end
        
        function value = get.IsLineScan(this)
            value = [];
            if ~isempty(this.RawImage)
                value = size(this.RawImage, 1) == 1;
			elseif ~isempty(this.ROIs)
				value = min(size(this.ROIs)) == 1;
            end
        end
        
        function value = get.IsFrameScan(this)
            value = [];
			if ~isempty(this.RawImage)
                value = size(this.RawImage, 1) > 1;
			elseif ~isempty(this.ROIs)
				value = min(size(this.ROIs)) > 1;
			end
        end
        
        function value = get.PixelWidth(this)
            value = [];
            for i = 1:length(this.MesMetadata)
                if strcmp(this.MesMetadata(i).Type, 'XY') == 1
                    value = this.MesMetadata(i).WidthStep;
                end
            end
        end
        
        function value = get.PixelHeight(this)
            value = [];
            for i = 1:length(this.MesMetadata)
                if strcmp(this.MesMetadata(i).Type, 'XY') == 1
                    value = this.MesMetadata(i).HeightStep;
                end
            end
        end
        
        function value = get.GRRatio(this)
            value = [];
            if ~isempty(this.RefImage) && ~isempty(this.ROIs)
                if this.IsFrameScan % 2D measurement
                    red = regionprops(this.ROIs, this.RefImage(:,:,1), 'MeanIntensity');
                    green = regionprops(this.ROIs, this.RefImage(:,:,2), 'MeanIntensity');
                elseif ~isempty(this.ROIs2D) % line-scan with 2D ROIs
                    red = regionprops(this.ROIs2D, this.RefImage(:,:,1), 'MeanIntensity');
                    green = regionprops(this.ROIs2D, this.RefImage(:,:,2), 'MeanIntensity');
                else % line-scan with 1D ROIs
                    ref = zeros(size(this.RefImage(:,:,1)));
                    for i = 1:this.CellNum
                        obj = find(this.ROIs == i) * this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).scanspeed;
                        l = this.MesMetadata(1).info_Linfo.lines(this.MesMetadata(1).info_Linfo.current).line2;
                        l2(1,:) = this.MesMetadata(3).Height - round((l(2,:) - this.MesMetadata(3).HeightOrigin) / this.MesMetadata(3).HeightStep);
                        l2(2,:) = round((l(1,:) - this.MesMetadata(3).WidthOrigin) / this.MesMetadata(3).WidthStep);
                        ind = l2(1:2,min(obj):max(obj));
                        % Remove line segments laying outside the image
                        ind = ind(1:2,ind(1,:) .* ind(2,:) > 0);
                        ind = ind(1:2, ind(1,:) <= size(ref, 1) & ind(2,:) <= size(ref, 2));
                        
                        ref(sub2ind(size(ref), ind(1,:), ind(2,:))) = i;
                    end
                    red = regionprops(ref, this.RefImage(:,:,1), 'MeanIntensity');
                    green = regionprops(ref, this.RefImage(:,:,2), 'MeanIntensity');
                end
                red = [red.MeanIntensity];
                red = (red - min(red)) / (max(red) - min(red));
                green = [green.MeanIntensity];
                green = (green - min(green)) / (max(green) - min(green));
                value = bsxfun(@rdivide, green, red);
            end
		end

		% Simple methods
        function [pxx,f] = periodogram(this)
			l = length(this.Time);
			for i = 1:size(this.DeltaFperF0, 2)
				[pxx(i,:),f] = periodogram(this.DeltaFperF0(:,i,1), rectwin(l), l, this.SamplingFrequency);
			end
		end
		
		function plotPowerSpectrumEphys(this, freq)
			samplingFrequency = 1 / (this.EphysTime(2) - this.EphysTime(1));
			% Low-pass filter at 50 Hz
			% [b,a] = butter(4, 50*2/samplingFrequency);
			% data = filter(b, a, this.Ephys);

			data = this.Ephys;

			% Calculate power spectrum
			wind = hann(length(data));
			fmin = freq(1);
			fmax = freq(2);
			fr = linspace(fmin, fmax, 50);
			[pxx, f] = periodogram(data, wind, fr, samplingFrequency, 'power');
			plot(f, pxx);
			xlabel('Frequency (Hz)');
			ylabel('Power (dB)');
		end
		
		function plotPhaselock(this)
			if (~isempty(this.PhaseLock))
				imagesc(this.PhaseLock);
				colormap jet;
				colorbar;
				xlabel("Cell #");
				ylabel("Cell #");
			end
		end
		
		function plotPhaselockMap(this)
			if (~isempty(this.PhaseLock))
				% All ROIs
				subplot(6,2,1:4);
				m = double(this.ROIs2D);
				meanPLV = nanmean(this.PhaseLock);
				for i = 1:this.CellNum
					m(m == i) = meanPLV(i);
				end
				imagesc(m);
				colorbar;
				colormap jet;

				subplot(6,2,6);
				for i = 1:size(this.PhaseLock, 1)
					for j = i+1:size(this.PhaseLock, 2)
						if this.PhaseLock(i,j) > 0.8
							line([this.CellCoordinates.centerX(i) this.CellCoordinates.centerX(j)], [size(m,1)-this.CellCoordinates.centerY(i) size(m,1)-this.CellCoordinates.centerY(j)], 'LineWidth', 0.1, 'Color', 'w');
						end
					end
				end
			end
		end
		
		function plotPhaselockVsCellDistance(this)
			if (~isempty(this.PhaseLock) && ~isempty(this.CellDistance))
				dist = tril(this.CellDistance);
				dist(dist == 0) = nan;
				pl = tril(this.PhaseLock);
				pl(pl == 0) = nan;
				plot(dist(this.Glia, this.Glia), pl(this.Glia, this.Glia), 'r.');
				hold on;
				plot(dist(this.Neuron, this.Neuron), pl(this.Neuron, this.Neuron), 'g.');
				plot(dist(this.Glia, this.Neuron), pl(this.Glia, this.Neuron), 'b.');
				xlabel("Cell pair distance");
				ylabel("PLV");
			end
		end

		function plotWaveletCell(this, ind, freq)
			wavelettype = 'cmor1-2';
			if freq(1) > 2
				wavelettype = 'cmor1-6';
			end
			dt = this.SamplingInterval;
			fmin = freq(1);
			fmax = freq(2);
			minscale = centfrq(wavelettype)/(fmin*dt);
			maxscale = centfrq(wavelettype)/(fmax*dt);
			scales = logspace(log10(minscale), log10(maxscale), 100);
			data = this.DeltaFperF0(:,ind,1);
			waveletFrequency = scal2frq(scales, wavelettype, dt);
			waveletCfs = cwt(data, scales, wavelettype);
			waveletCfs(:, this.Time < 3 | this.Time > max(this.Time) - 3) = NaN; % Delete first and last 3 s due to border effect
			waveletTime = dt:dt:size(data,1)*dt;
			pcolor(waveletTime, waveletFrequency, abs(waveletCfs));
			xlim([min(this.Time) max(this.Time)]);
			ylim([min(waveletFrequency) max(waveletFrequency)]);
			colormap jet;
			shading flat;
			xlabel('Time (s)');
			ylabel('Frequency (Hz)');
		end

        function showCell(this, ind)
			celldata = this.getCellData(ind);
			imagesc(imoverlay(celldata.image, celldata.roiPerim));
			% red = celldata.image;
			% red(:,:,2) = 0;
			% imwrite(red, "imr.png", "png")
			% green = celldata.image;
			% green(:,:,1) = 0;
			% imwrite(green, "img.png", "png")
		end
       
        function showAstrocytes(this)
			im = cell(sum(this.Glia), 1);
			i = 1;
			for ind = find(this.Glia)
				celldata = this.getCellData(ind);
				im{i} = imoverlay(celldata.image, celldata.roiPerim);
				i = i + 1;
			end
			montage(im);
		end		
       
        function showNeurons(this)
			im = cell(sum(this.Neuron), 1);
			i = 1;
			for ind = find(this.Neuron)
				celldata = this.getCellData(ind);
				im{i} = imoverlay(celldata.image, celldata.roiPerim);
				i = i + 1;
			end
			montage(im);
		end		
       
        function showNotCells(this)
			im = cell(sum(~this.Neuron & ~this.Glia), 1);
			i = 1;
			for ind = find(~this.Neuron & ~this.Glia)
				celldata = this.getCellData(ind);
				im{i} = imoverlay(celldata.image, celldata.roiPerim);
				i = i + 1;
			end
			montage(im);
		end		
       
        % Complex methods
        adjustBaseline(this, method, smooth, showPlot, varargin)
        autoSubtractBackgroundLevel(this)
        autoClassifyCells(this)
        calculateCellCoordinates(this)
        calculateCrossCorrelation(this)
        calculateDeltaFperF0(this)
        calculateF(this)
        calculatePhaselock(this, frequencyRange)
		calculateWavelet(this, frequencyRange)
		calculateSWAanalytics(this)
        convert1DTo2D(this)
		exportCells2DB(this)
        findROIs(this)
        findROIsFromRawImage(this)
        findActiveROIs(this, method)
        findPeriodicActivity(this, frequencyRange, windowSize, showPlot)
        findSLEs(this)
		importCellAnnotation(this)
		response = getCellData(this, cellnum)
		response = getCellDataAll(this)
        loadEphys(this, filepath)
        loadImage(this, filepath, varargin)
        surfPlot(this, figHandle, filter)
        plot(this, varargin)
        plotCells(this)
		plotCellsByWavelet(this, frequencyRange)
        plotFrequency(this)
		plotWaveletCells(this)
		reportCellData(this)
		reportSWA(this)
		reportWavelets(this)
        resetLineROIs(this)
        resetProperties(this)
        saveGraph(this)
        send2gephi(this)
    end
end