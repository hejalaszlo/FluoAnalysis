function varargout = FluoAnalysis(varargin)
    % FLUOANALYSIS M-file for FluoAnalysis.fig
    %      FLUOANALYSIS, by itself, creates a new FLUOANALYSIS or raises the existing
    %      singleton*.
    %
    %      H = FLUOANALYSIS returns the handle to a new FLUOANALYSIS or the handle to
    %      the existing singleton*.
    %
    %      FLUOANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in FLUOANALYSIS.M with the given input arguments.
    %
    %      FLUOANALYSIS('Property','Value',...) creates a new FLUOANALYSIS or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before FluoAnalysis_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to FluoAnalysis_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help FluoAnalysis

    % Last Modified by GUIDE v2.5 19-Jul-2024 13:52:16

	warning off;

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @FluoAnalysis_OpeningFcn, ...
                       'gui_OutputFcn',  @FluoAnalysis_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end

% --- Executes just before FluoAnalysis is made visible.
function FluoAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
    
    % Choose default command line output for FluoAnalysis
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes FluoAnalysis wait for user response (see UIRESUME)
    % uiwait(handles.FluoAnalysis);
	
    % Variables
    handles.imagingData = ImagingData;
    handles.imagingData.CellExtractionMinCellSize = 20;
    handles.imagingData.CellExtractionMaxCellSize = 400;
    handles.imagingData.CellExtractionBoundarySize = 0;
    handles.imagingData.LineSegmentMinPixel = 20;
    handles.remainingScans = 0;
    handles.selectedChannel = 1;
    handles.selectedCell = 0;
    
    handles.updateInProgress = false;

    guidata(handles.output, handles);
	setupGUI(handles);
    
    % Property listeners
    addlistener(handles.imagingData, 'RawImage', 'PostSet', @(o,e) RawImageChanged(handles));
    addlistener(handles.imagingData, 'PicBW', 'PostSet', @(o,e) PicBWChanged(handles));
    addlistener(handles.imagingData, 'ROIs', 'PostSet', @(o,e) ROIsChanged(handles));
    addlistener(handles.imagingData, 'Smooth', 'PostSet', @(o,e) showPlot(handles));
    addlistener(handles.imagingData, 'DeltaFperF0', 'PostSet', @(o,e) showPlot(handles));
    
    % Load previous pathname
	up = strrep(userpath, ';', '');
	if exist(fullfile(up(1:end), 'heja_config.mat'), 'file') == 2
		load(fullfile(up(1:end), 'heja_config.mat'));
	end
	if exist('FluoAnalysis', 'var') && ~isempty(FluoAnalysis.pathname)
		handles.pathname = FluoAnalysis.pathname;
	end
	
    try
        addlistener(handles.sExperiment, 'ContinuousValueChange', @sImage_ContinuousCallback);
    catch % For Matlab versions older than 2014a
        try
            addlistener(handles.sExperiment, 'ActionEvent', @sImage_ContinuousCallback);
        catch % For even older Matlab versions
            sliderListener = handle.listener(handles.sExperiment, 'ActionEvent', @sImage_ContinuousCallback);
            setappdata(handles.sExperiment, 'sliderListeners', sliderListener);
        end
    end
    
    h = datacursormode(handles.FluoAnalysis);
    set(h, 'UpdateFcn', @updateTooltip);
    
    linkaxes([handles.axReference handles.axLeveled handles.axCells]);
    
    guidata(handles.output, handles);	
end

% --- Outputs from this function are returned to the command line.
function varargout = FluoAnalysis_OutputFcn(hObject, eventdata, handles)
    % Get default command line output from handles structure
    varargout{1} = handles.output;
    
    warning on;
end

%% PROPERTY LISTENERS
% ---------------------------------------------------

function RawImageChanged(handles)
    handles = guidata(handles.output);
    
    if ~isempty(handles.imagingData.RawImage)
        set(handles.sExperiment, 'Value', 1, 'Min', 1, 'Max', size(handles.imagingData.RawImage, 3), 'SliderStep', [1/(size(handles.imagingData.RawImage, 3) - 1) 10/(size(handles.imagingData.RawImage, 3) - 1)]);
        set(handles.eRefStart, 'String', num2str(1));
        set(handles.eRefEnd, 'String', num2str(size(handles.imagingData.RawImage, 3)));

        % Go to first frame
        showMainImage(handles);

        updateGUI(handles);
    end
end

function PicBWChanged(handles)
    imshow(handles.imagingData.PicBW, 'Parent', handles.axLeveled);
end

function ROIsChanged(handles)
    if ~isempty(handles.imagingData.ROIs)
        if handles.imagingData.IsLineScan && get(handles.panelLineScan, 'SelectedObject') == handles.rb2DRoi
            handles.imagingData.calculateDeltaFperF0();
        end
        
        updateGUI(handles);
    end
end

%% GUI SETUP
% ---------------------------------------------------

% Initial GUI setup
function setupGUI(handles)
    set(handles.axExperiment, 'XTick', [], 'YTick', []);
    colormap(handles.axExperiment, 'gray');
    
	axes(handles.axReference);
	axis off;
    axes(handles.axLeveled);
	axis off;
    axes(handles.axCells);
	axis off;
	
	xlabel(handles.axDeltaFperF0, 'Time (sec)');
	ylabel(handles.axDeltaFperF0, '\DeltaF/F_0');
	set(get(handles.axDeltaFperF0, 'ylabel'), 'rotation', 90);
    
    updateGUI(handles);
end

% Update GUI after data changes or events
function updateGUI(handles)
    if handles.updateInProgress
        return
    end
    
    set(handles.sExperiment, 'enable', 'off');
    set(findall(handles.panelReferenceImage, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panelCellExtraction, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panelLineScan, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panel2P, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panelChannelSelection, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panelChannelArithmetic, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.panelSubtractBackground, '-property', 'enable'), 'enable', 'off');
    set(handles.eCalcBackground, 'enable', 'off');
    set(handles.sSmooth, 'enable', 'off');
    set(handles.eSmooth, 'enable', 'off');
    
    % Input boxes
    set(handles.sRollingBallRadius, 'Value', handles.imagingData.CellExtractionRollingBallRadius);
    set(handles.eRollingBallRadius, 'String', num2str(handles.imagingData.CellExtractionRollingBallRadius));
    set(handles.sBackgroundLevel, 'Value', handles.imagingData.CellExtractionThreshold);
    set(handles.eBackgroundLevel, 'String', num2str(handles.imagingData.CellExtractionThreshold));
    set(handles.sMinCellSize, 'Value', handles.imagingData.CellExtractionMinCellSize);
    set(handles.eMinCellSize, 'String', num2str(handles.imagingData.CellExtractionMinCellSize));
    set(handles.sMaxCellSize, 'Value', handles.imagingData.CellExtractionMaxCellSize);
    set(handles.eMaxCellSize, 'String', num2str(handles.imagingData.CellExtractionMaxCellSize));
    set(handles.sBoundary, 'Value', handles.imagingData.CellExtractionBoundarySize);
    set(handles.eBoundary, 'String', num2str(handles.imagingData.CellExtractionBoundarySize));
    set(handles.eMinLineSize, 'String', num2str(handles.imagingData.LineSegmentMinPixel));
    set(handles.sSmooth, 'Value', handles.imagingData.Smooth);
    set(handles.eSmooth, 'String', num2str(handles.imagingData.Smooth));
    
    if ~isempty(handles.imagingData.Time)
        set(handles.txtFrequency, 'String', [num2str(handles.imagingData.SamplingFrequency, '%0.1f'), ' Hz (', num2str(round(handles.imagingData.SamplingInterval * 1000), '%0.1f'), ' ms)']);
    end
    
    % We have an experiment image
    if ~isempty(handles.imagingData.RawImage)
        set(handles.sExperiment, 'enable', 'on');
        set(findall(handles.panelReferenceImage, '-property', 'enable'), 'enable', 'on');
        showMainImage(handles);
    end
    
    % ROIs have been identified
    if ~isempty(handles.imagingData.ROIs)
        cellnum = num2str(max(handles.imagingData.ROIs(:)));
        neuronnum = num2str(nansum(handles.imagingData.Neuron));
        glianum = num2str(nansum(handles.imagingData.Glia));
        invalidcellnum = num2str(sum(handles.imagingData.ValidCell == 0));
        set(handles.txtCellNumber, 'String', [cellnum ' (' neuronnum ' neuron, ' glianum ' glia, ' invalidcellnum ' non-cell)']);    

        if size(handles.imagingData.ROIs, 1) == 1 % Line scan
            set(findall(handles.panelLineScan, '-property', 'enable'), 'enable', 'on');

            if isempty(handles.imagingData.ROIs2D)
                set(handles.panelLineScan, 'SelectedObject', handles.rb1DRoi);
                picPseudo = label2rgb(handles.imagingData.ROIs, 'lines', 'k');
                imshow(imresize(picPseudo, size(handles.imagingData.RefImage(:,:,1))), 'Parent', handles.axCells);
            else
                set(handles.panelLineScan, 'SelectedObject', handles.rb2DRoi);
                set(findall(handles.panelCellExtraction, '-property', 'enable'), 'enable', 'on');
                picPseudo = label2rgb(handles.imagingData.ROIs2D, 'lines', 'k');
                imshow(picPseudo, 'Parent', handles.axCells);
            end
        else % Frame scan
            set(findall(handles.panelCellExtraction, '-property', 'enable'), 'enable', 'on');
            picPseudo = label2rgb(handles.imagingData.ROIs2D, 'lines', 'k');
            imshow(picPseudo, 'Parent', handles.axCells);
        end        
    end
    
    if exist('KPM_IsReady') == 6
        set(findall(handles.panel2P, '-property', 'enable'), 'enable', 'on');
    end
    
    if ~isempty(handles.imagingData.SubtractBackgroundLevel) && isfield(handles, 'selectedChannel') && length(handles.imagingData.SubtractBackgroundLevel) >= handles.selectedChannel
        set(findall(handles.panelSubtractBackground, '-property', 'enable'), 'enable', 'on');
    	set(handles.eCalcBackground, 'String', num2str(handles.imagingData.SubtractBackgroundLevel(handles.selectedChannel)));
        if strcmp(handles.imagingData.SubtractBackgroundLevelMode, 'auto')
            set(handles.panelSubtractBackground, 'SelectedObject', handles.rbAuto);
        else
            set(handles.panelSubtractBackground, 'SelectedObject', handles.rbManual);
            set(handles.eCalcBackground, 'enable', 'on');
        end
    end
    
    if ~isempty(handles.imagingData.F0Range)
        valuemin = handles.imagingData.F0Range(1);
        valuemax = handles.imagingData.F0Range(2);
        if ~isempty(handles.imagingData.Time)
            set(handles.txtF0RangeDimension, 'String', 'sec');
            set(handles.eF0RangeStart, 'String', num2str(valuemin * handles.imagingData.SamplingInterval));
            set(handles.eF0RangeEnd, 'String', num2str(valuemax * handles.imagingData.SamplingInterval));
        else
            set(handles.txtF0RangeDimension, 'String', 'frame');
            set(handles.eF0RangeStart, 'String', num2str(valuemin));
            set(handles.eF0RangeEnd, 'String', num2str(valuemax));
        end
    end

    % Set channel number
    if handles.imagingData.ChannelNum > 0
        set(handles.txtChannels, 'String', [num2str(handles.selectedChannel) '/' num2str(handles.imagingData.ChannelNum)]);
        if handles.imagingData.ChannelNum == 1
            set(handles.panelChannelSelection, 'SelectedObject', handles.rbCh1);
            set(handles.panelChannelArithmetic, 'SelectedObject', handles.rbSingle);
        else
            set(findall(handles.panelChannelSelection, '-property', 'enable'), 'enable', 'on');
            if ~isempty(handles.imagingData.DeltaGperR)
                set(findall(handles.panelChannelArithmetic, '-property', 'enable'), 'enable', 'on');
            end
        end
    end
    
    if handles.imagingData.ReductionFactor > 1
        set(handles.txtReductionFactor, 'String', ['Reduction factor: ' num2str(handles.imagingData.ReductionFactor)]);
    else
        set(handles.txtReductionFactor, 'String', '');
    end
    
    % Smoothing
    if ~isempty(handles.imagingData.DeltaFperF0)
        set(handles.sSmooth, 'enable', 'on');
        set(handles.eSmooth, 'enable', 'on');
    end
    
    if ~isempty(handles.imagingData.RefImage)
        imshow(handles.imagingData.RefImage, 'Parent', handles.axReference);
    end
end

%% OPEN EXPERIMENT FILE
% ---------------------------------------------------

% Open .tif, .mes or .mat file
function openExperiment_Callback(hObject, eventdata, handles)
    if ~isfield(handles, 'pathname')
        handles.pathname = '';
    end
    
    [filename, pathname] = uigetfile({'*.*', 'All files'; '*.tif', 'Multiframe TIFF files (*.tif)'; '*.mes', 'MES files (*.mes)'; '*.mat', 'Matlab files (*.mat)'}, 'Open experiment file', handles.pathname);
    if filename == 0
		return;
    end
     
	% Save path
    handles.pathname = pathname;
    handles.filename = filename;
	up = strrep(userpath, ';', '');
	if exist(fullfile(up(1:end), 'heja_config.mat'), 'file') == 2
		load(fullfile(up(1:end), 'heja_config.mat'));
	end
	FluoAnalysis.pathname = pathname;
	if exist(fullfile(up(1:end), 'heja_config.mat'), 'file') == 2
		save(fullfile(up, 'heja_config.mat'), 'FluoAnalysis', '-append');
	else
		save(fullfile(up, 'heja_config.mat'), 'FluoAnalysis');
	end
    
	% Change window name
	set(gcf, 'Name', ['FluoAnalysis - ', fullfile(pathname, filename)]);
    
    set(handles.tbOpenNext,'Enable', 'off');
    set(handles.menuOpenNext,'Enable', 'off');
    
    handles.selectedChannel = 1;
    handles.updateInProgress = true;
    guidata(handles.output, handles);
    
    handles.imagingData.loadImage(fullfile(pathname, filename));
	
    handles.updateInProgress = false;
    guidata(handles.output, handles);

	if ~isempty(handles.imagingData.ROIs2D)
		set(handles.panelLineScan, 'SelectedObject', handles.rb2DRoi);
	end
    if isempty(handles.imagingData.SamplingInterval)
        menuSetFrameInterval_Callback(handles.menuSetFrameInterval, eventdata, handles)
    end
    
    updateGUI(handles);
end

% Open the next FF image in a .mes file
function tbOpenNext_ClickedCallback(hObject, eventdata, handles)
	mesVars = whos('-file', fullfile(handles.pathname, handles.filename));
	filteredVars = {mesVars(cellfun(@(x)strcmpi(x(1:2), 'df'), {mesVars.name})).name};
	for iVar=handles.mesImageIndex + 1:size(filteredVars, 2)
		loadedVar = getVar(handles, char(filteredVars(iVar)));
		if strcmp(loadedVar(1).Type, 'FF') == 1
			selectedIndex = iVar;
			load(fullfile(handles.pathname, handles.filename), '-mat', filteredVars{selectedIndex});
			metadata = eval(filteredVars{selectedIndex});

			res = loadImageMes(metadata, fullfile(handles.pathname, handles.filename));
			
            time = res.time;
			numChannel = res.numChannel;
			frameNum = res.frameNum;
			objectsFiltered = res.objectsFiltered;
			picMulti = res.picMulti;
            lutLower = res.lutLower;
            lutUpper = res.lutUpper;

			% Show identified cells in pseudo color
			picPseudo = label2rgb(objectsFiltered, 'lines', 'k');
			image(picPseudo, 'Parent', handles.axCells);

			% Change window name
			set(gcf, 'Name', ['FluoAnalysis - ', fullfile(handles.pathname, handles.filename), ' F', num2str(selectedIndex)]);
			
			break;
		end
	end
	
    handles.picMulti = picMulti;
	handles.deltaFperF0 = [];
	handles.time = time;
    handles.lutLower = lutLower;
    handles.lutUpper = lutUpper;
	handles.metadata = metadata;
	handles.mesImageIndex = selectedIndex;
	handles.calcBackground = [];
	for iCh = 1:numChannel
		handles.calcBackground(iCh) = safe_median(mean(picMulti(:,:,:,iCh), 3));
	end
	set(handles.eCalcBackground, 'String', num2str(handles.calcBackground(handles.selectedChannel)));
	
    guidata(handles.output, handles);
	
    showPlot(handles);
end

% Open the next FF image in a .mes file
function tbOpenEphys_ClickedCallback(hObject, eventdata, handles)
    if isfield(handles, 'pathname')
        pathname = handles.pathname;
    else
        pathname = '';
    end
    
    [filename, pathname] = uigetfile({'*.abf', 'ABF files (*.abf)'}, 'Open ABF file', pathname);
    handles.pathname = pathname;
    guidata(handles.output, handles);
    
    handles.imagingData.loadEphys(fullfile(pathname, filename));
end

%% CHANGE IMAGE FRAME
% ---------------------------------------------------

function sImage_ContinuousCallback(hObject, eventdata, dummy)
    handles = guidata(hObject);
	showMainImage(handles);
end

function showMainImage(handles)
    if ~isempty(handles.imagingData.RawImage)
		frame = round(get(handles.sExperiment, 'Value'));
        pic = handles.imagingData.RawImage;
        sizeY = size(pic, 1);
        sizeX = size(pic, 2);
        frameNum = size(pic, 3);
        
        window = handles.imagingData.Smooth - 1;
        if ~isempty(handles.imagingData.ROIs)
            if isempty(handles.imagingData.PicFileName) || handles.imagingData.PicFileType == ".mes"
                if handles.imagingData.IsFrameScan % Folded frame
                    if sizeY / sizeX > 2
                        rowNum = ceil(sqrt((sizeY+2) * sizeX));
                    else
                        rowNum = sizeY;
                    end
                    col = 1;
                    for i = 1:sizeY+2:rowNum
                        fullPic(i:i+sizeY-1, 1:min(rowNum, sizeX-col+1)) = mean(pic(1:sizeY, col:min(col+rowNum-1, sizeX), min(frame,frameNum-window):min(frame+window,frameNum),handles.selectedChannel), 3);
                        obj(i:i+sizeY-1, 1:min(rowNum, sizeX-col+1)) = logical(handles.imagingData.ROIs(1:sizeY, col:min(col+rowNum-1, sizeX)) > 0);
                        col = col + rowNum;
                    end
                    rgb = imoverlay(mat2gray(fullPic, [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]), logical(bwperim(obj)), [1 0 0]);
%                     rgb = reshape(permute(handles.picMulti(:,:,min(frame,size(handles.picMulti,3)-15):min(frame+15,size(handles.picMulti,3))), [1 3 2]), [16*size(handles.picMulti, 1), size(handles.picMulti, 2)]);
%                     rgb = imoverlay(mat2gray(handles.picMulti(:,:,frame,handles.selectedChannel), [handles.lutLower(handles.selectedChannel) handles.lutUpper(handles.selectedChannel)]), logical(bwperim(handles.objectsFiltered)), [1 0 0]);
                else % Line scan
                    fullPic = mat2gray(squeeze(permute(pic(1,:,min(frame,frameNum-50):min(frame+50,frameNum),handles.selectedChannel), [3 2 1 4])), [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]);
                    if handles.selectedCell == 0
                        rgb = imresize(fullPic, [512,512], 'bilinear');
                    else
                        obj = repmat(handles.imagingData.ROIs, size(fullPic, 1), 1);
                        rgb = imoverlay(mat2gray(fullPic, [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]), logical(bwperim(obj)), [1 0 0]);
                        rgb = imresize(rgb, [512,512], 'bilinear');
                    end
                end
            else % Tiff or MESc image
                if window == 1
                    rgb = imoverlay(mat2gray(pic(:,:,frame,handles.selectedChannel), [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]), logical(bwperim(handles.imagingData.ROIs)), [1 1 0]);
                else
                    rgb = imoverlay(mat2gray(mean(pic(:,:,min(frame,frameNum-window):min(frame+window,frameNum),handles.selectedChannel), 3), [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]), logical(bwperim(handles.imagingData.ROIs)), [1 1 0]);
                end
                
                if handles.selectedCell > 0
                    rgb = imoverlay(rgb, logical(bwperim(handles.imagingData.ROIs == handles.selectedCell)), [1 0 0]);
                end
            end
		else
            if ~isempty(handles.imagingData.MesMetadata)
                if sizeY > 1 % Folded frame
                    window = handles.imagingData.Smooth - 1;
                    if sizeY / sizeX > 2
                        rowNum = ceil(sqrt((sizeY+2) * sizeX));
                    else
                        rowNum = sizeY;
                    end
                    col = 1;
                    for i = 1:sizeY+2:rowNum
                        fullPic(i:i+sizeY-1, 1:min(rowNum, sizeX-col+1)) = mean(pic(1:sizeY, col:min(col+rowNum-1, sizeX), min(frame,frameNum-window):min(frame+window,frameNum),handles.selectedChannel), 3);
                        col = col + rowNum;
                    end
                    rgb = imoverlay(mat2gray(fullPic, [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]), false(size(fullPic)), [1 0 0]);
%                     rgb = reshape(permute(handles.picMulti(:,:,min(frame,size(handles.picMulti,3)-15):min(frame+15,size(handles.picMulti,3))), [1 3 2]), [16*size(handles.picMulti, 1), size(handles.picMulti, 2)]);
%                     rgb = imoverlay(mat2gray(handles.picMulti(:,:,frame,handles.selectedChannel), [handles.lutLower(handles.selectedChannel) handles.lutUpper(handles.selectedChannel)]), logical(bwperim(handles.objectsFiltered)), [1 0 0]);
                else % Line scan
                    fullPic = mat2gray(squeeze(permute(pic(1,:,min(frame,frameNum-50):min(frame+50,frameNum),handles.selectedChannel), [3 2 1 4])), [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]);
                    rgb = imresize(fullPic, [512,512], 'bilinear');
                end
            else % Tiff image
                rgb = mat2gray(pic(:,:,frame,handles.selectedChannel), [handles.imagingData.LUTLower(handles.selectedChannel) handles.imagingData.LUTUpper(handles.selectedChannel)]);
            end
        end
        
% 		imagesc(rgb, 'Parent', handles.axExperiment, 'HitTest', 'off', [handles.lutLower(handles.selectedChannel) handles.lutUpper(handles.selectedChannel)]);
%         set(handles.axExperiment, 'HitTest', 'off');
        if isfield(handles, 'iExperiment') && ishandle(handles.iExperiment)
            set(handles.iExperiment, 'CData', rgb);
        else
            handles.iExperiment = imshow(rgb, 'Parent', handles.axExperiment);
            guidata(handles.output, handles);
        end
        set(handles.iExperiment, 'ButtonDownFcn', @imageClicked);

		set(handles.txtFrame, 'String', [num2str(frame * handles.imagingData.ReductionFactor), '/', num2str(length(handles.imagingData.Time))]);
        if ~isempty(handles.imagingData.Time)
			set(handles.txtTime, 'String', [sprintf('%02d', floor(handles.imagingData.Time(frame) * handles.imagingData.ReductionFactor / 60)), ':', num2str(rem(handles.imagingData.Time(frame) * handles.imagingData.ReductionFactor, 60))]);
        end
    end
end

%% SET REFERENCE IMAGE
% ---------------------------------------------------

function btnRefLoad_Callback(hObject, eventdata, handles)
    if ~isfield(handles, 'pathname')
        handles.pathname = '';
    end
    [filename, pathname] = uigetfile({'*.tif; *.jpg', 'Image files (*.tif,*.jpg)'}, 'Open reference image', handles.pathname);
    
    handles.pathname = pathname;
    handles.imagingData.RefImage = imread(fullfile(pathname, filename));
end

function cboRefMethod_Callback(hObject, eventdata, handles)
    btnRefSubmit_Callback(hObject, eventdata, handles);
end

function btnRefSubmit_Callback(hObject, eventdata, handles)
	refStart = str2double(get(handles.eRefStart,'String'));
	refEnd = str2double(get(handles.eRefEnd,'String'));
    
    switch get(handles.cboRefMethod, 'Value')
        case 1 % AVG
            g = mean(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelGreen), 3);
            if handles.imagingData.ChannelRed > 0
                r = mean(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelRed), 3);
            end
        case 2 % MAX
            g = max(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelGreen), [], 3);
            if handles.imagingData.ChannelRed > 0
                r = max(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelRed), [], 3);
            end
        case 3 % STD
            g = std(single(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelGreen)), [], 3);
            if handles.imagingData.ChannelRed > 0
                r = std(single(handles.imagingData.RawImage(:,:,refStart:refEnd, handles.imagingData.ChannelRed)), [], 3);
            end
    end
    g = mat2gray(g);
    g = imadjust(g, stretchlim(g), [0.01 0.9]);
    g = uint8(g * 255);
    if handles.imagingData.ChannelRed > 0
        r = mat2gray(r);
        r = imadjust(r, stretchlim(r), [0.01 0.9]);
        r = uint8(r * 255);
        handles.imagingData.RefImage = cat(3, r, g, zeros(size(g)));
    else
        handles.imagingData.RefImage = cat(3, zeros(size(g)), g, zeros(size(g)));
    end
		
    guidata(handles.output, handles);
    
    updateGUI(handles);
end

%% THRESHOLD THE IMAGE
% ---------------------------------------------------

function eRollingBallRadius_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionRollingBallRadius ~= str2double(get(hObject,'String'))
        handles.imagingData.CellExtractionRollingBallRadius = str2double(get(hObject,'String'));
    end
end

function sRollingBallRadius_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionRollingBallRadius ~= get(hObject, 'Value')
        handles.imagingData.CellExtractionRollingBallRadius = get(hObject, 'Value');
    end
end

function eBackgroundLevel_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionThreshold ~= str2double(get(hObject,'String'))
        handles.imagingData.CellExtractionThreshold = str2double(get(hObject,'String'));
    end
end

function sBackgroundLevel_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionThreshold ~= get(hObject, 'Value')
        handles.imagingData.CellExtractionThreshold = get(hObject, 'Value');
    end
end

function eMinCellSize_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionMinCellSize ~= str2double(get(hObject,'String'))
        handles.imagingData.CellExtractionMinCellSize = str2double(get(hObject,'String'));
    end
end

function sMinCellSize_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionMinCellSize ~= get(hObject, 'Value')
        handles.imagingData.CellExtractionMinCellSize = get(hObject, 'Value');
    end
end

function eMaxCellSize_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionMaxCellSize ~= str2double(get(hObject,'String'))
        handles.imagingData.CellExtractionMaxCellSize = str2double(get(hObject,'String'));
    end
end

function sMaxCellSize_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionMaxCellSize ~= get(hObject, 'Value')
        handles.imagingData.CellExtractionMaxCellSize = get(hObject, 'Value');
    end
end

function eBoundary_Callback(hObject, eventdata, handles)
    if handles.imagingData.CellExtractionBoundarySize ~= str2double(get(hObject,'String'))
        handles.imagingData.CellExtractionBoundarySize = str2double(get(hObject,'String'));
    end
end

function sBoundary_Callback(hObject, eventdata, handles)
    boundary = round(get(hObject, 'Value'));
    set(hObject, 'Value', boundary);
    
    if handles.imagingData.CellExtractionBoundarySize ~= boundary
        handles.imagingData.CellExtractionBoundarySize = boundary;
    end
end

function panelLineScan_SelectionChangedFcn(hObject, eventdata, handles)
    if size(handles.imagingData.ROIs, 1) == 1 && get(handles.panelLineScan, 'SelectedObject') == handles.rb1DRoi
        handles.imagingData.resetLineROIs();
    else
        handles.imagingData.findROIs();
    end
end

function eMinLineSize_Callback(hObject, eventdata, handles)
    if handles.imagingData.LineSegmentMinPixel ~= str2double(get(hObject,'String'))
        handles.imagingData.LineSegmentMinPixel = str2double(get(hObject,'String'));
    end
    panelLineScan_SelectionChangedFcn(handles.panelLineScan, [], handles);
end

%% 2P SETUP
% Control MATLAB-based Femtonics microscopes
% ---------------------------------------------------

% Scan reference image
function btnRefScan_Callback(hObject, eventdata, handles)
    handles.remainingScans = 0;
    while ~KPM_IsReady
        pause(0.05);
    end
    dobackgroundimage('startautom', {@refScanFinished, handles});
end

function refScanFinished(funcstr, res, handles)
    mestags = get(res.mth);
%     mestags = get(mestaghandle('f3'));

    % Find green channel
    metadataSelected = getSelectedChannelMetadata(mestags, 'red');

%     handles.imagingData.RawImage = imadjust(uint16(rot90(metadataSelected.IMAGE)));
    handles.imagingData.RawImage = uint16(rot90(metadataSelected.IMAGE));
    if isempty(handles.imagingData.CellExtractionThreshold)
        handles.imagingData.CellExtractionThreshold = 0;
    end
    handles.imagingData.RefImage = imadjust(uint16(rot90(metadataSelected.IMAGE)));
    handles.imagingData.MesMetadata = metadataSelected;
    handles.imagingData.findROIs();
    
    updateGUI(handles);

%     showMainImage(handles);
    
    if handles.remainingScans > 0
        btnSetLines_Callback([], [], handles);
        
        while ~KPM_IsReady
            pause(0.05);
        end
        disp(['Starting line scan (' num2str(round(str2double(get(handles.eLineScanRepeat, 'String'))) - handles.remainingScans + 1) '/' num2str(round(str2double(get(handles.eLineScanRepeat, 'String')))) ')']);
        dolinemeasurement('startautom', {@lineScanFinished, handles});
        
        % Save ROIs
        rois = handles.imagingData.ROIs;
        save(['RoiSets/' datestr(now, 'yyyymmdd HH-MM-ss.fff') '.mat'], 'rois');
    end
end

% Set scan lines
function btnSetLines_Callback(hObject, eventdata, handles)
    global guiinfo;
    global Linfo;

    if ~strcmp(guiinfo.currentset, 'lineview')
        msgbox('Change to Line menu');
        return;
    end
    
    % Update the handles structure (otherwise the handles before the first call will be used)
    handles = guidata(handles.output);

    while ~KPM_IsReady
        pause(0.05);
    end  
   
    stats = regionprops(handles.imagingData.ROIs, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'BoundingBox', 'Extent');
%     stats = stats([stats.Extent] > 0.4);
    Linfo.lines(Linfo.current).line1 = cell(1, length(stats));
    metadata = handles.imagingData.MesMetadata(1);
    for iCell = 1:length(stats)
        % Major axis
        deltaX = stats(iCell).MajorAxisLength * cosd(stats(iCell).Orientation);
        deltaY = stats(iCell).MajorAxisLength * sind(stats(iCell).Orientation);
        lineX = [stats(iCell).Centroid(1) - deltaX/2 stats(iCell).Centroid(1) + deltaX/2];
        lineY = [stats(iCell).Centroid(2) - deltaY/2 stats(iCell).Centroid(2) + deltaY/2];
        line(lineX, lineY, 'Color', 'w', 'Parent', handles.axCells);

        Linfo.lines(Linfo.current).line1{(iCell - 1) * 2 + 1} = [lineX * metadata.WidthStep + metadata.WidthOrigin; metadata.Height * metadata.HeightStep - lineY * metadata.HeightStep + metadata.HeightOrigin; metadata.Zlevel metadata.Zlevel];
        
        % Minor axis
        deltaX = stats(iCell).MinorAxisLength * (cosd(stats(iCell).Orientation - 90));
        deltaY = stats(iCell).MinorAxisLength * (sind(stats(iCell).Orientation - 90));
        lineX = [stats(iCell).Centroid(1) - deltaX/2 stats(iCell).Centroid(1) + deltaX/2];
        lineY = [stats(iCell).Centroid(2) - deltaY/2 stats(iCell).Centroid(2) + deltaY/2];
        line(lineX, lineY, 'Color', 'w', 'Parent', handles.axCells);

        Linfo.lines(Linfo.current).line1{(iCell - 1) * 2 + 2} = [lineX * metadata.WidthStep + metadata.WidthOrigin; metadata.Height * metadata.HeightStep - lineY * metadata.HeightStep + metadata.HeightOrigin; metadata.Zlevel metadata.Zlevel];
    end
    linput('llineselectcb');

    % Optimize the path by Travelling Salesman method
    if get(handles.cbOptimizePath, 'Value')
        starts = Linfo.lines(Linfo.current).line2(1:2,Linfo.lines(Linfo.current).line2RoI(1,:))';
        ends = Linfo.lines(Linfo.current).line2(1:2,Linfo.lines(Linfo.current).line2RoI(2,:))';
        % Save .tsp file
        str{1} = 'NAME: lkh';
        str{2} = 'COMMENT: ';
        str{3} = 'TYPE: TSP';
        str{4} = sprintf('DIMENSION: %d', size(starts, 1));
        str{5} = 'EDGE_WEIGHT_TYPE: EUC_2D';
        str{6} = 'NODE_COORD_SECTION';
        for i = 1:size(starts, 1)
            str{i+6} = sprintf('%d %0.2f %0.2f', i, starts(i,1), starts(i,2));
        end
        fid = fopen('D:\lkh.tsp', 'wt');
        fprintf(fid, '%s\n', str{:});
        fclose(fid);
        status = system('D:\LKH-2.exe D:\lkh.par <nul >nul'); % LKH-2 is faster than LKH-3
        if status == 0
            % Load result file
            fid = fopen('D:\lkh.txt');
            tline = fgetl(fid);
            i = 1;
            optRoute = zeros(size(starts, 1), 1);
            while ischar(tline)
                if strcmp(tline, 'TOUR_SECTION') == 1 || i > 1
                    tline = fgetl(fid);
                    if str2double(tline) < 0
                        break;
                    end
                    optRoute(i) = str2double(tline);
                    i = i + 1;
                else
                    tline = fgetl(fid);
                end
            end
            fclose(fid);
        end

%         resultStruct = tsp_ga(struct('XY', starts, 'XYcityexit', ends, 'showProg', true, 'showResult', false, 'popsize', 100, 'NUMITER', 5000));
%         startsOpt = starts(resultStruct.optRoute, :);
%         endsOpt = ends(resultStruct.optRoute, :);
        startsOpt = starts(optRoute, :);
        endsOpt = ends(optRoute, :);
        Linfo.lines(Linfo.current).line1 = cell(1, length(stats) * 2);
        for i = 1:size(startsOpt, 1)
            Linfo.lines(Linfo.current).line1{i} = [[startsOpt(i,:)'; metadata.Zlevel] [endsOpt(i,:)'; metadata.Zlevel]];
        end
        linput('llineselectcb');
    end
end

% Start/stop line scan
function btnStartStopLineScan_Callback(hObject, eventdata, handles)
    global guiinfo;

    if ~strcmp(guiinfo.currentset, 'lineview')
        msgbox('Change to Line menu');
        return;
    end
    
    if strcmp(get(handles.btnStartStopLineScan, 'String'), 'Stop') == 1
        dolinemeasurement('stop');
        
        handles.remainingScans = 0;
        guidata(handles.output, handles);

        set(handles.btnStartStopLineScan, 'String', 'Line-scan');
    else
        handles.remainingScans = round(str2double(get(handles.eLineScanRepeat, 'String')));
        guidata(handles.output, handles);

        disp(['Starting background scan (' num2str(round(str2double(get(handles.eLineScanRepeat, 'String'))) - handles.remainingScans + 1) '/' num2str(round(str2double(get(handles.eLineScanRepeat, 'String')))) ')']);
        while ~KPM_IsReady
            pause(0.05);
        end
        dobackgroundimage('startautom', {@refScanFinished, handles});
    end
end

function lineScanFinished(funcstr, res, handles)
    % Update the handles structure (otherwise the handles before the first call will be used)
    handles = guidata(handles.output);

    handles.remainingScans = handles.remainingScans - 1;
    disp(handles.remainingScans);
    guidata(handles.output, handles);

    % Start new scan if it is needed
    if handles.remainingScans > 0
        disp(['Starting background scan (' num2str(round(str2double(get(handles.eLineScanRepeat, 'String'))) - handles.remainingScans + 1) '/' num2str(round(str2double(get(handles.eLineScanRepeat, 'String')))) ')']);
        while ~KPM_IsReady
            pause(0.05);
        end
        dobackgroundimage('startautom', {@refScanFinished, handles});
    else
        handles.remainingScans = round(str2double(get(handles.eLineScanRepeat, 'String')));
        set(handles.btnStartStopLineScan, 'String', 'Line-scan');
    
        guidata(handles.output, handles);
    end
end

function metadata = getSelectedChannelMetadata(mestags, channel)
    % Get selected (green or red) metadata
    for iCh = 1:length(mestags)
        if strcmp(channel, 'green')
            if strcmp(mestags(iCh).Channel, 'PMTg') == 1 || strcmp(mestags(iCh).Channel, 'pmtLG') == 1 || strcmp(mestags(iCh).Channel, 'pmtUG') == 1
                metadata = mestags(iCh);
                break;
            end
        elseif strcmp(channel, 'red')
            if strcmp(mestags(iCh).Channel, 'PMTr') == 1 || strcmp(mestags(iCh).Channel, 'pmtLR') == 1 || strcmp(mestags(iCh).Channel, 'pmtUR') == 1
                metadata = mestags(iCh);
                break;
            end
        else
            if strcmp(mestags(iCh).Channel, 'PMTg') == 1 || strcmp(mestags(iCh).Channel, 'pmtLG') == 1
                if ~exist('metadata', 'var')
                    metadata = mestags(iCh);
                    metadata.IMAGE = 4096 * mat2gray(mestags(iCh).IMAGE, [mestags(iCh).LUTstruct.lower mestags(iCh).LUTstruct.upper]);
                else
                    metadata.IMAGE = max(metadata.IMAGE, 4096 * mat2gray(mestags(iCh).IMAGE, [mestags(iCh).LUTstruct.lower mestags(iCh).LUTstruct.upper]));
                end
                metadata.LUTstruct.lower = 0;
                metadata.LUTstruct.upper = 4096;
            end
            if strcmp(mestags(iCh).Channel, 'PMTr') == 1 || strcmp(mestags(iCh).Channel, 'pmtLR') == 1
                if ~exist('metadata', 'var')
                    metadata = mestags(iCh);
                    metadata.IMAGE = 4096 * mat2gray(mestags(iCh).IMAGE, [mestags(iCh).LUTstruct.lower mestags(iCh).LUTstruct.upper]);
                else
                    metadata.IMAGE = max(metadata.IMAGE, 4096 * mat2gray(mestags(iCh).IMAGE, [mestags(iCh).LUTstruct.lower mestags(iCh).LUTstruct.upper]));
                end
                metadata.LUTstruct.lower = 0;
                metadata.LUTstruct.upper = 4096;
            end
        end
    end
end

%% SHOW DELTAFPERF0 PLOT
% ---------------------------------------------------

function showPlot(handles)
    handles = guidata(handles.output);
    
	if isempty(handles.imagingData.DeltaFperF0)
		cla(handles.axDeltaFperF0);
		return
	end

    xlim(handles.axDeltaFperF0, 'auto');
    ylim(handles.axDeltaFperF0, 'auto');

    if max(handles.imagingData.Time) >= 300
		time = handles.imagingData.Time./60;
		xla = 'Time (min)';
	else
		time = handles.imagingData.Time;
		xla = 'Time (sec)';
	end 
	
    xl = xlim;
    yl = ylim;
    mode = xlim(handles.axDeltaFperF0, 'mode');
    if size(handles.imagingData.DeltaFperF0, 2) == size(handles.imagingData.ValidCell, 1) && sum(handles.imagingData.ValidCell ~= 0) > 0
        validcell = handles.imagingData.ValidCell;
    else
        validcell = ones(size(handles.imagingData.DeltaFperF0, 2), 1);
    end
    selectedArithmetic = get(get(handles.panelChannelArithmetic, 'SelectedObject'), 'Tag');
    switch selectedArithmetic
		case 'rbSingle'
			plot(handles.axDeltaFperF0, time, handles.imagingData.DeltaFperF0Smoothed(:,validcell ~= 0,handles.selectedChannel));
		case 'rbRatio'
			plot(handles.axDeltaFperF0, time, handles.imagingData.DeltaGperRSmoothed(:,validcell ~= 0));
    end
    if strcmp(mode, 'manual')
        xlim(xl);
        ylim(yl);
    end
    
    xlabel(handles.axDeltaFperF0, xla);
	ylabel(handles.axDeltaFperF0, '\DeltaF/F_0');
	set(get(handles.axDeltaFperF0, 'ylabel'), 'rotation', 90);

    if handles.selectedCell > 0
        lines = flipud(get(handles.axDeltaFperF0, 'Children'));
        set(lines, 'Color', [0.7 0.7 0.7]);
        hold(handles.axDeltaFperF0, 'on');
        plot(handles.axDeltaFperF0, lines(handles.selectedCell).XData, lines(handles.selectedCell).YData, 'r');
    end
    
%     addContextMenu(handles);
end

function addContextMenu(handles)
	% Attach the context menu to each line on the dFperF0 graph
    lines = flipud(get(handles.axDeltaFperF0, 'Children'));
	for iLine = 1:length(lines)
		cmenu = uicontextmenu;
		uimenu(cmenu, 'Label', 'Delete cell', 'Callback', @removeCell_graph, 'Userdata', iLine);
		try
			set(lines(iLine), 'uicontextmenu', cmenu);
			set(lines(iLine), 'ButtonDownFcn', @graphDeltaFperF0_ButtonDownFcn, 'Userdata', iLine);
		catch
		end
	end	
end

%% INTERACTING WITH IMAGES
% ---------------------------------------------------

function imageClicked(hObject, eventdata)
	handles = guidata(hObject);
    selectedCell = 0;
    switch get(gcf,'selectiontype')
		case 'normal' % click - Select cell
			if ~isempty(handles.imagingData.ROIs2D)
				pos = get(gca, 'CurrentPoint');
                if handles.imagingData.IsLineScan
                    selectedCell = handles.imagingData.ROIs(round(pos(1,1)));
                else
                    selectedCell = handles.imagingData.ROIs2D(round(pos(1,2)), round(pos(1,1)));
                end
% 				if selectedCell ~= handles.selectedCell
% 					markCell(handles, selectedCell);
% 				else
% 					showMainImage(handles);
%                     showPlot(handles);
% 				end
			end
		case 'open' % double click - Add/remove ROI
			pos = get(gca, 'CurrentPoint');
			selectedCell = handles.imagingData.ROIs2D(round(pos(1,2)), round(pos(1,1)));
			if selectedCell > 0
				removeROI(handles, selectedCell);
			else
				addROI(handles, pos);
			end
		case 'extend' % shift-click - Split ROI
    end
    
    handles.selectedCell = selectedCell;
    guidata(hObject, handles);
    
    showMainImage(handles);
    showPlot(handles);
end

function axDeltaFperF0_ButtonDownFcn(hObject, eventdata)
	handles = guidata(hObject);
	y = get(hObject, 'YData');
	[dummy, index] = ismember(y, handles.deltaFperF0(:,:,handles.selectedChannel)', 'rows');
	markCell(handles, index);
end

function txt = updateTooltip(dummy, event_obj)
    handles = guidata(get(event_obj.Target, 'Parent'));
    pos = event_obj.Position;

	if strcmp(get(event_obj.Target, 'Type'), 'line')
        % This is a line plot
        
        % Get the index of the corresponding data in deltaFperF0
        y = get(event_obj.Target, 'YData');
        [dummy, index] = ismember(y, handles.deltaFperF0(:,:,1)', 'rows');

        % Tooltip
        txt = {['Time: ', num2str(pos(1)), ' min'],['dF/F0: ', num2str(pos(2))]};
    elseif strcmp(get(event_obj.Target, 'Type'), 'image')
        % This is an image
        
        % Get the index of the selected cell
        index = handles.objectsFiltered(pos(2), pos(1));
        if index > 0
            txt = {['Cell ', num2str(index)]};
        else
            txt = {'No cell here'};
        end
	end
	
	markCell(handles, index);
end

% Mark cell on the image and the graph
function markCell(handles, index)
    showPlot(handles);
    lines = flipud(get(handles.axDeltaFperF0, 'Children'));
    if index > 0 && length(lines) >= index
        set(lines, 'Color', [0.7 0.7 0.7]);
        hold(handles.axDeltaFperF0, 'on')
        plot(handles.axDeltaFperF0, lines(index).XData, lines(index).YData, 'r');
    
		showMainImage(handles);
		rgb = imoverlay(handles.iExperiment, logical(imdilate(double(bwperim(handles.objectsFiltered == index)), strel('square',3))), color);
%         image(rgb, 'Parent', handles.axExperiment, 'HitTest', 'off');
% 		set(handles.axExperiment, 'XTick', [], 'YTick', []);
    end
end

%% ADD/REMOVE CELLS
% ---------------------------------------------------

function removeCell_graph(hObject, eventdata)
	handles = guidata(hObject);
	index = get(gcbo, 'Userdata');
	removeROI(handles, index);
end

function removeCell_image(hObject, eventdata)
	handles = guidata(hObject);
	cp = get(gca, 'CurrentPoint');
	index = handles.objectsFiltered(cp(1,2), cp(1,1));
	if index > 0
		removeROI(handles, index);
	end
end

function removeROI(handles, cellIndex)
    handles.imagingData.ROIs(handles.imagingData.ROIs == cellIndex) = 0;
    return;
	% Remove from deltaFperF0
	if isfield(handles, 'deltaFperF0') && size(handles.deltaFperF0, 2) >= cellIndex
		handles.deltaFperF0(:,cellIndex,:) = [];
		guidata(handles.output, handles);
		showPlot(handles);
	end
	
	% Remove from objectsfiltered
	handles.objectsFiltered(handles.objectsFiltered == cellIndex) = 0;
	handles.objectsFiltered(handles.objectsFiltered > cellIndex) = handles.objectsFiltered(handles.objectsFiltered > cellIndex) - 1;
    picPseudo = label2rgb(handles.objectsFiltered, 'lines', 'k');
    imshow(picPseudo, 'Parent', handles.axCells);
	
	% Show main image
	showMainImage(handles);
	
    guidata(handles.output, handles);
end

function addROI(handles, pos)
    frame = get(handles.sExperiment, 'Value');
	
	% Crop region around the selected pixel
	maxRadius = floor(sqrt(handles.maxCellSize / 3.14 * 4));
	pos = round(min(size(handles.iExperiment, 1) - maxRadius - 1, max(maxRadius + 1, pos)));
	rect = imcrop(handles.picMulti(:,:,frame,1), [pos(1,1) - maxRadius, pos(1,2) - maxRadius, maxRadius * 2, maxRadius * 2]);
    
	% Subtract unified background
    background = imopen(rect, strel('disk', 15));
    picGray = imsubtract(rect, background);

    % Convert grayscale image to binary image
    picBW = bwareaopen(im2bw(picGray, graythresh(picGray)), handles.boundary);
	
    % Extract objects from image
    [objects, dummy] = bwlabel(picBW, 4);

    % Remove objects that are outside the min and max cell sizes
    stats = regionprops(objects, 'Area');
    idx = find([stats.Area] > handles.minCellSize & [stats.Area] < handles.maxCellSize);
    objectsFiltered = bwlabel(ismember(objects, idx), 4);

    % Extend cells by n picels
	s = strel('disk', handles.boundary);
    objectsFiltered = imdilate(objectsFiltered, s);
	
    % Save objectsFiltered
	objectsFiltered(objectsFiltered == 1) = max(handles.objectsFiltered(:)) + 1;
	handles.objectsFiltered(pos(1,2) - maxRadius:pos(1,2) + maxRadius, pos(1,1) - maxRadius:pos(1,1) + maxRadius) = max(uint16(objectsFiltered), handles.objectsFiltered(pos(1,2) - maxRadius:pos(1,2) + maxRadius, pos(1,1) - maxRadius:pos(1,1) + maxRadius));
    guidata(handles.output, handles);

	% Show identified cells in pseudo color
    picPseudo = label2rgb(handles.objectsFiltered, 'lines', 'k');
    imshow(picPseudo, 'Parent', handles.axCells);

	% Show image
	showMainImage(handles);
end

%% CALCULATE F
function btnCalculateF_Callback(hObject, eventdata, handles)
    if isempty(handles.imagingData.SamplingInterval)
        menuSetFrameInterval_Callback(handles.menuSetFrameInterval, eventdata, handles)
    end
    handles.imagingData.calculateF();
    updateGUI(handles);
    showPlot(handles);
end

%% CHANGE CHANNEL
% ---------------------------------------------------

function panelChannelSelection_SelectionChangeFcn(hObject, eventdata, handles)
    newValue = get(eventdata.NewValue);
	handles.selectedChannel = newValue.UserData;
    
	guidata(handles.output, handles);
	
	if length(handles.imagingData.SubtractBackgroundLevel) >= handles.selectedChannel
        set(handles.eCalcBackground, 'String', num2str(handles.imagingData.SubtractBackgroundLevel(handles.selectedChannel)));
    end
	
	showMainImage(handles);
	showPlot(handles);
end

%% CHANGE CHANNEL ARITHEMTIC
% ---------------------------------------------------

% --- Executes when selected object is changed in panelChannelArithmetic.
function panelChannelArithmetic_SelectionChangedFcn(hObject, eventdata, handles)
	showPlot(handles);
end

%% BACKGROUND SUBTRACTION
% ---------------------------------------------------

function panelSubtractBackground_SelectionChangeFcn(hObject, eventdata, handles)
    selectedSubtractBackground = get(get(handles.panelSubtractBackground, 'SelectedObject'), 'Tag');
    switch selectedSubtractBackground
		case 'rbAuto'
            handles.imagingData.SubtractBackgroundLevelMode = 'auto';
            handles.imagingData.autoSubtractBackgroundLevel();
			set(handles.eCalcBackground, 'String', num2str(handles.imagingData.SubtractBackgroundLevel(handles.selectedChannel)));
			set(handles.eCalcBackground, 'Enable', 'off');
		case 'rbManual'
            handles.imagingData.SubtractBackgroundLevelMode = 'manual';
			set(handles.eCalcBackground, 'Enable', 'on');
    end
    handles.imagingData.calculateDeltaFperF0();
end

function eCalcBackground_Callback(hObject, eventdata, handles)
    set(handles.panelSubtractBackground, 'SelectedObject', handles.rbManual);

    handles.imagingData.SubtractBackgroundLevel(handles.selectedChannel) = str2double(get(handles.eCalcBackground, 'String'));
    handles.imagingData.calculateDeltaFperF0();
end

function eF0RangeStart_Callback(hObject, eventdata, handles)
    value = str2double(get(hObject,'String'));
    if ~isempty(handles.imagingData.Time)
        value = round(value / handles.imagingData.SamplingInterval);
    end
    value = min(handles.imagingData.FrameNum, max(1, value));
    
    if handles.imagingData.F0Range(1) ~= value
        handles.imagingData.F0Range(1) = value;
    end
end

function eF0RangeEnd_Callback(hObject, eventdata, handles)
    value = str2double(get(hObject,'String'));
    if ~isempty(handles.imagingData.Time)
        value = round(value / handles.imagingData.SamplingInterval);
    end
    
    if handles.imagingData.F0Range(2) ~= value
        handles.imagingData.F0Range(2) = value;
    end
end


%% CHANGE SMOOTHING
% ---------------------------------------------------

function eSmooth_Callback(hObject, eventdata, handles)
    if handles.imagingData.Smooth ~= str2double(get(hObject,'String'))
        handles.imagingData.Smooth = str2double(get(hObject,'String'));
    end
    
    set(handles.sSmooth, 'Value', handles.imagingData.Smooth);
end

function sSmooth_Callback(hObject, eventdata, handles)
    if handles.imagingData.Smooth ~= round(get(hObject, 'Value'))
        handles.imagingData.Smooth = round(get(hObject, 'Value'));
    end
    set(handles.eSmooth, 'String', num2str(handles.imagingData.Smooth));
end

%% SAVE RESULTS
% ---------------------------------------------------

function tbSave_ClickedCallback(hObject, eventdata, handles)
    imagingData = handles.imagingData;
        
    [pathstr, fileName, ext] = fileparts(handles.imagingData.PicFileName);
    if ~isempty(handles.imagingData.MesImageIndex) && handles.imagingData.MesImageIndex > 0 && ~strcmp(ext, 'mat')
        dataFilename = strcat(fileName, ' F', num2str(handles.imagingData.MesImageIndex), '.mat');
    else
        dataFilename = strcat(fileName, '.mat');
    end
    if isfield(handles, 'pathname')
        pathname = handles.pathname;
    else
        pathname = '';
    end
    
    uisave({'imagingData'}, char(fullfile(pathname, char(dataFilename))));
end

%% ADDITIONAL GUIs
% --------------------------------------------------------------------
function tbTraceVaildation_ClickedCallback(hObject, eventdata, handles)
    if isempty(handles.imagingData.DeltaFperF0)
        return
    end
    
    FACellClassification('FluoAnalysis');
    
    guidata(handles.output, handles);
end

%% MENU FUNCTIONS
% ---------------------------------------------------

% Open file
function menuOpenFile_Callback(hObject, eventdata, handles)
    openExperiment_Callback([], [], handles);
end

% Open next image in MES
function menuOpenNext_Callback(hObject, eventdata, handles)
    tbOpenNext_ClickedCallback([], [], handles);
end

% Set frame interval
function menuSetFrameInterval_Callback(hObject, eventdata, handles)
    dlg_title = 'Set frame interval';
    prompt = {'Frame interval (s):'};
    num_lines = 1;
    defaultans = {'1.2'};
    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);
    interval = str2double(answer{1});
    
	handles.imagingData.Time = interval:interval:interval*handles.imagingData.FrameNum;
    showMainImage(handles);
end

% Add grid objects
function menuAddGridObjects_Callback(hObject, eventdata, handles)
    dlg_title = 'Add grid objects';
    prompt = {'Grid size:'};
    num_lines = 1;
    defaultans = {'32'};
    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);
    gridsize = str2double(answer{1});
    
	% Show identified cells in pseudo color
    objectsFiltered = uint16(zeros(size(handles.imagingData.RawImage, 1), size(handles.imagingData.RawImage, 2)));
    maxCol = ceil(size(objectsFiltered, 2) / gridsize);
    for i = 1:size(objectsFiltered, 1)
        for j = 1:size(objectsFiltered, 2)
            objectsFiltered(i, j) = ceil(j / gridsize) + (floor(i / gridsize) * maxCol);
        end
    end
    picPseudo = label2rgb(objectsFiltered, 'lines', 'k');
    imshow(picPseudo, 'Parent', handles.axCells);
	
    % Save objectsFiltered
	handles.imagingData.ROIs = objectsFiltered;
	handles.imagingData.ROIs2D = objectsFiltered;
    guidata(handles.output, handles); 
end

function menuCellValidation_Callback(hObject, eventdata, handles)
    if isempty(handles.imagingData.DeltaFperF0)
        return
    end
    
    FACellClassification('FluoAnalysis');
    
    guidata(handles.output, handles);
end

% Export data to variables
function menuExportData_Callback(hObject, eventdata, handles)
    dlg_title = 'Export data to variables';
    prompt = {'Variable name:'};
    num_lines = 1;
    defaultans = {'data'};
    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);
    varname = answer{1};
    assignin('base', varname, handles.imagingData);
end

% Create report of individual cell activity (Word file)
function menuCreateReport_Callback(hObject, eventdata, handles)
	handles.imagingData.reportCellData;
end

% Load objects from another file
function menuLoadObjects_Callback(hObject, eventdata, handles)
    [filename, pathname] = uigetfile({'*.*', 'Matlab files (*.mat)'}, 'Open result file', handles.pathname);
    if filename == 0
		return;
    end
    
    % Save objectsFiltered
    o = load(fullfile(pathname, filename));
    handles.imagingData.ROIs = o.imagingData.ROIs;
    handles.imagingData.ROIs2D = o.imagingData.ROIs2D;
    handles.imagingData.Neuron = o.imagingData.Neuron;
    handles.imagingData.Glia = o.imagingData.Glia;
    
    updateGUI(handles);

	% Show image
	showMainImage(handles);
end

% Load validation data from another file
function menuLoadValidation_Callback(hObject, eventdata, handles)
    [filename, pathname] = uigetfile({'*.*', 'Matlab files (*.mat)'}, 'Open result file', handles.pathname);
    if filename == 0
		return;
    end
    
    % Save validation data
    o = load(fullfile(pathname, filename), '-mat', 'validcell', 'neuron', 'glia');
    if max(handles.objectsFiltered) == length(o.validcell)
        handles.validcell = o.validcell;
        handles.neuron = o.neuron;
        handles.glia = o.glia;
        guidata(handles.output, handles);
    else
        msgbox('The number of cells are different in the two measurements');
    end
end

% Show frequency map
function menuShowFrequencyMap_Callback(hObject, eventdata, handles)
    if isfield(handles, 'objectsFiltered') && isfield(handles, 'peaks')
        activitymap = nan(size(handles.objectsFiltered));
        for i = 1:length(handles.peaks.frequency)
            if handles.validcell(i) == 1
                f = handles.peaks.frequency{i,1};
                [n, c] = hist(f, linspace(0,2,20));
                activitymap(handles.objectsFiltered == i) = mean(c(n == max(n)));
            end
        end
        figure('Name', 'Most frequent peak frequencies', 'NumberTitle', 'off');
        imagesc(activitymap);
        colorbar;
    end
end

% Show peak number map
function showPeakNumMap_Callback(hObject, eventdata, handles)
    if isfield(handles, 'objectsFiltered') && isfield(handles, 'peaks')
        activitymap = nan(size(handles.objectsFiltered));
        for i = 1:length(handles.peaks.location)
            if handles.validcell(i) == 1
                activitymap(handles.objectsFiltered == i) = size(handles.peaks.location{i,1}, 2);
            end
        end
        figure('Name', 'Peak number per sessions', 'NumberTitle', 'off');
        imagesc(activitymap);
        colorbar;
    end
end

% Open in Fiji
function menuOpenInFiji_Callback(hObject, eventdata, handles)
	Miji();
	
    for iCh = 1:handles.imagingData.ChannelNum
		MIJ.createImage(['Channel ' num2str(iCh)], mean(handles.imagingData.RawImage(:,:,:,iCh), 3), true);
    end
end

% Find active ROI
function menuFindActiveRoiByDeviation_Callback(hObject, eventdata, handles)
    handles.imagingData.findActiveROIs('deviation');
end

% --------------------------------------------------------------------
function menuFindActiveRoiByOscillation_Callback(hObject, eventdata, handles)
    handles.imagingData.findActiveROIs('oscillation');
end

% Move ROI
function menuMoveRoi_Callback(hObject, eventdata, handles)
    handles.imagingData.ROIs2D = FARoiMove(mean(handles.imagingData.RawImage(:,:,:,1), 3), handles.imagingData.RefImage, handles.imagingData.ROIs2D);
    if handles.imagingData.IsFrameScan
        handles.imagingData.ROIs = handles.imagingData.ROIs2D;
    end
end

% Merge crossed ROIs
function menuMergeCrossedROIs_Callback(hObject, eventdata, handles)
    if handles.imagingData.IsLineScan
        handles.imagingData.ROIs = ceil(handles.imagingData.ROIs / 2);
        updateGUI(handles);
    end
end

%% ITEM CREATE FUNCTIONS
% ---------------------------------------------------

function eBackgroundLevel_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sBackgroundLevel_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function eMinCellSize_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sMinCellSize_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function eMaxCellSize_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sMaxCellSize_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

function sExperiment_CreateFcn(hObject, eventdata, handles)
	if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
	end
end

function cboRef_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sBoundary_CreateFcn(hObject, eventdata, handles)
	if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor',[.9 .9 .9]);
	end
end

function eMaxStart_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eMaxEnd_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eRefStart_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eRefEnd_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sSmooth_CreateFcn(hObject, eventdata, handles)
	if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor',[.9 .9 .9]);
	end
end

function eSmooth_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
end

function eCalcBackground_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
end

function eLineScanRepeat_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eMinLineSize_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eBoundary_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eF0RangeStart_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eF0RangeEnd_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function menuFindActiveRoi_Callback(hObject, eventdata, handles)
end

function eRollingBallRadius_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function sRollingBallRadius_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
end

% --- Executes during object creation, after setting all properties.
function cboRefMethod_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
