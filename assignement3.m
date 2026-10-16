%% Initialization
clear; clc; clear all; close all;
load("VAJA3.mat");

%% Standardization functions
function [mind, maxd, standard_data] = standardizeData(data)
    mind = min(data);
    maxd = max(data);
    standard_data = (data-mind)./(maxd-mind);
    
end

function destdData = deStandardizeData(mind, maxd, data)
    destdData = data.*(maxd - mind) + mind;
end

function [meand, stdd, zscore_data] = zScoreStandard(data)
    meand = mean(data);
    stdd = std(data);
    zscore_data = (data-meand)./stdd;
end

function deZData = deZScoreStandard(meand, stdd, data)
    deZData = data.*stdd + meand;
end

%% PCA/PCR functions
function [pc, X_pca, latent] = PCA_om(data)
    [n, m] = size(data);
    data = data - mean(data);%, 'all');
    
    cov_mat = (data' * data)/(n-1); % Computing the cov matrix

    [eigVec, eigVal] = svd(cov_mat); % Computing eigenvectors and eigenvalues
    [eigVal_sort, ind] = sort(diag(eigVal), 'descend');
    eigVec_sort = eigVec(:, ind);

    X_pca = data * eigVec_sort(:, 1:m);   
    pc = eigVec_sort(:, 1:m);
    latent = eigVal_sort(1:m);
end

% Data sorting into X, Y
X = [A_FLOW, T_H2O, C_ACID];
Y = [I_EFF];

% model : I_EFF = a*A_FLOW + b*T_H2O + C*C_ACID

function s_num = estimatePrincipal(eigVal, threshold)
    explained_variance = cumsum(eigVal) / sum(eigVal); % Cumulative variance explained
    s_num = find(explained_variance >= threshold, 1); % Choose K PCs explaining threshold% variance
end

function [Ps, Xs, Ts] = approxData(P, X, s)
    Ps = P(:, 1:s);
    Ts = X * Ps;
    Xs = Ts * Ps';
end

function approxParams = approxParams(P, K, X, y)    
    disp(diag(K));
    approxParams = P * K * P' *X'*y;
end

function approxParams = approximateParamsPCR(X, Y, P, T)
    % Project the data onto the principal component space
    T = X * P;

    % Estimate parameters in the principal component space
    beta_PC = (T' * T) \ (T' * Y);

    % Transform parameters back to the original feature space
    approxParams = P * beta_PC;
end

function params = PCA(data, y)
    [kcoeff, kscore, klatent] = PCA_om(data);
    s_num = estimatePrincipal(klatent, 0.95); % Principal component selection. 
    params = kcoeff(:, 1:s_num)*(kscore(:, 1:s_num)\y);
end


function params = PCR(data, y)
    [kcoeff, kscore, klatent] = PCA_om(data); % Initial parameters est.
    s_num = estimatePrincipal(klatent, 0.95); % Principal component selection. 
    [Ps, Xs, Ts] = approxData(kcoeff, data, s_num); % Projection into principal component space
    params = approximateParamsPCR(Xs, y, Ps, Ts); % Est. of parameters with cast back into main space
end

function [err, mn_err, std_err, nrmse] = estimateParams(x, y, params)
    [n, m] = size(y);
    err = y - x*params;
    mn_err = mean(err);
    std_err = std(err);
    nrmse = sqrt(sum((x*params-y).^2)/n)/std(y);
end


sample_n = (1:size(X, 1));
function params = LSE(X, Y)
    % θ̂ = (X^T.X + αI)^-1 . X^T . y
    [n, m] = size(X);
    params = inv(X' * X)*X' * Y;    
end

function param_variance = estimate_param_variance(X, err_param)
    % est. of sigma^2
    n = length(X(:, 1));
    p = size(X, 2);
    sigma2_hat = (err_param' * err_param) / (n - p);

    % covariance matrix of beta_hat
    cov_beta = sigma2_hat * pinv(X' * X);

    % theoretical variances (diagonal elements)
    param_variance = diag(cov_beta);
end


%% Standardizations
%X = [X, ones(size(A_FLOW))];

[minstd, maxstd, std] = standardizeData([Y, X]);
X_std = [std(:, 2:end), ones(size(A_FLOW))];
Y_std = std(:,1);

[meanz, stdz, zdata] = zScoreStandard([Y, X]);
X_z = [zdata(:, 2:end), ones(size(A_FLOW))];
Y_z = zdata(:, 1);

X = [X, ones(size(A_FLOW))];

%% Computations
params_lse = LSE(X, Y);
params_lse_std = LSE(X_std, Y_std);
params_lse_z = LSE(X_z, Y_z);

params_pca_std = PCA(X_std, Y_std);
params_pca_z = PCA(X_z, Y_z);
params_pca = PCA(X, Y);

k = 7; 
% Creates a cross-validation partition object
cv = cvpartition(size(Y, 1), 'KFold', k);

% Average err position
avg_err_lse = zeros(21/k, 1);
avg_err_lse_std = zeros(21/k, 1);
avg_err_lse_z = zeros(21/k, 1);

avg_err_pca = zeros(21/k, 1);
avg_err_pca_std = zeros(21/k, 1);
avg_err_pca_z = zeros(21/k, 1);

% Keeping track of MSE
mse_err_lse = Inf;
mse_err_lse_std = Inf;
mse_err_lse_z = Inf;

mse_err_pca = Inf;
mse_err_pca_std = Inf;
mse_err_pca_z = Inf;

% Best parameters
bst_lse = [0; 0; 0; 0];
bst_lse_std = [0; 0; 0; 0];
bst_lse_z = [0; 0; 0; 0];

bst_pca = [0; 0; 0; 0];
bst_pca_std = [0; 0; 0; 0];
bst_pca_z = [0; 0; 0; 0];


% Train and evaluate the network
for i = 1:k
    % Get the training and test indices
    trainIdx = training(cv, i);
    testIdx = test(cv, i);

    % Determining the regression
    params_lse = LSE(X(trainIdx, :), ...
        Y(trainIdx));
    params_lse_std = LSE(X_std(trainIdx, :), ...
        Y_std(trainIdx));
    params_lse_z = LSE(X_z(trainIdx, :), ...
        Y_z(trainIdx));
    
    params_pca = PCA(X(trainIdx, :), ...
        Y(trainIdx));
    params_pca_std = PCA(X_std(trainIdx, :), ...
        Y_std(trainIdx));
    params_pca_z = PCA(X_z(trainIdx, :), ...
        Y_z(trainIdx));
    

    % Evaluates the regression
    err_lse = (Y(testIdx) - X(testIdx, :)*params_lse);
    err_lse_std = (Y_std(testIdx) - X_std(testIdx, :)*params_lse_std);
    err_lse_z = (Y_z(testIdx) - X_z(testIdx, :)*params_lse_z);

    err_pca = (Y(testIdx) - X(testIdx, :)*params_pca);
    err_pca_std = (Y_std(testIdx) - X_std(testIdx, :) * params_pca_std);
    err_pca_z = (Y_z(testIdx) - X_z(testIdx, :) * params_pca_z);

    avg_err_lse = (avg_err_lse + err_lse)/2;
    avg_err_lse_std = (avg_err_lse_std + err_lse_std)/2;
    avg_err_lse_z = (avg_err_lse_z + err_lse_z)/2;

    avg_err_pca = (avg_err_pca + err_pca)/2;
    avg_err_pca_std = (avg_err_pca_std + err_pca_std)/2;
    avg_err_pca_z = (avg_err_pca_z + err_pca_z)/2;
    
    %LSE err choice 
    if (mean(err_lse.^2) < mse_err_lse)
        bst_lse(:) = params_lse(:);
        mse_err_lse = mean(err_lse.^2);
    end
    
    if (mean(err_lse_std.^2) < mse_err_lse_std)
        bst_lse_std(:) = params_lse_std(:);
        mse_err_lse_std = mean(err_lse_std.^2);
    end
    
    if (mean(err_lse_z.^2) < mse_err_lse_z)
        bst_lse_z(:) = params_lse_z(:);
        mse_err_lse_z = mean(err_lse_z.^2);
    end
    
    if (mean(err_pca.^2) < mse_err_pca)
        bst_pca(:) = params_pca(:);
        mse_err_pca = mean(err_pca.^2);
    end
    
    if (mean(err_pca_std.^2) < mse_err_pca_std)
        bst_pca_std(:) = params_pca_std(:);
        mse_err_pca_std = mean(err_pca_std.^2);
    end

    if (mean(err_pca_z.^2) < mse_err_pca_z)
        bst_pca_z(:) = params_pca_z(:);
        mse_err_pca_z = mean(err_pca_z.^2);
    end

end 

disp("Theoretical var. of each params for LSE");
disp("Non std"); disp(estimate_param_variance(X, avg_err_lse));
disp("Non std"); disp(estimate_param_variance(X_std, avg_err_lse_std));
disp("Non std"); disp(estimate_param_variance(X_z, avg_err_lse_z));



%% verification with interpolation

n_interp = 100;
og_points = linspace(1, 21, 21);

% New interpolation points
interp_points = linspace(1, 21, n_interp);

% Interpolate Y
Y_interp = interp1(og_points, Y, interp_points, 'spline')';

% Interpolate X (column-wise)
X_interp = zeros(n_interp, 4);
for i = 1:4
    X_interp(:, i) = interp1(og_points, X(:, i), interp_points, 'spline')';
end

[~, ~, X_interp_std] = standardizeData(X_interp(:, 1:end-1)); 
X_interp_std = [X_interp_std, ones(size(X_interp(:, 1)))];
[~, ~, X_interp_z] = zScoreStandard(X_interp(:, 1:end-1)); 
X_interp_z = [X_interp_z, ones(size(X_interp(:, 1)))];
%% Calculation visualizations

% PCA plot
figure;
plot(interp_points, Y_interp); hold on;
plot(interp_points, (X_interp*bst_pca));
plot(interp_points, deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std));
plot(interp_points, deZScoreStandard(meanz(1,1), stdz(1,1), X_interp_z * bst_pca_z));
grid on;
legend("Original Y", "No std.", "Standardized [0, 1]", "Z-score");
xlabel("Sample n°");
ylabel("Output values");
title("PCA on different standardizations")

% LSE plot
figure;
plot(interp_points, Y_interp); hold on;
plot(interp_points, (X_interp*bst_lse));
plot(interp_points, deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std));
plot(interp_points, deZScoreStandard(meanz(1,1), stdz(1,1), X_interp_z * bst_lse_z));
grid on;
legend("Original Y", "No std.", "Standardized [0, 1]", "Z-score");
xlabel("Sample n°");
ylabel("Output values");
title("LSE on different standardizations")

% PCA error plot
figure;
hold on;
%plot(interp_points, Y_interp); hold on;
plot(interp_points, Y_interp- (X_interp*bst_pca));
plot(interp_points, Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std));
plot(interp_points, Y_interp- deZScoreStandard(meanz(1,1), stdz(1,1), X_interp_z * bst_pca_z));
grid on;
legend("No std.", "Standardized [0, 1]", "Z-score");
xlabel("Sample n°");
ylabel("Output error values");
title("PCA error on different standardizations")

% LSE error plot
figure;
hold on;
%plot(interp_points, Y_interp); hold on;
plot(interp_points, Y_interp- (X_interp*bst_lse));
plot(interp_points, Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std));
plot(interp_points, Y_interp- deZScoreStandard(meanz(1,1), stdz(1,1), X_interp_z * bst_lse_z));
grid on;
legend("No std.", "Standardized [0, 1]", "Z-score");
xlabel("Sample n°");
ylabel("Output error values");
title("LSE error on different standardizations")


% LSE error plot
figure;
hold on;
plot(interp_points, Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std));
plot(interp_points, Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std));
grid on;
legend("PCA", "LSE");
xlabel("Sample n°");
ylabel("Output error values");
title("LSE vs PCA errors, on std dataset")
clear std;
disp(std(Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std)));
disp(mean(Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std)));
disp(std(Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std)));
disp(mean(Y_interp- deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std)));

% LSE error plot
figure;
hold on;
plot(interp_points, Y_interp);
plot(interp_points, deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_pca_std));
plot(interp_points, deStandardizeData(minstd(1,1), maxstd(1,1), X_interp_std * bst_lse_std));
grid on;
legend("Original", "PCA", "LSE");
xlabel("Sample n°");
ylabel("Output values");
title("LSE vs PCA, on std dataset")

%% Colinearity problem

% Loop variables initialization
X2 = [X, 2*T_H2O+6+0.1*randn(size(T_H2O))];
Y2_lse = Y;
Y2_pcr = Y;
params_lse_cumul = []; %[0; 0; 0; 0];
params_pcr_cumul = [];%[0; 0; 0; 0];

% Main loop
for k=1:10
    X2 = [X, 2*T_H2O+6+0.1*randn(size(T_H2O))];
    params_lse = LSE(X2, Y2_lse);
    params_pcr = PCR(X2, Y2_pcr);
    
    params_lse_cumul = [params_lse_cumul, params_lse];
    params_pcr_cumul = [params_pcr_cumul, params_pcr];

    Y2_lse = X2*params_lse;
    Y2_pcr = X2*params_pcr;
end

% LSE parameters
figure;
hold on;
for i=1:4
    plot(params_lse_cumul(i, :));
end
grid on;
title("LSE parameters evolution");
xlabel("n° sample");

% PCR parameters
figure;
hold on;
for i=1:4
    plot(params_pcr_cumul(i, :));
end
grid on;
title("PCR parameters evolution");
xlabel("n° sample");

% LSE plotting
figure;
plot(sample_n, Y); hold on;
plot(sample_n, X2*params_lse_cumul(:, 1)); 
plot(sample_n, Y2_lse);
grid on;
legend();
title("LSE resulting curves");
xlabel("n° sample");

% PCR plotting
figure;
plot(sample_n, Y); hold on;
plot(sample_n, X2*params_pcr_cumul(:, 1)); 
plot(sample_n, Y2_pcr);
grid on;
legend();
title("PCR resulting curves");
xlabel("n° sample");

disp("Theoretical var. of each params for LSE");
disp("Non std"); disp(estimate_param_variance(X2, (params_lse_cumul(:, 1)')));
disp("Non std"); disp(estimate_param_variance(X2, (params_lse_cumul(:, end)')));

disp("== variance of the parameters ==");
disp(var(params_lse_cumul(:, 1)));
disp(var(params_pcr_cumul(:, 1)));

disp(var(params_lse_cumul(:, end)));
disp(var(params_pcr_cumul(:, end)));

disp("== Errors and std ==");
err_pcr_0 = (Y - X2*params_pcr_cumul(:, 1));
err_pcr_10 = (Y - X2*params_pcr_cumul(:, end));

err_lse_0 = (Y - X2*params_lse_cumul(:, 1));
err_lse_10 = (Y - X2*params_lse_cumul(:, end));

disp(std(err_lse_10));
disp(mean(err_lse_10));
disp(std(err_pcr_10));
disp(mean(err_pcr_10));