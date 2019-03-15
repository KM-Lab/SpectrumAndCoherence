%Given a set of traces of data, columns are different sets, find the
%outliers depending on definition within the function.
%
% Last Update: 2-19-2019        Chris Krook-Magnuson
%

function [cleantraces,dirtytraces,outliers]=RemoveOutliers(traces,DoDisplay,DoSaveFig)
    %INPUT
    %traces            1 or more columns of data of equal length, all traces
    %DoDisplay         0=do not show figure, 1=show figure on screen
    %DoSaveFig         0=do not save figure to disk, 1=save figure
    
    %OUTPUT
    %cleantraces         columns of data which were not outliers
    %dirtytraces         columns of outlier traces
    %outliers            indices of the outliers

        %In case of an empty dataset or 1 column of data, return it.
        if size(traces,2)<2
            cleantraces=traces;
            dirtytraces=[];
            outliers=[];
            return
        end

        %Initialize datastructures
        outliers=[];
        nrtraces=size(traces,2);
        maxpeaks=zeros(1,nrtraces);
        minpeaks=zeros(1,nrtraces);
        rangepeaks=zeros(1,nrtraces);
        meanpeaks=zeros(1,nrtraces);
        
        %Find range of data for each trace
        for i=1:nrtraces
            maxpeaks(i)=max(traces(:,i));
            minpeaks(i)=min(traces(:,i));
            rangepeaks(i)=maxpeaks(i)-minpeaks(i);
            meanpeaks(i)=mean(traces(:,i));
        end
        
        %Those sets with a range exceeding the mean by more than factor 2
        %are removed.
        for i=1:nrtraces
            if rangepeaks(i)>2*mean(rangepeaks) 
                outliers=[outliers,i];
            end
        end
   
        %return the correct sets
        cleantraces=traces;
        cleantraces(:,outliers)=[];
        dirtytraces=traces(:,outliers);
        
        if DoDisplay || DoSaveFig
           if DoDisplay
               vis='on'
           else
               vis='off'
           end
           popupoutlier=figure('Name','Remove Outliers','Visible',vis,'units','normalized','outerposition',[0 0 1 1]);
           
           %First plot - all data overlapping
           s1=subplot(3,1,1);
           plot(traces);
           title(['Overlay of all ' num2str(nrtraces) ' traces']);
           
           %Second plot - dirty sets overlapping
           s2=subplot(3,1,2);
           plot(cleantraces);
           title(['Overlay of ' num2str(length(outliers)) ' dirty traces']);
           
           %Third plot - clean sets overlapping
           s3=subplot(3,1,3);
           plot(dirtytraces);
           title(['Overlay of ' num2str(nrtraces-length(outliers)) ' clean traces']);
           
           linkaxes([s1,s2,s3],'xy');
           
           if DoSaveFig
              savefig(popupoutlier,['Remove Outliers ' datestr(now,'dd-mm-yyyy_HH-MM-SS')]);
           end
           if ~DoDisplay
              close(popupoutlier); 
           end
        end
end
        