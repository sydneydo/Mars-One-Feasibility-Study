%% myBioSim Test Code

clear all
clc
% close all

%% Initialize Crew Environments
hab = SimEnvironmentImpl('Crew Quarters',55,2700000,0.33,0,0.659,0.01,0.001);
% hab.tick
% hab.O2Store

maint = SimEnvironmentImpl('Maintenance',55,19000,0.33,0,0.659,0.01,0.001);

% Plant Environment
plant = SimEnvironmentImpl('Plant Environment',55,1000000,0.28,0.19,0.519,0.01,0.001);

%% Initialize Stores
PotableWaterStore = StoreImpl('Potable H2O','Material',100000,10000);
DirtyWaterStore = StoreImpl('Dirty H2O','Material',1000000,0);
GreyWaterStore = StoreImpl('Grey H2O','Material',50000,50000);
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);

PowerStore = StoreImpl('Power','Material',100000000,100000000);

CO2Store = StoreImpl('CO2 Store','Material',1000,0);    % CO2 store for VCCR
H2Store = StoreImpl('H2 Store','Material',10000,0);     % H2 store for output of OGS
MethaneStore = StoreImpl('CH4 Store','Material',1000,0);    % CH4 store for output of CRS (Sabatier)
O2Store = StoreImpl('O2 Store','Material',10000,1000);    % O2 store for OGS output

% FoodStore = StoreImpl('Food','Material');
% FoodStore.currentLevel = 10000;
% FoodStore.currentCapacity = 10000;

% caloriesNeeded = 4E7;   % Test value
% limitingMass = 5;   % Test value
xmlFoodStoreLevel = 1000;
xmlFoodStoreCapacity = 10000;
defaultFoodWaterContent = 5;
initialfood = FoodMatter(Wheat,xmlFoodStoreLevel,defaultFoodWaterContent); % xmlFoodStoreLevel is declared within the createFoodStore method within SimulationInitializer.java

% FoodStore = FoodStoreImpl(xmlFoodStoreCapacity,initialfood);
FoodStore = FoodStoreImpl(xmlFoodStoreCapacity);

xml_inedibleFraction = 0.25;
xml_edibleWaterContent = 5;
xml_inedibleWaterContent = 5;
initialBiomatter = [BioMatter(Wheat,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent),...
    BioMatter(Rice,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent),...
    BioMatter(Rice,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent)];
% BiomassStore = BiomassStoreImpl(BioMatter(Wheat,0,0,0,0),100000);
BiomassStore = BiomassStoreImpl(100000);
% Set more crop type for FoodMatter somewhere later on

%% Initialize BiomassPS
WheatShelf = ShelfImpl2(Wheat,25);
DryBeanShelf = ShelfImpl2(DryBean,15);
WhitePotatoShelf = ShelfImpl2(WhitePotato,10);
biomassSystem = BiomassPSImpl([WheatShelf,DryBeanShelf,WhitePotatoShelf]);
numberOfShelves = 3;
defaultrate = 1000;

biomassSystem.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,defaultrate,defaultrate);
biomassSystem.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate,defaultrate);
biomassSystem.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate,defaultrate);
biomassSystem.AirConsumerDefinition = ResourceUseDefinitionImpl(plant,defaultrate,defaultrate);
biomassSystem.AirProducerDefinition = ResourceUseDefinitionImpl(plant,defaultrate,defaultrate);
% biomassSystem.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
biomassSystem.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000,10000);
				

WheatShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.AirProducerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
WheatShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);				

DryBeanShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.AirProducerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
DryBeanShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

WhitePotatoShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirProducerDefinition = ResourceUseDefinitionImpl(plant,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WhitePotatoShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
WhitePotatoShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

%% Initialize FoodProcessor
FoodProcessor = FoodProcessorImpl;
FoodProcessor.BiomassConsumerDefinition = ResourceUseDefinitionImpl(BiomassStore,1000,1000);
FoodProcessor.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,1000,1000);
FoodProcessor.FoodProducerDefinition = ResourceUseDefinitionImpl(FoodStore,1000,1000);
FoodProcessor.WaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);
FoodProcessor.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,1000,1000);

%% Test WheatShelf
simtime = 6000;
dailycarbongain = zeros(1,simtime);
foodlevel = zeros(1,simtime);
drywastelevel = zeros(1,simtime);
avgPPF = zeros(1,simtime);
ppffractionabsorbed = zeros(1,simtime);
atmpressure = zeros(1,simtime);
dailyCanopyTranspirationRate = zeros(1,simtime);
waterfraction = zeros(1,simtime);
avgCO2 = zeros(1,simtime);
cqy = zeros(1,simtime);
plantwaterlevel = zeros(1,simtime);
timetilcanopyclosure = zeros(1,simtime);
canopyClosed = zeros(1,simtime);
o2level = zeros(1,simtime);
co2level = zeros(1,simtime);
vaporlevel = zeros(1,simtime);
n2level = zeros(1,simtime);
otherlevel = zeros(1,simtime);
biomasslevel = zeros(1,simtime);
potablewaterlevel = zeros(1,simtime);
dirtywaterlevel = zeros(1,simtime);
greywaterlevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
for i = 1:simtime
    WheatShelf.tick;
    DryBeanShelf.tick;
    WhitePotatoShelf.tick;
    FoodProcessor.tick
    foodlevel(i) = FoodStore.currentLevel;
    drywastelevel(i) = DryWasteStore.currentLevel;
%     dailycarbongain(i) = WheatShelf.DailyCarbonGain;
%     atmpressure(i) = plant.pressure;
%     waterfraction(i) = WheatShelf.WaterFraction;
%     ppffractionabsorbed(i) = WheatShelf.PPFFractionAbsorbed;
%     dailyCanopyTranspirationRate(i) = WheatShelf.DailyCanopyTranspirationRate;
%     avgPPF(i) = WheatShelf.AveragePPF;
%     avgCO2(i) = WheatShelf.AverageCO2Concentration;
%     cqy(i) = WheatShelf.CQY;
%     plantwaterlevel(i) = WheatShelf.WaterLevel;
%     canopyClosed(i) = WheatShelf.canopyClosed;
%     timetilcanopyclosure(i) = WheatShelf.TimeTillCanopyClosure;
    o2level(i) = plant.O2Store.currentLevel;
    co2level(i) = plant.CO2Store.currentLevel;
    vaporlevel(i) = plant.VaporStore.currentLevel;
    n2level(i) = plant.NitrogenStore.currentLevel;
    otherlevel(i) = plant.OtherStore.currentLevel;
    biomasslevel(i) = BiomassStore.currentLevel;
    potablewaterlevel(i) = PotableWaterStore.currentLevel;
    dirtywaterlevel(i) = DirtyWaterStore.currentLevel;
    greywaterlevel(i) = GreyWaterStore.currentLevel;
    powerlevel(i) = PowerStore.currentLevel;
end


%% Initialize Fan
fan = FanImpl;
fan.AirConsumerDefinition = ResourceUseDefinitionImpl(hab,1000,1000);
fan.AirProducerDefinition = ResourceUseDefinitionImpl(maint,1000,1000);
fan.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,50,50);

%% Initialize Dehumidifier
dehumidifier = DehumidifierImpl;
dehumidifier.AirConsumerDefinition = ResourceUseDefinitionImpl(hab,1000,1000);
dehumidifier.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);

%% Initialize VCCR (Linear)
% For now, we connect the VCCR to the hab module
vccr = VCCRLinearImpl;
vccr.AirConsumerDefinition = ResourceUseDefinitionImpl(hab,10000,10000);
vccr.AirProducerDefinition = ResourceUseDefinitionImpl(hab,10000,10000);
vccr.CO2ProducerDefinition = ResourceUseDefinitionImpl(CO2Store,10000,10000);
vccr.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,2000,2000);

%% Initialize WaterRS (Linear)
% We connect the WaterRS to the grey, dirty, and potable water stores
waterRS = WaterRSLinearImpl;
waterRS.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,10,10);
waterRS.DirtyWaterConsumerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,10,10);
waterRS.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,1000,1000);
waterRS.PotableWaterProducerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,1000,1000);

%% Initialize OGS
% We connect the OGS directly to the hab and the potable water stores
ogs = OGSImpl;
ogs.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,1000,1000);
ogs.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,10,10);
ogs.O2ProducerDefinition = ResourceUseDefinitionImpl(O2Store,1000,1000);
ogs.H2ProducerDefinition = ResourceUseDefinitionImpl(H2Store,1000,1000);

%% Initialize CRS (Sabatier Reactor)
% We connect the CRS to the CO2, H2, CH4 and potable water stores
crs = CRSImpl;
crs.CO2ConsumerDefinition = ResourceUseDefinitionImpl(CO2Store,100,100);
crs.H2ConsumerDefinition = ResourceUseDefinitionImpl(H2Store,100,100);
crs.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,100,100);
crs.PotableWaterProducerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,100,100);
crs.MethaneProducerDefinition = ResourceUseDefinitionImpl(MethaneStore,100,100);

%% Initialize Pyrolizer
pyro = PyrolizerImpl;
pyro.PowerConsumerDefinition = ResourceUseDefinitionImpl(PowerStore,100,100);
pyro.MethaneConsumerDefinition = ResourceUseDefinitionImpl(MethaneStore,100,100);
pyro.H2ProducerDefinition = ResourceUseDefinitionImpl(H2Store,100,100);
pyro.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,100,100);

%% Initialize Power Production System
powerPS = PowerPSImpl('Nuclear',500000);
powerPS.PowerProducerDefinition = ResourceUseDefinitionImpl(PowerStore,1E6,1E6);
% powerPS.LightConsumerDefinition = hab;

%% Initialize CrewPersons
% Crew in Crew Quarters (hab)
astro1 = CrewPersonImpl('Buck Rogers',35,75,'Male',[]);
activity(1) = ActivityImpl('Ruminating',2,12);
activity(2) = ActivityImpl('Sleep',0,8);
activity(3) = ActivityImpl('Exercise',5,2);
activity(4) = ActivityImpl('EVA',4,2);
astro1.addSchedule(activity);

% Initialize consumer and producer definitions
astro1.AirConsumerDefinition = AirConsumerDefinitionImpl(hab,0,0);
astro1.AirProducerDefinition = AirProducerDefinitionImpl(hab,0,0);
astro1.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro1.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro1.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro1.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro1.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);

% Crew in Maintenance Module (maint)
astro2 = CrewPersonImpl('Kane',35,77,'Male',[]);
activity2(1) = ActivityImpl('Ruminating',2,12);
activity2(2) = ActivityImpl('Sleep',0,8);
activity2(3) = ActivityImpl('Exercise',5,2);
% activity2(4) = ActivityImpl('EVA',4,2);
astro2.addSchedule(activity2);

% Initialize consumer and producer definitions
astro2.AirConsumerDefinition = AirConsumerDefinitionImpl(maint,0,0);
astro2.AirProducerDefinition = AirProducerDefinitionImpl(maint,0,0);
astro2.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro2.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro2.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro2.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro2.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);

%% Initialize CrewGroup
% Add crewmembers and declare resource consumption and production
% relationships
testgroup = CrewGroupImpl('Test Group');
testgroup.addCrewMembers(astro1)

% % Initialize AirConsumerDefinition
% testgroup.AirConsumerDefinition = AirConsumerDefinitionImpl(hab,1000,1000);

% testgroup.AirConsumerDefinition
% testgroup.AirConsumerDefinition.ConsumptionStore

%% Code to Test Advance Activity
t = 0;
for i = 1:24

    advanceActivity(astro1)
    intensity(i) = astro1.CurrentActivity.Intensity;
    id(i) = astro1.CurrentActivity.ID;
end
figure, plot(1:24,id,'o',1:24,intensity,'o')
figure, bar(1:24,id)

%% Code to Test CrewPersonImpl.tick
% tic

simtime = 10000;
O2level = zeros(1,simtime);
CO2level = zeros(1,simtime);
H2level = zeros(1,simtime);
CH4level = zeros(1,simtime);
vaporlevel = zeros(1,simtime);
intensity = zeros(1,simtime);
H2Ostorelevel = zeros(1,simtime);
DirtyH2Ostorelevel = zeros(1,simtime);
GreyH2Ostorelevel = zeros(1,simtime);
FoodStoreLevel = zeros(1,simtime);
DryStoreLevel = zeros(1,simtime);
CO2conc = zeros(1,simtime);
O2conc = zeros(1,simtime);
vaporconc = zeros(1,simtime);
CO2storelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
pres = zeros(1,simtime);

h = waitbar(0,'Please wait...');
tic
for i = 1:simtime
    if astro1.alive == 0 %|| astro2.alive == 0
        break
    end
    hab.tick;
    astro1.tick;
%     astro2.tick;
    powerPS.tick;
    waterRS.tick;
    dehumidifier.tick
    ogs.tick;
    crs.tick;
    vccr.tick;
    
%     fan.tick;
    O2level(i) = astro1.AirConsumerDefinition.ConsumptionStore.O2Store.currentLevel;
    CO2level(i) = astro1.AirProducerDefinition.ProductionStore.CO2Store.currentLevel;
    H2level(i) = H2Store.currentLevel;
    CH4level(i) = MethaneStore.currentLevel;
    vaporlevel(i) = astro1.AirProducerDefinition.ProductionStore.VaporStore.currentLevel;
    intensity(i) = astro1.CurrentActivity.Intensity;
    H2Ostorelevel(i) = PotableWaterStore.currentLevel;
    DirtyH2Ostorelevel(i) = DirtyWaterStore.currentLevel;
    GreyH2Ostorelevel(i) = GreyWaterStore.currentLevel;
    FoodStoreLevel(i) = FoodStore.currentLevel;
    DryStoreLevel(i) = DryWasteStore.currentLevel;
    O2conc(i) = hab.O2Percentage;
    CO2conc(i) = hab.CO2Percentage;
    vaporconc(i) = hab.VaporPercentage;
    CO2storelevel(i) = CO2Store.currentLevel;
    powerlevel(i) = PowerStore.currentLevel;
    pres(i) = hab.pressure;
%     CO2concMain(i) = maint.CO2Percentage;
%     O2concMain(i) = maint.O2Percentage;
%     O2levelMain(i) = maint.O2Store.currentLevel;
    waitbar(i/simtime)

end

toc

close(h)

figure, plot(1:length(O2level),O2level), grid on
figure, plot(1:length(CO2level),CO2level), grid on
figure, plot(1:length(H2level),H2level), grid on
figure, plot(1:length(CH4level),CH4level), grid on
figure, plot(1:length(vaporlevel),vaporlevel), grid on
figure, plot(1:length(H2Ostorelevel),H2Ostorelevel), grid on
figure, plot(1:length(DirtyH2Ostorelevel),DirtyH2Ostorelevel), grid on
figure, plot(1:length(FoodStoreLevel),FoodStoreLevel), grid on
figure, plot(1:length(DryStoreLevel),DryStoreLevel), grid on
figure, plot(1:length(CO2conc),CO2conc), grid on
figure, plot(1:length(O2conc),O2conc), grid on
figure, plot(1:length(vaporconc),vaporconc), grid on
figure, plot(1:length(CO2concMain),CO2concMain), grid on
figure, plot(1:length(O2concMain),O2concMain), grid on
figure, plot(1:length(O2levelMain),O2levelMain), grid on
figure, plot(1:length(pres),pres), grid on
figure, plot(1:length(CO2storelevel),CO2storelevel), grid on
figure, plot(1:length(powerlevel),powerlevel), grid on
figure, plot(1:length(intensity),intensity)
