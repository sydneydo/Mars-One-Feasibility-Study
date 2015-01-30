%% Mars One Plant Test
% Code to test plant growth strategies for the Mars One feasibility study

% By:               Sydney Do
% Created:          11/12/2014
% Last Modified:    11/13/2014

% Replicate original WheatShelf Test.xml <-- obsolete comment

clear all
clc

simtime = 10000;       % hours

plant = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001);%,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.
plant.temperature = 20;
targetCO2conc = 1200*1E-6;
CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
plant.CO2Store.add(CO2toInject);

%% Initialize Stores
PotableWaterStore = StoreImpl('Potable H2O','Material',100000,100000);

DirtyWaterStore = StoreImpl('Dirty H2O','Material',100000,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

GreyWaterStore = StoreImpl('Grey H2O','Material',1000000,1000000);

% Power Stores
MainPowerStore = StoreImpl('Power','Material',100000000,100000000);

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

% Biomass Stores
BiomassStore = BiomassStoreImpl(100000);

% Food Store
FoodStore = FoodStoreImpl(100000);

%% Initialize BiomassPS
growthArea = 10;
WhitePotatoShelf = ShelfImpl2(Wheat,growthArea,plant,GreyWaterStore,PotableWaterStore,MainPowerStore,BiomassStore);

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
    

    if GreyWaterStore.currentLevel <= 0
        disp(['Grey Water Store is empty at tick: ',num2str(i)])
        break
    end
    
    % Tick Shelves    
    WhitePotatoShelf.tick;

    
    
%     CO2toInject = (targetCO2conc*plant.totalMoles-plant.CO2Store.currentLevel)/(1-targetCO2conc);
%     plant.CO2Store.add(CO2toInject);
    
    
%     FoodProcessor.tick;
%     foodstorelevel(i) = FoodStore.currentLevel;
%     if FoodStore.currentLevel > 0
%         
%         dryfoodlevel(i) = sum(cell2mat({FoodStore.foodItems.Mass})-cell2mat({FoodStore.foodItems.WaterContent}));
%         caloriccontent(i) = sum([FoodStore.foodItems.CaloricContent]);
%     end
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