function [RX, fixedDelaySym] = time_delay(RX, SPS, timingErr)

fixedDelay = dsp.Delay(timingErr);

release(fixedDelay);

RX = fixedDelay(RX);
fixedDelaySym = ceil(fixedDelay.Length/SPS);

end

