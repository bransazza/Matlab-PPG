%% 1. Load Data & Pre-processing (Sama seperti sebelumnya)
clear; clc; close all;

folderPath = 'C:\Users\gibra\OneDrive\Dokumen\pythonbelajar';
fileName = 'bpm85.csv';
fullPath = fullfile(folderPath, fileName);

data_table = readtable(fullPath, 'ReadVariableNames', false);
raw_green = double(data_table{:, 5}); 

Fs = 135; % Frekuensi sampling data kamu
num_samples = length(raw_green);
t = (0:num_samples-1)' / Fs;

%% 2. Heart Rate Filtering (Langkah Awal)
% Filter bandpass 0.5 - 5 Hz untuk mendapatkan denyut nadi yang bersih
[b_hr, a_hr] = butter(3, [0.5 5]/(Fs/2));
ppg_filtered = filtfilt(b_hr, a_hr, raw_green);

%% 3. Deteksi Puncak (Systolic Peaks)
% Mencari puncak-puncak detak jantung untuk melihat variasi amplitudonya
[peaks, locs] = findpeaks(ppg_filtered, 'MinPeakDistance', 0.5*Fs);

%% 4. Ekstraksi Sinyal Pernapasan (RIAV Method)
% Amplitudo puncak detak jantung akan naik-turun seiring tarikan napas.
% Kita ambil nilai 'peaks' sebagai sinyal baru (Respiratory Signal).
respiratory_signal_raw = peaks; 

% Hitung frekuensi sampling baru untuk sinyal pernapasan
% Karena sinyal ini diambil per-detak jantung, maka Fs_respiratory = Heart Rate / 60
Fs_res = length(peaks) / t(end); 

%% 5. Respiratory Filtering (Sesuai Jurnal)
% Filter Lowpass atau Bandpass sangat rendah (0.1 - 0.5 Hz) 
% untuk mengambil gelombang napas (6 - 30 napas per menit)
[b_rr, a_rr] = butter(3, [0.1 0.5]/(Fs_res/2));
respiratory_filtered = filtfilt(b_rr, a_rr, respiratory_signal_raw);

%% 6. Deteksi Puncak Napas & Hitung RR (Rumus 4.2-13 & 4.2-14)
% Mencari puncak pada gelombang napas yang sudah difilter
[rr_peaks, rr_locs] = findpeaks(respiratory_filtered, 'MinPeakDistance', 1.5*Fs_res);

% Menghitung interval antar napas
% RR_interval (s) = selisih lokasi puncak napas / Fs_res
RR_intervals = diff(rr_locs) / Fs_res;

% Menghitung Respiratory Rate dalam BrPM (Breaths Per Minute)
% RR = 60 / rata-rata interval
rr_val = 60 / mean(RR_intervals);

fprintf('====================================\n');
fprintf('HASIL ANALISIS RESPIRATORY RATE (RR)\n');
fprintf('RR Terdeteksi : %.2f BrPM (Napas/Menit)\n', rr_val);
fprintf('====================================\n');

%% 7. Visualisasi
figure('Color', 'w');

subplot(2,1,1);
plot(t, ppg_filtered, 'Color', [0.7 0.7 0.7]); hold on;
plot(t(locs), peaks, 'ro-');
title('Ekstraksi Variasi Amplitudo (RIAV)');
legend('PPG Signal', 'Amplitude Variation'); grid on;

subplot(2,1,2);
t_res = (0:length(respiratory_filtered)-1) / Fs_res;
plot(t_res, respiratory_filtered, 'b', 'LineWidth', 1.5); hold on;
plot(t_res(rr_locs), rr_peaks, 'ko', 'MarkerFaceColor', 'k');
title(['Sinyal Pernapasan (RR: ', num2str(round(rr_val)), ' BrPM)']);
xlabel('Waktu (detik)'); ylabel('Amplitudo');
grid on;