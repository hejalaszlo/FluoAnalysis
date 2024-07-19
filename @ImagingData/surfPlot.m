function surfPlot(this)
    c(:,1) = ones(255,1);
    c(:,2) = linspace(1, 0, 255)';
    c(:,3) = linspace(1, 0, 255)';

    % Calculate baselines
    if isempty(this.DeltaFperF0BaselineAdjusted)
        disp('Calculating baselines');
        this.adjustBaseline;
    end
    
    figure('NumberTitle', 'off', 'Name', [this.PicFileName ' ' num2str(this.MesImageIndex)]);
    
%     if isempty(filter)
%         filter = 1:this.CellNum;
%     end

    if ~isempty(this.Ephys)
        if size(this.Ephys, 2) == 1
            ax(1) = subplot(6,1,[1 2]);
            plot(this.EphysTime, this.Ephys);
            axis off;
        elseif size(this.Ephys, 2) == 2
            ax(1) = subplot(6,1,1);
            plot(this.EphysTime, this.Ephys(:,1));
            ylabel('Ch. 1');
            box off;
            set(ax(1),'XColor',get(gca,'Color'));
            
            ax(2) = subplot(6,1,2);
            plot(this.EphysTime, this.Ephys(:,2));
            ylabel('Ch. 2');
            axis off;
            box off;
            set(ax(2),'XColor',get(gca,'Color'));
        end
        
        ax(3) = subplot(6,1,[3 6]);
        linkaxes(ax, 'x');
    end
    
%     surf(this.Time, filter, this.DeltaFperF0BaselineAdjusted(:,filter,1)');
    surf(this.Time, 1:this.CellNum, this.DeltaFperF0BaselineAdjusted(:,:,1)');
    shading flat;
    axis tight;
    view(2);
    colormap(c);
    xlabel('Time (s)');
    ylabel('Cell # (imaging)');
    
    % TODO: limit legyen a histogram maximumhelye és 90-95% helye
    caxis([0.17 0.89]);
    % Find optimal limits for the colormap
    [count, val] = hist(this.DeltaFperF0BaselineAdjusted(:,:,1), 50);
    maxCount = max(count(:));
    cmapmin = find(max(count') == maxCount, 1);
    cmapmax = find(max(count(cmapmin+1:end,:)') < maxCount * 0.05, 1) + cmapmin;
    caxis([val(cmapmin) val(cmapmax)]);
    
%     spaceplots;
end