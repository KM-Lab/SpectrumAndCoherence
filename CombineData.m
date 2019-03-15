function AllData=CombineData(FileOverview) 
%FileOverview contains meta info on all files to be analyzed and combined
%Combining will happen by genotype, across multiple animals, for each
%stimulation parameter

if isequal(FileOverview,'')
   %Fileoverview was not yet generated and will be called now
   [FileOverview,TotalNumberOfGeno,TotalNumberOfAnimals,TotalNumberOfFiles]=GroupAnalysis('')
end

genotypes=unique({FileOverview.genotype});          %cell of all genotypes
stimfrequencies=unique([FileOverview.stimfreq]);    %array of stim freqs
TotalNumberOfFiles=size(FileOverview,2);            %total number of files
allmicename=unique({FileOverview.mouseid});
allmicename=[allmicename{1:end}];

%Loop through the genotypes
for i_g=1:size(genotypes,2)
    
    disp(['Combining data for genotype: ' genotypes{i_g}]);
    %Select genotype
    geno=genotypes{i_g};
    
    %Extract just the files matching this genotype
    CurrentFiles=FileOverview(strcmp({FileOverview.genotype},geno));
    
    AllData(i_g).genotype=geno;
    
    %Initialize Data structure for 100 entries (one for each stimulation
    %frequency upto 100, so that Data(17) is Data at 17Hz stimulation (if
    %exists)
    Data=struct;
    if length(CurrentFiles)>=1
        tempdata=load(CurrentFiles(1).location,'t1','f1','params');
        nrranges=length(fields(tempdata.params.ranges));
        AllData(i_g).freqranges=tempdata.params.ranges;
    else
        tempdata.t1=0;tempdata.f1=0;
        nrranges=1;
    end
    nrtimebins=size(tempdata.t1,2); %needed for initialization of strcture arrays
    nrfreqbins=size(tempdata.f1,2); %needed for initialization of strcture arrays
    Data(100).included=[]; %initialize
    Data(100).Cperc=zeros(nrtimebins,nrfreqbins); 
    Data(100).S1perc=zeros(nrtimebins,nrfreqbins);
    Data(100).S2perc=zeros(nrtimebins,nrfreqbins);
    Data(100).IncreaseSpectrum1AtFreq=zeros(1,nrranges);
    Data(100).IncreaseSpectrum2AtFreq=zeros(1,nrranges);
    Data(100).IncreaseSpectrum1AtStimFreq=0;
    Data(100).IncreaseSpectrum2AtStimFreq=0;
    Data(100).IncreaseCoherenceAtFreq=zeros(1,nrranges);
    Data(100).IncreaseCoherenceAtStimFreq=0;
    for i=1:100
        Data(i).Cperc=zeros(nrtimebins,nrfreqbins); 
        Data(i).S1perc=zeros(nrtimebins,nrfreqbins); 
        Data(i).S2perc=zeros(nrtimebins,nrfreqbins); 
        Data(i).IncreaseSpectrum1AtFreq=zeros(1,nrranges);
        Data(i).IncreaseSpectrum2AtFreq=zeros(1,nrranges);
        Data(i).IncreaseSpectrum1AtStimFreq=0;
        Data(i).IncreaseSpectrum2AtStimFreq=0;
        Data(i).IncreaseCoherenceAtFreq=zeros(1,nrranges);
        Data(i).IncreaseCoherenceAtStimFreq=0;
        Data(i).nrfiles=0;
        Data(i).included={};
    end

    %Loop through the files for this genotype
    for i_f=1:length(CurrentFiles)
    
        fn=CurrentFiles(i_f).location;
        fndata=load(fn,'t1','f1','t2','f2','tC','fC','S1perc','S2perc','Cperc','mouseid',...
                        'IncreaseCoherenceAtFreq','IncreaseSpectrum1AtFreq','IncreaseSpectrum2AtFreq',...
                        'IncreaseCoherenceAtStimFreq','IncreaseSpectrum1AtStimFreq','IncreaseSpectrum2AtStimFreq');
                        
        mouseid=CurrentFiles(i_f).mouseid;
        stimfreq=CurrentFiles(i_f).stimfreq;
    
        Data(stimfreq).S1perc=Data(stimfreq).S1perc+fndata.S1perc;
        Data(stimfreq).S2perc=Data(stimfreq).S2perc+fndata.S2perc;
        Data(stimfreq).Cperc=Data(stimfreq).Cperc+fndata.Cperc;
        Data(stimfreq).nrfiles=Data(stimfreq).nrfiles+1;
        Data(stimfreq).included=[Data(stimfreq).included {mouseid}];
        Data(stimfreq).IncreaseSpectrum1AtFreq=Data(stimfreq).IncreaseSpectrum1AtFreq+...
                                           fndata.IncreaseSpectrum1AtFreq(:,3)';
        Data(stimfreq).IncreaseSpectrum2AtFreq=Data(stimfreq).IncreaseSpectrum2AtFreq+...
                                           fndata.IncreaseSpectrum2AtFreq(:,3)';
        Data(stimfreq).IncreaseCoherenceAtFreq=Data(stimfreq).IncreaseCoherenceAtFreq+...
                                           fndata.IncreaseCoherenceAtFreq(:,3)';
        Data(stimfreq).IncreaseSpectrum1AtStimFreq=Data(stimfreq).IncreaseSpectrum1AtStimFreq+...
                                           fndata.IncreaseSpectrum1AtStimFreq(:,3)';
        Data(stimfreq).IncreaseSpectrum2AtStimFreq=Data(stimfreq).IncreaseSpectrum2AtStimFreq+...
                                           fndata.IncreaseSpectrum2AtStimFreq(:,3)';
        Data(stimfreq).IncreaseCoherenceAtStimFreq=Data(stimfreq).IncreaseCoherenceAtStimFreq+...
                                           fndata.IncreaseCoherenceAtStimFreq(:,3)';
    end
    
    %Load vars that are assumed to be the same in each of these files
    t1=fndata.t1;
    f1=fndata.f1;
    t2=fndata.t2;
    f2=fndata.f2;
    tC=fndata.tC;
    fC=fndata.fC;
    priortime=load(fn,'priortime');priortime=priortime.priortime;

    %Averaging the variables S1perc,S2perc and Cperc over the number of files
    freqsavailable=[];
    for i=1:100
        if Data(i).nrfiles~=0
           Data(i).Cperc=Data(i).Cperc/Data(i).nrfiles; 
           Data(i).S1perc=Data(i).S1perc/Data(i).nrfiles;
           Data(i).S2perc=Data(i).S2perc/Data(i).nrfiles;
           Data(i).IncreaseSpectrum1AtFreq=Data(i).IncreaseSpectrum1AtFreq/Data(i).nrfiles;
           Data(i).IncreaseSpectrum2AtFreq=Data(i).IncreaseSpectrum2AtFreq/Data(i).nrfiles;
           Data(i).IncreaseSpectrum1AtStimFreq=Data(i).IncreaseSpectrum1AtStimFreq/Data(i).nrfiles;
           Data(i).IncreaseSpectrum2AtStimFreq=Data(i).IncreaseSpectrum2AtStimFreq/Data(i).nrfiles;
           Data(i).IncreaseCoherenceAtFreq=Data(i).IncreaseCoherenceAtFreq/Data(i).nrfiles;
           Data(i).IncreaseCoherenceAtStimFreq=Data(i).IncreaseCoherenceAtStimFreq/Data(i).nrfiles;
           freqsavailable=[freqsavailable i];       
        end
    end
    
    AllData(i_g).Data=Data;
    AllData(i_g).freqsavailable=freqsavailable;
    AllData(i_g).t1=t1;
    AllData(i_g).f1=f1;
    AllData(i_g).t2=t2;
    AllData(i_g).f2=f2;
    AllData(i_g).tC=tC;
    AllData(i_g).fC=fC;
    AllData(i_g).priortime=priortime;
end
outputfilename=['AllAnalysis_' num2str(TotalNumberOfFiles) ' files_' '(' allmicename ')' '_' datestr(now,'dd-mm-yyyy_HH-MM')];
disp(['Saving data to file: ' outputfilename]);
save(outputfilename,'AllData','genotypes','stimfrequencies','TotalNumberOfFiles','FileOverview');
