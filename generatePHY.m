function [DATA, TX] = generatePHY(nPacks, M)

DATA = [];
TX = [];

for i=1:nPacks
    syncHeader = randi([0 M-1], 5*8, 1);
    phyHeader = randi([0 M-1], 8, 1);
    phyPayload = randi([0 M-1], 127*8, 1);
    PHY = [syncHeader' phyHeader' phyPayload'];
    
    DATA = [DATA PHY];
end

DATA = DATA';
TX = DATA;

end