
[data, fs] = audioread('Recording 112534-110519a.wav');

vTime = (1:length(data))/fs; 
nBlocklen = 32;

%a = ans.vPeakLoc;

hFig1 = figure();
plot(vTime, data(:,1));
load threshold.txt;

hold on;

for iOnset = 1:length(threshold)
   
    plot(threshold(iOnset)*nBlocklen/fs*[1,1], [-1,1], 'r');
    plot(threshold(iOnset)*nBlocklen/fs*[1,1], [-1,1], 'b');
    plot(threshold(iOnset)*nBlocklen/fs*[1,1], [-1,1], 'g');
    plot(threshold(iOnset)*nBlocklen/fs*[1,1], [-1,1], 'm');
   
end

for iOnset = 1:length(a)
   
    plot(a(iOnset)*[1,1], [-1,1], ':k');
    
end

hold off;