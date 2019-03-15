function FigureHeatmapsPerStim(filename,idname, varname,stimfreqs,cb_plot)
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
%
%       varname         the variable name you want plots for:
%                       options are:    S1perc,S2perc,Cperc, 
%
%       stimfreqs       which stimulation frequencies should be included?
%                       [] -> then all are included
%                       [4]-> then 4Hz
%                       [4 20] -> then all stim frequencies between 4hz
%                                 and 20hz (included) are used
%
%       cb_plot         range for imagesc color bars
%                       [] -> default is auto
%                       [0 100] -> 0 to 100, good start for %
%


DoTitle=1;                      %Include titles
trange=[3 6];                   %time ([]=auto)
frange=[0 50];                  %frequencies ([]=auto)
ttitle='Time (s)';              %if '', leave out
ftitle='Frequencies (Hz)';      %if '', leave out
layout=[3 3];                      %if [], auto layout
                                %[3 4] is 3 rows of 4 columns

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
    if ~iscell(idname)
        idname={idname};
    end
    nranimals=length(idname);
    
    waitfor(warndlg('You will be asked to select the parent directory, that contains this mouse dir within geno dir'));
    %We are just doing given animal, so recalc for just this one. 
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

%Make sure these frequencies are present in analysis file
%Interpret empty list as wanting to see all
if isempty(stimfreqs)
    stimfreqs=stimfrequencies
elseif length(stimfreqs)==1
    stimfreqs=stimfreqs;
elseif length(stimfreqs)==2
    freqfilter=logical((stimfrequencies>=stimfreqs(1)).*(stimfrequencies<=stimfreqs(2)));
    stimfreqs=stimfrequencies(freqfilter);
end
NumberOfStimFreqs=size(stimfreqs,2);


%Determine Layout for figure
if ~isempty(layout)
    nrcols=layout(2)
    nrrows=layout(1)
else
    nrrows=floor(sqrt(NumberOfStimFreqs));
    nrcols=ceil(NumberOfStimFreqs/nrrows);
end
perpage=nrrows*nrcols;
nrpages=ceil(NumberOfStimFreqs/perpage);

    
%Loop through genotypes, makeing separate figure(s) for each
for i_geno=1:NumberOfGenoTypes
    
    geno=genotypes{i_geno};
    MouseIDs=unique([AllData(i_geno).Data.included]);
    MouseIDs=[MouseIDs{1:end}];
    figurename=['Genotype: ' geno ', ' 'IDs: ' MouseIDs ', ' 'Varname: ' varname ', ' '#Stimfreqs:' num2str(length(stimfreqs))];
    
    %Extract relevant info for this plot
    Data={AllData(i_geno).Data.(varname)};
    if isequal(varname,'S1perc')
        t=AllData(i_geno).t1;
        f=AllData(i_geno).f1;
    elseif isequal(varname,'S2perc')
        t=AllData(i_geno).t2;
        f=AllData(i_geno).f2;
    elseif isequal(varname,'Cperc')
        t=AllData(i_geno).tC;
        f=AllData(i_geno).f2;
    end
    
    if isempty(trange)
        trange(1)=t(1);
        trange(2)=t(end);
    end
    if isempty(frange)
        frange(1)=f(1);
        frange(2)=f(end);
    end
    
    %Initialize indices for proper plotting
    i_fr=1;             %stim freq
    i_r=1;i_c=1;i_p=1;  %row, column, page
    newfig=1;
    while i_fr<NumberOfStimFreqs
        %Open new fig if needed
        if newfig
            figure('Name', [figurename ' (page ' num2str(i_p) '/' num2str(nrpages) ')']);    
            newfig=0;
        end

        %Display plot
        subplot(nrrows,nrcols,(i_r-1)*nrcols+i_c);
        imagesc(t,f,Data{stimfreqs(i_fr)}');
        set(gca,'YDir','normal')
        if isempty(cb_plot)
            caxis('auto')
        else
            caxis(cb_plot)
        end
        xlim(trange);
        ylim(frange);
        if ~isequal(ttitle,'')
           xlabel(ttitle); 
        end
        if ~isequal(ftitle,'')
           ylabel(ftitle); 
        end
        colorbar;
        if DoTitle
            title([num2str(stimfreqs(i_fr)) 'Hz']);
        end
        
        %Update indices
        i_c=i_c+1;
        i_fr=i_fr+1;
        if i_c>nrcols
            i_c=1;
            i_r=i_r+1;
        end

        if i_r>nrrows
            i_r=1;
            i_p=i_p+1;
            newfig=newfig+1;
            
        end    
    end
    
end