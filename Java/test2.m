
[data, fs] = audioread('Recording 112534-110519a.wav');

vTime = (1:length(data))/fs; 

%a = ans.vPeakLoc;

hFig1 = figure();
plot(vTime, data(:,1));
load threshold.txt;

hold on;

for iOnset = 1:length(threshold)
   
    plot(threshold(iOnset)*32/fs*[1,1], [-1,1], 'r');
    
end

for iOnset = 1:length(a)
   
    plot(a(iOnset)*[1,1], [-1,1], ':k');
    
end

hold off;