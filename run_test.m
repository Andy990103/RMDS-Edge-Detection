clc;
clear;
close all;


%% Automatically locate project directory

projectPath = fileparts(mfilename('fullpath'));


%% Define input image path

imageFile = fullfile(projectPath,...
                     'data',...
                     'rmds4.tif');


%% Input parameters

basisType = 'cos';          % Basis function type: 'sin' or 'cos'

frequency = 4;              % Frequency of basis function (Hz)


butterOrder = 6;            % Order of Butterworth low-pass filter

butterCutoff = 0.05;        % Cutoff frequency


r_range = 120:180;          % Range of circular template radii

ring_thickness = 1;         % Thickness of circular ring template


thresholdRatio = 4/5;       % Detection threshold ratio

epsScale = 0.4;             % DBSCAN epsilon scaling factor

minPts = 20;                % Minimum number of points for DBSCAN



%% Add project path

addpath(projectPath);



%% Run RMDS detection

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



%% Display results

disp('Detection results [row col radius response]');

disp(circles);