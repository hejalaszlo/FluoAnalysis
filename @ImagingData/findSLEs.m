function findSLEs(this)
    if isempty(this.Ephys) || isempty(this.EphysTime)
        warning('ImagingData findSLEs: not all required properties set');
        return
    end
    
    % High-pass filter at 1 Hz
    minfreq = 1;
    dt = this.EphysTime(2) - this.EphysTime(1);
    
    [b,a] = butter(4, minfreq*2*dt, 'high');
    filteredEphys = filter(b, a, this.Ephys);
    
    % Calculate moving standard deviation
    window = 5; % in second
    ephysSTD = movstd(filteredEphys, window/dt);
end