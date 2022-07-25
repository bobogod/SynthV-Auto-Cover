function out = mel(x)
    %out=x(1);
    out=melSpectrogram(x',44100,'FrequencyRange',[20,20000],'NumBands',128,'FFTLength',2048,'WindowLength',441,'OverlapLength',305);
end

