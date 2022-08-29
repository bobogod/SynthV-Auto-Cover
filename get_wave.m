close all

%% load wav
[x,fs]=audioread('aurora.wav');
bin=0.1; %100ms*2 bin for fft
step=0.01; %calc every 10ms
L=(bin*2)*fs+1; %length of each bin
timesteps=bin+step:step:length(x)/fs-bin;
Tone=zeros(round(L/2)+1,length(timesteps)); 
F0=nan(1,length(timesteps));
power=log10(x(:,1).^2+1); 


%% load midi

mid=readmidi("aurora.mid");
mid(:,4)=261.6*2.^((mid(:,4)-60)/12);
for i=2:length(x)
    if power(i)>3e-4 && power(i-1)<3e-4
        wave_onset=i/fs;
        break;
    end
end
midi_onset=mid(1,6);
% midi_onset=wave_onset;

%% waveform with fft, according to midi
x_fft=fft(x(1:2*bin*fs+1));
t=abs(x_fft); t=t(1:round(L/2+1)); 
f=fs*(0:(L/2))/L;

i_tone=1;
for i=timesteps
    x_fft=fft(x(round((i-bin)*fs):round((i+bin)*fs)));
    t=abs(x_fft); t=t(1:round(L/2)+1); 
    
    
    tt=find(mid(:,6)-midi_onset<i-wave_onset);
    if ~isempty(tt)
        pitch_mid=mid(tt(end),4);
    else
        pitch_mid=20;
    end
    
    if abs(x(round(i*fs)))>0.0005
        t_index=find(f>pitch_mid/1.414 & f<pitch_mid*1.414);
        tt=t(f>pitch_mid/1.414 & f<pitch_mid*1.414);
        tt=abs(tt)./abs(log2(t(t_index)./pitch_mid));
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
F0=movmean(F0,5,'omitnan');

%% plot
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




%% Kalman filter
% THIS IS A MODEL OF Linear motion
% x=[p;v]
% p(t)=p(t-1)+v(t-1)*dt+u(t)*dt^2/2
% v(t)=v(t-1)+u(t)*dt
% let F=[1,dt;0,1], B=[dt^2/2;dt]
% thus, x_estimate(t)=F*x(t-1)+B*u(t)
% However,x_real(t)!=x_estimate(t)
% we need to measure how good the predicted x is

% we measure it use transform matrix P 
% since cov(AX,BX)=Acov(X,X)B',and P(t)=cov(Fx(t-1),Fx(t-1))
% P_estimate(t)=F*P(t-1)*F'+Q
% Q is noise of the model

% if we can measure the position, we define it as Z
% thus, Z=[1,0]*[p;v]+noise
% or we rewrite into this: Z=H*x_real(t)+v
% H is used for transforming x to z

% we combine Z and x to get x_real
% x_real(t)=x_estimate(t)+K(t)*(Z(t)-H*x_estimate(t))
% K(t) is a factor to determine the weight of Z and x
% K(t)=P_estimate(t)H'/(H*P_estimate(t)*H'+R)
% then we update P, P(t)=(I-K(t)*H)*P_estimate(t)

F0=F0; %F0 is what we measured, same as Z
A=0.7; %the degree to which the filtered F0 evolves, bigger A means smoother
B=0.85; %how much to believe in already extracted F0

X=[F0(1)]; %record all filtered F0
P=1; %initial data
F=[A,1-A;0,0]; %in this case, assume pitch(t)=A*pitch(t-1)+(1-A)*(B*F0(t)+(1-B)*pitch_mid)
Q=[0.1,0;0,0.1]; %we believe P is not that bad
H=[1 0]; %here we measure F0 only
R=1^2;  %???

for i=2:length(F0)
    pitch_now=F0(i); %used for pitch=[pitch pitch_now]
    tt=find(mid(:,6)-midi_onset<timesteps(i)-wave_onset);
    if ~isempty(tt)
        pitch_mid=mid(tt(end),4);
    else
        pitch_mid=NaN;
    end
    if ~isnan(X(end)) && ~isnan(F0(i)) && ~isnan(pitch_mid)
        pitch_now=F*[X(end);B*pitch_now+(1-B)*pitch_mid];  %our model: pitch remains the same
        P_=F*P*F'+Q; %SD of predicted pitch
        K=P_*H'/(H*P_*H'+R); %Kalman factor
        pitch_now=pitch_now+K*(pitch_mid-H*pitch_now);
        P=(1-K*H)*P_;        
    end
    if isnan(F0(i)) && ~isnan(X(end))
%         P=1; %initialize for next sentence
    end
    X=[X pitch_now(1)];
end
F0=X;



%% calc pitch drift
%log2(hz)=0.0833(or 1/12)index+7.948,index=1 <-> 261.6hz
%therefore, log2(freq/freq_midi)=0.0833(or 1/12)*cent/100

% 233.1HZ <-> 58; 261.6HZ <-> 60

pitch_drift=F0;
for i=1:length(F0)
    if ~isnan(F0(i))
        t=timesteps(i)-wave_onset+midi_onset;
        X=0;
        for j=2:length(mid(:,1))
            if mid(j,6)>t && mid(j-1,6)<t
                X=mid(j-1,4);
                break;
            end
        end
        
        pitch_drift(i)=log2(F0(i)/X)*1200;
    end
end
%pitch_drift=movmean(pitch_drift,5);
%pitch_drift=pitch_drift/1.25;
subplot(2,1,2)
plot(timesteps,pitch_drift)
    
C=1; %how much relative movement
f=fopen("pitch.txt",'w');
i_last=0;
for i=1:length(pitch_drift)
    if ~isnan(pitch_drift(i)) && ~isinf(pitch_drift(i))
        if i-i_last>3
            i_last=i;
            if abs(pitch_drift(i))<400
                fprintf(f,"%.3f %.1f\n",timesteps(i)+C*(-wave_onset+midi_onset),pitch_drift(i));
            end
        end
    end
end
fclose(f);