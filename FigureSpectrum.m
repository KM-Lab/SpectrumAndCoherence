function FigureSpectrum(filename,DodB,DoShow,extension)
%Show Spectrum and Coherence for a single file in popup figure. Optionally save figure
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

        %Overwrite dbrange here
        if DodB
            dbstring=' (dB)';
            try 
                dbrange=params.dbrange;
            catch
                dbrange='auto';
            end
        else
            dbstring='';
            dbrange='auto';
        end


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
        figure('name', ['Spectrum Plots' mouseid '_' num2str(stimfreq) 'Hz' ' (' num2str(numberoftraces) ' traces)'], 'units','normalized','outerposition',[0 0 1 1],'Visible',vis);

        %define average traces of filteredsets
        averagetrace1=mean(filteredsets1,2);
        averagetrace2=mean(filteredsets2,2);
        yrange=[min([averagetrace1.' averagetrace2.']) max([averagetrace1.' averagetrace2.'])];

        specstart=priortime*fs+1;
        specend=priortime*fs+treatmenttime*fs;

        %First plots are average traces for each channel
        splot1=subplot(2,4,1);
        plot(timepoints, averagetrace1);
        hold on
        plot([0,treatmenttime],[yrange(1),yrange(1)],'y');
        hold off
        axis([-inf,inf,yrange(1),yrange(2)]);
        xlabel('Time from trigger (s)');
        ylabel('signal');
        title(['average trace: channel ' num2str(channel1)]);

        splot2=subplot(2,4,2);
        plot(timepoints, averagetrace2);
        hold on
        plot([0,treatmenttime],[yrange(1),yrange(1)],'y');
        hold off
        axis([-inf,inf,yrange(1),yrange(2)]);
        xlabel('Time from trigger (s)');
        ylabel('signal');
        title(['average trace: channel ' num2str(channel2)]);


        %Determine splotectra for sub-range
        splot4=subplot(2,4,5)
        plot(f_p1,dbdata(Spectrum_prior1,DodB),'b',f_d1,dbdata(Spectrum_during1,DodB),'r'); 
        xlabel('Frequency Hz'); 
        ylabel(['Spectrum' dbstring]);
        yrange=get(gca,'ylim');
        hold on

        %Include subtraction, but deal with unequal x-spacing by interpolating
        [f_new,sp,sd,warn]=GiveSameDomain(f_p1,f_d1,Spectrum_prior1,Spectrum_during1);
        plot(f_new,dbdata(sd,DodB)-dbdata(sp,DodB),'g');
        plot([stimfreq,stimfreq],yrange,'y');
        hold off
        title(['Spectrogram for time [' num2str(specstart) ',' num2str(specend) ']' ' (' warn ')'])
        legend([num2str(priortime) 's prior'],[num2str(treatmenttime) 's during']);

        splot5=subplot(2,4,6)
        plot(f_p2,dbdata(Spectrum_prior2,DodB),'b',f_d2,dbdata(Spectrum_during2,DodB),'r'); 
        xlabel('Frequency Hz'); ylabel(['Spectrum' dbstring]);
        yrange=get(gca,'ylim');
        hold on

        %include subtraction, but deal with unequal x-spacing by interpolating
        [f_new,sp2,sd2,warn]=GiveSameDomain(f_p2,f_d2,Spectrum_prior2,Spectrum_during2);
        plot(f_new,dbdata(sd2,DodB)-dbdata(sp2,DodB),'g');
        plot([stimfreq,stimfreq],yrange,'y');
        hold off
        title(['Spectrogram for time [' num2str(specstart) ',' num2str(specend) ']' ' (' warn ')']);
        legend([num2str(priortime) 's prior'],[num2str(treatmenttime) 's during']);

         %Determine moving time spectogram
        splot3=subplot(2,4,3);
        imagesc(t1-priortime,f1,dbdata(S1,DodB)'); axis xy; colorbar;title(['(CH' num2str(channel1) ')']);
        caxis(dbrange);
        ylabel('Frequency');
        xlabel('Time from trigger');

        splot6=subplot(2,4,7);
        imagesc(t2-priortime,f2,dbdata(S2,DodB)'); axis xy; colorbar; title(['(CH' num2str(channel2) ')']);
        caxis(dbrange);
        ylabel('Frequency');
        xlabel('Time from trigger');

        %Subplots of %increase in S1 and S2
        splot10=subplot(2,4,4);
        imagesc(t1-priortime,f1,S1perc'); axis xy; colorbar;title(['%Increase wrt prior (CH' num2str(channel1) ')']);
        caxis('auto');
        ylabel('Frequency');
        xlabel('Time from trigger');


        splot11=subplot(2,4,8);
        imagesc(t2-priortime,f2,S2perc'); axis xy; colorbar;title(['%Increase wrt prior (CH' num2str(channel2) ')']);
        caxis('auto');
        ylabel('Frequency');
        xlabel('Time from trigger');


        linkaxes([splot1,splot2,splot3,splot6],'x');
        linkaxes([splot4,splot5],'x');

        %Optionally save fig to file
        if ~isequal(extension,0)
           stimfreqstring=strrep(num2str(stimfreq),'.','-');
           saveas(gcf,['Spectrum_' mouseid '_' stimfreqstring 'Hz'],extension);
           if ~DoShow
              close(gcf); 
           end
        end
    end