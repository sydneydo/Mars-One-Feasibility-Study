%% Mars One Plant Test
% Code to test plant growth strategies for the Mars One feasibility study

% By:               Sydney Do
% Created:          8/18/2014
% Last Modified:    8/18/2014

% Replicate original WheatShelf Test.xml

clear all
clc

simtime = 19000;       % hours

targetCO2conc = 1200*1E-6;
% plant = SimEnvironmentImpl('Plant Growth Environment',55,1000000,0.28,targetCO2conc,(1-targetCO2conc-0.28-0.03194-0.001),0.03194,0.001,0);     %,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.
plant = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001);%,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.
plant.temperature = 20;

%% Initialize Stores
PotableWaterStore = StoreImpl('Potable H2O','Material',100000,100000);

DirtyWaterStore = StoreImpl('Dirty H2O','Material',100000,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

GreyWaterStore = StoreImpl('Grey H2O','Material',100000,100000);

% Power Stores
MainPowerStore = StoreImpl('Power','Material',100000000,100000000);

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

% Biomass Stores
BiomassStore = BiomassStoreImpl(100000);

% Food Store
FoodStore = FoodStoreImpl(100000);

%% Initialize BiomassPS

% WheatShelf = ShelfImpl2(Wheat,25);
% DryBeanShelf = ShelfImpl2(DryBean,15);
daysTilCropMaturity = 138;
timeTilCropMaturity = daysTilCropMaturity*24;


dailyGrowthRate = 16.821715823162/1000;     %kg/day/m^2
growthRatePerCycle = dailyGrowthRate*daysTilCropMaturity;       %kg/CropCycle/m^2

% Want each crop cycle to equal the target daily supply (for a daily
% harvest)
targetDailySupply = 1.76461;%2.21;       % kg/day

% growthArea = targetDailySupply/growthRatePerCycle;
optimizedGrowthArea =1; % 104.9007;     % This approach only works if you've calibrated the growth/day/m^2 areas correctly, in adherence to the MEC models
numberOfPlots = 1; %5;
% growthArea = optimizedGrowthArea/numberOfPlots*ones(1,numberOfPlots);
growthArea = 100;
CropGrowthStartDays = (0:(numberOfPlots-1))*timeTilCropMaturity/numberOfPlots;

WhitePotatoShelf = ShelfImpl2(WhitePotato,growthArea,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);
% WhitePotatoShelf2 = ShelfImpl2(WhitePotato,5,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore,138*24/2);

% WhitePotatoShelf = ShelfImpl2.empty(0,daysTilCropMaturity);
% 
% for i = 1:numberOfPlots
%     WhitePotatoShelf(i) = ShelfImpl2(DryBean,growthArea(i),plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore,CropGrowthStartDays(i));
% end

% WhitePotatoShelf(i) = ShelfImpl2(DryBean,growthArea(i),plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore,CropGrowthStartDays(i));

growthArea = [54.7489,63.9891,25.3224,6.3862,49.1451];  % Growth areas calculated from the plant optimizer

% Initialize crop shelves
LettuceShelf = ShelfImpl2(Lettuce,26.15,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);
PeanutShelf = ShelfImpl2(Peanut,69.88,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);
SoybeanShelf = ShelfImpl2(Soybean,34.76,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);
SweetPotatoShelf = ShelfImpl2(SweetPotato,1.65,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);
WheatShelf = ShelfImpl2(Wheat,67.52,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);

% biomassSystem = BiomassPSImpl([WhitePotatoShelf]);
% biomassSystem = BiomassPSImpl([WheatShelf,DryBeanShelf,WhitePotatoShelf]);
% numberOfShelves = 1;
% defaultrate = 1000;

% biomassSystem.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate,defaultrate);

%% Initialize FoodProcessor
FoodProcessor = FoodProcessorImpl;
FoodProcessor.BiomassConsumerDefinition = ResourceUseDefinitionImpl(BiomassStore,1000,1000);
FoodProcessor.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1000,1000);
FoodProcessor.FoodProducerDefinition = ResourceUseDefinitionImpl(FoodStore,1000,1000);
FoodProcessor.WaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);
FoodProcessor.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,1000,1000);

%% Time Loop
% Initialize data vectors
plantO2level = zeros(1,simtime);
plantN2level = zeros(1,simtime);
plantCO2level = zeros(1,simtime);
plantVaporlevel = zeros(1,simtime);
plantOtherlevel = zeros(1,simtime);
plantTotalMoles = zeros(1,simtime);
plantCO2percentage = zeros(1,simtime);

cropAvgPPF = zeros(1,simtime);
cropAvgCO2 = zeros(1,simtime);
cropgrowthrate = zeros(1,simtime);

potablewaterstorelevel = zeros(1,simtime);
dirtywaterstorelevel = zeros(1,simtime);
greywaterstorelevel = zeros(1,simtime);
drywastestorelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
biomassstorelevel = zeros(1,simtime);
foodstorelevel = zeros(1,simtime);
dryfoodlevel = zeros(1,simtime);
caloriccontent = zeros(1,simtime);

h = waitbar(0,'Please wait...');
tic
for i = 1:simtime
    
    plantO2level(i) = plant.O2Store.currentLevel;
    plantN2level(i) = plant.NitrogenStore.currentLevel;
    plantCO2level(i) = plant.CO2Store.currentLevel;
    plantVaporlevel(i) = plant.VaporStore.currentLevel;
    plantOtherlevel(i) = plant.OtherStore.currentLevel;
    plantTotalMoles(i) = plant.totalMoles;
    plantCO2percentage(i) = plant.CO2Percentage;
%     cropAvgPPF(i) = WhitePotatoShelf.AveragePPF;
%     cropAvgCO2(i) = WhitePotatoShelf.AverageCO2Concentration;
    
    potablewaterstorelevel(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel(i) = DirtyWaterStore.currentLevel;
    greywaterstorelevel(i) = GreyWaterStore.currentLevel;
    drywastestorelevel(i) = DryWasteStore.currentLevel;
    biomassstorelevel(i) = BiomassStore.currentLevel;
    powerlevel(i) = MainPowerStore.currentLevel;
    
%     for j = 1:length(WhitePotatoShelf)
%         WhitePotatoShelf(j).tick;
%     end

    LettuceShelf.tick;
    CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
    plant.CO2Store.add(CO2toInject);
    
    PeanutShelf.tick;
    CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
    plant.CO2Store.add(CO2toInject);
    
    SoybeanShelf.tick;
    CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
    plant.CO2Store.add(CO2toInject);
    
    SweetPotatoShelf.tick;
    CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
    plant.CO2Store.add(CO2toInject);
    
    WheatShelf.tick;
    CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
    plant.CO2Store.add(CO2toInject);

%     WhitePotatoShelf2.tick;
%     cropgrowthrate(i) = WhitePotatoShelf.CropGrowthRate;
    FoodProcessor.tick;
    foodstorelevel(i) = FoodStore.currentLevel;
    if FoodStore.currentLevel > 0
        
        dryfoodlevel(i) = sum(cell2mat({FoodStore.foodItems.Mass})-cell2mat({FoodStore.foodItems.WaterContent}));
        caloriccontent(i) = sum([FoodStore.foodItems.CaloricContent]);
%         dryfoodlevel(i) = FoodStore.foodItems.Mass-FoodStore.foodItems.WaterContent;
    end
    % Inject appropriate amount of CO2 into plant environment to
    % maintain targetCO2conc
%     CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
%     plant.CO2Store.add(CO2toInject);
    
    % Tick Waitbar  
    if mod(i,100) == 0
        waitbar(i/simtime);
    end
end
toc
close(h)
beep

figure, plot(biomassstorelevel,'LineWidth',2),grid on, title('Biomass Store')

figure, plot(foodstorelevel,'LineWidth',2),grid on, title('Food Store')

figure, plot(dryfoodlevel,'LineWidth',2),grid on, title('Dry Food Level')

figure, plot(caloriccontent,'LineWidth',2),grid on, title('Caloric Content within Food Store')

figure, plot(greywaterstorelevel,'LineWidth',2),grid on, title('Grey Water Store')

figure, plot(dirtywaterstorelevel,'LineWidth',2),grid on, title('Dirty Water Store')

figure, plot(drywastestorelevel,'LineWidth',2),grid on, title('Dry Waste Store')

% CO2 concentration
figure, plot(plantCO2level*1E6./plantTotalMoles,'LineWidth',2),grid on, title('Plant Environment CO2 Concentration (micromoles/mole)')
figure, plot(plantCO2percentage,'LineWidth',2),grid on, title('Plant Environment CO2 Molar Fraction')

% crop growth rate
% figure, plot(t,cropgrowthrate,'LineWidth',2),grid on, title('Crop Growth Rate (moles/m^2/hour)')
t = (1:length(cropgrowthrate))/24;
figure, plot(t,cropgrowthrate/12.011*WhitePotatoShelf.Crop.BCF,'LineWidth',2),grid on, title('Crop Growth Rate (moles/m^2/day)')
xlim([0 150]),ylim([0 1.5])

% Plot PPF
figure, plot(cropAvgPPF,'LineWidth',2),grid on, title('Crop Average PPF')

% Plot average CO2 concentration
figure, plot(cropAvgCO2,'LineWidth',2),grid on, title('Crop Average CO2 Concentration (micromoles/mole)')