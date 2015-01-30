%% Mars One Plant Test
% Code to test plant growth strategies for the Mars One feasibility study

% By:               Sydney Do
% Created:          12/10/2014
% Last Modified:    12/10/2014

% Last modification performed to test the implementation of modifications
% in the plant code to account for low [CO2] conditions

% Current test plant is wheat (time to maturity = 62 days)

clear all
clc

simtime = 200*24;       % hours

targetCO2conc = 1200*1E-6;
plant = SimEnvironmentImpl('Plant Growth Environment',55,1000000,0.28,targetCO2conc,(1-targetCO2conc-0.28-0.01-0.001),0.01,0.001,0);     %,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.
% SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001);%,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.

plant.temperature = 20;

%% Initialize Stores
PotableWaterStore = StoreImpl('Potable H2O','Material',100000,100000);

DirtyWaterStore = StoreImpl('Dirty H2O','Material',500,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

GreyWaterStore = StoreImpl('Grey H2O','Material',50000,50000);

% Power Stores
MainPowerStore = StoreImpl('Power','Material',100000000,100000000);

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

% Biomass Stores
BiomassStore = BiomassStoreImpl(100000);

%% Initialize BiomassPS

% WheatShelf = ShelfImpl2(Wheat,25);
% DryBeanShelf = ShelfImpl2(DryBean,15);
% WhitePotatoShelf = ShelfImpl2(WhitePotato,104.9007);
WheatShelf = ShelfImpl2(Wheat,104.9007,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);


%% Time Loop
% Initialize data vectors
plantO2level2 = zeros(1,simtime);
plantN2level2 = zeros(1,simtime);
plantCO2level2 = zeros(1,simtime);
plantVaporlevel2 = zeros(1,simtime);
plantOtherlevel2 = zeros(1,simtime);
plantTotalMoles2 = zeros(1,simtime);
plantCO2percentage2 = zeros(1,simtime);

cropAvgPPF2 = zeros(1,simtime);
cropAvgCO22 = zeros(1,simtime);
cropgrowthrate2 = zeros(1,simtime);

potablewaterstorelevel2 = zeros(1,simtime);
dirtywaterstorelevel2 = zeros(1,simtime);
greywaterstorelevel2 = zeros(1,simtime);
drywastestorelevel2 = zeros(1,simtime);
powerlevel2 = zeros(1,simtime);
biomassstorelevel2 = zeros(1,simtime);
dailycarbongain = zeros(1,simtime);
co2molesinhaled = zeros(1,simtime);
o2molesexhaled = zeros(1,simtime);

h = waitbar(0,'Please wait...');
tic
for i = 1:simtime
    
    plantO2level2(i) = plant.O2Store.currentLevel;
    plantN2level2(i) = plant.NitrogenStore.currentLevel;
    plantCO2level2(i) = plant.CO2Store.currentLevel;
    plantVaporlevel2(i) = plant.VaporStore.currentLevel;
    plantOtherlevel2(i) = plant.OtherStore.currentLevel;
    plantTotalMoles2(i) = plant.totalMoles;
    plantCO2percentage2(i) = plant.CO2Percentage;
    cropAvgPPF2(i) = WheatShelf.AveragePPF;
    cropAvgCO22(i) = WheatShelf.AverageCO2Concentration;
    
    potablewaterstorelevel2(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel2(i) = DirtyWaterStore.currentLevel;
    greywaterstorelevel2(i) = GreyWaterStore.currentLevel;
    drywastestorelevel2(i) = DryWasteStore.currentLevel;
    biomassstorelevel2(i) = BiomassStore.currentLevel;
    powerlevel2(i) = MainPowerStore.currentLevel;
    
    WheatShelf.tick;
    cropgrowthrate2(i) = WheatShelf.CropGrowthRate;
    dailycarbongain(i) = WheatShelf.DailyCarbonGain;
    co2molesinhaled(i) = WheatShelf.MolesOfCO2Inhaled;
    o2molesexhaled(i) = WheatShelf.MolesOfO2Exhaled;
    % Inject appropriate amount of CO2 into plant environment to
    % maintain targetCO2conc
%     CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
%     plant.CO2Store.add(CO2toInject);
    
    % Tick Waitbar  
    waitbar(i/simtime);
end
toc
close(h)

figure, plot(biomassstorelevel2,'LineWidth',2),grid on, title('Wheat Biomass Production')

% CO2 concentration
figure, plot(plantCO2level2*1E6./plantTotalMoles2,'LineWidth',2),grid on, title('Plant Environment CO2 Concentration (micromoles/mole)')
figure, plot(plantCO2percentage,'LineWidth',2),grid on, title('Plant Environment CO2 Molar Fraction')

% CO2 Level
figure, plot(plantCO2level2,'LineWidth',2), grid on, title('Ambient CO2 Level (moles)')
% crop growth rate
% figure, plot(t,cropgrowthrate,'LineWidth',2),grid on, title('Crop Growth Rate (moles/m^2/hour)')
%% Validation Plot for Crop Growth Rate with Figure 5 of Crop Models for Varying Environmental Conditions
t = (1:length(cropgrowthrate2))/24+5;
figure, plot(t,cropgrowthrate2/12.011*WheatShelf.Crop.BCF,'LineWidth',2),grid on, title('Crop Growth Rate (moles/m^2/day)')
xlim([0 150]),ylim([0 1.5])

figure, plot(dailycarbongain,'LineWidth',2),grid on, title('Daily Carbon Gain')


% Plot PPF
figure, plot(cropAvgPPF,'LineWidth',2),grid on, title('Crop Average PPF')

% Plot average CO2 concentration
figure, plot(cropAvgCO2,'LineWidth',2),grid on, title('Crop Average CO2 Concentration (micromoles/mole)')