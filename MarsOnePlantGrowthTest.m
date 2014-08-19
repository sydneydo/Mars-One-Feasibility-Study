%% Mars One Plant Test
% Code to test plant growth strategies for the Mars One feasibility study

% By:               Sydney Do
% Created:          8/18/2014
% Last Modified:    8/18/2014

% Replicate original WheatShelf Test.xml

clear all
clc

simtime = 6000;       % hours

plant = SimEnvironmentImpl('Plant Growth Environment',55,1000000,0.28,0.019,0.69,0.01,0.001,0);     %,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,FoodStore);     %Note volume input is in Liters.

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
WhitePotatoShelf = ShelfImpl2(WhitePotato,25);
% biomassSystem = BiomassPSImpl([WhitePotatoShelf]);
% biomassSystem = BiomassPSImpl([WheatShelf,DryBeanShelf,WhitePotatoShelf]);
numberOfShelves = 1;
defaultrate = 1000;

% biomassSystem.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate,defaultrate);
% biomassSystem.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate,defaultrate);
% biomassSystem.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate,defaultrate);
% biomassSystem.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
% biomassSystem.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
% % biomassSystem.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);      % Note that plant model does not consume dirty water! (Only grey and potable water - grey should be preferred!)			
% biomassSystem.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000,10000);
				

% WheatShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% % WheatShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
% WheatShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);				
% 
% DryBeanShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% % DryBeanShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
% DryBeanShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

WhitePotatoShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirProducerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WhitePotatoShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
WhitePotatoShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

%% Time Loop
% Initialize data vectors
plantO2level = zeros(1,simtime);
plantN2level = zeros(1,simtime);
plantCO2level = zeros(1,simtime);
plantVaporlevel = zeros(1,simtime);
plantOtherlevel = zeros(1,simtime);

potablewaterstorelevel = zeros(1,simtime);
dirtywaterstorelevel = zeros(1,simtime);
greywaterstorelevel = zeros(1,simtime);
drywastestorelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
biomassstorelevel = zeros(1,simtime);

for i = 1:simtime
    
    plantO2level(i) = plant.O2Store.currentLevel;
    plantN2level(i) = plant.NitrogenStore.currentLevel;
    plantCO2level(i) = plant.CO2Store.currentLevel;
    plantVaporlevel(i) = plant.VaporStore.currentLevel;
    plantOtherlevel(i) = plant.OtherStore.currentLevel;
    
    potablewaterstorelevel(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel(i) = DirtyWaterStore.currentLevel;
    greywaterstorelevel(i) = GreyWaterStore.currentLevel;
    drywastestorelevel(i) = DryWasteStore.currentLevel;
    biomassstorelevel(i) = BiomassStore.currentLevel;
    powerlevel(i) = MainPowerStore.currentLevel;
    
    WhitePotatoShelf.tick;
end

figure, plot(biomassstorelevel,'LineWidth',2),grid on, title('White Potato Biomass Production')
