%% 1. Load Data & Pengaturan
clear; clc; close all;

% Sesuaikan path dengan folder kamu
folderPath = 'C:\Users\gibra\OneDrive\Dokumen\pythonbelajar';
fileName = 'bpm85.csv';
fullPath = fullfile(folderPath, fileName);

% Membaca data tanpa header
opts = detectImportOptions(fullPath);
opts.VariableNamesLine = 0; 
data_table = readtable(fullPath, opts);

% AMBIL DATA GREEN (Kolom ke-5 berdasarkan analisis file kamu)
raw_green = double(data_table{:, 5}); 

%% 2. Parameter Sinyal (INI KUNCI PERBAIKANNYA)
Fs = 135; % BERUBAH: Data kamu aslinya 135 Hz, bukan 25 Hz
num_samples = length(raw_green);
t = (0:num_samples-1)' / Fs; 

%% 3. Pre-processing
% Karena data kamu sudah memiliki nilai negatif (sudah di-offset), 
% kita tidak perlu normalisasi jurnal yang / 262143.
% Cukup hilangkan Baseline Drift dengan detrend atau filter.
ppg_clean = detrend(raw_green); 

%% 4. Filtering (Sesuai Jurnal tapi disesuaikan ke Fs 135)
% Filter Bandpass 0.5 - 5 Hz
[b, a] = butter(3, [0.5 5]/(Fs/2));
filteredSignal = filtfilt(b, a, ppg_clean);

%% 5. Deteksi Puncak & Hitung BPM
% Jarak minimal antar puncak disesuaikan (0.5 detik pada 135Hz)
min_dist = 0.5 * Fs; 
[peaks, locs] = findpeaks(filteredSignal, 'MinPeakDistance', min_dist, ...
    'MinPeakHeight', std(filteredSignal)*0.5);

% Hitung BPM
RR_intervals = diff(locs) / Fs;
bpm_val = 60 / mean(RR_intervals);

% Tampilkan di layar
fprintf('====================================\n');
fprintf('HASIL ANALISIS (Fs = 135 Hz)\n');
fprintf('BPM Terdeteksi: %.2f\n', bpm_val);
fprintf('BPM dari Sensor (Kolom 6): %.2f\n', mean(data_table{:, 6}));
fprintf('====================================\n');

%% 6. Plotting
figure('Color', 'w');
subplot(2,1,1);
plot(t, raw_green, 'Color', [0 0.5 0]); 
title('Sinyal Mentah Green LED'); grid on;

subplot(2,1,2);
plot(t, filteredSignal, 'b', 'LineWidth', 1); hold on;
plot(t(locs), peaks, 'ro', 'MarkerFaceColor', 'r'); 
title(['Hasil Filter & Peak Detection (BPM: ', num2str(round(bpm_val)), ')']);
xlabel('Waktu (detik)'); grid on;