wav_index=8

%% load params
f=fopen('params.txt','r');
params=[];
times=[];
while ~feof(f)
    str = fgetl(f);
    t=split(str,' ');
    pitch_time=str2double(t{1});
    pitch=str2double(t{3});
    t=t(4:end);
    params=[params;0,0,0,0,0,pitch];
    times=[times;0,0,0,0,0,pitch_time];
    for i=1:length(t)
        tt=split(t{i},'+');
        params(end,i)=str2double(tt{1});
        times(end,i)=str2double(tt{2});
    end
end
fclose(f);

params=params(1000*wav_index-999:1000*wav_index,:);
times=times(1000*wav_index-999:1000*wav_index,:);

for i=1:5
    t1=params(:,i);
    t2=times(:,i);
    t=sortrows([t1,t2],2);
    params(:,i)=t(:,1);
    times(:,i)=t(:,2);
end
times=times*0.25;

%% load wav
[x,fs]=audioread([num2str(wav_index) '_Mixdown.wav']);
totaltime=length(x)/fs;
half_window=round(0.025*fs)

%% generate dataset at randomly pick time 
N_sample=4000;
samples=[];
i=0;
while i<N_sample
    t=round(rand()*length(x));
    flag=1;
    t_param=[0,0,0,0,0,0];
    for j=1:6
        t_left=times(times(:,j)<=t/fs,j);
        t_right=times(times(:,j)>=t/fs,j);
        if isempty(t_left) || isempty(t_right) || (length(t_left)>1 && t_left(end-1)==t_left(end)) || (length(t_left)>1 && t_left(1)==t_left(2)) || (t_left(end)==t_right(1))
            flag=0;
            break;
        end
        t_left=t_left(end);  t_right=t_right(1);
        p_left=params(times(:,j)<=t/fs,j);  p_left=p_left(end);
        p_right=params(times(:,j)>=t/fs,j); p_right=p_right(1);
        if j<6
            t_param(j)=p_left*(t_right-t/fs)/(t_right-t_left)+p_right*(t/fs-t_left)/(t_right-t_left);
        else
            t_param(j)=p_left;
        end
    end
        
    if flag
        i=i+1;
        samples=[samples;t,t_param];
    end
end

mels=[];
for i=1:N_sample
    xclip=x(samples(i,1)-half_window:samples(i,1)+half_window);
    MEL=melSpectrogram(xclip,fs,'FrequencyRange',[20,14000],'NumBands',128,'FFTLength',4096,'WindowLength',441,'OverlapLength',220);
    MEL=mean(MEL');
    mels=[mels;MEL];
end

index=load('index.mat').index;
for i=1:N_sample
    [~,F,~]=melSpectrogram(xclip,fs,'FrequencyRange',[20,14000],'NumBands',128,'FFTLength',4096,'WindowLength',441,'OverlapLength',220);
    MEL=mels(i,:);
    Param=samples(i,2:6);
    [~,MelPitch]=min(abs(F-261.6*2.^((samples(i,7)-60)/12)));
    if MelPitch<3
        i
        pause(); 
    end
    %plot((1:128)-MelPitch,MEL)
    %hold on
    save([sprintf('%05d',index),'.mat'],'MEL','Param','MelPitch');
    index=index+1;
end
save('index.mat','index');