function loadImage(this, filepath, varargin)
    [pathstr,name,ext] = fileparts(filepath);
    this.FilePath = pathstr;
    this.PicFileName = [name ext];
    
    this.MesImageIndex = [];
    if nargin > 2
        this.MesImageIndex = varargin{1};
    end
        
    progressbar('Loading image');
    
	if strcmpi(ext, '.tif') == 1 || strcmpi(ext, '.tiff') == 1 % TIFF file
		% Metadata
		info = imfinfo(fullfile(this.FilePath, this.PicFileName));
		height = info(1).Height;
		width = info(1).Width;
        % Number of frames
		frameNum = size(info, 1);
		% Number of channels
		numChannel = [];
		if isfield(info(1), 'ImageDescription')
			numChannel = regexp(info(1).ImageDescription, '\NumberOfViews= (.)', 'tokens', 'once');
			if size(numChannel, 1) > 0
				numChannel = str2double(numChannel{1});
				frameNum = frameNum / numChannel;
			end
		end
		if isempty(numChannel)
            numChannel = 1;
			this.ChannelRed = 0;
		end
		% Sampling frequency
		if contains(info(2).PageName, "Calibrated Position")
			[tokens,matches] = regexp([info(1:frameNum).PageName], 'Calibrated Position	(.*?)\s', 'tokens', 'match');
			this.Time = cell2mat(cellfun(@(x) str2double(x{1}), tokens, 'UniformOutput', false));
		end
        % Load image
		rawImage = zeros(height, width, frameNum, numChannel, 'uint16');
        for ch = 1:numChannel
			for frame = 1:frameNum
	% 			[picMulti(:,:,frame,1), ~] = imread(fullfile(pathname, filename), 'Index', frame, 'Info', info);
				rawImage(:,:,frame,ch) = imread(fullfile(this.FilePath, this.PicFileName), 'Index', (ch - 1) * frameNum + frame, 'Info', info);
				progressbar(((ch - 1) * frameNum + frame) / (ch * frameNum));
			end
        end
        this.RawImage = rawImage;
    elseif strcmpi(ext, '.mes') == 1 % MES file
        mesVars = whos('-file', filepath);
        filteredVars = {mesVars(cellfun(@(x)strcmpi(x(1:2), 'df'), {mesVars.name})).name};
        if isempty(this.MesImageIndex)
            % Load var names from the file
            filteredVarComments = cell(size(filteredVars));
            ffexists = 0;
            for iVar = 1:size(filteredVars, 2)
                varName = filteredVars(iVar);
                load(filepath, '-mat', char(varName));
                loadedVar = eval(char(varName));
                if strcmp(loadedVar(1).Type, 'FF') == 1 || strcmp(loadedVar(1).Type, 'Line2') == 1
                    filteredVarComments(iVar) = {['F', num2str(iVar), ' ', loadedVar(1).Type, '(', num2str(size(loadedVar, 1)), ') ', loadedVar(1).Comment]};
                    ffexists = 1;
                else
                    filteredVarComments(iVar) = {'Not an FF or Line image'};
                end
                progressbar(iVar / (iVar + 1));
            end
            clear loadedVar;
            progressbar(1);
            if ffexists == 0
                msgbox('There is no raster scan or line scan image in the .mes file', 'No FF image', 'error');
                return;
            end
            [selectedIndex, success] = listdlg('PromptString', 'Select an FF or Line2 image:', 'SelectionMode', 'single', 'ListString', filteredVarComments);
            if success == 0
                return;
            end
            this.MesImageIndex = selectedIndex;
        end
        
		% Metadata
        load(filepath, '-mat', filteredVars{this.MesImageIndex});
        metadata = eval(filteredVars{this.MesImageIndex});
        clear(filteredVars{this.MesImageIndex});

		% Load image
		res = loadImageMes(metadata, filepath);
		
		% Show background as reference image
		bgIndex = find(cell2mat(arrayfun(@(x) strcmp(x.Context, 'Background') && (strcmp(x.Channel, 'PMTr') || strcmp(x.Channel, 'pmtUR') || strcmp(x.Channel, 'pmtLR')), metadata, 'UniformOutput', false)) == 1, 1);
		load(filepath, '-mat', metadata(bgIndex).IMAGE);
		LUT = [metadata(bgIndex).LUTstruct.lower metadata(bgIndex).LUTstruct.upper];
        if ~isempty(bgIndex) && bgIndex > 0
            RefImage(:,:,1) = rot90(mat2gray(eval(metadata(bgIndex).IMAGE), LUT)); % Red channel
        end
		bgIndex = find(cell2mat(arrayfun(@(x) strcmp(x.Context, 'Background') && (strcmp(x.Channel, 'PMTg') || strcmp(x.Channel, 'pmtUG') || strcmp(x.Channel, 'pmtUGraw') || strcmp(x.Channel, 'pmtLG')), metadata, 'UniformOutput', false)) == 1, 1);
		load(filepath, '-mat', metadata(bgIndex).IMAGE);
		LUT = [metadata(bgIndex).LUTstruct.lower metadata(bgIndex).LUTstruct.upper];
        if ~isempty(bgIndex) && bgIndex > 0
            RefImage(:,:,2) = rot90(mat2gray(eval(metadata(bgIndex).IMAGE), LUT)); % Green channel
        end
        RefImage(:,:,3) = zeros(size(RefImage(:,:,2))); % Blue channel

        % Save variables
		this.Time = res.time;
        this.RefImage = RefImage;
        this.MesMetadata = metadata;
		this.RawImage = res.picMulti;
		this.RefFileName = [name '.' ext];
        this.Neuron = false(max(res.objectsFiltered(:)), 1);
        this.Glia = false(max(res.objectsFiltered(:)), 1);
		this.ROIs = res.objectsFiltered;
    elseif strcmpi(ext, '.mesc') == 1 % MESC file
		progressbar('Loading variables');
		
        if isempty(this.MesImageIndex)
            % Get list of images
            mesVars = h5info(filepath);
            exp = '_(\d)\>';
            listitems = cell(size(mesVars.Groups.Groups));
            for iVar = 1:size(mesVars.Groups.Groups, 1)
                zdim = h5readatt(filepath, mesVars.Groups.Groups(iVar).Name, 'ZDim');
                comment = char(h5readatt(filepath, mesVars.Groups.Groups(iVar).Name, 'Comment')');
                realIndex = str2double(mesVars.Groups.Groups(iVar).Name(19:end)) + 1;
                listitems(realIndex) = {['F', num2str(realIndex), ' (', num2str(zdim), ') ', comment]};
                progressbar(iVar / (iVar + 1));
            end

            progressbar(1);

            [selectedIndex, success] = listdlg('PromptString', 'Select an FF or Line2 image:', 'SelectionMode', 'single', 'ListString', listitems);
            if success == 0
                return;
            end
            this.MesImageIndex = selectedIndex;
        end
		
		% Load selected image
		res = loadImageMesc(filepath, this.MesImageIndex);
		
		% Show background as reference image
        im = zeros(size(res.picMulti, 1), size(res.picMulti, 2), size(res.picMulti, 4));
        for i = 1:size(im, 3)
            im(:,:,i) = mean(res.picMulti(:,:,:,i), 3);
        end
        imRGB = mesCreateRGB(im, res.metadata, res.channels, '');
        this.RefImage = imadjust(imRGB, stretchlim(imRGB), []);

        % Save variables
		this.Time = res.time;
        this.MesMetadata = res.metadata;
        this.RawImage = res.picMulti;
		this.RefFileName = [name '.' ext];
        this.ReductionFactor = res.reductionFactor;
        this.ChannelRed = 2;
        if isfield(res, 'objectsFiltered') && ~isempty(res.objectsFiltered)
            this.Neuron = nan(max(res.objectsFiltered(:)), 1);
            this.Glia = nan(max(res.objectsFiltered(:)), 1);
            this.ROIs = res.objectsFiltered;
        end
	elseif strcmpi(ext, '.mat') == 1 % Previously analyzed .mat file or custom-saved raw file
        load(filepath);
        if exist('imagingData', 'var')
            this.resetProperties();
            % Load RawImage
            if exist(fullfile(imagingData.FilePath, imagingData.PicFileName), 'file') > 0
                this.loadImage(fullfile(imagingData.FilePath, imagingData.PicFileName), imagingData.MesImageIndex);
            elseif exist(fullfile(pathstr, imagingData.PicFileName), 'file') > 0
                % Look in the current directory if the image is not available at the original location
                this.loadImage(fullfile(pathstr, imagingData.PicFileName), imagingData.MesImageIndex);
            end
            % Copy all non-hidden properties
            this.Updating = true;
            p = properties(imagingData);
            for i = 1:length(p)
                mp = findprop(ImagingData, p{i});
                if strcmp(mp.SetAccess, 'public') && mp.Dependent == 0 && mp.Transient == 0
                    this.(p{i}) = imagingData.(p{i});
                end
            end
            this.Updating = false;
        elseif exist('objectsFiltered', 'var') % Old format
            this.resetProperties();
            % Load RawImage
            this.loadImage(fullfile(pathname, picFilename), mesImageIndex);
            % Copy available properties
            this.FilePath = pathname;
            this.PicFileName = picFilename;
            this.RefFileName = reference;
            if exist('objectsFiltered', 'var')
                this.MesMetadata = metadata;
                this.MesImageIndex = mesImageIndex;
            end
            this.Time = time;
            this.RefImage = referenceImage;
            this.CellExtractionThreshold = backgroundLevel;
            this.CellExtractionMinCellSize = minCellSize;
            this.CellExtractionMaxCellSize = maxCellSize;
            this.CellExtractionBoundarySize = eval('boundary');
            this.ROIs = objectsFiltered;
            if exist('objectsFiltered2D', 'var')
                this.ROIs2D = objectsFiltered2D;
            end
            this.F = f;
            this.F0Range = [1 10];
            this.Neuron = neuron;
            this.Glia = glia;
            this.SubtractBackgroundLevel = [0;0];
            this.SubtractBackgroundLevelMode = 'manual';
            this.Smooth = eval('smooth');
            if exist('peaks', 'var')
                this.Peaks = eval('peaks');
            end
            this.ReductionFactor = 1;
        end
	end
	
    % Look for saved ROIs
    if exist(fullfile(this.FilePath, 'RoiSets')) == 7
        measurementDate = datenum(this.MesMetadata(1).MeasurementDate, 'yyyy.mm.dd. HH:MM:SS,fff');
        roiFiles = dir(fullfile(this.FilePath, 'RoiSets', '*.mat'));
        for iFile = 1:length(roiFiles)
            roiDate = datenum(roiFiles(iFile).name, 'yyyymmdd HH-MM-SS.fff');
            if abs(roiDate - measurementDate) * 24 * 60 * 60 * 1000 < 100
                choice = questdlg(['A RoiSet likely corresponding to the measurement was found. Do you want to load ' roiFiles(iFile).name '?'], 'RoiSet loading', 'OK', 'Cancel',' OK');
                if strcmp(choice, 'OK')
                    load(fullfile(this.FilePath, 'RoiSets', roiFiles(iFile).name));
                    this.ROIs2D = rois;
                    
                    % Convert to line scan positions
                    ROIs = zeros(1, size(this.RawImage, 2), 'uint16');
                    metadata = this.MesMetadata;
                    metadataBg = metadata(find(strcmp({metadata.Context}, 'Background') == 1, 1));
                    l2 = metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).line2;
                    l2(1,:) = round((l2(1,:) - metadataBg.WidthOrigin) / metadataBg.WidthStep);
                    l2(2,:) = metadataBg.Height - round((l2(2,:) - metadataBg.HeightOrigin) / metadataBg.HeightStep);
                    scanspeed = metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).scanspeed;
                    scanline = l2(1:2,scanspeed:scanspeed:length(l2));
                    for i = 1:size(scanline,2)
                        x = scanline(1,i);
                        y = scanline(2,i);
                        if x > 0 && x <= size(this.ROIs2D, 2) && y > 0 && y < size(this.ROIs2D, 1)
                            ROIs(i) = this.ROIs2D(y,x);
                        end
                    end
                    this.ROIs = ROIs;
                    break;
                end
            end
        end
    end
end