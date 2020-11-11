clear; clc; close all;
%%��������� ������
nPacks = 100;               % ���������� ������������ �������
SPS = 4;                    % �������� �� ������
rxFiltDecFactor = SPS/2;    % ��������� ������� �� ������� �������
modType = 'QPSK';           % ��� ���������
M = 4;                      % ������� ���������
FS = 1e6;                   % ������� �������������
timingErr = 5;              % ������������ �������� ��������� �������� (��������)
freqErr = 1e4;              % ������������ �������� ���������� ��������������� (��)
phaseErr = 45;              % ������������ �������� �������� ��������������� (��������)
EbN0_min = 3;               % ����������� �������� EbN0
EbN0_max = 15;              % ������������ �������� EbN0

%% ��������������� ������� � ������������� ����������
k = log2(M);
errs = [];

%% ����������
for EbN0 = EbN0_min:EbN0_max
    tx_accum = [];
    rx_accum = [];
    numErr = 0;
    attempts = 0;
    
    while (numErr < 100 && attempts < 100)
        attempts = attempts + 1;
        % ��������� ������������ ������� ������
        [DATA, TX] = generatePHY(nPacks, M);
        % ���������
        TX = variable_modulator(TX, M);
        % SRRC ������
        [TX, txDelay] = tx_filter(TX, SPS);
        %% �����
        % AWGN
        RX  = channel(TX, SPS, k, EbN0);
        %     % �������� ���������� ���������������
        RX = phase_frequency_offset(RX, FS, phaseErr, freqErr);
        %     % �������� �������� ��������
        [RX, fixedDelaySym] = time_delay(RX, SPS, timingErr);
        
        %% ��������
        % ������� SRRC ������ � ���������� = 2
        %      [RX, rxDelay] = rx_filter(RX, SPS, 4);
        [RX, rxDelay] = rx_filter(RX, SPS, rxFiltDecFactor);
        %     % ���������� �������������, ��������� = 2
        RX = symbol_sync(RX);
        %     % ���� ������ ������ �������� ������� � ��������� �������
        [RX, estFreqOffset] = fr_compensator(RX, FS, modType);
        %     % ���� ������ �������� ������� � ����
        RX = carrier_sync(RX, SPS, modType);
        % �����������
        RX = variable_demodulator(RX, M);
        
        %% ����������
        % ����������� �������� ��������
        %     sysDelay = dsp.Delay(txDelay/2 + rxDelay/2);
        %     compensatedData = sysDelay(DATA);
        sysDelay = dsp.Delay(fixedDelaySym + txDelay/2 + rxDelay/2);
        compensatedData = sysDelay(DATA);
        
        %����� ������� ������� ��� ������ BER, ������� � 30%-��
        trimmedTX = compensatedData(0.3*end:end);
        trimmedRX = RX(0.3*end:end);
        
        %����������� ������ ��� ����������, ���� ������ <100
        tx_accum = [tx_accum' trimmedTX']';
        rx_accum = [rx_accum' trimmedRX']';
        
        % ������� ����������
        [numErr, ber] = biterr(tx_accum, rx_accum);
        % [numErr,ber] = biterr(compensatedData, RX);
        
        % ������� ���������� ������� �� 100 ��������� �������. ���� ������
        % ������ ����, ������������ ���� ����������� ������� ������� ������
        % attempts
        if (numErr >= 100 || attempts == 100)
            errs = [errs ber];
            disp(['EbN0: ', num2str(EbN0), ...
                ', ��� �������������: ', num2str(length(rx_accum)), ...
                ', ������: ', num2str(numErr), ...
                ', BER: ', num2str(ber)]);
        end
    end
end

%% ����� ��������
% ������ ������������� �������� BER ��� ��������� ���� ���������
theoryBER = berawgn((EbN0_min:EbN0_max), 'dpsk', M);
% theoryBER = berawgn((EbN0_min:EbN0_max), 'psk',M,'nodiff');
% ���������� ���������� �������� BER
semilogy((EbN0_min:EbN0_max),errs, '-o')
hold on
% ���������� ������������ �������� BER
semilogy((EbN0_min:EbN0_max),theoryBER, '-*')
legend('Signal','Theory')
grid
xlim([EbN0_min EbN0_max])
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')

