%% 1. Load Data & Pengaturan
clear; clc; close all;

folderPath = 'C:\Users\gibra\OneDrive\Dokumen\pythonbelajar';
fileName = 'bpm85.csv';
fullPath = fullfile(folderPath, fileName);

opts = detectImportOptions(fullPath);
opts.VariableNamesLine = 0; 
data_table = readtable(fullPath, opts);

% AMBIL DATA RED (Kolom 3) dan IR (Kolom 4)
% Sesuai dataset kamu: [Time, ID, Red, IR, Green, BPM, SpO2]
raw_red = double(data_table{:, 3}); 
raw_ir = double(data_table{:, 4}); 

%% 2. Parameter & Waktu
Fs = 135; 
num_samples = length(raw_red);
t = (0:num_samples-1)' / Fs; 

%% 3. Filtering (Sesuai Metodologi Jurnal)
% Bandpass Filter 0.5 - 5 Hz untuk mengambil komponen AC (denyut)
[b, a] = butter(3, [0.5 5]/(Fs/2));

% Filter sinyal untuk mendapatkan komponen AC
red_ac_signal = filtfilt(b, a, raw_red);
ir_ac_signal = filtfilt(b, a, raw_ir);

%% 4. Ekstraksi Nilai AC dan DC%% Modifikasi Bagian Ekstraksi AC dan DC sesuai Rumus 4.2-11
% Kita ambil jendela data tertentu, misal sepanjang data yang ada (np = total sampel)
np = length(red_ac_signal); 

% Menghitung AC_rms secara manual sesuai rumus jurnal:
% sqrt( (1/np) * sum(xi^2) )
red_ac_rms = sqrt( sum(red_ac_signal.^2) / np );
ir_ac_rms  = sqrt( sum(ir_ac_signal.^2) / np );

% Menghitung DC sesuai rumus jurnal (Rata-rata):
red_dc = mean(raw_red);
ir_dc = mean(raw_ir);

% Menghitung R (Ratio of Ratios) sesuai rumus 4.2-12
R = (red_ac_rms / red_dc) / (ir_ac_rms / ir_dc);

% Hitung SpO2 (Gunakan konstanta kalibrasi)
spo2_val = 110 - 25 * R;

% Batasi nilai maksimal 100%
if spo2_val > 100, spo2_val = 100; end

% Perbandingan dengan Sensor
ref_spo2 = mean(data_table{:, 7});

fprintf('====================================\n');
fprintf('HASIL ANALISIS SpO2\n');
fprintf('------------------------------------\n');
fprintf('R-Ratio        : %.4f\n', R);
fprintf('Estimasi SpO2  : %.2f %%\n', spo2_val);
fprintf('SpO2 Sensor    : %.2f %%\n', ref_spo2);
fprintf('Akurasi        : %.2f %%\n', 100 - abs(spo2_val - ref_spo2)/ref_spo2*100);
fprintf('====================================\n');

%% 6. Plotting
figure('Color', 'w');
subplot(2,1,1);
plot(t, red_ac_signal, 'r'); hold on;
plot(t, ir_ac_signal, 'k');
title('Sinyal AC (Red vs IR) setelah Filtering');
legend('Red AC', 'IR AC'); grid on;

subplot(2,1,2);
plot(t, raw_red, 'r'); hold on;
plot(t, raw_ir, 'k');
title('Sinyal Mentah (DC Components)');
legend('Red Raw', 'IR Raw'); grid on;