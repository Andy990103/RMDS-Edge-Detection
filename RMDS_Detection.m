function circles = RMDS_Detection( ...
    imageFile,...
    basisType,...
    frequency,...          % Frequency of basis function (currently fixed at 4 Hz)
    butterOrder,...
    butterCutoff,...
    r_range,...
    ring_thickness,...
    thresholdRatio,...     % Threshold ratio (currently fixed at 0.8)
    epsScale,...           % DBSCAN epsilon scale (currently fixed at 0.4)
    minPts)                % Minimum number of points for DBSCAN (currently fixed at 20)

% =====================================================
% RMDS Automatic Detection Algorithm
%
% Input:
% imageFile       : Path of input image
% basisType       : Basis function type ('sin' or 'cos')
% frequency       : Frequency of basis function
% butterOrder     : Order of Butterworth low-pass filter
% butterCutoff    : Cutoff frequency of Butterworth filter
% r_range         : Range of template radii
% ring_thickness  : Thickness of circular ring template
% thresholdRatio  : Threshold coefficient for candidate selection
% epsScale        : Scaling factor for DBSCAN epsilon
% minPts          : Minimum number of points required by DBSCAN
%
% Output:
% circles = [row col radius response]
%
% row             : Row coordinate of detected RMDS center
% col             : Column coordinate of detected RMDS center
% radius          : Estimated RMDS radius
% response        : Detection response value
%
% =====================================================


%% =====================================================
% 1. Read input image
%% =====================================================

img = imread(imageFile);

if size(img,3)==3
    img = rgb2gray(img);
end

img = double(img);
[rows,cols] = size(img);



%% =====================================================
% 2. Generate basis function for cross-correlation
%% =====================================================

fs = cols;
T = 1;

t = 0:1/fs:(T-1/fs);

switch lower(basisType)

    case 'sin'
        x = sin(2*pi*frequency*t);

    case 'cos'
        x = cos(2*pi*frequency*t);

    otherwise
        error('basisType must be either ''sin'' or ''cos''');

end


N = numel(t);

Lc = round(fs/frequency);

c0 = floor((N+1)/2);

a = c0-floor(Lc/2);
b = a+Lc-1;

L = b-a;

a = a+L/4;
b = b-L/4;


F = round(0.5*Lc);

F = max(0,min([F,a-1,N-b]));


w = zeros(1,N);

w(a:b)=1;


if F>0

    n = 1:F;

    % Smooth transition window
    rise = sin((n/F)*(pi/2)).^2;
    fall = fliplr(rise);

    w(a-F:a-1)=rise;
    w(b+1:b+F)=fall;

end


signal_cycle = x.*w;



%% =====================================================
% 3. Design Butterworth low-pass filter
%% =====================================================

[bw,aw] = butter(butterOrder,butterCutoff,'low');



%% =====================================================
% 4. Row-wise cross-correlation
%% =====================================================

result = zeros(rows,cols);


for r=1:rows

    signal = img(r,:);

    % Remove mean value
    signal = signal-mean(signal);


    % Median filtering to suppress noise
    signal = medfilt1(signal,3);


    if max(signal)==min(signal)
        continue;
    end


    % Normalize signal to [-1,1]
    signal = 2*(signal-min(signal))/(max(signal)-min(signal))-1;


    % Normalized cross-correlation
    corr_full = xcorr(signal,signal_cycle,'normalized');


    mid = ceil(length(corr_full)/2);


    result(r,:) = corr_full(mid-floor(cols/2):mid+ceil(cols/2)-1);

end



%% =====================================================
% 5. Column-wise Butterworth filtering
%% =====================================================

result_lp = zeros(rows,cols);


for c=1:cols

    result_lp(:,c)=filtfilt(bw,aw,result(:,c));

end



%% =====================================================
% 6. First-order derivative
%% =====================================================

dx = diff(result_lp,1,2);

dx = [dx zeros(rows,1)];


img_norm = dx;



%% =====================================================
% 7. Multi-scale circular template matching
%% =====================================================

numR = length(r_range);


volume_responses = zeros(rows,cols,numR);


for k=1:numR


    R = r_range(k);


    % Padding around the circular template
    pad = round(0.3*R);


    diam = 2*(R+pad)+1;


    [X,Y]=meshgrid(1:diam);


    cx=(diam+1)/2;


    dist = sqrt((X-cx).^2+(Y-cx).^2);


    % Circular ring template
    mask = abs(dist-R)<=ring_thickness/2;


    if ~any(mask(:))

        [~,id]=min(abs(dist(:)-R));

        mask(id)=1;

    end


    kernel = double(mask);


    % Template convolution
    resp = conv2(img_norm,kernel,'same');


    % Circumference normalization
    volume_responses(:,:,k)=resp/sum(mask(:));


end



%% =====================================================
% 8. Select maximum response and corresponding radius
%% =====================================================


[max_response,best_k] = max(volume_responses,[],3);


best_radius = r_range(best_k);



%% =====================================================
% 9. Response thresholding
%% =====================================================


thr = thresholdRatio * max(max_response(:));


max_response(max_response<thr)=0;



%% =====================================================
% 10. DBSCAN clustering
%% =====================================================


[row,col]=find(max_response>0);


pts=[row col];


% Adaptive epsilon based on detected radius
eps_val = epsScale * mean(best_radius(best_radius>0));


minpts = minPts;


labels=dbscan(double(pts),eps_val,minpts);


ids=unique(labels);


% Remove noise points
ids(ids==-1)=[];




%% =====================================================
% 11. Extract detected RMDS parameters
%% =====================================================


circles=[];


for i=1:length(ids)


    idx = labels==ids(i);


    lin=sub2ind(size(max_response),pts(idx,1),pts(idx,2));


    [resp,id]=max(max_response(lin));


    lin_best=lin(id);


    [r0,c0]=ind2sub(size(max_response),lin_best);


    R0=best_radius(r0,c0);


    circles=[circles;
             r0 c0 R0 resp];


end



%% =====================================================
% 12. Visualization of detected RMDS
%% =====================================================


figure;


imagesc(img);


colormap(gray);


axis image;


hold on



theta=linspace(0,2*pi,360);



for i=1:size(circles,1)


    x=circles(i,2)+circles(i,3)*cos(theta);


    y=circles(i,1)+circles(i,3)*sin(theta);


    plot(x,y,'r--','LineWidth',2);


end



axis off


set(gca,'Position',[0 0 1 1]);


hold off


end