clear;
% Create an audioDeviceReader System object --> 오디오 입력장치 관련 객체 생성
deviceReader = audioDeviceReader;
setup(deviceReader);

%% Record 25 seconds of sound
disp('Recording...')
tic;
Signal = [];
while toc < 25
    acquiredAudio = deviceReader(); %deviceReader()는 한 프레임의 음성을 입력장치로부터 입력받는다.
    Signal = [Signal; acquiredAudio]; %MATLAB에서 벡터 안의 ;는 행의 나눔을 이야기 한다 즉, 이 코드는 한 프레임을 하나의 행으로 하는 행렬을 만드는 것이다.
end
disp('Recording complete.')
Signal = Signal.'; %그리고 이 행렬을 transpose한다. Signal을 표현하면 [프레임1, 프레임2, 프레임3]
%% Generate modulator (bit를 여러가지 주파수 신호를 이용하여 modulate)
i = 1:16; %[1, 2, ... , 16] 단위간격의 벡터 생성
t = 1:2000; %[1, 2, ... , 2000] 단위간격의 벡터 생성
tg = 1:2000; %[1, 2, ... , 2000] 단위간격의 벡터 생성
Fs = 500*i + 8000; %Fs = [8500, 9000, ..., 16000] 값을 가짐
Modulator = zeros(i(end),t(end)+tg(end)); % (16, 4000)의 zero array 생성
for i = 1:length(i) %i 1부터 16까지 반복
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i)); %(i, t)위치에 sin값
end

%% Create preamble (length 64)
preamble = zeros(1,16000); %(1, 16000) preamble zero array 생성
tp = 1:12000; %[1, 2, ..., 12000] 단위간격의 벡터 생성
a= [1 1 1 -1 -1 -1 1 -1 -1 1 1 -1 1 -1 1];
b= [0 0 0 a a a];
preamble = b;
Preamble = reshape(preamble,[16,length(preamble)/16]).';    %bits를 [16, bits길이/16]으로 변환, Bits %bits는 원래 이미지 변환
pre = [];  %data라는 배열 생성
for i = 1:size(Preamble,1)  %i를 1부터 bits/16만큼 반복
    pre = [pre Preamble(i,:)*Modulator];  %data에 Bits 배열이랑 Modulator 배열이랑 i 순서로 곱하여서 저장
end

%% Syncronize

[xC, lags] = xcorr(Signal,pre);
[~, idx] = max(xC);
startPoint = lags(idx);

%% Equalize (Demodulation에 필요한 threshold 계산, 임의로 대체가능)
rPreamble = Signal(startPoint:startPoint+15999);
Data = Signal(startPoint+16000:end);
tt = 1:16000;
Resp = zeros(1,16);
for i=1:16
    Resp(i) = abs(sum(rPreamble.*exp(-Fs*2*pi*tt/44100*(8000+500*Fs)))).^2;
end
% preamble의 각 주파수별 파워를 참고하여 threshold 정함

%% Detection & Demodulation
bits = [];
tt = 1:2000;
while(length(Data)>=4000)
    data = Data(1:2000);
    Data = Data(4001:end);
    resp = zeros(1,16);
    for k=1:16
        resp = abs(sum(data.*exp(-8000*2*pi*tt/44100*(Fs+500*8000)))).^2;
    end
        resp = resp./Resp; 
    bits = [bits resp>0.002];   % threshold 넘으면 1, 아니면 0
end

%% Plot
img_bits = zeros(1,64*64);
img_bits(1:length(bits)) = bits;
img_hat = reshape(img_bits.',[64,64]);
imshow(img_hat)

figure(2);
pspectrum(Signal,44100,'spectrogram')

release(deviceReader);