%Filter 60Hz from signal
function newdata=Remove60HzNoise(data, fs)
remove60d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
               'DesignMethod','butter','SampleRate',fs);
newdata = filtfilt(remove60d,data);

