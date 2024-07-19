function loadDataFromFolder(this,folderpath)
	warning('off');
	
    folderpath = string(folderpath);
    if extractAfter(folderpath, strlength(folderpath)-1) ~= "\"
        folderpath = strcat(folderpath, "\");
    end
    files = dir(strcat(folderpath, '*.mat'));
	origfilenum = length(this.Data);
	for iFile = 1:size(files, 1)
        disp(files(iFile).name);

		a = load(strcat(folderpath, files(iFile).name));
        this.Data(origfilenum + iFile, 1) = a.imagingData;
        this.FilePath(origfilenum + iFile, 1) = strcat(folderpath, files(iFile).name);
        this.FileName(origfilenum + iFile, 1) = files(iFile).name;
	end
	
	% Sort measurements
	[~, ind] = sort(datenum(this.MeasurementDate, 'yyyy.mm.dd. HH:MM:SS,FFF'));
	this.Data = this.Data(ind);
	this.FilePath = this.FilePath(ind);
	this.FileName = this.FileName(ind);
	
	warning('on');
end