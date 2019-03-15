function FigureIncreases(filename,DoShow,extension)
%Show Spectrum and Coherence for a single file in popup figure. Optionally save figure
%to file. 

    
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
        figure('name', ['Increase Plots' mouseid '_' num2str(stimfreq) 'Hz' ' (' num2str(numberoftraces) ' traces)'], 'units','normalized','outerposition',[0 0 1 1],'Visible',vis);

                
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
        splot5=subplot(2,4,5)
        
        %frequency ranges
        freqranges=fields(params.ranges);
        incr=IncreaseSpectrum1AtFreq(:,3);
        plot(stimfreq,IncreaseSpectrum1AtStimFreq(3),'o','DisplayName','Stim Freq');
        hold on
        for i=1:length(freqranges)
            fr=params.ranges.(freqranges{i});
            plot(mean(fr),incr(i),'*','DisplayName',freqranges{i});
        end
        hold off
        title(['%Increase in Spectrum Channel ' num2str(channel1)]);
        
        splot6=subplot(2,4,6)
        
        %frequency ranges
        freqranges=fields(params.ranges);
        incr=IncreaseSpectrum2AtFreq(:,3);
        plot(stimfreq,IncreaseSpectrum2AtStimFreq(3),'o','DisplayName','Stim Freq');
        hold on
        for i=1:length(freqranges)
            fr=params.ranges.(freqranges{i});
            plot(mean(fr),incr(i),'*','DisplayName',freqranges{i});
        end
        hold off
        title(['%Increase in Spectrum Channel ' num2str(channel2)]);
        
        
        splot7=subplot(2,4,7)
        
        %frequency ranges
        freqranges=fields(params.ranges);
        incr=IncreaseCoherenceAtFreq(:,3);
        plot(stimfreq,IncreaseCoherenceAtStimFreq(3),'o','DisplayName','Stim Freq');
        hold on
        for i=1:length(freqranges)
            fr=params.ranges.(freqranges{i});
            plot(mean(fr),incr(i),'*','DisplayName',freqranges{i});
        end
        hold off
        title('%Increase in Coherence');
        
        
        splot8=subplot(2,4,8) %for legend
        freqranges=fields(params.ranges);
        incr=IncreaseSpectrum1AtFreq(:,3);
        plot(stimfreq,IncreaseSpectrum1AtStimFreq(3),'DisplayName','Stim Freq');
        hold on
        for i=1:length(freqranges)
            fr=params.ranges.(freqranges{i});
            plot(mean(fr),incr(i),'DisplayName',freqranges{i});
        end
        hold off
        
        legend
        
        %Optionally save fig to file
        if ~isequal(extension,0)
           stimfreqstring=strrep(num2str(stimfreq),'.','-');
           saveas(gcf,['Increases_' mouseid '_' stimfreqstring 'Hz'],extension);
           if ~DoShow
              close(gcf); 
           end
        end
    end