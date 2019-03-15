function FigureCoherence(filename,DodB,DoShow,extension)
%Show Coherence for a single file in popup figure. Optionally save figure
%to file. Optionally show units in dB or not in dB.
    
    if isequal(filename,'')
       [fn,fp]=uigetfile('*.mat','Select One or More Files','MultiSelect','on'); 
       filename=[fp fn];
       if iscell(fn)
            numberoffiles=size(fn,2);
            for i_f=1:numberoffiles
                filenames{i_f}=[fp fn{i_f}];
            end
       else
            numberoffiles=1;
            filenames={filename};
       end
    else
       numberoffiles=1;
       filenames={filename};
    end
    
    
    for i_f=1:numberoffiles
        load(filenames{i_f});

        if DoShow
            vis='on';
        else
            vis='off';
        end
        if ~exist('mouseid','var')
            mouseid='unknown id';
        end
        if ~exist('stimfreq','var')
            stimfreq=0;
        end

        if ~exist('channel1','var')
            channel1=0;
        end
        if ~exist('channel2','var')
            channel2=0;
        end
        if ~exist('numberoftraces','var')
            numberoftraces=size(filteredsets1,2);
        end

        %Open figure and give title based on animal
        figure('name', ['Coherence plots: ' mouseid '_' num2str(stimfreq) 'Hz' ' (' num2str(numberoftraces) ' traces)'], 'units','normalized','outerposition',[0 0 1 1],'Visible',vis);

        %define average traces of filteredsets
        averagetrace1=mean(filteredsets1,2);
        averagetrace2=mean(filteredsets2,2);
        yrange=[min([averagetrace1.' averagetrace2.']) max([averagetrace1.' averagetrace2.'])];

        specstart=priortime*fs+1;
        specend=priortime*fs+treatmenttime*fs;

        %First plots are average traces for each channel


        %First plots are average traces for each channel
        splot1=subplot(2,3,1);
        plot(timepoints, averagetrace1);
        hold on
        plot([0,treatmenttime],[yrange(1),yrange(1)],'y');
        hold off
        axis([-inf,inf,yrange(1),yrange(2)]);
        xlabel('Time from trigger (s)');
        ylabel('signal');
        title(['average trace: channel ' num2str(channel1)]);

        splot2=subplot(2,3,2);
        plot(timepoints, averagetrace2);
        hold on
        plot([0,treatmenttime],[yrange(1),yrange(1)],'y');
        hold off
        axis([-inf,inf,yrange(1),yrange(2)]);
        xlabel('Time from trigger (s)');
        ylabel('signal');
        title(['average trace: channel ' num2str(channel2)]);

        %Add Coherence Plots
        splot6=subplot(2,3,6);
        imagesc(tC-priortime,fC,C',[0 1]); axis xy; colorbar;    
        ylabel('Frequency');
        xlabel('Time from trigger');
        title('Avg Coherency between channels around trigger');

        splot4=subplot(2,3,4);
        plot(f_pc,Coherence_prior,'b',f_dc,Coherence_during,'r');xlabel('frequency'); ylabel('Coherency');
        yrange=get(gca,'ylim');
        hold on
        plot([stimfreq,stimfreq],yrange,'y');
        hold off
        legend('prior','during')
        title(['Avg Coherency between channel ' num2str(channel1) ' and channel ' num2str(channel2)])

        splot5=subplot(2,3,5);
        [f_new,cp,cd,warn]=GiveSameDomain(f_pc,f_dc,Coherence_prior,Coherence_during);
        plot(f_new,cd-cp,'m');xlabel('frequency'); ylabel('Increase in Coherency');
        yrange=get(gca,'ylim');
        hold on
        plot([stimfreq,stimfreq],yrange,'y');
        hold off
        title(['Increase in Coherency between channel ' num2str(channel1) ' and channel ' num2str(channel2) ' (' warn ')'])

        linkaxes([splot1,splot2,splot6],'x');
        linkaxes([splot4,splot5],'x');

        %Optionally save fig to file
        if ~isequal(extension,0)
           stimfreqstring=strrep(num2str(stimfreq),'.','-');
           saveas(gcf,['Coherence_' mouseid '_' stimfreqstring 'Hz'],extension);
           if ~DoShow
              close(gcf); 
           end
        end
    end