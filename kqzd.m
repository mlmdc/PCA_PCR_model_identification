x = -5:.1:5; % set of x- values - known explanatory variables
y = 5.3 + 1.2* x; % Straight line without noise
e=randn(size(y));
y = y + e; % adding random noise to get observed variable -
%Linear model - Y=Xa+e where a - parameters to be estimated

X = [ ones(length(x),1) x']; %first column treated aas all ones since x_1=1
y = y'; %column vector for proper dimension during multiplication
a = inv(X'*X)*X'*y  % Least Squares Estimator - equivalent code X\y
h=plot ( x , y , 'o'); %original data
hold on;
plot( x , a(1)+ a(2)*x , 'r-' ); %Fitted line
legend('observed samples',['y=' num2str(a(1)) '+' num2str(a(2)) 'x'])
title('Least Squares Estimate for Curve Fitting');
xlabel('X values');
ylabel('Y values');
