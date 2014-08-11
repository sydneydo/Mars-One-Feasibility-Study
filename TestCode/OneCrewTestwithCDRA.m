%% Scribble code - PCA Test
 
clear all
clc

tic

%% Key Mission Parameters
TotalAtmPressureTargeted = 70.3;        % targeted total atmospheric pressure, in kPa
TargetO2MolarFraction = 0.265; 
O2FractionHypoxicLimit = 0.23;          % lower bound for a 70.3kPa atm based on EAWG Fig 4.1.1 and Advanced Life Support Requirements Document Fig 4-3
TotalPPO2Targeted = TargetO2MolarFraction*TotalAtmPressureTargeted;               % targeted O2 partial pressure, in kPa (converted from 26.5% O2)

numberOfEVAdaysPerWeek = 5;
numberOfCrew = 4;
missionDurationInHours = 19000;
missionDurationInWeeks = ceil(missionDurationInHours/24/7);

% Auto-Generate Crew Schedule
[crewSchedule, missionEVAschedule,crewEVAScheduleLogical] = CrewScheduler(numberOfEVAdaysPerWeek,numberOfCrew,missionDurationInWeeks);

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
 
%% Initialize Stores
% Potable Water Store within Life Support Units (note water store capacity
% measured in liters)
PotableWaterStore = StoreImpl('Potable H2O','Material',1500,1500);      % 1500L Potable Water Store Capacity according to: http://www.mars-one.com/faq/health-and-ethics/will-the-astronauts-have-enough-water-food-and-oxygen#sthash.aCFnUUFk.dpuf
% PotableWaterStore = StoreImpl('Potable H2O','Material',56.7,56.7);      %
% WPA Product Water tank has a capacity of 56.7L (ref: SAE 2008-01-2007).
% Note that on ISS, the WPA Product Water Tank feeds the Potable Water
% Dispenser, the OGA, and the WHC flush and hygiene hose.

% O2 Store within Life Support Units (note O2 capacity measured in moles)
initialO2TankCapacityInKg = 100.2;      % Calculated initial O2 tank capacity based on support crew for 60 days, note that another source on the Mars One webpage suggests a 60kg initial capacity for each living unit tank <http://www.mars-one.com/mission/roadmap/2023>
o2MolarMass = 2*15.999; % g/mol
initialO2StoreMoles = initialO2TankCapacityInKg*1E3/o2MolarMass;
O2Store = StoreImpl('O2 Store','Material',initialO2StoreMoles,initialO2StoreMoles);

% Store size TBD (note WaterRSLinear takes dirty water first, then grey
% water)

% Dirty water corresponds to Humidity Condensate and Urine 
DirtyWaterStore = StoreImpl('Dirty H2O','Material',100,0);        % Corresponds to the WPA waste water tank

% Grey water corresponds to wash water - it is included for the purposes of
% modeling a biological water processor
GreyWaterStore = StoreImpl('Grey H2O','Material',45.5,0);
% Note that WPA waste water tank has a 100lb capacity, but is nominally
% operated at 65lb capacity
% Lab Condensate tank has a working capacity of 45.5L

% Gas Stores

H2Store = StoreImpl('H2 Store','Material',10000,0);     % H2 store for output of OGS - note that currently on the ISS, there is no H2 store, it is sent directly to the Sabatier reactor 
% CO2Store = StoreImpl('CO2 Store','Material',1000,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA
CO2Store = StoreImpl('CO2 Store','Material',19.8,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA (volume of 19.8L) - convert this to moles! - tank pressure is 827kPa (see spreadsheet)
MethaneStore = StoreImpl('CH4 Store','Material',1000,0);    % CH4 store for output of CRS (Sabatier) - note CH4 is currently vented directly to space on ISS
% Look at option of including a pyrolyzer?

% N2 Store
% Corresponds to 2x high pressure N2 tanks currently mounted on exterior of Quest airlock on ISS (each holds 91kg of N2)
% This is subject to change based on requirements
numberOfN2Tanks = 2;
initialN2TankCapacityInKg = numberOfN2Tanks*91;
n2MolarMass = 2*14.007; %g/mol;
initialN2StoreMoles = initialN2TankCapacityInKg*1E3/n2MolarMass;
N2Store = StoreImpl('N2 Store','Material',initialN2StoreMoles,initialN2StoreMoles);     

% Power Stores
MainPowerStore = StoreImpl('Power','Material',100000,100000);

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

% Food Stores
xmlFoodStoreLevel = 10000;
xmlFoodStoreCapacity = 10000;
defaultFoodWaterContent = 5;
initialfood = FoodMatter(Wheat,xmlFoodStoreLevel,defaultFoodWaterContent); % xmlFoodStoreLevel is declared within the createFoodStore method within SimulationInitializer.java
FoodStore = FoodStoreImpl(xmlFoodStoreCapacity,initialfood);  
 
%% Initialize Injector

inflatableO2inj = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Inflatable1);

%% Initialize Air Processing Technologies

% Initialize Main VCCR (Linear)
mainvccr = ISSVCCRLinearImpl(Inflatable1,Inflatable1,CO2Store,MainPowerStore);

% Initialize OGS
ogs = ISSOGA(TotalAtmPressureTargeted,TargetO2MolarFraction,Inflatable1,PotableWaterStore,MainPowerStore,H2Store);

% Initialize CCAA CHX
inflatableCCAA = ISSDehumidifierImpl(Inflatable1,DirtyWaterStore,MainPowerStore);

%% Initialize Power Production Systems
% We assume basically unlimited power here
% Initialize General Power Producer
powerPS = PowerPSImpl('Nuclear',500000);
powerPS.PowerProducerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1E6,1E6);
powerPS.LightConsumerDefinition = Inflatable1;

%% Crew in Crew Quarters (crew)
astro1 = CrewPersonImpl('Male 1',35,75,'Male',[crewSchedule{1,:}],O2FractionHypoxicLimit);
% You can automate this using arrayfunc (see CrewScheduler.m for an example
% use)
% you might want to clear crewSchedule after initializing all crewpersons
% (the whos function indicates that crewSchedule consumes almost 2MB of memory)

% Initialize consumer and producer definitions
astro1.AirConsumerDefinition = AirConsumerDefinitionImpl(Inflatable1,0,0);
astro1.AirProducerDefinition = AirProducerDefinitionImpl(Inflatable1,0,0);
astro1.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro1.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro1.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro1.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro1.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);

%% Run Time Loop

timesteps = 75000;
 
totalmoles = zeros(1,timesteps);
totalpressure = zeros(1,timesteps);
o2moles = zeros(1,timesteps);
co2moles = zeros(1,timesteps);
n2moles = zeros(1,timesteps);
vapormoles = zeros(1,timesteps);
othermoles = zeros(1,timesteps);
o2percentage = zeros(1,timesteps);
PCAaction = zeros(4,timesteps);
ogsoutput = zeros(1,timesteps);
CCAAoutput = zeros(1,timesteps);

o2storelevel = zeros(1,timesteps);
co2storelevel = zeros(1,timesteps);
n2storelevel = zeros(1,timesteps);
potablewaterstorelevel = zeros(1,timesteps);
dirtywaterstorelevel = zeros(1,timesteps);

PCAaction(:,1) = zeros(4,1);


for i = 1:timesteps
    
    if astro1.alive == 0 %|| astro2.alive == 0 || astro3.alive == 0 || astro4.alive == 0
        break
    end
    
    totalmoles(i) = Inflatable1.totalMoles;
    totalpressure(i) = Inflatable1.pressure;
    o2moles(i) = Inflatable1.O2Store.currentLevel;
    co2moles(i) = Inflatable1.CO2Store.currentLevel;
    n2moles(i) = Inflatable1.NitrogenStore.currentLevel;
    vapormoles(i) = Inflatable1.VaporStore.currentLevel;
    othermoles(i) = Inflatable1.OtherStore.currentLevel;
    o2percentage(i) = Inflatable1.O2Percentage;
    
    o2storelevel(i) = O2Store.currentLevel;
    co2storelevel(i) = CO2Store.currentLevel;
    n2storelevel(i) = N2Store.currentLevel;
    potablewaterstorelevel(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel(i) = DirtyWaterStore.currentLevel;
    
    Inflatable1.tick;

    ogsoutput(i) = ogs.tick;

    PCAaction(:,i+1) = inflatableO2inj.tick(PCAaction(:,i));
    
    CCAAoutput(i) = inflatableCCAA.tick;
    
    powerPS.tick;
    
    mainvccr.tick;
    
    astro1.tick;
end

beep

toc