function [RX] = symbol_sync(RX)

symbolSync = comm.SymbolSynchronizer( ...
    'SamplesPerSymbol', 2);

release(symbolSync);

RX = symbolSync(RX);

end