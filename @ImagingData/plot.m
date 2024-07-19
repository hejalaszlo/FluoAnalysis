function plot(this, varargin)
    figure('NumberTitle', 'off', 'Name', strcat(this.PicFileName(1), ' F', num2str(this.MesImageIndex)), 'Pos', [100 100 1000 800]);
    
    if ~isnan(sum(this.ValidCell))
        ax(1) = subplot(3,2,1);
        plot(this.Time, this.DeltaFperF0(:,:,1), varargin{:});
        title('All cells');
        ylabel('\DeltaF/F_0');
        
        ax(2) = subplot(3,2,3);
        plot(this.Time, this.DeltaFperF0(:,this.Neuron == 1,1), varargin{:});
        title('Neurons');
        ylabel('\DeltaF/F_0');
        
        ax(3) = subplot(3,2,5);
        plot(this.Time, this.DeltaFperF0(:,this.Glia == 1,1), varargin{:});
        title('Glia');
        xlabel('Time (s)');
        ylabel('\DeltaF/F_0');
        
        ax(4) = subplot(3,2,[2 4]);
        for i = 1:size(this.PeriodicActivityFrequency, 2)
            if sum(~isnan(this.PeriodicActivityFrequency(:,i,1))) > 0
                if this.Glia(i) == 1
                    plot(this.PeriodicActivityTime, this.PeriodicActivityFrequency(:,i,1) ./ this.PeriodicActivityFrequency(:,i,1) * i, 'r');
                elseif this.Neuron(i) == 1
                    plot(this.PeriodicActivityTime, this.PeriodicActivityFrequency(:,i,1) ./ this.PeriodicActivityFrequency(:,i,1) * i, 'k');
                else
                    plot(this.PeriodicActivityTime, this.PeriodicActivityFrequency(:,i,1) ./ this.PeriodicActivityFrequency(:,i,1) * i, 'Color', [0.2 0.2 0.2]);
                end
            end
            hold on;
        end
        title('Periodic activity');
        ylabel('Cell number');
        
        ax(5) = subplot(3,2,6);
        plot(this.PeriodicActivityTime, sum(~isnan(this.PeriodicActivityFrequency(:,this.Glia == 1,1)')) / sum(this.Glia == 1) * 100, 'r');
        hold on;
        plot(this.PeriodicActivityTime, sum(~isnan(this.PeriodicActivityFrequency(:,this.Neuron == 1,1)')) / sum(this.Neuron == 1) * 100, 'k');
        ylabel('Active cell (%)');  
        xlabel('Time (s)');
    else
        plot(this.Time, this.DeltaFperF0(:,:,1), varargin{:});
        title('All cells');
        xlabel('Time (s)');
        ylabel('\DeltaF/F_0');
    end
    
    linkaxes(ax, 'x');
    
    spaceplots;
end