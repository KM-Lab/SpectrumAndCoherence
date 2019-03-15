% Last Update: 02-22-2019       Chris Krook-Magnuson

%Take in the files produced by the recorder, and for each file perform the first steps of
%the SpectrumCoherence process, extracting the sets around the triggers,
%removing outliers, running single file statistics on each, saving info to
%analysis files, saving those in specified location

%Load in parameters
params=SetParameters;
channel1=params.channel1;               %Load channel 1 (number)
channel2=params.channel2;               %Load channel 2 (number)
priortime=params.priortime;             %Load prior time (s)
treatmenttime=params.treatmenttime;     %Load treatment time (s)
posttime=params.posttime;               %Load posttime (s)



%Ask for a directory of files to process (or take value from params)
if isequal(params.inputfolder,'')
    inputfolder = uigetdir(pwd,'Select an input directory');
else
    inputfolder = params.inputfolder
end

%Analyze files in the directory by stimulation parameters
%Will return structure array with fields 'folder','name','StimParams','Nr'
FileList=FileAnalysis(inputfolder, channel1);
NumberOfFiles=length(FileList);

%Ask for a mouse ID (if not already set in SetParameters)
if isequal(params.mouseid,'')
    mouseid=inputdlg('Provide mouse id (should reflect ALL files you''re about to analyze)');
    mouseid=mouseid{1};
else
    mouseid=params.mouseid;
end

%Specify the outputfolder for the analysis files (if not already set in SetParameters)
%Files will be stored in MOUSE ID subdir
if isequal(params.outputfolder,'')
    outputfolder = uigetdir(pwd,'Select an output directory');
else
    outputfolder=params.outputfolder;
end
outputfolder=[outputfolder '\' mouseid];
if ~exist(outputfolder,'dir')
    mkdir(outputfolder)
end

%Loop through all the files in the directory
i_f=1;
while i_f<=NumberOfFiles

    %Load in the file
    disp(['Processing file ' num2str(i_f) '/' num2str(NumberOfFiles)]);
    patient=[FileList(i_f).folder '\' FileList(i_f).name]
    file=load(patient);
    fs=file.fs;
    params.Fs=fs;
    
    %Realign (if desired)
    if params.do_realign
        %We want to use realigned traces. This might already have been done
        %in which case we can load it in from file.
        try
           %if it exists, use the realigned triggers
           triggerlist=file.pulsestamps(channel1).timestamp();
           method='Use realigned triggers, already in file'

           %if it exists but is empty, then pulsestamps was generated for another
           %channel but not this one, so we still have to do it.
           if isempty(triggerlist)
              a=triggerlist(1); %this is impossible, hence will lead us to the catch
           end
    
        catch
            pulsestamps=Realign(patient,params.realign_threshold,params.ch_trigger,params.ch_pulses,[params.channel1,params.channel2,params.ch_pulses],1,params.doshow_realignment);
            triggerlist=pulsestamps(params.channel1).timestamp;
            method='Use realigned triggers, calculated now'
            disp(['Biggest realignment: ' num2str(max(pulsestamps(params.channel1).delays(:,1)))]); 
        end
    else
        %Don't realign, but simply use the trdata triggerlist
        triggerlist=file.trdata(channel1).timestamp();
        method='Use original triggers (do not realign)'  
    end %do_realign
    
    %Optionally remove 60hz noise from signal at this point
    if params.do_remove_60hz
        Removed60HzNoise=true;
        file.sbuf(:,channel1)=Remove60HzNoise(file.sbuf(:,channel1),fs);
        file.sbuf(:,channel2)=Remove60HzNoise(file.sbuf(:,channel2),fs);
        disp('Remove 60Hz Noise');
    else
        Removed60HzNoise=false;
    end
    
    %Extract info on recording
    tempts=file.trdata(channel1).timestamp(1);
    recordingday=datestr(tempts,'dd-mm-yyyy');
    recordingstarttime=datestr(tempts,'HH:MM:SS');
    
    %Extract FilteredSets
    sets1=ExtractSets(file.sbuf(:,channel1),fs,triggerlist,priortime,treatmenttime,posttime);
    sets2=ExtractSets(file.sbuf(:,channel2),fs,triggerlist,priortime,treatmenttime,posttime);
    
    %Combine FilteredSets if there is more than 1 file for the parameters
    %According to (.Nr field in FileList)
    if FileList(i_f).Nr==1
        filteredsets1=sets1;
        filteredsets2=sets2;
        filesource{1}=patient;
        recday{1}=recordingday;
        rectime{1}=recordingstarttime;
    else
        filteredsets1 = [filteredsets1 sets1];
        filteredsets2 = [filteredsets2 sets2];
        filesource{end+1}=patient;
        recday{end+1}=recordingday;
        rectime{end+1}=recordingstarttime;
    end
    
    
    %Only do the next steps if we are done with the files with this stim paramaters
    if FileList(i_f).LastOfSet
        
        sets1=filteredsets1;
        sets2=filteredsets2;
        timepoints=(-priortime:1/fs:-priortime+(1/fs)*(length(sets1(:,1))-1));
        
        %Remove Outliers from FilteredSets
        if params.do_removeoutliers
            [filteredsets,dirtytraces,outliers]=RemoveOutliersFromMultiple({filteredsets1,filteredsets2},0,0);
            filteredsets1=filteredsets{1};
            filteredsets2=filteredsets{2};
            dirtytraces1=dirtytraces{1};
            dirtytraces2=dirtytraces{2};
        else
           ditrytraces1=[];
           dirtytraces2=[];
           outliers=[];
        end   
        nrtraces=size(filteredsets1,2);
        
        %Run Single File Statistics
        ledon=FileList(i_f).StimParams(1);
        ledoff=FileList(i_f).StimParams(2);
        stimfreq=1000/(ledon+ledoff);           %Calculate stimulation frequency
        stimrange=[stimfreq-0.5 stimfreq+0.5];  %Calculat stimulation range
        specstart=priortime*fs+1;
        specend=priortime*fs+treatmenttime*fs;

        if 1 %SPECTRUM OF EACH
            %Moving time spectogram, for sets associated with channel
            disp('Calculate moving time spectogram');
            [Spectrum_during1,f_d1]=mtspectrumc(filteredsets1(specstart:specend,:),params);
            [Spectrum_prior1,f_p1]=mtspectrumc(filteredsets1(1:specstart-1,:),params);
            
            [Spectrum_during2,f_d2]=mtspectrumc(filteredsets2(specstart:specend,:),params);
            [Spectrum_prior2,f_p2]=mtspectrumc(filteredsets2(1:specstart-1,:),params);
    
            [S1,S1perc,t1,f1]=CalculateSpectrumIncrease(filteredsets1,params,priortime);
            [S2,S2perc,t2,f2]=CalculateSpectrumIncrease(filteredsets2,params,priortime);
        end
        
        if 1 %COHERENCE BETWEEN
            [Coherence_prior,~,~,~,~,f_pc]=coherencyc(filteredsets1(1:specstart-1,:),filteredsets2(1:specstart-1,:),params); 
            [Coherence_during,~,~,~,~,f_dc]=coherencyc(filteredsets1(specstart:specend,:),filteredsets2(specstart:specend,:),params); 
            [C,Cperc,tC,fC,phi]=CalculateCoherenceIncrease(filteredsets1,filteredsets2,params,priortime);
        end

        if 1 %Increase at predefined frequency ranges and at stimulation frequency
           allfreqranges=fields(params.ranges);
           nrranges=size(allfreqranges,1);
           %Loop through all frequency ranges defined in params.ranges
           for i_fr=1:nrranges
                freqrange=params.ranges.(allfreqranges{i_fr});
                [tempa1,tempa2,tempa3]=FindIncreaseAtF(Coherence_prior,Coherence_during,f_pc,f_dc,freqrange);
                IncreaseCoherenceAtFreq(i_fr,:)=[tempa1,tempa2,tempa3];
                [tempa1,tempa2,tempa3]=FindIncreaseAtF(Spectrum_prior1,Spectrum_during1,f_p1,f_d1,freqrange);
                IncreaseSpectrum1AtFreq(i_fr,:)=[tempa1,tempa2,tempa3];
                [tempa1,tempa2,tempa3]=FindIncreaseAtF(Spectrum_prior2,Spectrum_during2,f_p2,f_d2,freqrange);
                IncreaseSpectrum2AtFreq(i_fr,:)=[tempa1,tempa2,tempa3];
           end
           [tempa1,tempa2,tempa3]=FindIncreaseAtF(Coherence_prior,Coherence_during,f_pc,f_dc,stimrange);
           IncreaseCoherenceAtStimFreq=[tempa1,tempa2,tempa3];
           [tempa1,tempa2,tempa3]=FindIncreaseAtF(Spectrum_prior1,Spectrum_during1,f_p1,f_d1,stimrange);
           IncreaseSpectrum1AtStimFreq=[tempa1,tempa2,tempa3];
           [tempa1,tempa2,tempa3]=FindIncreaseAtF(Spectrum_prior2,Spectrum_during2,f_p2,f_d2,stimrange);
           IncreaseSpectrum2AtStimFreq=[tempa1,tempa2,tempa3];
        end
        
        %Save Output File
        %Might be compiled from different files for the same animal and same
        %stimulation parameter conditions.
        timeanalyzed=now; %datestr(now,'mm-dd-yyyy_HH_MM_SS');
        name_prefix=params.outputfilename;
        name_stimfreq=[num2str(round(stimfreq)) 'Hz'];
        sp=FileList(i_f).StimParams;
        name_stimparam=['(' num2str(sp(1)) ' ' num2str(sp(2)) ' ' num2str(sp(3)) ' ' num2str(sp(4)) ')'];
        outputname=[outputfolder '\' name_prefix '_' mouseid '_' name_stimfreq '_' name_stimparam '.mat'];
        save(outputname,'params','mouseid','filesource','sets1','sets2','filteredsets1','filteredsets2','timepoints',...
                        'recday','rectime','triggerlist','dirtytraces1','dirtytraces2','outliers','nrtraces',...
                        'Removed60HzNoise',...
                        'channel1','channel2',...
                        't1','f1','S1','S1perc',...
                        't2','f2','S2','S2perc',...
                        'tC','fC','C','Cperc',...
                        'Spectrum_prior1','Spectrum_during1','f_d1','f_p1','Spectrum_prior2','Spectrum_during2','f_d2','f_p2',...
                        'Coherence_prior','Coherence_during','f_pc','f_dc',...
                        'priortime','posttime','treatmenttime','fs','stimfreq','stimrange','ledon','ledoff','timeanalyzed',...
                        'IncreaseCoherenceAtFreq','IncreaseSpectrum1AtFreq','IncreaseSpectrum2AtFreq',...
                        'IncreaseCoherenceAtStimFreq','IncreaseSpectrum1AtStimFreq','IncreaseSpectrum2AtStimFreq');
                        
        
         %Plot spectrum and coherence graphs
         if params.do_plots %MAKE FIGURE OF SPECTRUM AND/OR COHERENCE
            FigureSpectrumAndCoherence(outputname,1,params.do_plots,params.extension)
         elseif params.do_saveplots
            FigureSpectrumAndCoherenceAndIncrease(outputname,1,0,params.extension)
         end
                   
                    
    else
       %will do another iteration to combine filteredsets 
    end
    
    %Go to next file
    i_f=i_f+1;
    
end %i_f (files)
