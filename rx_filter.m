function [RX, rxDelay] = rx_filter(TX, SPS, rxFiltDecFactor)

rxfilter = comm.RaisedCosineReceiveFilter( ...
    'InputSamplesPerSymbol', SPS, ...
    'DecimationFactor', rxFiltDecFactor);

release(rxfilter);

RX = rxfilter(TX);
rxDelay = rxfilter.FilterSpanInSymbols;

end