function newdata=dbdata(olddata,DodB)
        if ~DodB
            newdata=olddata;
        else
            newdata=10*log10(olddata);
        end
    end