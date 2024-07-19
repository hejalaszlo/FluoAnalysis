function loadEphys(this, filepath)
    downSampling = 10;
    [data, samplingInterval, headers] = abfload2(filepath);
    time = (samplingInterval:samplingInterval:headers.dataPtsPerChan * samplingInterval)' / 1000000;
    
    if headers.fFileVersionNumber >= 2 % ABF 2.0, 2-photon
        % Time when the ephys recording was started
        ephysStart = datenum(num2str(headers.uFileStartDate), 'yyyymmdd') + headers.uFileStartTimeMS / 1000 / 60 / 60 / 24;
        % Time when the imaging session was started
        imagingStart = datenum(this.MesMetadata(1).MeasurementDate, 'yyyy.mm.dd. HH:MM:SS,FFF');
    else % ABF 1.8, confocal (ephys and imaging started synchronously
        ephysStart = 0;
        imagingStart = 0;
    end
    
    % Extract ephys segment corresponding to the imaging session
    ephysImagingSessionStart = [];
    if ~isempty(headers.tags) % imaging session start is tagged in the .abf file
        % Find the corresponding tag
        temp = [headers.tags.timeSinceRecStart] * samplingInterval - (imagingStart - ephysStart) * 24 * 60 * 60;
        if min(abs(temp)) < 1
            tagNum = find(abs(temp) == min(abs(temp)));
            fprintf('Tag number corresponding to imaging session: %d\n', tagNum);
            ephysImagingSessionStart = find(time >= headers.tags(tagNum).timeSinceRecStart * samplingInterval - 0.3, 1);
            ephysImagingSessionEnd = find(time > headers.tags(tagNum).timeSinceRecStart * samplingInterval - 0.3 + this.Time(end), 1);
        end
    end
%     if isempty(ephysImagingSessionStart)
%         ephysImagingSessionStart = find(time >= (imagingStart - ephysStart) * 24 * 60 * 60, 1);
%         ephysImagingSessionEnd = find(time > (imagingStart - ephysStart) * 24 * 60 * 60 + this.Time(end), 1);
%     end
%     if isempty(ephysImagingSessionEnd)
%         ephysImagingSessionEnd = length(time);
%     end
   
	if ~isempty(ephysImagingSessionStart) && ~isempty(ephysImagingSessionEnd)
		this.Ephys = data(ephysImagingSessionStart:downSampling:ephysImagingSessionEnd,:);
		this.EphysTime = time(ephysImagingSessionStart:downSampling:ephysImagingSessionEnd) - time(ephysImagingSessionStart);    
	end
end