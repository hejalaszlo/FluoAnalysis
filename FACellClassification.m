function varargout = FACellClassification(varargin)
    % FACELLCLASSIFICATION M-file for FACellClassification.fig
    %      FACELLCLASSIFICATION, by itself, creates a new FACELLCLASSIFICATION or raises the existing
    %      singleton*.
    %
    %      H = FACELLCLASSIFICATION returns the handle to a new FACELLCLASSIFICATION or the handle to
    %      the existing singleton*.
    %
    %      FACELLCLASSIFICATION('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in FACELLCLASSIFICATION.M with the given input arguments.
    %
    %      FACELLCLASSIFICATION('Property','Value',...) creates a new FACELLCLASSIFICATION or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before FACellClassification_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to FACellClassification_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help FACellClassification

    % Last Modified by GUIDE v2.5 18-Jul-2024 21:35:25

    warning off;

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @FACellClassification_OpeningFcn, ...
                       'gui_OutputFcn',  @FACellClassification_OutputFcn, ...
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


% --- Executes just before FACellClassification is made visible.
function FACellClassification_OpeningFcn(hObject, eventdata, handles, varargin)
    % Choose default command line output for FACellClassification
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
        
    % Variables
    handles.matpathname = '';
    handles.selectedCell = 1;
    
    linkaxes([handles.axEphys handles.axCellSelected], 'x');
    
	% Load previous pathname
	up = userpath;
    if exist(fullfile(up(1:end-1), 'heja_config.mat'), 'file') == 2
		load(fullfile(up(1:end-1), 'heja_config.mat'));
    end
    if exist('FACellClassification', 'var') && ~isempty(FACellClassification.pathname)
		handles.matpathname = FACellClassification.pathname;
    end
    
    set(gcf, 'Name', 'Cell classification');

    setupGUI(handles);
    handles = guidata(handles.output);

    % Get data from FluoAnalysis if FACellClassification was opened from that
    h = findobj('Tag', 'FluoAnalysis');
    if ~isempty(h) && nargin > 3 && strcmp(varargin{1}, 'FluoAnalysis') == 1
        FluoAnalysisData = guidata(h);

        % Save variable to handles
        handles.imagingData = FluoAnalysisData.imagingData;
        
        % Change window name
        set(gcf, 'Name', ['Cell classification - ', fullfile(handles.imagingData.FilePath, handles.imagingData.PicFileName)]);
        
        set(handles.tbOpen, 'Enable', 'off');
      
        updateEphys(handles);
        
        % G/R ratio
        if sum(isnan(handles.imagingData.ValidCell)) == handles.imagingData.CellNum
            handles.imagingData.autoClassifyCells();
		end

		set(handles.eWaveletFreq2, 'String', handles.imagingData.SamplingFrequency / 2);

        handles.saveEnabled = false;

        % Save handles
        guidata(handles.output, handles);

        updateGUI(handles);
    else
        handles.saveEnabled = true;
        guidata(handles.output, handles);
    end
    
    % UIWAIT makes FACellClassification wait for user response (see UIRESUME)
%     uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = FACellClassification_OutputFcn(hObject, eventdata, handles)
    % Get default command line output from handles structure
    varargout{1} = handles.output;

    warning on;
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    h = findobj('Tag', 'FluoAnalysis');
    if ~isempty(h) && handles.saveEnabled == false
        FluoAnalysisData = guidata(h);
        FluoAnalysisData.imagingData = handles.imagingData;
        
        cellnum = num2str(max(handles.imagingData.ROIs(:)));
        neuronnum = num2str(nansum(handles.imagingData.Neuron));
        glianum = num2str(nansum(handles.imagingData.Glia));
        invalidcellnum = num2str(sum(handles.imagingData.ValidCell == 0));
        set(FluoAnalysisData.txtCellNumber, 'String', [cellnum ' (' neuronnum ' neuron, ' glianum ' glia, ' invalidcellnum ' non-cell)']);    
    end
    delete(hObject);
    
%     if isequal(get(hObject, 'waitstatus'), 'waiting')
%         % The GUI is still in UIWAIT, use UIRESUME
%         uiresume(hObject);
%     else
%         % The GUI is no longer waiting, just close it
%         delete(hObject);
%     end
end

function setupGUI(handles)
    xlabel(handles.axEphys, 'Time (sec)');
    ylabel(handles.axEphys, 'mV');
    set(handles.axCellSelected, 'xtick', []);
    
    handles.iExperiment = imshow(zeros(300), 'Parent', handles.axExperiment);
    handles.iCh1 = imshow(zeros(150), 'Parent', handles.axCh1);
    handles.iCh2 = imshow(zeros(150), 'Parent', handles.axCh2);
    
    colormap(handles.axExperiment, 'gray');

	set(handles.eFilterFreq1, 'String', '');
	set(handles.eFilterFreq2, 'String', '300');
	set(handles.eWaveletFreq1, 'String', '0.1');
	set(handles.eWaveletFreq2, 'String', '20');

    guidata(handles.output, handles);
end

function updateGUI(handles)
    % Show selected cell
	if ~isempty(handles.imagingData.MesMetadata) && handles.imagingData.IsLineScan % mes file, we need to convert the ROIs to real 2D coordinates
        if isempty(handles.imagingData.ROIs2D) % 1D ROIs
            obj = find(handles.imagingData.ROIs == handles.selectedCell) * handles.imagingData.MesMetadata(1).info_Linfo.lines(handles.imagingData.MesMetadata(1).info_Linfo.current).scanspeed;
            l = handles.imagingData.MesMetadata(1).info_Linfo.lines(handles.imagingData.MesMetadata(1).info_Linfo.current).line2(:,obj);
            if isempty(l)
                return;
            end
            l(1,:) = round((l(1,:) - handles.imagingData.MesMetadata(3).WidthOrigin) / handles.imagingData.MesMetadata(3).WidthStep);
            l(2,:) = handles.imagingData.MesMetadata(3).Height - round((l(2,:) - handles.imagingData.MesMetadata(3).HeightOrigin) / handles.imagingData.MesMetadata(3).HeightStep);
            rect = [min(l(1,:))-20 min(l(2,:))-20 max(l(1,:))-min(l(1,:))+40 max(l(2,:))-min(l(2,:))+40];
            objectPerim = false(size(handles.imagingData.RefImage(:,:,1)));
            objectPerim(max(1, rect(2)):rect(2)+rect(4)-1, max(1, rect(1)):rect(1)+rect(3)-1) = 1;
            objectPerim = bwperim(objectPerim);
        else % 2D ROIs
            objectStats = regionprops(handles.imagingData.ROIs2D, 'Centroid');
            top = max(0, objectStats(handles.selectedCell).Centroid(1) - 20/handles.imagingData.PixelWidth);
            left = max(0, objectStats(handles.selectedCell).Centroid(2) - 20/handles.imagingData.PixelHeight);
            width = 40/handles.imagingData.PixelHeight;
            rect = [top left width width];
            objectPerim = logical(bwperim(handles.imagingData.ROIs2D == handles.selectedCell));
        end
	else % tiff files
		objectStats = regionprops(handles.imagingData.ROIs, 'Centroid');
        top = max(0, objectStats(handles.selectedCell).Centroid(1) - 20);
        left = max(0, objectStats(handles.selectedCell).Centroid(2) - 20);
        width = 40;
        rect = [top left width width];
        objectPerim = logical(bwperim(handles.imagingData.ROIs == handles.selectedCell));
	end
    
    % Main pic
	if ndims(handles.imagingData.RefImage) <= 3
	    rgb = imoverlay(handles.imagingData.RefImage, objectPerim, [1 1 1]);
	else
	    rgb = imoverlay(handles.imagingData.RefImage(:,:,1,1), objectPerim, [1 1 1]);
	end
    set(handles.iExperiment, 'CData', imresize(rgb, [300 300]));

	% Channel green
    if ndims(handles.imagingData.RefImage) <= 3        
		croppedImage = imcrop(handles.imagingData.RefImage(:,:,2), rect);
	else
	    croppedImage = imcrop(handles.imagingData.RefImage(:,:,:,1), rect);
    end
    set(handles.iCh1, 'CData', imresize(mat2gray(croppedImage), [150 150]));
    if handles.imagingData.IsLineScan
        o1 = imoverlay(mat2gray(croppedImage), imcrop(objectPerim, rect), [1 1 0]); % ROI contour
        
        objectPerim = false(size(objectPerim));
        l2 = handles.imagingData.MesMetadata(1).info_Linfo.lines(handles.imagingData.MesMetadata(1).info_Linfo.current).line2;
		l2(1,:) = round((l2(1,:) - handles.imagingData.MesMetadata(3).WidthOrigin) / handles.imagingData.MesMetadata(3).WidthStep);
		l2(2,:) = handles.imagingData.MesMetadata(3).Height - round((l2(2,:) - handles.imagingData.MesMetadata(3).HeightOrigin) / handles.imagingData.MesMetadata(3).HeightStep);
        x = l2(1,:);
        y = l2(2,:);
        f = find(x>0 & x<=size(handles.imagingData.RefImage(:,:,1), 2) & y>0 & y<=size(handles.imagingData.RefImage(:,:,1), 1));
        x = x(f);
        y = y(f);
        objectPerim(sub2ind(size(handles.imagingData.RefImage(:,:,1)), y, x)) = 1;
        set(handles.iCh1, 'CData', imresize(imoverlay(o1, imcrop(objectPerim, rect), [1 0 0]), [150 150]));
    else
%         set(handles.iCh1, 'CData', imresize(mat2gray(croppedImage), [150 150]));
        set(handles.iCh1, 'CData', imresize(imoverlay(mat2gray(croppedImage), imcrop(objectPerim, rect), [1 1 0]), [150 150]));
    end
    
	% Channel red
    if size(handles.imagingData.RefImage, 3) > 1
        if ndims(handles.imagingData.RefImage) <= 3
			croppedImage2 = imcrop(handles.imagingData.RefImage(:,:,1), rect);
        else
			croppedImage2 = imcrop(handles.imagingData.RefImage(:,:,:,size(handles.imagingData.FrameNum, 1) / handles.imagingData.ChannelNum + 1), rect);
        end
        set(handles.iCh2, 'CData', imresize(mat2gray(croppedImage2), [150 150]));
    end

    set(handles.txtNeuron, 'String', nansum(handles.imagingData.Neuron));
    set(handles.txtGlia, 'String', nansum(handles.imagingData.Glia));
    set(handles.txtNotCell, 'String', sum(handles.imagingData.ValidCell == 0));
    set(handles.txtNotClassified, 'String', sum(isnan(handles.imagingData.ValidCell)));
    
    % Cell type
    if isnan(handles.imagingData.ValidCell(handles.selectedCell))
       set(handles.txtCellType, 'String', 'Not classified');
	else
       set(handles.txtCellType, 'String', handles.imagingData.CellType(handles.selectedCell));
    end
    
    % G/R ratio
    if ~isempty(handles.imagingData.GRRatio)
        ratio = handles.imagingData.GRRatio;
        set(handles.txtChRatio, 'String', num2str(ratio(handles.selectedCell)));
        cla(handles.axChRatio);
        axes(handles.axChRatio);
        plot(find(isnan(handles.imagingData.ValidCell)), ratio(isnan(handles.imagingData.ValidCell)), 'o', 'Color', [0.8 0.8 0.8], 'MarkerSize', 4);
        hold(handles.axChRatio, 'on');
        plot(find(handles.imagingData.ValidCell == 0), ratio(handles.imagingData.ValidCell == 0), 'ko', 'MarkerSize', 4);
        plot(find(handles.imagingData.Glia == 1), ratio(handles.imagingData.Glia == 1), 'ro');
        plot(find(handles.imagingData.Neuron == 1), ratio(handles.imagingData.Neuron == 1), 'o', 'Color', [0 0.7 0]);
        plot(handles.selectedCell,ratio(handles.selectedCell), 'b.', 'MarkerSize', 25);
        hold(handles.axChRatio, 'off');
        set(handles.axChRatio, 'XLim', [0 handles.imagingData.CellNum]);
        set(handles.axChRatio, 'YLim', [0 10]);
        set(handles.axChRatio, 'XTick', []);
        
        axes(handles.axChRatioHist);
        hist(handles.imagingData.GRRatio(handles.imagingData.GRRatio <= 10), handles.imagingData.CellNum);
	end

    % Plot selected trace
	xlim = get(handles.axCellSelected, 'XLim');
	axes(handles.axCellSelected);
	if strcmp(get(get(handles.rbgSelectedCellPlotType, 'SelectedObject'), 'String'), 'dF/F0 trace')
		% Plot dF/F0 trace
		set(handles.axCellSelected, 'ColorOrder', [0 0.7 0; 1 0 0], 'NextPlot', 'replacechildren');
		plot(handles.axCellSelected, handles.imagingData.Time, squeeze(handles.imagingData.DeltaFperF0(:,handles.selectedCell,:)));
% 	    plot(handles.axCellSelected, handles.imagingData.Time, squeeze(handles.imagingData.DeltaFperF0Smoothed(:,handles.selectedCell,:)));
% 	    plot(handles.axCellSelected, handles.imagingData.Time, squeeze(handles.imagingData.DeltaGperR(:,handles.selectedCell,:)));
		axis 'auto y';
        ylabel(handles.axCellSelected, '\DeltaF/F_0');
		set(get(handles.axCellSelected, 'ylabel'), 'rotation', 90);
	else
		% Plot wavelet
        fmin = str2double(get(handles.eWaveletFreq1, 'String'));
        fmax = str2double(get(handles.eWaveletFreq2, 'String'));
		wavelettype = strcat("cmor1-", num2str(round(fmin+fmax)/2));
		wavelettype = 'cmor1-2';
		dt = handles.imagingData.SamplingInterval;
		minscale = centfrq(wavelettype)/(fmin*dt);
		maxscale = centfrq(wavelettype)/(fmax*dt);
		scales = logspace(log10(minscale), log10(maxscale), 50);
		WaveletFrequency = scal2frq(scales, wavelettype, dt);

		data = handles.imagingData.DeltaFperF0(:,handles.selectedCell,1);
% 		data = handles.imagingData.DeltaFperF0Smoothed(:,handles.selectedCell,1);
% 		data = handles.imagingData.DeltaGperR(:,handles.selectedCell);
		WaveletCfs = cwt(data, scales, wavelettype);
		WaveletTime = dt:dt:size(data,1)*dt;
		pcolor(handles.axCellSelected, WaveletTime, WaveletFrequency, abs(WaveletCfs));
		ylim([fmin fmax]);
% 		colormap jet;
		shading interp;
		ylabel('Frequency (Hz)');
	end

    % Set xlim
    if sum(xlim == [0 1]) == 2
        xlim = [min(handles.imagingData.Time) max(handles.imagingData.Time)];
    end
    set(handles.axCellSelected, 'XLim', xlim);
    
    % Cell names
    if ~isempty(handles.imagingData.CellNames)
        set(handles.lbCellNames, 'String', handles.imagingData.CellNames);
        set(handles.lbCellNames, 'Value', handles.selectedCell);
	end
end

function updateEphys(handles)
    if ~isempty(handles.imagingData.EphysTime)
		% if strcmp(get(get(handles.rbgSelectedCellPlotType, 'SelectedObject'), 'String'), 'dF/F0 trace')
		if true
			dt = handles.imagingData.EphysTime(2) - handles.imagingData.EphysTime(1);
			freqLower = str2double(get(handles.eFilterFreq1, 'String'));
			freqUpper = str2double(get(handles.eFilterFreq2, 'String'));
			if isnan(freqLower) % Low-pass filter
				[b,a] = butter(4, freqUpper*2*dt);
			else % Band-pass filter
				[b,a] = butter(4, [freqLower*2*dt freqUpper*2*dt]);
			end
			filteredSig = filter(b,a,handles.imagingData.Ephys);
			plot(handles.axEphys, handles.imagingData.EphysTime, filteredSig);
		else
			wavelettype = 'cmor1-2';
			dt = (handles.imagingData.EphysTime(2) - handles.imagingData.EphysTime(1)) * 10;
        	fmin = str2double(get(handles.eWaveletFreq1, 'String'));
			minscale = centfrq(wavelettype)/(fmin*dt);
        	fmax = str2double(get(handles.eWaveletFreq2, 'String'));
			maxscale = centfrq(wavelettype)/(fmax*dt);
			scales = logspace(log10(minscale), log10(maxscale), 20);
			WaveletFrequency = scal2frq(scales, wavelettype, dt);
	
			% [b,a] = butter(4, [fmin*2*dt fmax*2*dt]);
			% data = filter(b,a,handles.imagingData.Ephys(1:10:end));
			data = handles.imagingData.Ephys(1:10:end);
			WaveletCfs = cwt(data, scales, wavelettype);
			WaveletTime = dt:dt:size(data,1)*dt;
			pcolor(handles.axEphys, WaveletTime, WaveletFrequency, abs(WaveletCfs));
			ylim([fmin fmax]);
	% 		colormap jet;
			shading interp;
			ylabel('Hz');
		end
    end
end

% --- Executes on button press in btnOpenFile.
% TODO: load PixelRegion only (see imread doc)
function openExperiment_Callback(hObject, eventdata, handles)
    % Open file
    if handles.matpathname == 0
        handles.matpathname = '';
    end
        
    [matfilename, matpathname] = uigetfile({'*.mat', 'Matlab files (*.mat)'}, 'Open result file', handles.matpathname);
   
    % Save variable to handles
    handles.matpathname = matpathname;
    handles.matfilename = matfilename;
    
	% Save path
	up = userpath;
	load(fullfile(up, 'heja_config.mat'));
	FACellClassification.pathname = matpathname;
	save(fullfile(up, 'heja_config.mat'), 'FACellClassification', '-append');

    % Change window name
	set(gcf, 'Name', ['FA Cell Classification - ', matfilename]);

    % Load result .mat file
    handles.imagingData = ImagingData;    
    handles.imagingData.loadImage(fullfile(matpathname, matfilename));
    
    updateEphys(handles);
	
    % Property listeners
%     addlistener(handles.imagingData, 'Neuron', 'PostSet', @(o,e) updateGUI(handles));
%     addlistener(handles.imagingData, 'Glia', 'PostSet', @(o,e) updateGUI(handles));

    % Reset selectedCell
    handles.selectedCell = 1;
    
    % G/R ratio
    if sum(isnan(handles.imagingData.ValidCell)) == handles.imagingData.CellNum
        handles.imagingData.autoClassifyCells();
    end
    guidata(handles.output, handles);
    
    % Go to the first cell
    gotoNextCell(handles);
end

% --- Executes on button press in btnValidateNeuron.
function btnValidateNeuron_Callback(hObject, eventdata, handles)
    handles.imagingData.Neuron(handles.selectedCell) = 1;
    handles.imagingData.Glia(handles.selectedCell) = 0;
    
    gotoNextCell(handles);
end

% --- Executes on button press in btnValidateGlia.
function btnValidateGlia_Callback(hObject, eventdata, handles)
    handles.imagingData.Neuron(handles.selectedCell) = 0;
    handles.imagingData.Glia(handles.selectedCell) = 1;
    
    gotoNextCell(handles);
end

% --- Executes on button press in btnValidateNotCell.
function btnValidateNotCell_Callback(hObject, eventdata, handles)
    handles.imagingData.Neuron(handles.selectedCell) = 0;
    handles.imagingData.Glia(handles.selectedCell) = 0;
        
    gotoNextCell(handles);
end

% --- Executes on key release with focus on figure1 or any of its controls.
function figure1_WindowKeyReleaseFcn(hObject, eventdata, handles)
    switch eventdata.Key
        case 'g'
           btnValidateGlia_Callback(handles.btnValidateGlia, [], handles);
        case 'n'
           btnValidateNeuron_Callback(handles.btnValidateNeuron, [], handles);
        case 'i'
           btnValidateNotCell_Callback(handles.btnValidateNotCell, [], handles);
    end
end

% --- Executes on selection change in lbCellNames.
function lbCellNames_Callback(hObject, eventdata, handles)
    handles.selectedCell = get(hObject,'Value');
    guidata(handles.output, handles);
    updateGUI(handles);
end

function gotoNextCell(handles)
    if handles.selectedCell < handles.imagingData.CellNum
        handles.selectedCell = handles.selectedCell + 1;
        guidata(handles.output, handles);
        updateGUI(handles);
    end
%     
%     if handles.selectedCell < size(handles.deltaFperF0, 2)
%         set(handles.btnNextCell, 'Enable', 'on');
%     else
%         set(handles.btnNextCell, 'Enable', 'off');
%     end
%    
%     if handles.selectedCell > 1
%         set(handles.btnPreviousCell, 'Enable', 'on');
%     else
%         set(handles.btnPreviousCell, 'Enable', 'off');
%     end
%    
    saveFile(handles);
end

% Save .mat file
function saveFile(handles)
    if isfield(handles, 'matfilename') && handles.saveEnabled
        imagingData = handles.imagingData;

        save(fullfile(handles.matpathname, handles.matfilename), 'imagingData');
    end
end

% --- Executes on button press in btnAutoClassifyCells.
function btnAutoClassifyCells_Callback(hObject, eventdata, handles)
    handles.imagingData.autoClassifyCells();
    updateGUI(handles);
end

% --- Executes on button press in btnFilter.
function btnFilter_Callback(hObject, eventdata, handles)
    updateEphys(handles);
end

function btnLimitWavelet_Callback(hObject, eventdata, handles)
    updateGUI(handles);
end

% --- Executes when selected object is changed in rbgSelectedCellPlotType.
function rbgSelectedCellPlotType_SelectionChangedFcn(hObject, eventdata, handles)
    updateGUI(handles);
end

% --------------------------------------------------------------------
function tbZoomIn_ClickedCallback(hObject, eventdata, handles)
    zoom;
end

% --------------------------------------------------------------------
function tbZoomOut_ClickedCallback(hObject, eventdata, handles)
    zoom out;
end

% --------------------------------------------------------------------
function tbPan_ClickedCallback(hObject, eventdata, handles)
    pan
end

function lbCellNames_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eFilterFreq1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eFilterFreq2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function eWaveletFreq1_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    	set(hObject,'BackgroundColor','white');
	end
end

function eWaveletFreq2_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    	set(hObject,'BackgroundColor','white');
	end
end

function eFilterFreq1_Callback(hObject, eventdata, handles)
end

function eFilterFreq2_Callback(hObject, eventdata, handles)
end

function eWaveletFreq1_Callback(hObject, eventdata, handles)
end

function eWaveletFreq2_Callback(hObject, eventdata, handles)
end
