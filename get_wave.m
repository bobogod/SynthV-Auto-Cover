close all

%% load wav
[x,fs]=audioread('bigfish.wav');
bin=0.1; %100ms*2 bin for fft
step=0.01; %calc every 10ms
L=(bin*2)*fs+1; %length of each bin
timesteps=bin+step:step:length(x)/fs-bin;
Tone=zeros(round(L/2)+1,length(timesteps)); 
F0=nan(1,length(timesteps));
power=log10(x(:,1).^2+1); 


%% load midi
mid=readmidi("bigfish.mid");
mid(:,4)=261.6*2.^((mid(:,4)-60)/12);
for i=2:length(x)
    if power(i)>3e-4 && power(i-1)<3e-4
        wave_onset=i/fs;
        break;
    end
end
midi_onset=mid(1,6);


%% waveform with fft, according to midi
x_fft=fft(x(1:2*bin*fs+1));
t=abs(x_fft); t=t(1:L/2+1); 
f=fs*(0:(L/2))/L;

i_tone=1;
for i=timesteps
    x_fft=fft(x((i-bin)*fs:(i+bin)*fs));
    t=abs(x_fft); t=t(1:round(L/2)+1); 
    
    
    tt=find(mid(:,6)-midi_onset<i-wave_onset);
    if ~isempty(tt)
        pitch_mid=mid(tt(end),4);
    else
        pitch_mid=20;
    end
    
    if abs(x(round(i*fs)))>0.0005
        t_index=find(f>pitch_mid/1.1225 & f<pitch_mid*1.1225);
        tt=t(f>pitch_mid/1.1225 & f<pitch_mid*1.1225);
        tt=movmean(tt,3);
%         [tt index]=maxk(t,10); %top 10 peaks
%         index=index(tt>60 & tt<2500); %band-pass
        [ttt index]=max(tt); %peak with lowest frequency
        if pitch_mid>20
            F0(i_tone)=f(t_index(index));             
%             tt
        end
    end
    if i_tone>1 && abs(F0(i_tone)-F0(i_tone-1))>200; F0(i_tone)=NaN; end
       
    Tone(:,i_tone)=t;%zscore(t);
    i_tone=i_tone+1;        

end

F0(F0-mean(F0,'omitnan')>4*std(F0,'omitnan'))=NaN;
F0=movmean(F0,3,'omitnan');

%% tone with audio
figure
subplot(2,1,1)
hold on
x_tone=x(:,1);
for i=(bin+step)*fs:length(x)-bin*fs
    t=(i/fs-bin-step)/step+1;
    if round(t)<length(F0)
        x_tone(i)=x_tone(i)*200+F0(round(t));
    end
end
plot((1:length(x))/fs,x_tone);
plot((1:length(x))/fs,x(:,1)*100+200,'g')
plot(timesteps,F0,'r');
time_line2=line([0 0],[0 1500],'color','k');



%log2(hz)=0.0833(or 1/12)index+7.948,index=1 <-> 261.6hz
%therefore, log2(freq/freq_midi)=0.0833(or 1/12)*cent/100

% 233.1HZ <-> 58; 261.6HZ <-> 60

pitch_drift=F0;
for i=1:length(F0)
    if ~isnan(F0(i))
        t=timesteps(i)-wave_onset+midi_onset;
        pitch=0;
        for j=2:length(mid(:,1))
            if mid(j,6)>t && mid(j-1,6)<t
                pitch=mid(j-1,4);
                break;
            end
        end
        
        pitch_drift(i)=log2(F0(i)/pitch)*1200;
    end
end
pitch_drift=movmean(pitch_drift,5);
subplot(2,1,2)
plot(timesteps,pitch_drift)
    
f=fopen("pitch.txt",'w');
i_last=0;
for i=1:length(pitch_drift)
    if ~isnan(pitch_drift(i)) && ~isinf(pitch_drift(i))
        if i-i_last>5
            i_last=i;
            fprintf(f,"%.3f %.1f\n",timesteps(i)-wave_onset+midi_onset,pitch_drift(i));
        end
    end
end
fclose(f);