% Running Optimizer to determine growth areas for Mars One crew

clear all
clc

% For a 4 person crew consuming an average of 3040 calories per day at a
% consumption ratio of 68% carbs, 12% protein, 20% fat by energy

% Mass fractions of the 9 crops of interest
carbfraction = [600.1/(600.1+8.3+235.8),0.6868,0.177,0.9112,0.3588,0.9256,0.7979,0.8342,0.8923];
proteinfraction = [235.8/(600.1+8.3+235.8),0.2548,0.2829,0.0813,0.4204,0.0631,0.1455,0.1478,0.1028];
fatfraction = [8.3/(600.1+8.3+235.8),0.0584,0.5401,0.0075,0.2209,0.0113,0.0565,0.018,0.0049];

% growthrate = [10,6.57,5.63,9.07,4.54,15,10.43,20,21.06];   % in g/m^2/day
load CropGrowthRates
growthrate = CropGrowthRates';
targetPerPersonDailyCalories = 3040;

targetcarbs = 0.68*targetPerPersonDailyCalories;    % in grams
targetprotein = 0.12*targetPerPersonDailyCalories;  % in grams
targetfat = 0.2*targetPerPersonDailyCalories/9*4;   % in grams (note 9 calories per gram of fat)

f = ones(1,9);

% Note that entries below are in the format: Ax<=b

% Inequality constraint matrix
A = -[carbfraction.*growthrate;proteinfraction.*growthrate;fatfraction.*growthrate];

% Inequality values
b = -[targetcarbs;targetprotein;targetfat];

% Solve linear program (can zero out crops)
[x,fval,exitflag,output] = linprog(f,A,b,[],[],ones(9,1),[]);

% Repeat problem except now the cost function is to minimize the average of
% the mass of plants grown (even distribution of plants by mass)
f2 = growthrate/9;

[x2,fval2,exitflag2,output2] = linprog(f2,A,b,[],[],zeros(9,1),[]);

%% Treat problem as mixed integer linear program
intcon = 1:9;       % components of x vector that should be integers

% Minimize area
[x3,fval3,exitflag3,output3] = intlinprog(f,intcon,A,b,[],[],zeros(9,1),[]);

%% non-linear cost function
f3 = @(x) 1.5*std(x)+sum(x);

[x4,fval4,exitflag4,output4] = fmincon(f3,x2,A,b,[],[],zeros(9,1),[]);

%% cost function - grow at least 4 crops
f3 = @(x) std(x);

[x5,fval5,exitflag5,output5] = fmincon(f3,x2,A,b,[],[],zeros(9,1),[]);

%% Full factorial
% area = 0:5:120;       % Range of potential areas
% totalarea = zeros(1,100000);
% xvec = zeros(9,100000);
% numberOfCrops = zeros(1,100000);
% h = waitbar(0,'Please wait...');
% tic
% for a = area
%     for b = area
%         for c = area
%             for d = area
%                 for e = area
%                     for f = area
%                         for g = area
%                             for h = area
%                                 for i = area
%                                     waitbar(i/simtime);
%                                     if [a b c d e f g h i].*growthrate*carbfraction' >= targetcarbs &&...
%                                             [a b c d e f g h i].*growthrate*proteinfraction' >= targetprotein && ...
%                                             [a b c d e f g h i].*growthrate*fatfraction' >= targetfat
%                                         count = count+1;
%                                         vec = [a b c d e f g h i]';
%                                         totalarea(count) = sum(vec);
%                                         xvec(:,count) = vec;
%                                         numberOfCrops(count) = length(vec(vec~=0));
%                                         
%                                         return
%                                         
%                                         % Limit collected data points to 100000
%                                         if count > 100000
%                                             return
%                                         end
%                                         
%                                         
%                                     end
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% toc
% close(h)

    
    