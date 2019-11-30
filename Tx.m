% Transform img to binary sequence
img = imread('Lena.png'); %원래 256X256 크기의 이미지
img = imresize(img, 0.25);  % 보내는 bit의 수를 줄이려면 0.25보다 작은 수를 대입 (bit수 바뀔시 Rx의 다른 파라미터도 수정)
img = imbinarize(img); %전역적으로 적용되는 임계값보다 큰 값을 모두 1로 바꾸고 그 외 값은 모두 0으로 설정하여 회색조 영상에서 이진 영상을 생성

bits = img(:); %행렬을 열 벡터 형태로 변환

% Generate modulator (bit를 여러가지 주파수 신호를 이용하여 modulate)
i = 1:16; %[1, 2, ... , 16] 단위간격의 벡터 생성
t = 1:2000; %[1, 2, ... , 2000] 단위간격의 벡터 생성
tg = 1:2000; %[1, 2, ... , 2000] 단위간격의 벡터 생성
Fs = 500*i + 8000; %Fs = [8500, 9000, ..., 16000] 값을 가짐
Modulator = zeros(i(end),t(end)+tg(end)); % (16, 4000)의 zero array 생성
for i = 1:length(i) %i 1부터 16까지 반복
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i)); %(i, t)위치에 sin값
end

% Create preamble (length 64)
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

% Modulate bits to sinusoidal signal
Bits = reshape(bits,[16,length(bits)/16]).';    %bits를 [16, bits길이/16]으로 변환, Bits %bits는 원래 이미지 변환
data = [];  %data라는 배열 생성
for i = 1:size(Bits,1)  %i를 1부터 bits/16만큼 반복
    data = [data Bits(i,:)*Modulator];  %data에 Bits 배열이랑 Modulator 배열이랑 i 순서로 곱하여서 저장
end

x = [pre data];    %preamble과 data를 순서대로 x벡터 생성
x = x./max(x);  %벡터 x를 max(x)로 normalize함
sound(x,44100)  %44100Hz sample rate로 신호 x를 전송