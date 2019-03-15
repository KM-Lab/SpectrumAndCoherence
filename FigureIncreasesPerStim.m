function FigureIncreasesPerStim(filename,idname, varname,rangename,stimfreqs)
% INPUT:
%       filename        name of an AllAnalysis file, including path
%                       if '' then will be prompted
%
%       idname          '' -> do all mice id for each geno
%                       'DN254' -> only show plots for specified mouse
%                       in this case filename is irrelevant and you will be
%                       prompted for the parent directory (containing geno,
%                       containing the animal)
%                       {'DN254','DN294'} -> combined plots for only these
%                       animals
%
%       varname         the variable name you want plots for:
%                       options are:    IncreaseSpectrum1AtFreq
%                                       IncreaseSpectrum2AtFreq
%                                       IncreaseCoherenceAtFreq
%                                       IncreaseSpectrum1AtStimFreq
%                                       IncreaseSpectrum2AtStimFreq
%                                       IncreaseCoherenceAtStimFreq
%
%       rangename       - 'delta' name of frequency range (as defined in params.ranges)
%                       - 'stimfreq' if you want to look at change at
%                          stimfreq (which is different for each file)
%                       - {'beta','delta'} will overlay both
%                       - 'all' will do all ranges (not stim freq)
%
%       stimfreqs       which stimulation frequencies should be included?
%                       [] -> then all are included
%                       [4]-> then 4Hz
%                       [4 20] -> then all stim frequencies between 4hz
%                                 and 20hz (included) are used
%
%


DoTitle=1;                             %Include titles
frange=[0 50];                         %frequencies ([]=auto)
incrrange=[-20 100];                   %increases ([]=auto)
incrtitle=['% Increase'];              %if '', leave out
ftitle='Stimulation Frequencies (Hz)'; %if '', leave out
plotcolors={'r','b','y','k','g','m','c'};

%check for validity of request
if isequal(rangename,'stimfreq') 
    if ~ismember(varname,{'IncreaseSpectrum1AtStimFreq','IncreaseSpectrum2AtStimFreq','IncreaseCoherenceAtStimFreq'})
        waitfor(warndlg('This variable does not make sense for analysis at stimfreq'));
        return
    end
else
    if ~ismember(varname,{'IncreaseSpectrum1AtFreq','IncreaseSpectrum2AtFreq','IncreaseCoherenceAtFreq'})
        waitfor(warndlg('This variable does not make sense for analysis at this range'));
        return
    end
end

%if we are doing more than just an animal, get filename for analysis
if isequal(idname,'')
    %Optionally prompt user for filename
    if isequal(filename,'')
           [fn,fp]=uigetfile('*.mat','Select AllAnalysis file'); 
           filename=[fp fn];
    end

    %Load in analysis file
    load(filename);
    NumberOfGenoTypes=size(genotypes,2);
else
    %Place in cell array
    if ~iscell(idname)
        idname={idname};
    end
    nranimals=length(idname);
    
    waitfor(warndlg('You will be asked to select the parent directory, that contains these mice dir within geno dir'));
    %We are just doing given animals, so recalc for just this one. 
    [FO,~,~,~]=GroupAnalysis('');
    fofilter=zeros(1,size(FO,2));
    for i_a=1:nranimals
        fofilter=fofilter+strcmp({FO.mouseid},idname{i_a});
    end
    fofilter=(fofilter>0);
    FO=FO(fofilter);
    AllData=CombineData(FO);
    NumberOfGenoTypes=size(AllData,2);
    stimfrequencies=unique([FO.stimfreq]);
    genotypes={AllData.genotype};
end

%Identify the range we look at
freqranges=AllData(1).freqranges;
if isequal(rangename,'stimfreq')
    %only show change at stimfreq
    rangeindex=1;
    nrranges=1;
    rangename={'stimfreq'};
    
elseif isequal(rangename,'all')
    %show changes at all defined ranges
    rangename=fields(freqranges)';
    nrranges=length(rangename);
    rangeindex=[1:nrranges];
elseif iscell(rangename)
    %multiple ranges
    rangeindex=[];
    for i_rn=1:length(rangename)
        rangeloc=find(strcmp(fields(freqranges),rangename{i_rn}))
        if isempty(rangeloc)
            rangeloc=0;
        end
        rangeindex=[rangeindex rangeloc];
    end
    nrranges=length(rangename);
else 
    rangeindex=find(strcmp(fields(freqranges),rangename));
    rangename={rangename};
    nrranges=1;
end

rangetitle='';
for i_r=1:nrranges
    rangetitle=[rangetitle ',' rangename{i_r}];
end

%Make sure these frequencies are present in analysis file
%Interpret empty list as wanting to see all
if isempty(stimfreqs)
    stimfreqs=stimfrequencies;
elseif length(stimfreqs)==1
    stimfreqs=stimfreqs;
elseif length(stimfreqs)==2
    freqfilter=logical((stimfrequencies>=stimfreqs(1)).*(stimfrequencies<=stimfreqs(2)));
    stimfreqs=stimfrequencies(freqfilter);
end
NumberOfStimFreqs=size(stimfreqs,2);

%Define the figure name and open the figure
figurename=['Increase at target range: ' rangetitle ', ' 'Varname: ' varname ', ' '#Stimfreqs:' num2str(length(stimfreqs))];
figure('Name', [figurename]);    


%Loop through genotypes, making separate figure(s) for each
for i_geno=1:NumberOfGenoTypes
    
    %Initialize the subplot (one for each geno type)
    subplot(NumberOfGenoTypes+1,1,i_geno)
    
    geno=genotypes{i_geno};
    MouseIDs=unique([AllData(i_geno).Data.included]);
    MouseIDs=[MouseIDs{1:end}];
    titlename=['Genotype: ' geno ', ' 'IDs: ' MouseIDs ', ' 'Varname: ' varname ', ' 'Range:' rangetitle];
    legnames={};
    %Possibly overlay multiple plots, depending on rangenames selected
    for i_rn=1:nrranges

        try
        %Extract relevant info for this plot 
        currentrange=rangename{i_rn};
        currentindex=rangeindex(i_rn);
        
        Data={AllData(i_geno).Data.(varname)};
        hold(gca,'on')
            for i_fr=1:NumberOfStimFreqs
               plot(stimfreqs(i_fr),Data{i_fr}(currentindex) ,['.' plotcolors{i_rn}]);
            end    
        hold(gca,'off')
        
        catch
           disp(['Could not make graph for ' rangename{i_rn}]); 
        end
    end
    
    if DoTitle
        title(titlename);
    end
    xlim(frange);
    ylim(incrrange);
    if ~isequal(ftitle,'')
        xlabel(ftitle);
    end
    if ~isequal(incrtitle,'')
        ylabel(incrtitle);
    end
end

%Plot with legend info
subplot(NumberOfGenoTypes+1,1,NumberOfGenoTypes+1)
for i_rn=1:nrranges
    hold(gca,'on');
    if rangeindex(i_rn)==0
        plot(0,0, plotcolors{i_rn}, 'DisplayName',['FAILED: ' rangename{i_rn}]);
    else
        plot(0,0, plotcolors{i_rn}, 'DisplayName',rangename{i_rn});
    end
    
    hold(gca,'off');
end
legend