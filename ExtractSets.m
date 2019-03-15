% ExtractSets
% Last update: 2-22-2019        Chris Krook-Magnuson

function sets=ExtractSets(data,fs,triggerlist,priortime,treatmenttime,posttime)
%Given a dataset, a triggerlist with timestamps of triggers, and priortime,
%treatmenttime,posttime, extract datasubsets around those triggers of
%specified lengths.
%
%INPUT:         data                    column vector(s) of data
%               triggerlist             timestamps of trigger events, first
%                                       entry is start of file, last entry is end of file
%               fs                      sampling rate (Hz)
%               priortime               #s of data to keep prior to trigger
%               treatmenttime           #s of data is considered treatment
%                                          after trigger
%               posttime                #s of data to keep after the
%                                          trigger
%               params
%
%OUTPUT:        sets                    Subsets of data around triggers.
%                                       All have equal length


disp(['Running ExtractSets']);

%Initialize sets to empty
sets=[];

%Triggerlist has the triggers, either after realignment, or directly from file
filestart=triggerlist(1);                           %Start of file
fileend=triggerlist(length(triggerlist));           %End of file
triggerlist=triggerlist(2:length(triggerlist)-1);   %Remove non-triggers
    
for i=1:size(triggerlist,2)
    %Determine proper indices for time-domain around trigger
    trigger=(triggerlist(i)-filestart)*3600*24;    %calculate trigger time in seconds
    timetr=round(fs*trigger);
    timestart=timetr-fs*priortime;
    timeend=timetr+posttime*fs;
    timeint=timetr+fs*treatmenttime;
     
    if  round(1000*(trigger+posttime))<length(data) %only consider if trigger wasn't too close to the end
        %Add subset as column vector
        sets=[sets data(timestart:timeend)];
    end
    
  end %for i=1:length(triggerlist)



