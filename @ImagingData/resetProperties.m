function resetProperties(this)
    p = properties(this);
    for i = 1:length(p)
        mp = findprop(ImagingData, p{i});
        if strcmp(mp.SetAccess, 'public') && mp.Dependent == 0
            if mp.HasDefault
                this.(p{i}) = mp.DefaultValue;
            else
                this.(p{i}) = [];
            end
        end
    end
end