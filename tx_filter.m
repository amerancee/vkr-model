function [TX, txDelay] = tx_filter(TX, SPS)

txfilter = comm.RaisedCosineTransmitFilter( ...
    'OutputSamplesPerSymbol', SPS, ...
    'Gain', sqrt(SPS));

release(txfilter);

TX = txfilter(TX);
txDelay = txfilter.FilterSpanInSymbols;

end