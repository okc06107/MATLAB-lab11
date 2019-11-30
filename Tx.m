% Transform img to binary sequence
img = imread('Lena.png'); %���� 256X256 ũ���� �̹���
img = imresize(img, 0.25);  % ������ bit�� ���� ���̷��� 0.25���� ���� ���� ���� (bit�� �ٲ�� Rx�� �ٸ� �Ķ���͵� ����)
img = imbinarize(img); %���������� ����Ǵ� �Ӱ谪���� ū ���� ��� 1�� �ٲٰ� �� �� ���� ��� 0���� �����Ͽ� ȸ���� ���󿡼� ���� ������ ����

bits = img(:); %����� �� ���� ���·� ��ȯ

% Generate modulator (bit�� �������� ���ļ� ��ȣ�� �̿��Ͽ� modulate)
i = 1:16; %[1, 2, ... , 16] ���������� ���� ����
t = 1:2000; %[1, 2, ... , 2000] ���������� ���� ����
tg = 1:2000; %[1, 2, ... , 2000] ���������� ���� ����
Fs = 500*i + 8000; %Fs = [8500, 9000, ..., 16000] ���� ����
Modulator = zeros(i(end),t(end)+tg(end)); % (16, 4000)�� zero array ����
for i = 1:length(i) %i 1���� 16���� �ݺ�
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i)); %(i, t)��ġ�� sin��
end

% Create preamble (length 64)
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

% Modulate bits to sinusoidal signal
Bits = reshape(bits,[16,length(bits)/16]).';    %bits�� [16, bits����/16]���� ��ȯ, Bits %bits�� ���� �̹��� ��ȯ
data = [];  %data��� �迭 ����
for i = 1:size(Bits,1)  %i�� 1���� bits/16��ŭ �ݺ�
    data = [data Bits(i,:)*Modulator];  %data�� Bits �迭�̶� Modulator �迭�̶� i ������ ���Ͽ��� ����
end

x = [pre data];    %preamble�� data�� ������� x���� ����
x = x./max(x);  %���� x�� max(x)�� normalize��
sound(x,44100)  %44100Hz sample rate�� ��ȣ x�� ����