clear;
% Create an audioDeviceReader System object --> ����� �Է���ġ ���� ��ü ����
deviceReader = audioDeviceReader;
setup(deviceReader);

%% Record 25 seconds of sound
disp('Recording...')
tic;
Signal = [];
while toc < 25
    acquiredAudio = deviceReader(); %deviceReader()�� �� �������� ������ �Է���ġ�κ��� �Է¹޴´�.
    Signal = [Signal; acquiredAudio]; %MATLAB���� ���� ���� ;�� ���� ������ �̾߱� �Ѵ� ��, �� �ڵ�� �� �������� �ϳ��� ������ �ϴ� ����� ����� ���̴�.
end
disp('Recording complete.')
Signal = Signal.'; %�׸��� �� ����� transpose�Ѵ�. Signal�� ǥ���ϸ� [������1, ������2, ������3]
%% Generate modulator (bit�� �������� ���ļ� ��ȣ�� �̿��Ͽ� modulate)
i = 1:16; %[1, 2, ... , 16] ���������� ���� ����
t = 1:2000; %[1, 2, ... , 2000] ���������� ���� ����
tg = 1:2000; %[1, 2, ... , 2000] ���������� ���� ����
Fs = 500*i + 8000; %Fs = [8500, 9000, ..., 16000] ���� ����
Modulator = zeros(i(end),t(end)+tg(end)); % (16, 4000)�� zero array ����
for i = 1:length(i) %i 1���� 16���� �ݺ�
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i)); %(i, t)��ġ�� sin��
end

%% Create preamble (length 64)
preamble = zeros(1,16000); %(1, 16000) preamble zero array ����
tp = 1:12000; %[1, 2, ..., 12000] ���������� ���� ����
a= [1 1 1 -1 -1 -1 1 -1 -1 1 1 -1 1 -1 1];
b= [0 0 0 a a a];
preamble = b;
Preamble = reshape(preamble,[16,length(preamble)/16]).';    %bits�� [16, bits����/16]���� ��ȯ, Bits %bits�� ���� �̹��� ��ȯ
pre = [];  %data��� �迭 ����
for i = 1:size(Preamble,1)  %i�� 1���� bits/16��ŭ �ݺ�
    pre = [pre Preamble(i,:)*Modulator];  %data�� Bits �迭�̶� Modulator �迭�̶� i ������ ���Ͽ��� ����
end

%% Syncronize

[xC, lags] = xcorr(Signal,pre);
[~, idx] = max(xC);
startPoint = lags(idx);

%% Equalize (Demodulation�� �ʿ��� threshold ���, ���Ƿ� ��ü����)
rPreamble = Signal(startPoint:startPoint+15999);
Data = Signal(startPoint+16000:end);
tt = 1:16000;
Resp = zeros(1,16);
for i=1:16
    Resp(i) = abs(sum(rPreamble.*exp(-Fs*2*pi*tt/44100*(8000+500*Fs)))).^2;
end
% preamble�� �� ���ļ��� �Ŀ��� �����Ͽ� threshold ����

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
    bits = [bits resp>0.002];   % threshold ������ 1, �ƴϸ� 0
end

%% Plot
img_bits = zeros(1,64*64);
img_bits(1:length(bits)) = bits;
img_hat = reshape(img_bits.',[64,64]);
imshow(img_hat)

figure(2);
pspectrum(Signal,44100,'spectrogram')

release(deviceReader);