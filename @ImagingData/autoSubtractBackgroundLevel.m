function autoSubtractBackgroundLevel(this)
    if isempty(this.F)
        error('F is not set');
    end
    
    if sum(this.ValidCell ~= 0) > 0
        this.SubtractBackgroundLevel = 0.95 * squeeze(min(min(this.F(:,this.ValidCell ~= 0,:))));
    else
        this.SubtractBackgroundLevel = 0.95 * squeeze(min(min(this.F)));
    end
end