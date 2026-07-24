clc;
clear;
close all;


%% Input parameters

imageFile = '/Users/Hzh/Desktop/isis_data/RMDS/初稿/c&g投稿准备/code/data/rmds4.tif';  % Remember to change the file path which is suited in your own computer, this is my file path.


basisType = 'cos';          % Basis function type: 'sin' or 'cos'

frequency = 4;              % Frequency of basis function (Hz)


butterOrder = 6;            % Order of Butterworth low-pass filter

butterCutoff = 0.05;        % Cutoff frequency of Butterworth filter


r_range = 120:180;          % Range of circular template radii

ring_thickness = 1;         % Thickness of circular ring template


thresholdRatio = 4/5;       % Response threshold ratio (same as the original program)

epsScale = 0.4;             % Scaling factor for DBSCAN epsilon

minPts = 20;                % Minimum number of points required for DBSCAN clustering



%% Run RMDS detection algorithm

circles = RMDS_Detection( ...
    imageFile,...
    basisType,...
    frequency,...
    butterOrder,...
    butterCutoff,...
    r_range,...
    ring_thickness,...
    thresholdRatio,...
    epsScale,...
    minPts);



%% Display detection results

disp('Detection results [row col radius response]');

disp(circles);