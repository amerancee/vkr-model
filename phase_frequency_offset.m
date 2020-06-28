function [RX] = phase_frequency_offset(RX, FS, phaseErr, freqErr)

pfo = comm.PhaseFrequencyOffset(...
    'PhaseOffset', phaseErr,  ...
    'FrequencyOffset', freqErr, ...
    'SampleRate', 4*FS);

release(pfo);

RX = pfo(RX);

end