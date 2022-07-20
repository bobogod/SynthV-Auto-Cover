[x,fs]=audioread('11_Mixdown.wav');

power=x.*x;

% plot((1:44100)/fs,power(1:44100))
% hold on
plot((1:length(x))/fs,x)
hold on
start_points=[];

for i=2:length(power)
    if power(i)>5e-4 && power(i-1)<5e-4
        if isempty(start_points) || (i-start_points(end))/fs>0.35
            start_points=[start_points i];
%             if i>15000 && i<16000
%                 start_points(end)=19000;
%             end
            line(start_points(end)/fs*[1 1],[-0.5 0.5],'color','k')
        end
    end
end

xlim([0,10])
clips=[];
clip_points=round(start_points-start_points(1)/3);
clip_bin=round(mean(diff(start_points)));
for i=1:length(clip_points)
    clips=[clips; x(clip_points(i):clip_points(i)+clip_bin)'];
end
% 
% index=load('index.mat').index;
% 
% for i=1:length(clip_points)
%     MEL=melSpectrogram(clips(i,:)',fs,'FrequencyRange',[20,20000],'NumBands',128,'FFTLength',2048,'WindowLength',441,'OverlapLength',315);
%     save([sprintf('%05d',index),'.mat'],'MEL');
%     index=index+1;
% end
% save('index.mat','index');