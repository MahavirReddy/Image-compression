clear; clc; close all; 
 
%% ------------------ IMAGE LOADING ------------------ 
% Load grayscale image 
I = imread('cameraman.tif'); % uint8 image 
I = double(I); % convert to double (0–255) 
 
%% ------------------ LEVEL SHIFT ------------------ 
I_shifted = I - 128; 
 
%% ------------------ JPEG QUANTIZATION MATRIX ------------------ 
Q = [16 11 10 16 24 40 51 61; 
 12 12 14 19 26 58 60 55; 
 14 13 16 24 40 57 69 56; 
 14 17 22 29 51 87 80 62; 
 18 22 37 56 68 109 103 77; 
 24 35 55 64 81 104 113 92; 
 49 64 78 87 103 121 120 101; 
 72 92 95 98 112 100 103 99]; 
 
%% ------------------ BLOCK FUNCTIONS ------------------ 
dct_func = @(b) dct2(b.data); 
quant_func = @(b) round(b.data ./ Q); 
inv_quant_func = @(b) b.data .* Q; 
idct_func = @(b) idct2(b.data); 
 
%% ------------------ COMPRESSION ------------------ 
dct_coeffs = blockproc(I_shifted, [8 8], dct_func); 
quantized = blockproc(dct_coeffs, [8 8], quant_func); 
 
%% ------------------ DECOMPRESSION (FOR VERIFICATION) ------------------ 
dequantized = blockproc(quantized, [8 8], inv_quant_func); 
reconstructed = blockproc(dequantized, [8 8], idct_func); 
 
% Inverse level shift 
reconstructed = reconstructed + 128; 
 
% Clip to valid range 
reconstructed = uint8(min(max(reconstructed, 0), 255)); 
 
%% ------------------ DISPLAY RESULTS ------------------ 
figure; 
subplot(1,2,1); 
imshow(uint8(I)); 
title('Original Image'); 
 
subplot(1,2,2); 
imshow(reconstructed); 
title('Reconstructed Image'); 
 
sgtitle('Edge-Based Image Compression using DCT'); 
 
%% ------------------ QUALITY METRICS ------------------ 
mse = mean((double(I(:)) - double(reconstructed(:))).^2); 
psnr_val = 10 * log10(255^2 / mse); 
 
fprintf('--- Quality Metrics ---\n'); 
fprintf('MSE = %.2f\n', mse); 
fprintf('PSNR = %.2f dB\n\n', psnr_val); 
 
%% ------------------ ENTROPY-BASED COMPRESSION (NO TOOLBOX) ------------------ 
% Flatten quantized coefficients 
data_stream = quantized(:); 
 
% Probability estimation 
[symbols, ~, idx] = unique(data_stream); 
counts = accumarray(idx, 1); 
probs = counts / sum(counts); 
 
% Shannon entropy 
entropy_val = -sum(probs .* log2(probs)); 
 
% Estimated compressed size 
estimated_compressed_bits = entropy_val * numel(data_stream); 
 
% Original image size (8 bits per pixel) 
original_size_bits = numel(I) * 8; 
 
% Compression ratio 
compression_ratio = original_size_bits / estimated_compressed_bits; 
 
%% ------------------ DISPLAY COMPRESSION RESULTS ------------------ 
fprintf('--- Compression Results (Entropy Based) ---\n'); 
fprintf('Entropy : %.2f bits/symbol\n', entropy_val); 
fprintf('Original Image Size : %d bits\n', original_size_bits); 
fprintf('Estimated Compressed Size : %.0f bits\n', estimated_compressed_bits); 
fprintf('Estimated Compression Ratio : %.2f : 1\n', compression_ratio); 
 
%% ------------------ SPARSITY ANALYSIS (OPTIONAL, GOOD FOR VIVA) ------------------ 
zero_percentage = 100 * sum(quantized(:) == 0) / numel(quantized); 
fprintf('\nZero Coefficients After Quantization: %.2f %%\n', zero_percentage);