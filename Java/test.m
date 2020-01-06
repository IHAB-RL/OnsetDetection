
a = [1, -0.5];
b = [0.5];


% freqz(b, a)
blocklen = 128;

signal = randn(blocklen, 1);

mem = 0;
out = zeros(size(signal));

for iSample = 1:blocklen
    
    out(iSample) = b(1)*signal(iSample) - a(2)*mem;
    mem = out(iSample);
    
    
end


out_filt = filter(b, a, signal);

hFig1 = figure();
plot(signal, 'g');
hold on;
plot(out, 'k');
plot(out_filt, 'r:');
