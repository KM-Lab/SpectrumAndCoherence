function Results=RecalculateFiles(inputfolder,DoSave)
%Prompts user for a directory of analysis files. Does not consider subdirs,
%so call on each animal dir separately.
%Load in basic info for each, perform a calculation or do something else, 
%Optionally save additional info /or overwritten info to each analysis file.
%THIS IS A TEMPLATE DESIGNED TO BE EDITED!!! NO POINT RUNNING IT AS IS
%MAKE CHANGES BETWEEN ROWS 34 AND 67

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
        fs=filedata.fs;
        filteredsets1=filedata.filteredsets1;
        filteredsets2=filedata.filteredsets2;
        %an example of how to deal with vars maybe not existing
        if isfield(filedata,'mouseid')
            mouseid=filedata.mouseid;
        else
            mouseid='unknown';
        end
    
        %% Do new calculations and define new variables (these are just examples)
        varname1=mean(filteredsets1,2);
        varname2=mean(filteredsets2,2);
        
        %% Add to datastructure that will collect data for each file 
        %(just example)
        Results(i_f).meansets1=varname1;
        Results(i_f).meansets2=varname2;
        
        %% Show something on screen (just an example)
        DoShowFigure='on'; %if 'off' then it won't show figures, but just save
        figure('Name','NewPopupplot','Visible',DoShowFigure);
        subplot(2,1,1); plot(filteredsets1);hold on; plot(varname1);hold off;
        subplot(2,1,2); plot(filteredsets2);hold on; plot(varname2);hold off;
        saveas(gcf,['Spectrum_' mouseid '_' datestr(now,'dd-mm-yyyy HH-MM-SS')],'jpg');
        if isequal(DoShowFigure,'off') %close the hidden figure
            close(gcf);
        end
        
        %% save (append to file. Will overwrite if var name already exists)
        if DoSave
            save(filename,'varname1','varname2','-append')
        end
    try    
    catch
       disp(['Could not process file ' num2str(i_f) ': ' filename]);
    end
    
end

