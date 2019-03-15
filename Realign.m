%There is a known variable discrepancy between recorder marked trigger
%times, and actual delivered pulses.  This function adds a structure
%array "pulsestamps" with timestamp information of actually delivered
%pulses, based on a channel receiving a copy of the TTL pulse data. 
function pulsestamps=Realign(filename,threshold,ch_trigger,ch_pulses,ch_target,do_append,do_show)
%
% INPUT:        filename        string of the full pathname and file name
%               threshold       amplitude cutoff used to distinguish pulses
%                               from baseline (used in FindTrains.m)
%               ch_trigger      channel number of (forced) trigger information
%               ch_pulses       channel number of copy of TTL pulses
%               ch_target       [channels...channels] array that will
%                               receive the new timestamp info
%               do_append       1   append 'pulsestamp' to the file
%                                   'filename'
%                               0   do not append the file
%               do_show         display the triggers and pulsetriggers
%                               in a plot in a new figure overlayed on pulses.
%
% OUTPUT:       pulsestamp      structure array where pulsestamp(i) is
%                               information on channel i. 
%                               Contains: pulsestamp.timestamp,
%                               pulsestamp.delays,
%                               pulsestamp.triggerchannel,
%                               pulsestamp.pulsechannel,
%                               pulsestamp.warning, pulsestamp.addedon,
%                               pulsestamp.threshold, pulsestamp.separation
%
% Uses:     FindTrains.m
% Used by:  ExtractSets.m
%
%
% Last change: 1-25-2019 Chris Krook-Magnson
%

disp('Running Realignment......');
load(filename,'fs');         %sampling frequency
load(filename,'trdata');     %trigger data
load(filename,'ledactive');  %duration of pulse
load(filename,'deadtime');   %space between starts
load(filename,'sbuf');       %load in all data
data=sbuf(:,ch_pulses);      %load in data on pulse channel
        
%Initialize structure array that will hold new information
try
    load(filename,'pulsestamps')
catch
    pulsestamps=struct();
end
        
%we are looking at the pulsechannel, and determining the start of
%pulse trains. However, the force triggers were setup at the
%trigger channel, so that is where we will get the trigger info
separation=floor(fs*(ledactive(ch_trigger)+deadtime(ch_trigger))/2);          %in datapoints
        
%indices of the start of pulsetrains
pulsetrains=FindTrains(data,separation,threshold);
numberoftrains=size(pulsetrains,2);
numberoftriggers=length(trdata(ch_trigger).timestamp)-2;
disp(['Found ' num2str(numberoftrains) ' pulses on channel ' num2str(ch_pulses)]);
disp(['Based on ' num2str(numberoftriggers) ' triggers on channel ' num2str(ch_trigger)]);
        
%convert to timestamps
startoffile = trdata(ch_pulses).timestamp(1);
endoffile=trdata(ch_pulses).timestamp(length(trdata(ch_pulses).timestamp));
newstamps = startoffile+(pulsetrains-1)/(3600*24*fs);
newstamps=[startoffile newstamps endoffile];
        
%Find delays between triggers in channel and pulsetrains in pulse
%channel. If discrepancy is too big, provide warning
delays=[];dodelays=1;
if dodelays%use the trains
  oldstamps=trdata(ch_trigger).timestamp;
  oldstamps=oldstamps(2:length(oldstamps)-1)-oldstamps(1);
  oldstamps=oldstamps*3600*24*fs;
  delays=[];
  for s=1:length(pulsetrains)
    %delay is defined as the number of data point between the trigger and
    %the start of the nearest spike train
    [m,i]=min(abs(oldstamps-pulsetrains(s)));
    delays=[delays ; pulsetrains(s)-oldstamps(i) s i];
    if abs(pulsetrains(s)-oldstamps(i))>100
        disp(['Big discrepancies in realignment of ' num2str(ch_trigger) ' of more than 100ms']);
        warndlg(['Big discrepancies in realignment of ' num2str(ch_trigger) ' of more than 100ms']);
    end
  end

if do_show
   figname=['Realignment from triggers on CH' num2str(ch_trigger) ' using pulses on CH' num2str(ch_pulses)];
   figure('name',figname);
   plot(data);                                                     %plot pulses
   hold on
   plot(oldstamps,threshold*ones(1,length(oldstamps)),'ro');       %overlay triggers
   plot(pulsetrains,threshold*ones(1,length(pulsetrains)),'g*');   %overlay pulsetriggers
   hold off
   drawnow;
end


warning='';
if length(oldstamps)<length(pulsetrains)
  warndlg([num2str(length(oldstamps)) '<' num2str(length(pulsetrains))]);
  warning='Something went wrong, the number of triggers is less than the number of pulses.';
  disp(warning);
end
disp(['Realignments between ' num2str(min(delays(:,1))) ' and ' num2str(max(delays(:,1)))]);
if 1
    %Update structure array for all target channels
    for i_target=1:length(ch_target)
        j=ch_target(i_target);
        pulsestamps(j).triggerchannel=ch_trigger;
        pulsestamps(j).pulsechannel=ch_pulses;
        pulsestamps(j).timestamp=newstamps;
        pulsestamps(j).threshold=threshold;
        pulsestamps(j).separation=separation;
        pulsestamps(j).delays=delays;
        pulsestamps(j).addedon=now();
        pulsestamps(j).warning=warning;
    end
        
    %add the structure array pulsestamps to the data file
    %if variable did not yet exist, it adds it, otherwise it overwrites the
    %value
    disp('All values saved in original file in structure array pulsestamp');
    if do_append
        save(filename,'pulsestamps','-append');
    end

else
    %only return the new pulsestamps but do not save it to file
end

        
end
        
    
    

