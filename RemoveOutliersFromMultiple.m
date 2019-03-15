function [cleantracescell,dirtytracescell,totaloutliers]=RemoveOutliersFromMultiple(tracescell,DoDisplay,DoSaveFig)
%Runs removeOutliers on multiple sets of data and throws them out of all
%sets if they need to be thrown out of one set
% cleantracescell       Cell Array of only those traces that aren't thrown out by ANY of the sets
% dirtytracescell       Cell Array of the bad traces for each
% outliers              Those traces that were bad for ANY of the sets

number_of_sets=size(tracescell,2);
dirtytracescell=cell(1,number_of_sets);
cleantracescell=cell(1,number_of_sets);
totaloutliers=[];

%Run RemoveOutliers on each set
for i_c=1:number_of_sets
    traces=tracescell{i_c};
    [~,dirtytraces,outliers]=RemoveOutliers(traces,DoDisplay,DoSaveFig);

    dirtytracescell{i_c}=dirtytraces;
    totaloutliers=union(totaloutliers,outliers);
end

%Update the clean sets based on total outliers
for i_c=1:number_of_sets
    traces=tracescell{i_c};
    traces(:,totaloutliers)=[];
    cleantracescell{i_c}=traces;
end
