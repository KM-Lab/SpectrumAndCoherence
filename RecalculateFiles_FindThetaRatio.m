function Results=RecalculateFiles_FindThetaRatio(inputfolder,DoSave)
%Prompts user for a directory of analysis files. Does not consider subdirs,
%so call on each animal dir separately.Find dirty traces, save
%filteredsets1, filteredsets2 and store old versions (preivously
%calculated, maybe differently) as old_filteredsets1,old_filteredsets2, 

Results=struct;

if isequal(inputfolder,'')
    inputfolder = uigetdir(pwd,'Select an input directory');
end

%Analyze files in the directory by stimulation parameters
%Will return structure array with fields 'folder','name','StimParams','Nr'

drctry = [inputfolder '/*.mat'];
FileList = dir(drctry);
FileList([FileList.isdir]) = []; %remove subdirectories from consideration
NumberOfFiles=length(FileList);

%Added to circumvent error Zoe got on 2-29-2019 where dir did not return
%folder as a field name
if ~isfield(FileList,'folder')
   disp('In matlab2016a and earlier, dir does not return field ''folder'' and so we''ll add it');
   for i_f=1:NumberOfFiles
       FileList(i_f).folder=inputfolder;
   end
end

figure;
subplot(1,1,1);
allpowerresults=[];
%Loop through all files
for i_f=1:NumberOfFiles
    
    %Select file
    disp(['Processing file ' num2str(i_f) '/' num2str(NumberOfFiles)]);
    filename=[FileList(i_f).folder '\' FileList(i_f).name]
    Results(i_f).filename=filename;
    
    try
        %% load in data into structure filedata
        filedata=load(filename);
        
        %% Obtain variables of interest (these are just examples)
        filteredsets1=filedata.filteredsets1;
        fs=filedata.fs;
        
        NumberOfSets=size(filteredsets1,2);
        if 1
            thetarange=[5,12];
            deltarange=[1,3];
            themthetarange=[3,8];
            themdeltarange=[2,3]
        end
        priortime=3;
        powerresults=[];
        threshold=4.5;
        nrexceeds=0;
        for i_nr=1:NumberOfSets
            
            currentset=filteredsets1(1:fs*priortime,i_nr);
            currentset=currentset-mean(currentset);
            thetapower=bandpower(currentset,fs,thetarange);
            deltapower=bandpower(currentset,fs,deltarange);
            thetadeltaratio=thetapower/deltapower;
            if thetadeltaratio>=threshold
                nrexceeds=nrexceeds+1;
            end
            themthetapower=bandpower(currentset,fs,themthetarange);
            themdeltapower=bandpower(currentset,fs,themdeltarange);
            themthetadeltaratio=themthetapower/themdeltapower;
            powerresults=[powerresults; [thetapower,deltapower,thetadeltaratio,...
                                         themthetapower,themdeltapower,themthetadeltaratio]];
        end
        Results(i_f).numberoftraces=NumberOfSets;
        Results(i_f).numberexceeds=nrexceeds;
        Results(i_f).percexceeds=100*Results(i_f).numberexceeds/NumberOfSets;
        hold on;
        plot(powerresults(:,6),powerresults(:,3),'.')
        hold off;
        
    catch
       disp(['Could not process file ' num2str(i_f) ': ' filename]);
    end
    
    
    
end

