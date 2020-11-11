clear; clc; close all;
%%ПАРАМЕТРЫ МОДЕЛИ
nPacks = 100;               % Количество передаваемых пакетов
SPS = 4;                    % Отсчетов на символ
rxFiltDecFactor = SPS/2;    % Децимация сигнала во входном фильтре
modType = 'QPSK';           % Тип модуляции
M = 4;                      % Порядок модуляции
FS = 1e6;                   % Частота дискретизации
timingErr = 5;              % Максимальное значение временной задержки (отсчетов)
freqErr = 1e4;              % Максимальное значение частотного рассогласования (гЦ)
phaseErr = 45;              % Максимальное значение фазового рассогласования (градусов)
EbN0_min = 3;               % Минимальное значение EbN0
EbN0_max = 15;              % Максимальное значение EbN0

%% ПРЕДВАРИТЕЛЬНЫЕ РАСЧЕТЫ И ИНИЦИАЛИЗАЦИЯ ПЕРЕМЕННЫХ
k = log2(M);
errs = [];

%% ПЕРЕДАТЧИК
for EbN0 = EbN0_min:EbN0_max
    tx_accum = [];
    rx_accum = [];
    numErr = 0;
    attempts = 0;
    
    while (numErr < 100 && attempts < 100)
        attempts = attempts + 1;
        % Генерация передаваемых пакетов данных
        [DATA, TX] = generatePHY(nPacks, M);
        % Модуляция
        TX = variable_modulator(TX, M);
        % SRRC фильтр
        [TX, txDelay] = tx_filter(TX, SPS);
        %% КАНАЛ
        % AWGN
        RX  = channel(TX, SPS, k, EbN0);
        %     % Внесение частотного рассогласования
        RX = phase_frequency_offset(RX, FS, phaseErr, freqErr);
        %     % Внесение задержки символов
        [RX, fixedDelaySym] = time_delay(RX, SPS, timingErr);
        
        %% ПРИЕМНИК
        % Входной SRRC фильтр с децимацией = 2
        %      [RX, rxDelay] = rx_filter(RX, SPS, 4);
        [RX, rxDelay] = rx_filter(RX, SPS, rxFiltDecFactor);
        %     % Символьная синхронизация, децимация = 2
        RX = symbol_sync(RX);
        %     % Блок грубой оценки смещения частоты и коррекция сигнала
        [RX, estFreqOffset] = fr_compensator(RX, FS, modType);
        %     % Блок оценки смещения частоты и фазы
        RX = carrier_sync(RX, SPS, modType);
        % Демодулятор
        RX = variable_demodulator(RX, M);
        
        %% СТАТИСТИКА
        % Компенсация задержки фильтров
        %     sysDelay = dsp.Delay(txDelay/2 + rxDelay/2);
        %     compensatedData = sysDelay(DATA);
        sysDelay = dsp.Delay(fixedDelaySym + txDelay/2 + rxDelay/2);
        compensatedData = sysDelay(DATA);
        
        %Берем отсчеты сигнала для оценки BER, начиная с 30%-го
        trimmedTX = compensatedData(0.3*end:end);
        trimmedRX = RX(0.3*end:end);
        
        %Накапливаем сигнал для статистики, пока ошибок <100
        tx_accum = [tx_accum' trimmedTX']';
        rx_accum = [rx_accum' trimmedRX']';
        
        % Подсчет статистики
        [numErr, ber] = biterr(tx_accum, rx_accum);
        % [numErr,ber] = biterr(compensatedData, RX);
        
        % Считаем статистику минимум по 100 набранным ошибкам. Если ошибок
        % крайне мало, ограничиваем сбор количеством попыток анализа пакета
        % attempts
        if (numErr >= 100 || attempts == 100)
            errs = [errs ber];
            disp(['EbN0: ', num2str(EbN0), ...
                ', Бит анализировано: ', num2str(length(rx_accum)), ...
                ', Ошибок: ', num2str(numErr), ...
                ', BER: ', num2str(ber)]);
        end
    end
end

%% ВЫВОД ГРАФИКОВ
% Расчет теоретических значений BER для заданного типа модуляции
theoryBER = berawgn((EbN0_min:EbN0_max), 'dpsk', M);
% theoryBER = berawgn((EbN0_min:EbN0_max), 'psk',M,'nodiff');
% Построение полученных значений BER
semilogy((EbN0_min:EbN0_max),errs, '-o')
hold on
% Построение теоретиеских значений BER
semilogy((EbN0_min:EbN0_max),theoryBER, '-*')
legend('Signal','Theory')
grid
xlim([EbN0_min EbN0_max])
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')

