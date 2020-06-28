function [TX] = variable_modulator(DATA, M)

dpskmod = comm.DPSKModulator(M, 0);

TX = dpskmod(DATA);

end