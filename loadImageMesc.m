function out = loadImageMesc(path, index)
% Converts an image from a .mes file into a standard format
%
% input: metadata of the current image	
% output: structure containing the converted image in sizeY * sizeX * frameNum * channelNum
% format and different image properties
    disp('Loading image...');
    tic;
    progressbar('Loading image');

    file = H5F.open(path);
    group = H5G.open(file,['/MSession_0/MUnit_' num2str(index - 1)]);

	attr_id = H5A.open(group, 'XDim');
    sizeX = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'YDim');
	sizeY = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'ZDim');
	out.numFrames = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'XAxisConversionConversionLinearOffset');
	originX = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'YAxisConversionConversionLinearOffset');
	originY = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'XAxisConversionConversionLinearScale');
	stepX = H5A.read(attr_id);
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'YAxisConversionConversionLinearScale');
	stepY = H5A.read(attr_id);
    H5A.close(attr_id);
% 		channels = {char(h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_0_Name')) char(h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_1_Name'))};
	out.channels = {'pmtUG' 'pmtUR'};
	out.numChannel = H5G.get_info(group).nlinks; % length(info.Groups.Groups(index).Datasets); CHeck whether it gives the correct result

	[userview systemview] = memory;
    if sizeX * sizeY * out.numFrames * out.numChannel * 2 < systemview.PhysicalMemory.Available
        out.picMulti(sizeY, sizeX, out.numFrames, out.numChannel) = uint16(0); % faster way to initialize large uint16 matrix
        for iCh = 1:out.numChannel
% 			for iT = 1:numFrames
% 				picMulti(:,:,iT,iCh) = flipud(readMEScMovieFrame(fullfile(handles.pathname, handles.filename),0,double(index - 1),double(iCh - 1),double(iT - 1)));
% 				picMulti(:,:,:,iCh) = h5read(fullfile(handles.pathname, handles.filename),[info.Groups.Groups(index).Name '/Channel_' num2str(iCh - 1)]);
% 			out.picMulti(:,:,:,iCh) = flipdim(65535 - permute(h5read(path,[info.Groups.Groups(index).Name '/Channel_' num2str(iCh - 1)]), [2 1 3]), 1);
%             out.picMulti(:,:,:,iCh) = 65535 - flipud(permute(h5read(path,[info.Groups.Groups(index).Name '/Channel_' num2str(iCh - 1)]), [2 1 3]));
            dset = H5D.open(file, ['/MSession_0/MUnit_' num2str(index - 1) '/Channel_' num2str(iCh - 1)]);
            out.picMulti(:,:,:,iCh) = 65535 - flipud(permute(H5D.read(dset), [2 1 3]));

            % 				progressbar(((iCh - 1) * numFrames + iT) / (numFrames * numChannel));
            progressbar(iCh / out.numChannel);
% 			end
        end
        out.reductionFactor = 1;
    else
        out.reductionFactor = ceil(sizeX * sizeY * out.numFrames * out.numChannel * 2 / systemview.PhysicalMemory.Available) * 2;
        out.picMulti(sizeY, sizeX, floor(out.numFrames / out.reductionFactor), out.numChannel) = uint16(0); % faster way to initialize large uint16 matrix
        file = H5F.open(path,'H5F_ACC_RDONLY','H5P_DEFAULT');
        for iCh = 1:out.numChannel
            dset = H5D.open(file, ['/MSession_0/MUnit_' num2str(index - 1) '/Channel_' num2str(iCh - 1)]);
            space = H5D.get_space(dset);
            block = [double(sizeY) double(sizeX) double(out.reductionFactor)];
            mem_space = H5S.create_simple(3, fliplr(block), []);
            for iFrame = 1:size(out.picMulti, 3)
                start = [0 0 double((iFrame - 1) * out.reductionFactor)];
                if out.numFrames < start(3) + out.reductionFactor
                    block = [double(sizeY) double(sizeX) double(out.numFrames - start(3))];
                    mem_space = H5S.create_simple(3, fliplr(block), []);
                end
                H5S.select_hyperslab(space, 'H5S_SELECT_SET', fliplr(start), [], [], fliplr(block));
                out.picMulti(:,:,iFrame,iCh) = mean(65535 - flipud(permute(H5D.read(dset,'H5ML_DEFAULT',mem_space,space,'H5P_DEFAULT'), [2 1 3])), 3);
%                 out.picMulti(:,:,iFrame,iCh) = mean(65535 - permute(h5read(path, [info.Groups.Groups(index).Name '/Channel_' num2str(iCh - 1)], [1 1 double((iFrame - 1) * out.reductionFactor + 1)], [double(sizeY) double(sizeX) double(iFrame * out.reductionFactor)]), [2 1 3]), 3);
%                 progressbar(((iCh - 1) * size(out.picMulti, 3) + iFrame) / size(out.picMulti, 3) / out.numChannel);
%                 waitbar(((iCh - 1) * size(out.picMulti, 3) + iFrame) / size(out.picMulti, 3) / out.numChannel);
            end
        end
		H5D.close(dset);
		H5S.close(space);
		H5S.close(mem_space);
    end
    progressbar(1);

    metadata(1).Type = 'FF';
	attr_id = H5A.open(group, 'MeasurementDatePosix');
	MeasurementDatePosix = double(H5A.read(attr_id));
    H5A.close(attr_id);
	attr_id = H5A.open(group, 'MeasurementDateNanoSecs');
	MeasurementDateNanoSecs = double(H5A.read(attr_id));
    H5A.close(attr_id);
    metadata(1).MeasurementDate = datestr(datenum(1970, 1, 1, 0, 0, MeasurementDatePosix) + MeasurementDateNanoSecs / 1000000000 / 60 / 60 / 24, 'yyyy-mm-dd HH:MM:SS.FFF');
	metadata(1).WidthOrigin = originX;
	metadata(1).Width = sizeX;
	metadata(1).WidthStep = stepX;
	metadata(1).HeightOrigin = originY;
	metadata(1).Height = sizeX;
	metadata(1).HeightStep = stepY;
	metadata(1).HeightDirection = 'normal';
	attr_id = H5A.open(group, 'ZAxisConversionConversionLinearOffset');
	ZAxisConversionConversionLinearOffset = double(H5A.read(attr_id));
    H5A.close(attr_id);
	metadata(1).FoldedFrameInfo.firstFrameStartTime = ZAxisConversionConversionLinearOffset;
	attr_id = H5A.open(group, 'ZAxisConversionConversionLinearScale');
	ZAxisConversionConversionLinearScale = double(H5A.read(attr_id));
    H5A.close(attr_id);
	metadata(1).FoldedFrameInfo.frameTimeLength = ZAxisConversionConversionLinearScale;
	metadata(2) = metadata(1);
	metadata(3) = metadata(1);
% 		metadata(1).LUTstruct.lower = h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_0_LUT_RangeLowerBound');
% 		metadata(1).LUTstruct.upper = h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_0_LUT_RangeUpperBound');
% 		metadata(2).LUTstruct.lower = h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_1_LUT_RangeLowerBound');
% 		metadata(2).LUTstruct.upper = h5readatt(fullfile(handles.pathname, handles.filename), info.Groups.Groups(index).Name, 'Channel_1_LUT_RangeUpperBound');
	lim = stretchlim(out.picMulti(:,:,1,1)) * 65536;
	metadata(1).LUTstruct.lower = lim(1);
	metadata(1).LUTstruct.upper = lim(2);
    out.lutLower(1) = lim(1);
    out.lutUpper(1) = lim(2);
	lim = stretchlim(out.picMulti(:,:,1,2)) * 65536;
	metadata(2).LUTstruct.lower = lim(1);
	metadata(2).LUTstruct.upper = lim(2);
    out.lutLower(2) = lim(1);
    out.lutUpper(2) = lim(2);
	
	out.time = double(metadata(1).FoldedFrameInfo.firstFrameStartTime):double(metadata(1).FoldedFrameInfo.frameTimeLength):double(metadata(1).FoldedFrameInfo.firstFrameStartTime) + double(out.numFrames - 1) * double(metadata(1).FoldedFrameInfo.frameTimeLength);
	out.time = out.time ./ 1000;

	out.metadata = metadata;
    
    H5G.close(group);
    H5F.close(file);
    
    fprintf('Loading done in %.2f seconds. \n', toc');
end