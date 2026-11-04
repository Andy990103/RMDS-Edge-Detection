clc;
clear;
close all;

%% =========================================================
% 1. Set input and output folder paths
% ==========================================================

input_folder = '/user/data/test';  %% Set the path to your own computer
output_folder = '/user/test_enh';  %% Set the path to your own computer

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% =========================================================
% 2. Retrieve input TIF files
% ==========================================================

files = dir(fullfile(input_folder, '*.tif'));

if isempty(files)
    error('No TIF files found in the input folder.');
end

fprintf('A total of %d TIF files were found.\n', length(files));

%% =========================================================
% 3. Set signal parameters
% ==========================================================

f = 6;
T = 1;

%% =========================================================
% 4. Design a Butterworth low-pass filter
% ==========================================================

fc = 0.05;
[bw, aw] = butter(6, fc, 'low');

%% =========================================================
% 5. Process all input images
% ==========================================================

for k = 1:length(files)

    %% -----------------------------------------------------
    % 5.1 Get the input file name and path
    % ------------------------------------------------------

    input_name = files(k).name;
    input_path = fullfile(input_folder, input_name);

    fprintf('\n========================================\n');
    fprintf('Processing file %d/%d: %s\n', ...
        k, length(files), input_name);
    fprintf('========================================\n');

    %% =====================================================
    % 5.2 Read and preprocess the input image
    % ======================================================

    img = imread(input_path);

    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    img = double(img);

    [rows, cols] = size(img);
    fprintf('Image dimensions: %d x %d\n', rows, cols);

    %% =====================================================
    % 5.3 Construct the cosine reference signal
    % ======================================================

    fs = cols;
    t = 0:1/fs:(T - 1/fs);
    N = numel(t);

    x = cos(2*pi*f*t);

    Lc = round(fs/f);
    c = floor((N+1)/2);

    a = c - floor(Lc/2);
    b = a + Lc - 1;

    L = b - a;

    a = a + L/4;
    b = b - L/4;

    F = round(0.5*Lc);
    F = max(0, min([F, a-1, N-b]));

    w = zeros(1, N);
    w(a:b) = 1;

    if F > 0
        n = 1:F;

        rise = sin((n/F)*(pi/2)).^2;
        fall = fliplr(rise);

        w((a-F):(a-1)) = rise;
        w((b+1):(b+F)) = fall;
    end

    signal_cycle = x .* w;

    %% =====================================================
    % 5.4 Perform row-wise normalized cross-correlation
    % ======================================================

    result = zeros(rows, cols);

    for r = 1:rows

        signal = img(r, :);

        signal_zero_mean = signal - mean(signal);

        % Apply median filtering
        y = medfilt1(signal_zero_mean, 3);

        if max(y) == min(y)
            continue;
        end

        % Normalize the signal to the range [-1, 1]
        signal_norm = 2 * ...
            (y - min(y)) / ...
            (max(y) - min(y)) - 1;

        % Perform normalized cross-correlation
        r_corr_full = xcorr( ...
            signal_norm, ...
            signal_cycle, ...
            'normalized');

        mid = ceil(length(r_corr_full)/2);

        start_idx = mid - floor(cols/2);
        end_idx = start_idx + cols - 1;

        r_corr_same = r_corr_full( ...
            start_idx:end_idx);

        result(r, :) = r_corr_same;
    end

    %% =====================================================
    % 5.5 Apply low-pass filtering
    % ======================================================

    result_lp = zeros(rows, cols);

    for c = 1:cols
        result_lp(:, c) = filtfilt( ...
            bw, ...
            aw, ...
            result(:, c));
    end

    %% =====================================================
    % 5.6 Compute the first-order derivative
    % ======================================================

    dx_mat = diff(result_lp, 1, 2);

    % Pad the last column with zeros to preserve the original dimensions
    % Size of dx_mat: rows x cols
    dx_mat = [dx_mat, zeros(rows, 1)];

    %% =====================================================
    % 5.7 Compute the second-order derivative
    % ======================================================

    d2x_mat = diff(result_lp, 2, 2);

    % Pad both sides with zeros to maintain the original dimensions
    d2x_mat = padarray( ...
        d2x_mat, ...
        [0 1], ...
        0, ...
        'both');

    %% =====================================================
    % 5.8 Apply soft thresholding
    % ======================================================

    filtered_dx = zeros(rows, cols);

    for r = 1:rows

        row_dx = dx_mat(r, :);

        max_dx = max(abs(row_dx));

        % Set the threshold to one-third of the maximum absolute value
        threshold = max_dx * 1/3;

        % Apply soft thresholding
        filtered_row = sign(row_dx) .* ...
            max(abs(row_dx) - threshold, 0);

        filtered_dx(r, :) = filtered_row;
    end

    %% =====================================================
    % 5.9 Select the final enhancement result
    % ======================================================

    output_data = dx_mat;

    % Alternative output using soft thresholding
    % output_data = filtered_dx;

    %% =====================================================
    % 5.10 Normalize the output to the range [0, 255]
    % ======================================================

    output_norm = mat2gray(output_data);
    output_uint8 = uint8(output_norm * 255);

    %% =====================================================
    % 5.11 Check and correct the output dimensions
    % ======================================================

    expected_rows = rows;
    expected_cols = cols;

    [enh_rows, enh_cols] = size(output_uint8);

    if enh_rows ~= expected_rows || ...
       enh_cols ~= expected_cols

        fprintf('Warning: Output dimensions do not match the input image.\n');

        fprintf( ...
            'Expected dimensions: %d x %d\n', ...
            expected_rows, ...
            expected_cols);

        fprintf( ...
            'Actual dimensions: %d x %d\n', ...
            enh_rows, ...
            enh_cols);

        fprintf('Resizing the output image...\n');

        % Resize the image while preserving the original dimensions
        % [rows, columns]
        output_uint8 = imresize( ...
            output_uint8, ...
            [expected_rows, expected_cols], ...
            'bilinear');
    end

    %% =====================================================
    % 5.12 Verify the final image dimensions
    % ======================================================

    [final_rows, final_cols] = size(output_uint8);

    if final_rows ~= rows || ...
       final_cols ~= cols

        error( ...
            'Final image dimensions are incorrect. Expected: %d x %d, Actual: %d x %d.', ...
            rows, ...
            cols, ...
            final_rows, ...
            final_cols);
    end

    %% =====================================================
    % 5.13 Convert the grayscale image to three-channel RGB
    % ======================================================

    % Final image dimensions:
    % rows x cols x 3
    %
    % Data type: uint8

    output_rgb = cat(3, ...
        output_uint8, ...
        output_uint8, ...
        output_uint8);

    %% =====================================================
    % 5.14 Verify the final RGB image dimensions
    % ======================================================

    [final_rows, final_cols, final_channels] = ...
        size(output_rgb);

    if final_rows ~= rows || ...
       final_cols ~= cols || ...
       final_channels ~= 3

        error('The final RGB image dimensions are incorrect.');
    end

    %% =====================================================
    % 5.15 Verify the output data type
    % ======================================================

    if ~isa(output_rgb, 'uint8')
        error('The output image data type must be uint8.');
    end

    %% =====================================================
    % 5.16 Generate the output file name and path
    % ======================================================

    [~, base_name, ~] = fileparts(input_name);

    output_name = [base_name, '_enh.tif'];

    output_path = fullfile( ...
        output_folder, ...
        output_name);

    %% =====================================================
    % 5.17 Save the enhanced image
    % ======================================================

    imwrite( ...
        output_rgb, ...
        output_path, ...
        'tif');

    %% =====================================================
    % 5.18 Read the saved image and verify its properties
    % ======================================================

    check_img = imread(output_path);

    [check_rows, check_cols, check_channels] = ...
        size(check_img);

    % Verify the image dimensions
    if check_rows ~= rows || ...
       check_cols ~= cols

        error('The saved image dimensions do not match the input image.');
    end

    % Verify the number of color channels
    if check_channels ~= 3
        error('The saved image must have three color channels.');
    end

    % Verify the image data type
    if ~isa(check_img, 'uint8')
        error('The saved image data type must be uint8.');
    end

    %% =====================================================
    % 5.19 Display processing information
    % ======================================================

    fprintf('\nInput file: %s\n', input_name);
    fprintf('Output file: %s\n', output_name);

    fprintf( ...
        'Input dimensions: %d x %d\n', ...
        rows, ...
        cols);

    fprintf( ...
        'Output dimensions: %d x %d x %d\n', ...
        check_rows, ...
        check_cols, ...
        check_channels);

    fprintf( ...
        'Output data type: %s\n', ...
        class(check_img));

    fprintf('Image successfully processed and saved.\n');

end

%% =========================================================
% 6. Display the final processing summary
% ==========================================================

fprintf('\n========================================\n');
fprintf('All image processing tasks completed.\n');

fprintf('Output folder:\n');
fprintf('%s\n', output_folder);

fprintf('========================================\n');