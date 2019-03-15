function [S,Sperc,t,f]=CalculateSpectrumIncrease(sets,params,priortime)

%Moving time spectogram, for sets associated with channel
%disp('Calculate moving time spectogram');
[S,t,f]=mtspecgramc( sets, params.movingwin, params );

%Find average value of the pre-trigger period for each frequency
pre_t=t<priortime-params.movingwin(1)/2;      %indices for prior
S_p_avg=mean(S(pre_t,:),1);

%disp('adjusting/normalizing ');
Sperc=S;
for i=1:size(S,1)
   Sperc(i,:)=100*(Sperc(i,:)-S_p_avg)./S_p_avg;
end