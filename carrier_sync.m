function [RX] = carrier_sync(RX, SPS, modType)

carrierSync = comm.CarrierSynchronizer( ...
    'SamplesPerSymbol', SPS/2, ...
    'Modulation', modType, ...
    'DampingFactor', 0.7);

RX = carrierSync(RX);

end