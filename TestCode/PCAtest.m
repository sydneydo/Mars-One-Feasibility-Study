%% Scribble code - PCA Test
 
clear all
clc
 
%% Key Mission Parameters
TotalAtmPressureTargeted = 70.3;        % targeted total atmospheric pressure, in kPa
TargetO2MolarFraction = 0.265; 
TotalPPO2Targeted = TargetO2MolarFraction*TotalAtmPressureTargeted;               % targeted O2 partial pressure, in kPa (converted from 26.5% O2)

%% Initialize SimEnvironments
% Convert daily leakage rate to hourly leakage rate
dailyLeakagePercentage = 0.05;      % Based on BVAD Table 4.1.1 for percentage of total gas mass lost per day 
% Let H = hourLeakagePercentage and initial total moles of gas = n_init
% Therefore we want:
% n_init*(1-dailyLeakagePercentage/100) = n_init*(1-H/100)^24
% Solving for H yields:
% H = 100*(1-(1-dailyLeakagePercentage/100)^(1/24))
 
% Using the above derived equation:
hourlyLeakagePercentage = 100*(1-(1-dailyLeakagePercentage/100)^(1/24));
Inflatable1 = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);
 
% O2 Store within Life Support Units (note O2 capacity measured in moles)
initialO2TankCapacityInKg = 100.2;      % Calculated initial O2 tank capacity based on support crew for 60 days, note that another source on the Mars One webpage suggests a 60kg initial capacity for each living unit tank <http://www.mars-one.com/mission/roadmap/2023>
o2MolarMass = 2*15.999; % g/mol
initialO2StoreMoles = initialO2TankCapacityInKg*1E3/o2MolarMass;
O2Store = StoreImpl('O2 Store','Material',initialO2StoreMoles,initialO2StoreMoles);
 
% N2 Store
% Corresponds to 2x high pressure N2 tanks currently mounted on exterior of Quest airlock on ISS (each holds 91kg of N2)
% This is subject to change based on requirements
numberOfN2Tanks = 2;
initialN2TankCapacityInKg = numberOfN2Tanks*91;
n2MolarMass = 2*14.007; %g/mol;
initialN2StoreMoles = initialN2TankCapacityInKg*1E3/n2MolarMass;
N2Store = StoreImpl('N2 Store','Material',initialN2StoreMoles,initialN2StoreMoles);  
 
inflatableO2inj = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Inflatable1);
 
timesteps = 10000;
 
totalmoles = zeros(1,timesteps);
totalpressure = zeros(1,timesteps);
o2moles = zeros(1,timesteps);
co2moles = zeros(1,timesteps);
n2moles = zeros(1,timesteps);
vapormoles = zeros(1,timesteps);
othermoles = zeros(1,timesteps);
o2percentage = zeros(1,timesteps);
PCAaction = zeros(4,timesteps);
PCAaction(:,1) = zeros(4,1);

for i = 1:timesteps
    totalmoles(i) = Inflatable1.totalMoles;
    totalpressure(i) = Inflatable1.pressure;
    o2moles(i) = Inflatable1.O2Store.currentLevel;
    co2moles(i) = Inflatable1.CO2Store.currentLevel;
    n2moles(i) = Inflatable1.NitrogenStore.currentLevel;
    vapormoles(i) = Inflatable1.VaporStore.currentLevel;
    othermoles(i) = Inflatable1.OtherStore.currentLevel;
    o2percentage(i) = Inflatable1.O2Percentage;
    
    Inflatable1.tick;
    PCAaction(:,i+1) = inflatableO2inj.tick(PCAaction(:,i));
end

