% Running Optimizer to determine growth areas for Mars One crew

clear all
clc

% For a 4 person crew consuming an average of 3040 calories per day at a
% consumption ratio of 68% carbs, 12% protein, 20% fat by energy

numberOfCrew = 4;

% Mass fractions of the 9 crops of interest
carbfraction = [600.1/(600.1+8.3+235.8),28.7/(28.7+13.6+1.5),158.2/(158.2+261.5+496),791.5/(791.5+65+5.2),...
    301.6/(301.6+364.9+199.4),201.2/(201.2+15.7+0.5),38.9/(38.9+8.8+2),744.8/(744.8+96.1+19.5),157.1/(157.1+16.8+1)];
proteinfraction = [235.8/(600.1+8.3+235.8),13.6/(28.7+13.6+1.5),261.5/(158.2+261.5+496),65/(791.5+65+5.2),...
    364.9/(301.6+364.9+199.4),15.7/(201.2+15.7+0.5),8.8/(38.9+8.8+2),96.1/(744.8+96.1+19.5),16.8/(157.1+16.8+1)];
fatfraction = [8.3/(600.1+8.3+235.8),1.5/(28.7+13.6+1.5),496/(158.2+261.5+496),5.2/(791.5+65+5.2),...
    199.4/(301.6+364.9+199.4),0.5/(201.2+15.7+0.5),2/(38.9+8.8+2),19.5/(744.8+96.1+19.5),1/(157.1+16.8+1)];

% growthrate = [10,6.57,5.63,9.07,4.54,15,10.43,20,21.06];   % in g/m^2/day
load CropGrowthRates
growthrate = CropGrowthRates';
targetPerPersonDailyCalories = 3040.2;

targetcarbs = 0.68*targetPerPersonDailyCalories/4*numberOfCrew;    % in grams
targetprotein = 0.12*targetPerPersonDailyCalories/4*numberOfCrew;  % in grams
targetfat = 0.2*targetPerPersonDailyCalories/9*numberOfCrew;   % in grams (note 9 calories per gram of fat)

f = ones(1,9);

% Note that entries below are in the format: Ax<=b

% Inequality constraint matrix
A = -[carbfraction.*growthrate;proteinfraction.*growthrate;fatfraction.*growthrate];

% Inequality values
b = -[targetcarbs;targetprotein;targetfat];

% Solve linear program (can zero out crops)
[x,fval,exitflag,output] = linprog(f,A,b,[],[],zeros(9,1),[]);

% Repeat problem except now the cost function is to minimize the average of
% the mass of plants grown (even distribution of plants by mass)
f2 = growthrate/9;

[x2,fval2,exitflag2,output2] = linprog(f2,A,b,[],[],zeros(9,1),[]);

%% Treat problem as mixed integer linear program
% intcon = 1:9;       % components of x vector that should be integers
% 
% % Minimize area
% [x3,fval3,exitflag3,output3] = intlinprog(f,intcon,A,b,[],[],zeros(9,1),[]);

%% non-linear cost function
f3 = @(x) 2.75/3.75*std(x)+1/3.75*sum(x);

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

    
    