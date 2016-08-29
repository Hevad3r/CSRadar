%% EXPERIMENT  - CLASSIF. ON ORIGINAL FEATURE SPACE     X_original , 
clear all; close all; 

D = 100; % Dimensionality: can be 50 or 100 to use 1 channel or 2
K = 10; % K nearest neighbors

%% Class 1 
load(sprintf('cube_d%d.mat',D)); % load data, MM, NN
M_cube = MM; % # rows
N_cube = NN; % # columns
data_cube = data; % D x (M_cube  N_cube)
N_cube = size(data_cube,2);


%% Class 2
load(sprintf('corner_d%d.mat',D)); % load data, MM, NN
M_corner = MM; % # rows
N_corner = NN; % # columns
data_corner = data; % D x (M_corner  N_corner)
N_corner = size(data_corner,2);

N = N_cube + N_corner;

%% Load data
X = abs([data_cube data_corner])'; % N x D
X = X - ones(N,1)*mean(X,1);
X = X ./ (ones(N,1)*var(X,1));
Y = [zeros(1,N_cube) ones(1,N_corner)]'; % 0 = cube, 1 = corner

%% Split into train and test
fracTrain = 0.5;
fracVal = 0.5;
idx = randperm(N);
idx_train = idx(1:round(fracTrain*N));
idx_val = idx(round(fracTrain*N)+1:end);

Xtrain = X(idx_train,:);
Ytrain = Y(idx_train,:);
Xval = X(idx_val,:);
Yval = Y(idx_val,:);

%%
%training
train_mdl = fitcknn(Xtrain,Ytrain,'NumNeighbors',K) ;

[label_test] = predict(train_mdl,Xval);
uncompressed_score =  sum ( label_test == Yval) / length(Yval);

%% MDA_FKT
C_TRAIN = {};

C_TRAIN{1} = Xtrain(Ytrain==0,:)'; % Cube
C_TRAIN{2} = Xtrain(Ytrain==1,:)'; % Corner

[Q,V] = mda_fkt(C_TRAIN);

 
%%

scores = zeros(size(V,2),1);
for k = 1:size(V,2) 
    Proj_Mat = abs(Q*V(:,1:k)); 
    Ctrain = Xtrain*Proj_Mat;
    Cval = Xval*Proj_Mat;
    
    mdl_mkt_fda = fitcknn(Ctrain,Ytrain,'NumNeighbors',K) ;
    label_test_mda = predict(mdl_mkt_fda,Cval);

    scores(k) = sum( label_test_mda == Yval ) / length(Yval);
end
%plot(1:length(scores),scores)
%title('Accuracy vs Supbspace Size');
%xlabel('Subspace Size');
%ylabel('Accuracy');
%figure
[mx,i] = max(scores);
fprintf('accuracy: min=%f, mean=%f, max=%f\n',min(scores),mean(scores),max(scores));
fprintf('best dimension=%d\n',i);
fprintf('uncompressed score=%f\n',uncompressed_score);

Proj_Mat = abs(Q*V(:,1:i));
Ctrain = Xtrain*Proj_Mat;
plot(Xtrain(Ytrain==1,:)','b');hold on;plot(Xtrain(Ytrain==0,:)','g');
title('Original Data');

figure
plot(Ctrain(Ytrain==1,:)','b');hold on;plot(Ctrain(Ytrain==0,:)','g')
title('Compressed Data');
