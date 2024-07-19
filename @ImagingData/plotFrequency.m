function plotFrequency(this)
%     c(:,1) = ones(255,1);
%     c(:,2) = linspace(1, 0, 255)';
%     c(:,3) = linspace(1, 0, 255)';
	c(:,1) = [ones(127,1); logspace(0, -3, 128)'];
	c(:,2) = [logspace(-3, 0, 127)'; 1; logspace(0, -3, 127)'];
	c(:,3) = [logspace(-3, 0, 128)'; ones(127,1)];

    figure('NumberTitle', 'off', 'Name', ['Frequency - ' this.PicFileName ' F' num2str(this.MesImageIndex)], 'units', 'centimeters', 'position', [10 10 25 10]);
    
    minfreq = 1;
    maxfreq = 0.5 * this.SamplingFrequency;

    if ~isempty(this.Ephys)
        fs = 1/(this.EphysTime(2) - this.EphysTime(1));
        if size(this.Ephys, 2) == 1 % Only 1 channel
            ax(1) = subplot(2,1,1);
            [pxx,f] = periodogram(this.Ephys, rectwin(length(this.Ephys)), linspace(minfreq,maxfreq,max(500,(maxfreq-minfreq))), fs);
            plot(f,pxx);
            title('Ephys power spectrum');
            
            ax(2) = subplot(2,1,2);
        elseif size(this.Ephys, 2) == 2
            ax(1) = subplot(3,1,1);
            [pxx,f] = periodogram(this.Ephys(:,1), rectwin(length(this.Ephys(:,1))), linspace(minfreq,maxfreq,max(500,(maxfreq-minfreq))), fs);
            plot(f,pxx);
            title('Ephys Ch1 power spectrum');
            set(ax(1),'XColor',get(gca,'Color'));
            
            ax(2) = subplot(3,1,2);
            [pxx,f] = periodogram(this.Ephys(:,2), rectwin(length(this.Ephys(:,2))), linspace(minfreq,maxfreq,max(500,(maxfreq-minfreq))), fs);
            plot(f,pxx);
            title('Ephys Ch2 power spectrum');
            set(ax(2),'XColor',get(gca,'Color'));
            
            ax(3) = subplot(3,1,3);
        end
        
        linkaxes(ax, 'x');
    end
    
    if maxfreq > this.SamplingFrequency
        msgbox('Maximum frequency is higher than sampling frequency. Setting it to 0.9*sampling frequency');
        maxfreq = 0.9 * this.SamplingFrequency;
    end

    [pxx,f] = periodogram(this.F(:,:,1), rectwin(size(this.F, 1)), linspace(minfreq,maxfreq,100), this.SamplingFrequency);
    if nansum(this.Glia) + nansum(this.Neuron) > 0
        pxxGlia = pxx(:,this.Glia == 1);
        pxxNeuron = pxx(:,this.Neuron == 1);
%         surf(f, 1:size(pxx,2), pxx');
%         surf(f, 1:size(pxxNeuron,2), pxxNeuron');
%         surf(f, size(pxxNeuron,2)+1:size(pxxNeuron,2)+size(pxxGlia,2), -pxxGlia');
		pxxNeuron = pxxNeuron ./ max(pxxNeuron(:));
		pxxGlia = pxxGlia ./ max(pxxGlia(:));
		surf(f, 1:size(pxx,2), [pxxNeuron'; -pxxGlia']);
    else
        surf(f, 1:size(pxx,2), pxx');
    end
    
    colormap(c);
    shading flat;
    axis tight;
    view(2);
    title('Imaging power spectrum');
    xlabel('Frequency (Hz)');
	ylabel("Cell number");
    
    % Find optimal limits for the colormap
%     [count, val] = hist(pxx, 50);
%     maxCount = max(count(:));
%     cmapmin = find(max(count') == maxCount, 1);
%     cmapmax = find(max(count(cmapmin+1:end,:)') < maxCount * 0.05, 1) + cmapmin;
%     caxis([val(cmapmin) val(cmapmax)]);
    
    spaceplots;
end