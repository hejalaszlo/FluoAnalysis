function out = loadImageMes(metadata, path)
% Converts an image from a .mes file into a standard format
%
% input: metadata of the current image	
% output: structure containing the converted image in sizeY * sizeX * frameNum * channelNum
% format and different image properties
	
	if strcmp(metadata(1).Type, 'FF') == 1 % FoldedFrame
		firstFramePos = metadata(1).FoldedFrameInfo.firstFramePos;
		sizeY = metadata(1).FoldedFrameInfo.numFrameLines;
		load(path, '-mat', metadata(1).IMAGE);
		sizeX = size(eval(metadata(1).IMAGE), 1);
		% Number of channels
		channels = metadata(1).FoldedFrameInfo.measureChannels;
		out.numChannel = size(channels, 1);
		% Number of frames
		out.frameNum = metadata(1).FoldedFrameInfo.numFrames;
		% Timing
		out.time = metadata(1).FoldedFrameInfo.firstFrameStartTime:metadata(1).FoldedFrameInfo.frameTimeLength:metadata(1).FoldedFrameInfo.firstFrameStartTime + (out.frameNum - 1) * metadata(1).FoldedFrameInfo.frameTimeLength;
		out.time = out.time ./ 1000;
		% Add ROIs
		rois = metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).line2RoI;
		rois = ceil(rois ./ metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).scanspeed);
		out.objectsFiltered = zeros(sizeY, sizeX, 'uint16');
		for iRoi = 1:size(rois, 2)
			roi = rois(:,iRoi);
			if roi(1) == roi(2) % Simple point
				out.objectsFiltered(:,(roi(1)-1)*sizeY+1:roi(1)*sizeY) = iRoi;
			else % Line
				out.objectsFiltered(:,roi(1):roi(2)) = iRoi;
			end
		end
	elseif strcmp(metadata(1).Type, 'Line2') == 1 % Line scan
		firstFramePos = 1;
		sizeY = 1;
		sizeX = metadata(1).DIMS(1);
		% Number of channels
		out.numChannel = sum(cell2mat(arrayfun(@(x) isequal(x.DIMS, metadata(1).DIMS), metadata, 'UniformOutput', false)));
		% Number of frames
		out.frameNum = metadata(1).DIMS(2);
		% Timing
		out.time = metadata(1).HeightOrigin:metadata(1).HeightStep:metadata(1).HeightOrigin + (out.frameNum - 1) * metadata(1).HeightStep;
		out.time = out.time ./ 1000;
		% Add ROIs
		rois = metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).line2RoI;
		rois = ceil(rois ./ metadata(1).info_Linfo.lines(metadata(1).info_Linfo.current).scanspeed);
		out.objectsFiltered = zeros(sizeY, sizeX, 'uint16');
		for iRoi = 1:size(rois, 2)
			roi = rois(:,iRoi);
			out.objectsFiltered(:,roi(1):min(roi(2), sizeX)) = iRoi;
		end
	end           

	% Load image
	out.picMulti = zeros(sizeY, sizeX, out.frameNum, out.numChannel, 'uint16');
	for iCh = 1:out.numChannel
		load(path, '-mat', metadata(iCh).IMAGE);
		imageVar = uint16(eval(metadata(iCh).IMAGE));
		clear(metadata(iCh).IMAGE);
		lineNum = firstFramePos;
		for iT = 1:out.frameNum
			out.picMulti(:,:,iT,iCh) = rot90(imageVar(:,lineNum:lineNum+sizeY-1));

			progressbar(((iCh - 1) * out.frameNum + iT) / (out.frameNum * out.numChannel));
			lineNum = lineNum + sizeY;
		end

		% LUT
		out.lutLower(iCh) = metadata(iCh).LUTstruct.lower;
		out.lutUpper(iCh) = metadata(iCh).LUTstruct.upper;
	end
end