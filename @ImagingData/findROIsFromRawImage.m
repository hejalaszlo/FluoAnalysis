function findROIsFromRawImage(this)
    refimage = this.RefImage;
	r = mean(this.RawImage(:,:,:,1), 3);
	this.RefImage = r ./ max(r(:)); % findROIs is automatically called when setting RefImage
% 	this.findROIs();
% 	this.RefImage = refimage;
end