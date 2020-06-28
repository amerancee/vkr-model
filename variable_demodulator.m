function [RX] = variable_demodulator(RX, M)


dpskdemod = comm.DPSKDemodulator(M, 0);

RX = dpskdemod(RX);

end