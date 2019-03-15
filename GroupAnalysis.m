% Last Update: 02-22-2019       Chris  Krook-Magnuson

function [FileOverview,TotalNumberOfGeno,TotalNumberOfAnimals,TotalNumberOfFiles]=GroupAnalysis(inputdirectory)
%Given a directory containing subdirs for genotype, which contain subdirs
%for animals, which contain analysis files, return structure array with
%info on these files

FileOverview=struct;
%Prompt user to select directory. Code will consider subdirectories as
%genotype. It will summarize data from all animals in that
%genotype directory, for each stimulation frequency.
if isequal(inputdirectory,'')
    ifu = uigetdir;
else
    ifu=inputdirectory;
end

%Check what the subdirectories are, and remove . and .. form list
%Interpret subdirectories as the categories over which to average
subdirs=dir(ifu);
DirectoryNames = {subdirs([subdirs.isdir]).name};
DirectoryNames = DirectoryNames(~ismember(DirectoryNames,{'.','..'}));
NumberOfGenotypes=size(DirectoryNames,2);

%Loop through the genotype folders
index=0;
TotalNumberOfGeno=NumberOfGenotypes;
TotalNumberOfAnimals=0;
TotalNumberOfFiles=0;
for i_geno=1:NumberOfGenotypes
   Genotype=DirectoryNames{i_geno}; 
    
   %Check which animal folders are present in the directory
   AnimalNames=dir([ifu '\' DirectoryNames{i_geno}]);
   AnimalNames = {AnimalNames([AnimalNames.isdir]).name};
   AnimalNames = AnimalNames(~ismember(AnimalNames,{'.','..'}));
   NumberOfAnimals=size(AnimalNames,2);
   TotalNumberOfAnimals=TotalNumberOfAnimals+NumberOfAnimals;
   
   %Loop through each mouse ID folder in the genotype folder
   for i_id=1:NumberOfAnimals
       
       %Check which failes are present in the directory
       FileNames=dir([ifu '\' DirectoryNames{i_geno} '\' AnimalNames{i_id} '\*.mat']);
       FileNames={FileNames(~[FileNames.isdir]).name};
       NumberOfFiles=size(FileNames,2);
       TotalNumberOfFiles=TotalNumberOfFiles+NumberOfFiles
       
       %Loop through all files
       for i_f=1:NumberOfFiles
           
           index=index+1;
           location=[ifu '\' DirectoryNames{i_geno} '\' AnimalNames{i_id} '\' FileNames{i_f}];
           try
               load(location,'mouseid');
           catch
               mouseid=[AnimalNames{i_id} '( from folder)'];
           end
           
           try
               load(location,'stimfreq');
           catch
               stimfreqloc=strfind(location,'Hz');
               stimfreq=location(stimfreqloc(end)-2:stimfreqloc(end)-1);
               if isequal(stimfreq(1),'_')
                   stimfreq=str2num(stimfreq(2:end));
               else
                   stimfreq=str2num(stimfreq);
               end
           end
           try
               load(location,'nrtraces')
           catch
               nrtraces=0;
           end
           try
               load(location,'outliers')
               nroutliers=length(outliers);
           catch
               nroutliers=0;
           end
           
           FileOverview(index).location=location;
           FileOverview(index).genotype=Genotype;
           FileOverview(index).mouseid=mouseid;
           FileOverview(index).stimfreq=round(stimfreq);
           FileOverview(index).nrtraces=nrtraces;
           FileOverview(index).nroutliers=nroutliers;
           
           %Now FileOverview has overview of all files we will analyze next
       end
   end
end

