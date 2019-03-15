%Last Change: 02-24-2019    Chris Krook-Magnuson

%Get percent increase in spectrum during wrt spectrum prior at certain
%frequency or at coherence during wrt coherence prior at certain frequency
function [mean_prior, mean_during, increase]=FindIncreaseAtF(data_prior,data_during,f_prior,f_during,f_range)
% INPUT:    data_prior          row vector where each entry belongs to a freq in f_prior
%           data_during         row vector where each entry belongs to a freq in f_during
%           f_prior             frequencies for which data is measured in data_prior
%           f_during            frequencies for which data is measured in data_during
%           f_range             - either single frequency, in which case 1hz band around is taken
%                               - [f_start, f_stop] range of frequencies of interest
%
% OUTPUT:   mean_prior          mean of the prior data over freq-range
%           mean_during         mean of the during data over freq range
%           increase            increase (%)
%

%Obtain cutoffs
if size(f_range,2)==1 %at 1% band around given frequency
    f_start=f_range-0.5;
    f_stop=f_range+0.5;
else
    f_start=f_range(1);
    f_stop=f_range(2);
end

%Design filters
filter_prior=logical((f_prior<=f_stop).*(f_prior>=f_start));
filter_during=logical((f_during<=f_stop).*(f_during>=f_start));

%Pull out relevant data and mean over values
mean_prior=mean(data_prior(filter_prior));
mean_during=mean(data_during(filter_during));

%Calculate the increase
increase=100*(mean_during-mean_prior)/mean_prior;