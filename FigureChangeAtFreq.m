function FigureChangeAtFreq(AnalysisFile,FreqRange)
%Show change at stimulation frequency or at given parameter frequency range
%

if isequal(FreqRange,'stimfreq')
    FreqRangeName='Stimulation Frequency';
else
    FreqRangeName=['[' num2str(FreqRange(1)) ' ' num2str(FreqRange(2)) ']'];
end

%Obtain file overview
if isequal(AnalysisFile,'')
   [fn,fp]=uigetfile('*.mat','Select Analysis File'); 
   AnalysisFile=[fp '\' fn];
end

%Load in data
filedata=load(AnalysisFile);


figure('Name','Increase at Stimulation Frequency');



s1=subplot(2,3,1)
title('Increase Spectrum1 at stimulation frequency');
hold on
for i=1:5
    plot(cohtable(i,:,3),'.');
    
end
plot(mean(cohtable(1:5,:,3),1),'*');
hold off

s2=subplot(2,3,2)
title('Increase Spectrum2 at stimulation frequency');
for i=1:5
    hold on
    plot(cohtable(i,:,6),'.');
    hold off
end
hold on
plot(mean(cohtable(1:5,:,6),1),'*');
hold off

s3=subplot(2,3,3)
title('Increase Coherence at stimulation frequency');
for i=1:5
    hold on
    plot(cohtable(i,:,6),'.');
    hold off
end
hold on
plot(mean(cohtable(1:5,:,6),1),'*');
hold off


s3=subplot(2,2,3)
title('1s sliding window, neg');
for i=6:11
    hold on
    plot(cohtable(i,:,3),'.');
    hold off
end
hold on
plot(mean(cohtable(6:11,:,3),1),'*');
hold off

s4=subplot(2,2,4)
title('2s sliding window, neg');
for i=6:11
    hold on
    plot(cohtable(i,:,6),'.');
    hold off
end
hold on
plot(mean(cohtable(6:11,:,6),1),'*');
hold off

linkaxes([s1,s2,s3,s4],'y');