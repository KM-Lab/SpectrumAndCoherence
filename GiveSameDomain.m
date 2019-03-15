%Help function used when two sets don't have same domain
function [newd,newdata1,newdata2,didinterp]=GiveSameDomain(domain1, domain2, data1, data2)
    newd=domain1; 
    newdata1=data1; newdata2=data2;
    didinterp='';
    if length(domain1)>length(domain2)
        newdata2=interp1(domain2,data2,domain1).';
        newd=domain1;
        didinterp='Contains interpolated values';
    elseif length(domain2)>length(domain1)
        newdata1=interp1(domain1,data1,domain2).';
        newd=domain2;
        didinterp='Contains interpolated values';
    end
end