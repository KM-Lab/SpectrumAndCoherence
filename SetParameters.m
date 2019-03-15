% Sets all parameters for the Spectrum adn Coherence Analysis and stores
% them in a structure params, for easy passing to functions.
%
% Last Update: 02-22-2019       Chris Krook-Magnuson
%

function params=SetParameters

%Set what you want the program to do
params.do_remove_60hz=true;     %should we remove 60hz noise (directly after possible realignment, before taking subsets)
params.do_removeoutliers=true;  %use RemoveOutliers.m to remove outliers
params.do_plots=false;          %true -> show popup of spectrum&coherence for each file
                                %false -> don't show popups. 
params.do_saveplots=false;      %true -> save plots, even if do_plots=false
params.extension='jpg';         %Save the figures created if do_saveplots=true with this extension
                                %'jpg','fig','epsc','png'
                                %0 => don't save

%Let's the program realign files using a channel receiving a copy of the
%TTL pulse, rather than the triggers. If you do not realign, there is still perfect temporal alignment
%between the channels, but there can be a variable delay between when the software
%marked a trigger, and when the pulse is actually delivered.
params.do_realign=true;                
params.ch_trigger=1;             %the channel in the software for which (forced) triggers were specified
params.ch_pulses=5;              %the channel receiving a copy of the pulses
params.realign_threshold=0.5;    %amplitude threshold to pick up TTL pulses
params.doshow_realignment=0;     %show realignment in popup figure
%These channels will be used to realign the channels specified in the next section.

%Set interest parameters
params.channel1=1; params.channel2=2;   %Channels from which to take the data (both will be aligned if chosen above)
params.settingschannel=params.channel1; %Channel from which to take the settings
params.priortime=3;                     %Time prior to trigger to use in sample (in s)
params.treatmenttime=3;                 %Duration of treatment (in s)
params.posttime=6;                      %Time in seconds post trigger (including treatment time)
params.inputfolder='';                  %If '', user will be prompted for an input directory
params.outputfolder='';                 %If '', user will be prompted for an output files
params.mouseid='';                      %If '', user will be prompted for a mousid, which will be included in each analysis file
params.outputfilename='Analysis';       %outputfilename will be included in each output file

%Define frequency ranges
params.ranges.delta=[1 3];
params.ranges.fmtheta=[3 5];
params.ranges.theta=[5 12];
params.ranges.beta=[15 30];
params.ranges.lowgamma=[30 55];
params.ranges.highgamma=[70 90];
params.ranges.epsilon=[100 140];

%Define color bar ranges
params.cb_hp=[-20,100];
params.cb_tt=[-20,100];
params.cb_coh=[-20,100];


%NOT CURRENTLY USED
%Determine which signals to exclude based on amplitude
%params.ylimit=2;               %limit of range in graphs
%params.amplitudecutoff=5;      %Any signal which exceeds the amplitude during the range around trigger is excluded


%Parameters for display purposes
params.dbrange=[-50 -20];      %Range of dB to include in color grams

%Parameters for the Chronux package (coherence calculations)
%params.Fs=fs;               Automatically set later in code
params.fpass=[0 150];       % band of frequencies to be kept
params.tapers=[2 3];        % taper parameters  %how to pick?%
params.pad=1;               % pad factor for fft
if 1                        
    params.err=[1 0.5];     % Jackknife error method with alpha level    
else
    params.err=0;
end
params.trialave=1;          % Should we average the trials
params.movingwin=[1, 0.1];
params.winseg=2*params.movingwin(1);

end