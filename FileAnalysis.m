function FileList=FileAnalysis(inputfolder,channel)
%Looks at all the files in the inputfolder and checks which files have
%matching parameters on the given channel.  If so, they will be combined in
%later stages.
%INPUT:
%   channel              %Channels of Interest
%   inputfolder          %The location of the Input Files
%
%OUTPUT:
%   FileList            %Structure array, with fields:
%                        name, folder, StimParams, Nr
%                        sorted by StimParams, and Nr indicates index wrt
%                        that stimulation parameter.
%
%LAST UPDATE:  2/21/2019    Chris Krook-Magnuson

%Get all files in the directory
if 1
    drctry = [inputfolder '/*.mat'];
    FileList = dir(drctry);
    FileList([FileList.isdir]) = []; %remove subdirectories from consideration
    NumberOfFiles=size(FileList,1);
end

try
    %remove fields we won't need
    FileList=rmfield(FileList,'date');
    FileList=rmfield(FileList,'bytes');
    FileList=rmfield(FileList,'isdir');
    FileList=rmfield(FileList,'datenum');
catch
    %probably an empty structure if this doesn't work
end

%Added to circumvent error Zoe got on 2-29-2019 where dir did not return
%folder as a field name
if ~isfield(FileList,'folder')
   disp('In matlab2016a and earlier, dir does not return field ''folder'' and so we''ll add it');
   for i_f=1:NumberOfFiles
       FileList(i_f).folder=inputfolder;
   end
end

%For each file, load in the parameters and use it to identify if there are
%multiple files with the same settings
for i_f = 1:NumberOfFiles

    %Load in relevant parameters from file
    patient = [FileList(i_f).folder '\' FileList(i_f).name];
    file=load(patient,'fs','ledon','ledoff','ledactive');
    
    %Save relevant variables
    fs=file.fs;                                         %Obtain the fs from the file
    ledon=file.ledon(channel);                          %#ms light is on
    ledoff=file.ledoff(channel);
    ledactive=file.ledactive(channel);
    
    %Add stimulation parameter information to file list
    FileList(i_f).StimParamsString=[num2str(ledon) '_' num2str(ledoff) '_' num2str(ledactive) '_' num2str(fs)];
    FileList(i_f).StimParams=[ledon ledoff ledactive fs];
end

%Reorder the structure array by stimulation parameter
[~,paramsorder]=sort({FileList.StimParamsString});
FileList=FileList(paramsorder);

%For each file, mark index of the file in the set 
%(check for multiple files with the same stimulation parameters)
FileList(1).Nr=1;
FileList(1).LastOfSet=1;
for i_f=2:NumberOfFiles
    if isequal(FileList(i_f).StimParams,FileList(i_f-1).StimParams)
        %Add to index if stimulation parameters match
        FileList(i_f).Nr=FileList(i_f-1).Nr+1;
        FileList(i_f).LastOfSet=1;
        FileList(i_f-1).LastOfSet=0;
    else
        %Reset index when stimulation parameters don't match
        FileList(i_f).Nr=1;
        FileList(i_f).LastOfSet=1;
    end
end