function [C,Cperc,tC,fC,phi]=CalculateCoherenceIncrease(sets1,sets2,params,priortime)

[C,phi,~,~,~,tC,fC]=cohgramc(sets1,sets2,params.movingwin,params);

%disp('adjusting/normalizing ');
tC_filter=tC<priortime-params.movingwin(1)/2;
C_avg=mean(C(tC_filter,:),1);
Cperc=C;
for i=1:size(C,1)
   Cperc(i,:)=100*(Cperc(i,:)-C_avg)./C_avg;
end
