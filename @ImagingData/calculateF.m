function calculateF(this)
    if isempty(this.RawImage) || isempty(this.ROIs)
        warning('ImagingData calculateF: not all required properties set');
        return
    end

    if this.Updating
        warning('ImagingData calculateF: update under progress, skipping calculation');
        return
    end
            
    if this.ReductionFactor > 1
        if ~strcmp(questdlg('Processing may last a long time. Do you want to process anyway?', 'Long processing time', 'Yes', 'No', 'No'), 'Yes')
            return
        end
    end
    
    disp('Calculating ROI intensities...');
    tic;
    
    progressbar('Calculating ROI intensities...');
    
    % Calculate F
    f = zeros(this.FrameNum, max(this.ROIs(:)), this.ChannelNum);
    if ~isempty(this.MesMetadata) && strcmp(this.MesMetadata(1).Type, 'Line2') == 1
        for iCell = 1:max(this.ROIs(:))
            f(:, iCell, :) = squeeze(nanmean(this.RawImage(:,this.ROIs == iCell,:,:), 2));
        end
    else
        for iCh = 1:this.ChannelNum
            if this.ReductionFactor > 1 % Too big dataset, we need to reload it frame by frame for calculation
                file = H5F.open(fullfile(this.FilePath, this.PicFileName), 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
                dset = H5D.open(file,['/MSession_0/MUnit_' num2str(this.MesImageIndex - 1) '/Channel_' num2str(iCh - 1)]);
                space = H5D.get_space(dset);
                block = [double(size(this.RawImage, 1)) double(size(this.RawImage, 2)) double(1)];
                mem_space = H5S.create_simple(3, fliplr(block), []);
                
%                 progressbar(1);
                frameNum = this.FrameNum;
                channelNum = this.ChannelNum;
                rois = this.ROIs;
                for iFrame = 1:frameNum
                    start = [0 0 double(iFrame - 1)];
                    H5S.select_hyperslab(space, 'H5S_SELECT_SET', fliplr(start), [], [], fliplr(block));
                    frame = 65535 - flipud(permute(H5D.read(dset,'H5ML_DEFAULT',mem_space,space,'H5P_DEFAULT'), [2 1 3]));
                    temp = regionprops(rois, frame, 'MeanIntensity');
                    f(iFrame, :, iCh) = [temp.MeanIntensity];
                    if rem(double(iFrame) / 10, 1) == 0
                        progressbar(((iCh - 1) * frameNum + iFrame) / frameNum / channelNum);
%                         progressbar(double(iFrame) * iCh / double(frameNum) / double(channelNum));
                    end
                end
                
                H5D.close(dset);
                H5S.close(space);
                H5S.close(mem_space);
                H5F.close(file);
            else
                for iFrame = 1:this.FrameNum
                    temp = regionprops(this.ROIs, this.RawImage(:,:,iFrame,iCh), 'MeanIntensity');
                    f(iFrame, :, iCh) = [temp.MeanIntensity];
                end
            end
        end
    end
    progressbar(1);
    
    fprintf('Calculation done in %.2f seconds. \n', toc');
    
    this.F = f;
end