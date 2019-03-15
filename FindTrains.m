%Given a dataset containing a baseline with spike trains, find the starts
%of the spike trains
function trains=FindTrains(data,separation,threshold)
%INPUT:     data            all the data, column vector or row vector
%           separation      minimum distance between start of trains (ms)
%                           MAKE SURE YOU SELECT A NUMBER LARGER THAN
%                           THE EXPECTED LENGTH OF A TRAIN
%           threshold       minimum amplitude to count as non-baseline
%
%OUTPUT:    trains          vector of indices of train starts
%
%      ex. FindTrains(sbuf(:,1),1000,1) will return the start of each spike
%      train exceeding 1, assuming trains are at most 1000ms long
%
%
%CALLED BY:     PlotAll.m, Realign.m
%

%Initialize
ln=length(data);             %length of the data
trains=[];                   %will contain the index of the start of each train
outtrainindex=-1*separation; %keeps track of the end of previous train. This initialization
                             %ensures the first train is found
intrain=0;                   %we assume we start out of a train

%Walk through the data and decide if we are in train or not in train.
%each time we enter a train, record the index.
i=1;
while i<=ln
    if ~intrain 
        %we are not yet in a train
        if data(i)>threshold
            %Enter a train
            intrain=1;
            if isempty(trains)
                trains=[i];
            elseif i-outtrainindex>separation
                trains=[trains i];
            end
        else
           %We are still not in a train
           i=i+1; 
        end
    else
        %We are already in a train, and try to find the end
        j=i;
        while data(j)>threshold && j<=ln
            %We are still in a train
            j=j+1;
        end
        i=j;
        outtrainindex=j;
        intrain=0;
        %We left the train or the file has ended (which also ends the train)
        %Next train must be more than separation away from current index
    end
end
        
