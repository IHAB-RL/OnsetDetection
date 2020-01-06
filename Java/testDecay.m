

nSeconds = 1;
vFs = [100, 200, 400, 800, 1600];
nTau = 0.001;

hFig = figure();
hold all;

for iFs = 1:length(vFs)

    nDecay = 4096^(-1/vFs(iFs));
    
    vTime = linspace(0, nSeconds, vFs(iFs));

    vDecay = ones(vFs(iFs), 1);
    
    for iDecay = 2:length(vDecay)
       
        vDecay(iDecay) = nDecay*vDecay(iDecay-1);
        
    end

    
    
    
    plot(vTime, vDecay);

end

hold off;