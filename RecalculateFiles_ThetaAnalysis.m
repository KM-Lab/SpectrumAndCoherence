function Results = RecalculateFiles_ThetaAnalysis(inputfolder,DoSave)
%Prompts user for a directory of analysis files. Does not consider subdirs,
%so call on each animal dir separately.
%6/4/2019
%Wrote to analyze theta in traces of filteredsets1. First did preliminary
%analysis using RecalculateFiles_ThetaAnalysis to find cutoffs. Now move
%forward to analyze those traces which have a theta/delta ratio of >=4.5

thetarange=[5,12];
deltarange=[1,3];
priortime=3;
duringtime=6;
threshold=4.5;

params.Fs=1000;
params.fpass=thetarange;
params.tapers=[3 5];
params.trialave=0;
params.pad=0;

Results=struct;
TraceResults=struct;

if isequal(inputfolder,'')
    inputfolder = uigetdir(pwd,'Select an input directory');
end

%Analyze files in the directory by stimulation parameters
%Will return structure array with fields 'folder','name','StimParams','Nr'

drctry = [inputfolder '/*.mat'];
FileList = dir(drctry);
FileList([FileList.isdir]) = []; %remove subdirectories from consideration
NumberOfFiles=length(FileList);

if ~isfield(FileList,'folder')
   disp('In matlab2016a and earlier, dir does not return field ''folder'' and so we''ll add it');
   for i_f=1:NumberOfFiles
       FileList(i_f).folder=inputfolder;
   end
end

i_tr=1;
%Loop through all files
for i_f=1:NumberOfFiles
    
    %Select file
    disp(['Processing file ' num2str(i_f) '/' num2str(NumberOfFiles)]);
    filename=[FileList(i_f).folder '\' FileList(i_f).name]
    Results(i_f).filename=filename;
    
    includelist=[]; %indices of those sets that exceed the threshold
    excludelist=[]; %indices of those sets that are too low
    powerprior=[];    %theta, delta, ratio
    powerduring=[];
    powerafter=[];
    thetaratioeffect=[];
    thetaraweffect=[];
    dominantfreqs=[];
    
        %% load in data into structure filedata
        filedata=load(filename);
        
        %% Obtain variables of interest (these are just examples)
        mouseid=filedata.mouseid;
        Results(i_f).mouseid=mouseid;
        
        filteredsets1=filedata.filteredsets1;
        fs=filedata.fs;
        params.Fs=fs;
        NumberOfSets=size(filteredsets1,2);

        %Create figure for current animal
        figure('Name',[mouseid]);
        plot1=subplot(4,3,1);
        title('Dominant Frequency in theta band');
        plot2=subplot(4,3,4);
        title('Power in Theta band');
        plot3=subplot(4,3,7);
        title('Theta/Delta ratio');
        plot4=subplot(4,3,3);
        title('Average trace');
        plot5=subplot(4,3,6);
        title('Average trace in theta band');
        plot6=subplot(4,3,2);
        title('Chronux psd of thetarange prior');
        plot7=subplot(4,3,5);
        title('Chronux psd of thetarange during');
        plot8=subplot(4,3,8);
        title('Chronux psd of thetarange after');
        
        plot9=subplot(4,3,9);
        title(plot9,'%Increase in theta (d & a)');
        
        plot10=subplot(4,3,10);
        title(plot10,'Dominant Frequency prior');
        
        plot11=subplot(4,3,11);
        title(plot11,'Dominant Frequency during');
        
        plot12=subplot(4,3,12);
        title(plot12,'Cheby filter bandpass');
        
        %Bandpass signal
        Fsp = 1000;                                     % Create Data
        Fn = Fsp/2;
        Wp = [5 12]/Fn;
        stopbandvar=0.1;
        Ws = [stopbandvar 1/stopbandvar].*Wp;
        Rp=3;
        Rs=30; 
        [n,Ws] = cheb2ord(Wp,Ws,Rp,Rs); 
        [z,p,k] = cheby2(n,Rs,Ws);
        [sos,g] = zp2sos(z,p,k);
        bpchebysets=filtfilt(sos,g,filteredsets1);
        bpsets=bandpass(filteredsets1,thetarange,fs);

        %Loop through traces
        for i_nr=1:NumberOfSets
            
            %Find the theta/delta ratio for the 3s prior to light
            priorset=filteredsets1(1:fs*priortime,i_nr);
            priorset=priorset-mean(priorset);
            thetapower=bandpower(priorset,fs,thetarange);
            deltapower=bandpower(priorset,fs,deltarange);
            thetadeltaratio=thetapower/deltapower;
            %Use prior theta/delta ratio to determine which traces to count
            if thetadeltaratio>=threshold
                includelist=[includelist; i_nr];
            else
                excludelist=[excludelist; i_nr];
            end
            powerprior=[powerprior; [thetapower,deltapower,thetadeltaratio]];
            
            %also find the power during 
            duringset=filteredsets1(fs*priortime+1:fs*duringtime,i_nr);
            duringset=duringset-mean(duringset);
            thetapower_d=bandpower(duringset,fs,thetarange);
            deltapower_d=bandpower(duringset,fs,deltarange);
            thetadeltaratio_d=thetapower_d/deltapower_d;
            powerduring=[powerduring; [thetapower_d,deltapower_d,thetadeltaratio_d]];
            
            %also find the power after 
            afterset=filteredsets1(fs*duringtime+1:end,i_nr);
            afterset=afterset-mean(afterset);
            thetapower_a=bandpower(afterset,fs,thetarange);
            deltapower_a=bandpower(afterset,fs,deltarange);
            thetadeltaratio_a=thetapower_a/deltapower_a;
            powerafter=[powerafter; [thetapower_a,deltapower_a,thetadeltaratio_a]];
            
            %Calculate increases in theta/delta ratio wrt prior
            increase_d=100*(thetadeltaratio_d-thetadeltaratio)/thetadeltaratio;
            increase_a=100*(thetadeltaratio_a-thetadeltaratio)/thetadeltaratio;
            thetaratioeffect=[thetaratioeffect;[thetadeltaratio,thetadeltaratio_d,thetadeltaratio_a,increase_d,increase_a]];
            
            %Also store raw theta power and increases in it
            incr_d=100*(thetapower_d-thetapower)/thetapower;
            incr_a=100*(thetapower_a-thetapower)/thetapower;
            thetaraweffect=[thetaraweffect;[thetapower,thetapower_d,thetapower_a, incr_d, incr_a]];
            
            %Determine dominant frequency for each trace prior,during,post
            %in the theta band
            [pow_p,freq_p]=mtspectrumc(priorset,params);
            [pow_d,freq_d]=mtspectrumc(duringset,params);
            [pow_a,freq_a]=mtspectrumc(afterset,params);
            
            [~,loc]=max(pow_p); dominantfreq_p=freq_p(loc);
            [~,loc]=max(pow_d); dominantfreq_d=freq_d(loc);
            [~,loc]=max(pow_a); dominantfreq_a=freq_a(loc);
            dominantfreqs=[dominantfreqs;[dominantfreq_p dominantfreq_d dominantfreq_a]];
            
            %Update plots
            if thetadeltaratio>=threshold %only add to graph if on include list
                hold(plot1,'on');
                plot(plot1,[1 2 3], [dominantfreq_p dominantfreq_d dominantfreq_a]);
                hold(plot1,'off');
                
                hold(plot2,'on');
                plot(plot2,[1 2 3],[thetapower thetapower_d thetapower_a]);
                hold(plot2,'off');
                
                hold(plot3,'on');
                plot(plot3,[1 2 3],[thetadeltaratio thetadeltaratio_d thetadeltaratio_a]);
                hold(plot3,'off');
                
                hold(plot4,'on');
                plot(plot4,filteredsets1(:,i_nr));
                hold(plot4,'off');
                
                hold(plot5,'on');
                plot(plot5,bpsets(:,i_nr));
                hold(plot5,'off');
                
                hold(plot12,'on');
                plot(plot12,bpchebysets(:,i_nr));
                hold(plot12,'off');
                
                
                hold(plot6,'on');
                plot(plot6,freq_p,pow_p);
                hold(plot6,'off');
                
                hold(plot7,'on');
                plot(plot7,freq_d,pow_d);
                hold(plot7,'off');

                hold(plot8,'on');
                plot(plot8,freq_a,pow_a);
                hold(plot8,'off');
            end
            
            TraceResults(i_tr).mouseid=mouseid;
            TraceResults(i_tr).tracenr=i_nr;
            TraceResults(i_tr).maxampl=max(filteredsets1(:,i_nr));
            if thetadeltaratio>=threshold 
                TraceResults(i_tr).include=1;
            else
                TraceResults(i_tr).include=0;
            end
            TraceResults(i_tr).thetapower=thetapower;
            TraceResults(i_tr).thetapower_d=thetapower_d;
            TraceResults(i_tr).thetapower_a=thetapower_a;
            TraceResults(i_tr).thetapowerincr_d=incr_d;
            TraceResults(i_tr).thetapowerincr_a=incr_a;
            TraceResults(i_tr).deltapower=deltapower;
            TraceResults(i_tr).deltapower_d=deltapower_d;
            TraceResults(i_tr).deltapower_a=deltapower_a;
            
            TraceResults(i_tr).thetadeltaratio=thetadeltaratio;
            TraceResults(i_tr).thetadeltaratio_d=thetadeltaratio_d;
            TraceResults(i_tr).thetadeltaratio_a=thetadeltaratio_a;
            TraceResults(i_tr).thetadeltaratioincr_d=increase_d;
            TraceResults(i_tr).thetadeltaratioincr_a=increase_a;
            TraceResults(i_tr).dominantfreq_p=dominantfreq_p;
            TraceResults(i_tr).dominantfreq_d=dominantfreq_d;
            TraceResults(i_tr).dominantfreq_a=dominantfreq_a;
            TraceResults(i_tr).shiftdominantfreq_d=dominantfreq_d-dominantfreq_a;
            TraceResults(i_tr).absdifffromtarget_p=abs(dominantfreq_p-6.667);
            TraceResults(i_tr).absdifffromtarget_d=abs(dominantfreq_d-6.667);
            TraceResults(i_tr).absdifffromtarget_a=abs(dominantfreq_a-6.667);
            i_tr=i_tr+1;
            
            
        end
        Results(i_f).numberoftraces=NumberOfSets;
        Results(i_f).numberexceeds=size(includelist,1);
        Results(i_f).percexceeds=100*Results(i_f).numberexceeds/NumberOfSets;
        Results(i_f).powerall=[powerprior powerduring powerafter];
        Results(i_f).powerprior=powerprior;
        Results(i_f).powerduring=powerduring;
        Results(i_f).powerafter=powerafter;
        Results(i_f).filteredsets1=filteredsets1;
        Results(i_f).bpsets=bpsets;
        Results(i_f).includelist=includelist;
        Results(i_f).excludelist=excludelist;
        Results(i_f).thetaratioeffect=thetaratioeffect;
        Results(i_f).thetaraweffect=thetaraweffect;
        Results(i_f).dominantfreqs=dominantfreqs;
        Results(i_f).absdifffromtarget=abs(dominantfreqs-6.667);
        
        %Add averaged results per animal
        %Only count those that exceed
        Results(i_f).avgthetadeltaratio_p=mean(powerprior(includelist,3));
        Results(i_f).avgthetadeltaratio_d=mean(powerduring(includelist,3));
        Results(i_f).avgthetadeltaratio_a=mean(powerafter(includelist,3));
        Results(i_f).avgpercincreaseratio_d=mean(thetaratioeffect(includelist,4));
        Results(i_f).avgpercincreaseratio_a=mean(thetaratioeffect(includelist,5));
    
        Results(i_f).avgtheta_p=mean(powerprior(includelist,1));
        Results(i_f).avgtheta_d=mean(powerduring(includelist,1));
        Results(i_f).avgtheta_a=mean(powerafter(includelist,1));
        Results(i_f).avgpercincreasetheta_d=mean(thetaraweffect(includelist,4));
        Results(i_f).avgpercincreasetheta_a=mean(thetaraweffect(includelist,5));
        Results(i_f).avgdominantfreq_p=mean(dominantfreqs(includelist,1));
        Results(i_f).avgdominantfreq_d=mean(dominantfreqs(includelist,2));
        Results(i_f).avgdominantfreq_a=mean(dominantfreqs(includelist,3));
        
        absshift=abs(abs(dominantfreqs(includelist,2)-6.6667)-...
                     abs(dominantfreqs(includelist,1)-6.6667));
        Results(i_f).avgabsshiftdominantfreq_d=mean(absshift);
        tempdata=Results(i_f).absdifffromtarget;
        Results(i_f).avgabsdifffromtarget_p=mean(tempdata(includelist,1));
        Results(i_f).avgabsdifffromtarget_d=mean(tempdata(includelist,2));
        Results(i_f).avgabsdifffromtarget_a=mean(tempdata(includelist,3));
        
        %Median results
        Results(i_f).mediantheta_p=median(powerprior(includelist,1));
        Results(i_f).mediantheta_d=median(powerduring(includelist,1));
        Results(i_f).mediantheta_a=median(powerafter(includelist,1));
        Results(i_f).medianpercincreasetheta_d=median(thetaraweffect(includelist,4));
        Results(i_f).medianpercincreasetheta_a=median(thetaraweffect(includelist,5));
        Results(i_f).mediandominantfreq_p=median(dominantfreqs(includelist,1));
        Results(i_f).mediandominantfreq_d=median(dominantfreqs(includelist,2));
        Results(i_f).mediandominantfreq_a=median(dominantfreqs(includelist,3));
        Results(i_f).medianabsshiftdominantfreq_d=median(absshift);
        Results(i_f).medianabsdifffromtarget_p=median(tempdata(includelist,1));
        Results(i_f).medianabsdifffromtarget_d=median(tempdata(includelist,2));
        Results(i_f).medianabsdifffromtarget_a=median(tempdata(includelist,3));
        
        %Mode results after binning
        if 1
        %discretize(powerprior(includelist,:))
        
        %Results(i_f).modetheta_p=median(powerprior(includelist,1));
        %Results(i_f).modetheta_d=median(powerduring(includelist,1));
        %Results(i_f).modetheta_a=median(powerafter(includelist,1));
%         disc_stepsize=10
%         bins=[-100:disc_stepsize:100];
%         discY=discretize(thetaraweffect(includelist,4),bins);
%         [discm,discl]=max(discY);
%         modeY=[bins(discl),bins(discl)+disc_stepsize];
          thetastepsize=10;
          hd=histogram(plot9,thetaraweffect(includelist,4),'BinWidth',thetastepsize);
          [mv,ml]=max(hd.Values);
          Results(i_f).modepercincreasetheta_d=hd.BinEdges(ml)+0.5*thetastepsize;
          
          hold(plot9,'on');
          ha=histogram(plot9,thetaraweffect(includelist,5),'BinWidth',thetastepsize);
          title(plot9,'%Increase in Theta');
          hold(plot9,'off');
          [mv,ml]=max(ha.Values);
          Results(i_f).modepercincreasetheta_a=ha.BinEdges(ml)+0.5*thetastepsize;
          
          domfreq_stepsize=0.25;
          h1=histogram(plot10,dominantfreqs(includelist,1),'BinWidth',domfreq_stepsize,'DisplayStyle','bar');
          title(plot10,'Dominant Frequency');
          [mv,ml]=max(h1.Values);
          Results(i_f).modedominantfreq_p=h1.BinEdges(ml)+0.5*domfreq_stepsize;
          
          hold(plot10,'on');
          h2=histogram(plot10,dominantfreqs(includelist,2),'BinWidth',domfreq_stepsize,'DisplayStyle','bar');
          [mv,ml]=max(h2.Values);
          Results(i_f).modedominantfreq_d=h2.BinEdges(ml)+0.5*domfreq_stepsize;
          
          h3=histogram(plot10,dominantfreqs(includelist,3),'BinWidth',domfreq_stepsize,'DisplayStyle','stairs');
          [mv,ml]=max(h3.Values);
          Results(i_f).modedominantfreq_a=h3.BinEdges(ml)+0.5*domfreq_stepsize;
          hold(plot10,'off');

        end 
        
        %Add averages to plots
        hold(plot1,'on');
        plot(plot1,[1 2 3], mean(dominantfreqs(includelist,:),1),'LineWidth',2,'Color','r');
        plot(plot1,[1 2 3], median(dominantfreqs(includelist,:),1),'LineWidth',2,'Color','g');
        plot(plot1,[1,2,3], [Results(i_f).modedominantfreq_p,Results(i_f).modedominantfreq_d,Results(i_f).modedominantfreq_a],'LineWidth',2,'Color','y');
        hold(plot1,'off');

        hold(plot2,'on');
        plot(plot2,[1 2 3], mean(thetaraweffect(includelist,[1 2 3]),1),'LineWidth',2,'Color','r');
        plot(plot2,[1 2 3], median(thetaraweffect(includelist,[1 2 3]),1),'LineWidth',2,'Color','g');
        hold(plot2,'off');
        
        hold(plot3,'on');
        plot(plot3,[1 2 3], mean(thetaratioeffect(includelist,[1 2 3]),1),'LineWidth',2,'Color','r');
        plot(plot3,[1 2 3], median(thetaratioeffect(includelist,[1 2 3]),1),'LineWidth',2,'Color','g');
        hold(plot3,'off');

        hold(plot4,'on');
        plot(plot4,mean(filteredsets1(:,includelist),2),'LineWidth',2,'Color','r');
        hold(plot4,'off');

        hold(plot5,'on');
        plot(plot5,mean(bpsets(:,includelist),2),'LineWidth',2,'Color','r');
        hold(plot5,'off');
        
        
        hold(plot12,'on');
        plot(plot12,mean(bpchebysets(:,includelist),2),'LineWidth',2,'Color','r');
        hold(plot12,'off');
        
        %Add averaged spectrogram 
        params.trialave=1;
        [pow_p,freq_p]=mtspectrumc(filteredsets1(1:3000,includelist),params);
        [pow_d,freq_d]=mtspectrumc(filteredsets1(3001:6000,includelist),params);
        [pow_a,freq_a]=mtspectrumc(filteredsets1(6001:end,includelist),params);
        params.trialave=0;
        hold(plot6,'on');
        plot(plot6,freq_p,pow_p,'LineWidth',2,'Color','r');
        hold(plot6,'off');        
        hold(plot7,'on');
        plot(plot7,freq_d,pow_d,'LineWidth',2,'Color','r');
        hold(plot7,'off');        
        hold(plot8,'on');
        plot(plot8,freq_a,pow_a,'LineWidth',2,'Color','r');
        hold(plot8,'off');        

        %linkaxes
        linkaxes([plot6,plot7,plot8],'y')
        names = {'p'; 'd'; 'a'};
        set(plot1,'xtick',[1:3],'xticklabel',names)
        set(plot2,'xtick',[1:3],'xticklabel',names)
        set(plot3,'xtick',[1:3],'xticklabel',names)
        savefig(mouseid);
end
save(['AllResults___' datestr(now,'mm_dd_yyyy__HH_MM_SS')],'Results','TraceResults');
