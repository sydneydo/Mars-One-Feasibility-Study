%%  Mars One Default Simulation Case
%   By: Sydney Do (sydneydo@mit.edu)
%   Date Created: 6/28/2014
%   Last Updated: 8/14/2014
%
%   Code to simulate the baseline architecture of the Mars One Mission
%   Errors within BioSim code have been removed from the class files
%   accessed by this file
%
%   NOTE:
%   This simulation represents the 26month mission of the first Mars One
%   Crew. Here, we assume that the potable water and oxygen stores have
%   already been filled by the ISRU system prior to the crew arriving
%   
%%  Simulation Notes
%   Time Horizon: 26 months (time between resupply) (approx. 19000 hours)
%   calculated from 2*365*24 + 2*31*24 (ie. 2 years + 2 months)
%   Crew Size: 4 persons
%   Nominal Atmosphere: 70.3kPa, 26.5% O2, N2 as Diluent Gas (referred to on
%   Mars One website: http://www.mars-one.com/mission/roadmap)
%   (This corresponds to the EAWG Recommendation for Lunar and Mars Landers)
%   
%   Minimum-Pressure Atmosphere: 52.4kPa, 32% O2
%   (Corresponds to EAWG Recommendation for Mars Habitats)
%
%   Habitat Architecture:
%   2 x inflatable modules, each at 500m^3, containing biomass production
%   system, crew quarters, exercise equipment
%   2 x living units containing "wet areas" including kitchen, shower,
%   laundry, and commodes
%   2 x life support units containing ECLSS hardware, power generation
%   hardware, and ISRU hardware
%   2 x cargo units containing cargo such as clothing, spare parts, 


%%  Assumptions
%   * All modules land with the nominal atmospheric composition
%   * Prior to crew landing, ISRU has the task of generating enough
%   atmosphere to inflate the two inflatable modules, and fill the oxygen
%   and water tanks
%   * Potable water use is budgeted for 50L/crewperson/day
%   * O2, Potable H2O, and Food Stores sized to hold enough supplies for
%   one month of open loop operation due to dust storms minimizing power
%   supplies 
%   (ref: http://www.mars-one.com/faq/mission-to-mars/what-are-the-risks-of-dust-and-sand-on-mars)

%% NOTE: we simulate half the habitat below (ie. one of each habitat element)

clear all
clc
% close all

tic

%% Key Mission Parameters
TotalAtmPressureTargeted = 70.3;        % targeted total atmospheric pressure, in kPa
O2FractionHypoxicLimit = 0.23;          % lower bound for a 70.3kPa atm based on EAWG Fig 4.1.1 and Advanced Life Support Requirements Document Fig 4-3
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

Inflatable1 = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);     %Note volume input is in Liters.
% Inflatable2 = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);     
LivingUnit1 = SimEnvironmentImpl('Living Unit 1',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);   % Note that here we assume that the internal volume of the Dragon modules sent to the surface is 25m^3
% LivingUnit2 = SimEnvironmentImpl('LivingUnit1',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);
LifeSupportUnit1 = SimEnvironmentImpl('Life Support Unit 1',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);
% LifeSupportUnit2 = SimEnvironmentImpl('LifeSupportUnit1',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);
CargoUnit1 = SimEnvironmentImpl('Cargo Unit 1',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);
% CargoUnit2 = SimEnvironmentImpl('CargoUnit2',70.3,25000,0.265,0,0.734,0,0.001,hourlyLeakagePercentage);

%% Initialize Key Activity Parameters
numberOfEVAdaysPerWeek = 5;
numberOfCrew = 4;
missionDurationInHours = 19000;
missionDurationInWeeks = ceil(missionDurationInHours/24/7);

% Baseline Activities and Location Mappings
lengthOfExercise = 2;                       % Number of hours spent on exercise activity

% Generate distribution of habitation options from which IVA activities
% will take place
HabDistribution = [repmat(Inflatable1,1,2),repmat(LivingUnit1,1,2),repmat(LifeSupportUnit1,1,2),CargoUnit1];

IVAhour = ActivityImpl('IVA',2,1,HabDistribution);          % One hour of IVA time (corresponds to generic IVA activity)
Sleep = ActivityImpl('Sleep',0,8,Inflatable1);          % Sleep period
Exercise = ActivityImpl('Exercise',5,lengthOfExercise,Inflatable1);    % Exercise period
EVA = ActivityImpl('EVA',4,8,Inflatable1);              % EVA - fixed length of 8 hours

% Vector of baselin activities:
ActivityList = [IVAhour,Sleep,Exercise,EVA];

% Auto-Generate Crew Schedule
[crewSchedule, missionEVAschedule,crewEVAScheduleLogical] = CrewScheduler(numberOfEVAdaysPerWeek,numberOfCrew,missionDurationInWeeks,ActivityList);


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
DirtyWaterStore = StoreImpl('Dirty H2O','Material',18/2.2*1.1,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

% Grey water corresponds to wash water - it is included for the purposes of
% modeling a biological water processor
GreyWaterStore = StoreImpl('Grey H2O','Material',100/2.2,0);
% Note that WPA waste water tank has a 100lb capacity, but is nominally
% operated at 65lb capacity
% Lab Condensate tank has a working capacity of 45.5L

% Gas Stores

H2Store = StoreImpl('H2 Store','Material',10000,0);     % H2 store for output of OGS - note that currently on the ISS, there is no H2 store, it is sent directly to the Sabatier reactor 
% CO2Store = StoreImpl('CO2 Store','Material',1000,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA

% From: "Analyses of the Integration of Carbon Dioxide Removal Assembly, Compressor, Accumulator 
% and Sabatier Carbon Dioxide Reduction Assembly" SAE 2004-01-2496
% "CO2 accumulator – The accumulator volume was set at 0.7 ft3, based on an assessment of available 
% space within the OGA rack where the CRA will reside. Mass balance of CO2 pumped in from the 
% compressor and CO2 fed to the Sabatier CO2 reduction system is used to calculate the CO2 pressure. 
% Currently the operating pressure has been set to 20 – 130 psia."

% From SAE 2004-01-2496, on CDRA bed heaters - informs temp of CO2 sent to
% accumulator
% "During the first 10 min of the heat cycle, ullage air is pumped out back to the cabin. After this time, the bed is
% heated to approximately 250 °F and is exposed to space vacuum for desorption of the bed."
% ...
% "The heaters were OFF during the “night time”, or when the desorb bed temperature reached its set point
% of 400 ºF, or when it was an adsorb cycle."

% (Ref: Functional Performance of an Enabling Atmosphere Revitalization Subsystem Architecture for Deep Space Exploration Missions (AIAA 2013-3421)
% Quote: “Because the commercial compressor discharge pressure was 414 kPa compared to the flight CO2 Reduction Assembly (CRA)
% compressor’s 827 kPa, the accumulator volume was increased from 19.8 liters to 48.1 liters”

% CO2StoreTemp = 5/9*(400-32)+273.15;        % Converted to Kelvin from 400F, here we assume isothermal compression by the compressor
% CO2accumulatorVolumeInLiters = 19.8;
% CO2AccumulatorMaxPressureInKPa = 827;                  % note that 827kPa corresponds to ~120psi
% molesInCO2Store = CO2AccumulatorMaxPressureInKPa*CO2accumulatorVolumeInLiters/8.314/CO2StoreTemp;
CO2Store = StoreImpl('CO2 Store','Environmental');    % CO2 store for VCCR - refer to accumulator attached to CDRA (volume of 19.8L) - convert this to moles! - tank pressure is 827kPa (see spreadsheet)
MethaneStore = StoreImpl('CH4 Store','Environmental');    % CH4 store for output of CRS (Sabatier) - note CH4 is currently vented directly to space on ISS
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

%% Initialize CrewPersons
% Assumed crew distribution across habitats

% Number of EVAs per week - drives activity schedule of crew
% We assume two crew per EVA


%% Crew in Crew Quarters (crew)
astro1 = CrewPersonImpl('Male 1',35,75,'Male',[crewSchedule{1,:}]);%,O2FractionHypoxicLimit);
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


%% Crew in Galley Module (galley)
astro2 = CrewPersonImpl('Female 1',35,55,'Female',[crewSchedule{2,:}]);

% Initialize consumer and producer definitions
astro2.AirConsumerDefinition = AirConsumerDefinitionImpl(Inflatable1,0,0);
astro2.AirProducerDefinition = AirProducerDefinitionImpl(Inflatable1,0,0);
astro2.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro2.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro2.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro2.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro2.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);

%% Crew in Labs Module (labs)
astro3 = CrewPersonImpl('Male 2',35,72,'Male',[crewSchedule{3,:}]);

% Initialize consumer and producer definitions
astro3.AirConsumerDefinition = AirConsumerDefinitionImpl(LivingUnit1,0,0);
astro3.AirProducerDefinition = AirProducerDefinitionImpl(LivingUnit1,0,0);
astro3.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro3.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro3.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro3.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro3.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);

%% Crew in Maintenance Module (maint)
astro4 = CrewPersonImpl('Female 2',35,55,'Female',[crewSchedule{4,:}]);

% Initialize consumer and producer definitions
astro4.AirConsumerDefinition = AirConsumerDefinitionImpl(LifeSupportUnit1,0,0);
astro4.AirProducerDefinition = AirProducerDefinitionImpl(LifeSupportUnit1,0,0);
astro4.PotableWaterConsumerDefinition = PotableWaterConsumerDefinitionImpl(PotableWaterStore,3,3);
astro4.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,100,100);
astro4.GreyWaterProducerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,100,100);
astro4.FoodConsumerDefinition = ResourceUseDefinitionImpl(FoodStore,5,5);
astro4.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,10,10);


%% Biomass Stores
% Located within Inflatable Structure
% xml_inedibleFraction = 0.25;
% xml_edibleWaterContent = 5;
% xml_inedibleWaterContent = 5;
% initialBiomatter = [BioMatter(Wheat,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent),...
%     BioMatter(Rice,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent),...
%     BioMatter(Rice,100000,xml_inedibleFraction,xml_edibleWaterContent,xml_inedibleWaterContent)];
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

biomassSystem.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate,defaultrate);
biomassSystem.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate,defaultrate);
biomassSystem.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate,defaultrate);
biomassSystem.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
biomassSystem.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
% biomassSystem.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);      % Note that plant model does not consume dirty water! (Only grey and potable water - grey should be preferred!)			
biomassSystem.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000,10000);
				

WheatShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WheatShelf.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WheatShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
WheatShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);				

DryBeanShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
DryBeanShelf.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% DryBeanShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
DryBeanShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

WhitePotatoShelf.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
WhitePotatoShelf.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,defaultrate/numberOfShelves,defaultrate/numberOfShelves);
% WhitePotatoShelf.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);				
WhitePotatoShelf.BiomassProducerDefinition = ResourceUseDefinitionImpl(BiomassStore,10000/numberOfShelves,10000/numberOfShelves);

%% Initialize FoodProcessor
FoodProcessor = FoodProcessorImpl;
FoodProcessor.BiomassConsumerDefinition = ResourceUseDefinitionImpl(BiomassStore,1000,1000);
FoodProcessor.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1000,1000);
FoodProcessor.FoodProducerDefinition = ResourceUseDefinitionImpl(FoodStore,1000,1000);
FoodProcessor.WaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);
FoodProcessor.DryWasteProducerDefinition = ResourceUseDefinitionImpl(DryWasteStore,1000,1000);

%% Initialize (Intermodule Ventilation) Fans

% NB. Under normal power consumption conditions, the ISS IMV fan moves 
% approx. 6791 moles of air every hour
% As a result, we modify the max and desired molar flow rates to meet this
% number
% Desired is rounded up to 6800moles/hr, and the max corresponds to the max
% volumetric flow rate of 4106L/min indicated within Section 2, Chapter
% 3.2.6 of "Living Together In Space"
% 4106L/min*60min/hr*70.3kPa/(8.314J/K/mol*296.15K) = 7034mol/hr (we round
% this up to 7035mol/hr)

% Inflatable 1 to Living Unit Fan
% inflatable2LivingUnitFan = ISSFanImpl;
% inflatable2LivingUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,6800,7035);
% inflatable2LivingUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
% inflatable2LivingUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

inflatable2LivingUnitFan = ISSFanImpl2(Inflatable1,LivingUnit1,MainPowerStore);

% Living Unit to Inflatable 1 Fan
% livingUnit2InflatableFan = ISSFanImpl;
% livingUnit2InflatableFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
% livingUnit2InflatableFan.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,6800,7035);
% livingUnit2InflatableFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Living Unit to Life Support Unit Fan
% livingUnit2LifeSupportFan = ISSFanImpl;
% livingUnit2LifeSupportFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
% livingUnit2LifeSupportFan.AirProducerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
% livingUnit2LifeSupportFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...
% 
% % Life Support Unit to Living Unit Fan
% lifeSupport2LivingUnitFan = ISSFanImpl;
% lifeSupport2LivingUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
% lifeSupport2LivingUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
% lifeSupport2LivingUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

livingUnit2LifeSupportFan = ISSFanImpl2(LivingUnit1,LifeSupportUnit1,MainPowerStore);

% Life Support Unit to Cargo Unit Fan
% lifeSupport2CargoUnitFan = ISSFanImpl;
% lifeSupport2CargoUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
% lifeSupport2CargoUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(CargoUnit1,6800,7035);
% lifeSupport2CargoUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...
% 
% % Cargo Unit to Life Support Unit Fan
% cargoUnit2LifeSupportFan = ISSFanImpl;
% cargoUnit2LifeSupportFan.AirConsumerDefinition = ResourceUseDefinitionImpl(CargoUnit1,6800,7035);
% cargoUnit2LifeSupportFan.AirProducerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
% cargoUnit2LifeSupportFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

lifeSupport2CargoUnitFan = ISSFanImpl2(LifeSupportUnit1,CargoUnit1,MainPowerStore);

%% Initialize Injectors (Models ISS Pressure Control Assemblies)
% See accompanying word doc for rationale behind PCA locations

% Inflatable PCA
inflatablePCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Inflatable1);

% Living Unit PCA
livingUnitPCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LivingUnit1);

% Living Unit PCA
lifeSupportUnitPCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LifeSupportUnit1);

%% Initialize Temperature and Humidity Control (THC) Technologies
% Insert CCAA within Inflatable, Living Unit, and Life Support Unit
% Placement of CCAAs is based on modules with a large period of continuous
% human presence (i.e. large sources of humidity condensate)

% Inflatable CCAA
inflatableCCAA = ISSDehumidifierImpl(Inflatable1,DirtyWaterStore,MainPowerStore);

% Living Unit/Airlock CCAA
livingUnitCCAA = ISSDehumidifierImpl(LivingUnit1,DirtyWaterStore,MainPowerStore);

% Life Support Unit CCAA
lifeSupportUnitCCAA = ISSDehumidifierImpl(LifeSupportUnit1,DirtyWaterStore,MainPowerStore);

%% Initialize Air Processing Technologies

% Initialize Main VCCR (Linear)
mainvccr = ISSVCCRLinearImpl(LifeSupportUnit1,LifeSupportUnit1,CO2Store,MainPowerStore);

% Initialize OGS
ogs = ISSOGA(TotalAtmPressureTargeted,TargetO2MolarFraction,LifeSupportUnit1,PotableWaterStore,MainPowerStore,H2Store);

% Initialize CRS (Sabatier Reactor)
crs = ISSCRSImpl(H2Store,CO2Store,GreyWaterStore,MethaneStore,MainPowerStore);

%% Initialize Water Processing Technologies

% Initialize WaterRS (Linear)
waterRS = ISSWaterRSLinearImpl(DirtyWaterStore,GreyWaterStore,GreyWaterStore,DryWasteStore,PotableWaterStore,MainPowerStore);


%% Initialize Power Production Systems
% We assume basically unlimited power here
% Initialize General Power Producer
powerPS = PowerPSImpl('Nuclear',500000);
powerPS.PowerProducerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1E6,1E6);
powerPS.LightConsumerDefinition = Inflatable1;

%% Time Loop

simtime = 100;
t = 1:simtime;

o2storelevel = zeros(1,simtime);
co2storelevel = zeros(1,simtime);
n2storelevel = zeros(1,simtime);
h2storelevel = zeros(1,simtime);
ch4storelevel = zeros(1,simtime);
potablewaterstorelevel = zeros(1,simtime);
dirtywaterstorelevel = zeros(1,simtime);
greywaterstorelevel = zeros(1,simtime);
drywastestorelevel = zeros(1,simtime);
foodstorelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);

inflatablePressure = zeros(1,simtime);
inflatableO2level = zeros(1,simtime);
inflatableCO2level = zeros(1,simtime);
inflatableN2level = zeros(1,simtime);
inflatableVaporlevel = zeros(1,simtime);
inflatableOtherlevel = zeros(1,simtime);
inflatableTotalMoles = zeros(1,simtime);

livingUnitPressure = zeros(1,simtime);
livingUnitO2level = zeros(1,simtime);
livingUnitCO2level = zeros(1,simtime);
livingUnitN2level = zeros(1,simtime);
livingUnitVaporlevel = zeros(1,simtime);
livingUnitOtherlevel = zeros(1,simtime);
livingUnitTotalMoles = zeros(1,simtime);

lifeSupportUnitPressure = zeros(1,simtime);
lifeSupportUnitO2level = zeros(1,simtime);
lifeSupportUnitCO2level = zeros(1,simtime);
lifeSupportUnitN2level = zeros(1,simtime);
lifeSupportUnitVaporlevel = zeros(1,simtime);
lifeSupportUnitOtherlevel = zeros(1,simtime);
lifeSupportUnitTotalMoles = zeros(1,simtime);

cargoUnitPressure = zeros(1,simtime);
cargoUnitO2level = zeros(1,simtime);
cargoUnitCO2level = zeros(1,simtime);
cargoUnitN2level = zeros(1,simtime);
cargoUnitVaporlevel = zeros(1,simtime);
cargoUnitOtherlevel = zeros(1,simtime);
CargoUnitTotalMoles = zeros(1,simtime);

ogsoutput = zeros(1,simtime);
inflatablePCAaction = zeros(4,simtime+1);
livingUnitPCAaction = zeros(4,simtime+1);
lifeSupportUnitPCAaction = zeros(4,simtime+1);
inflatableCCAAoutput = zeros(1,simtime);
livingUnitCCAAoutput = zeros(1,simtime);
lifeSupportUnitCCAAoutput = zeros(1,simtime);

crsH2OProduced = zeros(1,simtime);
crsCompressorOperation = zeros(2,simtime);
co2accumulatorlevel = zeros(1,simtime);
co2removed = zeros(1,simtime);

h = waitbar(0,'Please wait...');

toc

%% Time Loop

tic

for i = 1:simtime
        
    if astro1.alive == 0 || astro2.alive == 0 || astro3.alive == 0 || astro4.alive == 0
        close(h)
        return
    end

    %% Record Data
    % Resource Stores
    o2storelevel(i) = O2Store.currentLevel;
    co2storelevel(i) = CO2Store.currentLevel;
    n2storelevel(i) = N2Store.currentLevel;
    h2storelevel(i) = H2Store.currentLevel;
    ch4storelevel(i) = MethaneStore.currentLevel;
    potablewaterstorelevel(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel(i) = DirtyWaterStore.currentLevel;
    greywaterstorelevel(i) = GreyWaterStore.currentLevel;
    drywastestorelevel(i) = DryWasteStore.currentLevel;
    foodstorelevel(i) = FoodStore.currentLevel;
    powerlevel(i) = MainPowerStore.currentLevel;
    
    % Record Inflatable Unit Atmosphere
    inflatablePressure(i) = Inflatable1.pressure;
    inflatableO2level(i) = Inflatable1.O2Store.currentLevel;
    inflatableCO2level(i) = Inflatable1.CO2Store.currentLevel;
    inflatableN2level(i) = Inflatable1.NitrogenStore.currentLevel;
    inflatableVaporlevel(i) = Inflatable1.VaporStore.currentLevel;
    inflatableOtherlevel(i) = Inflatable1.OtherStore.currentLevel;
    inflatableTotalMoles(i) = Inflatable1.totalMoles;
    
    % Record Living Unit Atmosphere
    livingUnitPressure(i) = LivingUnit1.pressure;
    livingUnitO2level(i) = LivingUnit1.O2Store.currentLevel;
    livingUnitCO2level(i) = LivingUnit1.CO2Store.currentLevel;
    livingUnitN2level(i) = LivingUnit1.NitrogenStore.currentLevel;
    livingUnitVaporlevel(i) = LivingUnit1.VaporStore.currentLevel;
    livingUnitOtherlevel(i) = LivingUnit1.OtherStore.currentLevel;
    livingUnitTotalMoles(i) = LivingUnit1.totalMoles;
    
    % Record Life Support Unit Atmosphere
    lifeSupportUnitPressure(i) = LifeSupportUnit1.pressure;
    lifeSupportUnitO2level(i) = LifeSupportUnit1.O2Store.currentLevel;
    lifeSupportUnitCO2level(i) = LifeSupportUnit1.CO2Store.currentLevel;
    lifeSupportUnitN2level(i) = LifeSupportUnit1.NitrogenStore.currentLevel;
    lifeSupportUnitVaporlevel(i) = LifeSupportUnit1.VaporStore.currentLevel;
    lifeSupportUnitOtherlevel(i) = LifeSupportUnit1.OtherStore.currentLevel;
    lifeSupportUnitTotalMoles(i) = LifeSupportUnit1.totalMoles;
    
    % Record Cargo Unit Atmosphere
    cargoUnitPressure(i) = CargoUnit1.pressure;
    cargoUnitO2level(i) = CargoUnit1.O2Store.currentLevel;
    cargoUnitCO2level(i) = CargoUnit1.CO2Store.currentLevel;
    cargoUnitN2level(i) = CargoUnit1.NitrogenStore.currentLevel;
    cargoUnitVaporlevel(i) = CargoUnit1.VaporStore.currentLevel;
    cargoUnitOtherlevel(i) = CargoUnit1.OtherStore.currentLevel;
    CargoUnitTotalMoles(i) = CargoUnit1.totalMoles;
    
    %% Tick Modules
    
    % Leak Modules
    Inflatable1.tick;
    LivingUnit1.tick;
    LifeSupportUnit1.tick;
    CargoUnit1.tick;
    
    % Run Fans
    inflatable2LivingUnitFan.tick;
    livingUnit2LifeSupportFan.tick;
    lifeSupport2CargoUnitFan.tick;
%     cargoUnit2LifeSupportFan.tick;
%     lifeSupport2LivingUnitFan.tick;
%     livingUnit2InflatableFan.tick;   
    
    % Run Power Supply
    powerPS.tick; 
    
    % Run ECLSS Hardware       
    ogsoutput(i) = ogs.tick;
    
    % Pressure Control Assemblies
    inflatablePCAaction(:,i+1) = inflatablePCA.tick(inflatablePCAaction(:,i));
    livingUnitPCAaction(:,i+1) = livingUnitPCA.tick(livingUnitPCAaction(:,i));
    lifeSupportUnitPCAaction(:,i+1) = lifeSupportUnitPCA.tick(lifeSupportUnitPCAaction(:,i));

    % Common Cabin Air Assemblies
    inflatableCCAAoutput(i) = inflatableCCAA.tick;
    livingUnitCCAAoutput(i) = livingUnitCCAA.tick;
    lifeSupportUnitCCAAoutput(i) = lifeSupportUnitCCAA.tick;
    
    % Run Waste Processing ECLSS Hardware
    co2removed(i) = mainvccr.tick;
    crsH2OProduced(i) = crs.tick;
    crsCompressorOperation(:,i) = crs.CompressorOperation;
    co2accumulatorlevel(i) = crs.CO2Accumulator.currentLevel;
    waterRS.tick;
    
    % Tick Crew
    astro1.tick;
    astro2.tick;  
    astro3.tick;
    astro4.tick;
    
    % Tick Waitbar  
    waitbar(i/simtime);

end

toc

beep

close(h)

%% Random plot commande used in code validation exercise
figure, 
subplot(2,2,1), plot(t,inflatableO2level,t,inflatableCO2level,t,inflatableN2level,t,inflatableVaporlevel,t,inflatableOtherlevel,'LineWidth',2), title('Inflatable 1'),legend('O2','CO2','N2','Vapor','Other'), grid on
subplot(2,2,2), plot(t,livingUnitO2level,t,livingUnitCO2level,t,livingUnitN2level,t,livingUnitVaporlevel,t,livingUnitOtherlevel,'LineWidth',2), title('Living Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on
subplot(2,2,3), plot(t,lifeSupportUnitO2level,t,lifeSupportUnitCO2level,t,lifeSupportUnitN2level,t,lifeSupportUnitVaporlevel,t,lifeSupportUnitOtherlevel,'LineWidth',2), title('Life Support Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on
subplot(2,2,4), plot(t,cargoUnitO2level,t,cargoUnitCO2level,t,cargoUnitN2level,t,cargoUnitVaporlevel,t,cargoUnitOtherlevel,'LineWidth',2), title('Cargo Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on

% % Environmental N2 Store plots
% figure, 
% subplot(2,2,1), plot(1:simtime,crewN2level,'LineWidth',2), title('Crew Quarters Environmental N2 Level'), grid on
% subplot(2,2,2), plot(1:simtime,lifeSupportUnitN2level,'LineWidth',2), title('Galley Environmental N2 Level'), grid on
% subplot(2,2,3), plot(1:simtime,labsN2level,'LineWidth',2), title('Labs Environmental N2 Level'), grid on
% subplot(2,2,4), plot(1:simtime,maintN2level,'LineWidth',2), title('Maintenance Environmental N2 Level'), grid on
% 
% i = i-1;
% figure, plot(1:(i-1),crewO2level(1:(i-1)),1:(i-1),crewCO2level(1:(i-1)),...
%     1:(i-1),crewN2level(1:(i-1)),1:(i-1),crewOtherlevel(1:(i-1)),1:(i-1),crewVaporlevel(1:(i-1)),'LineWidth',2),...
%    legend('O_2','CO_2','N_2','Other','Vapor'), grid on
% title('MATLAB Crew Quarters')
% 
% figure, plot(1:(i-1),maintO2level(1:(i-1)),1:(i-1),maintCO2level(1:(i-1)),...
%     1:(i-1),maintN2level(1:(i-1)),1:(i-1),maintOtherlevel(1:(i-1)),1:(i-1),maintVaporlevel(1:(i-1)),'LineWidth',2),...
%    legend('O_2','CO_2','N_2','Other','Vapor'), grid on
% title('MATLAB Maintenance Module')
% 
% figure, plot(1:(i-1),labsO2level(1:(i-1)),1:(i-1),labsCO2level(1:(i-1)),...
%     1:(i-1),labsN2level(1:(i-1)),1:(i-1),labsOtherlevel(1:(i-1)),1:(i-1),labsVaporlevel(1:(i-1)),'LineWidth',2),...
%    legend('O_2','CO_2','N_2','Other','Vapor'), grid on
% title('MATLAB Labs Module')
% 
% figure, plot(1:(i-1),galleyO2level(1:(i-1)),1:(i-1),galleyCO2level(1:(i-1)),...
%     1:(i-1),lifeSupportUnitN2level(1:(i-1)),1:(i-1),lifeSupportUnitOtherlevel(1:(i-1)),1:(i-1),lifeSupportUnitVaporlevel(1:(i-1)),'LineWidth',2),...
%    legend('O_2','CO_2','N_2','Other','Vapor'), grid on
% title('MATLAB Galley Module')
% 
% figure, plot(maintN2level,'LineWidth',2),grid on
% 
% figure, plot(1:length(crewO2level),crewO2level), grid on
% figure, plot(1:length(N2level),N2level), grid on
% figure, plot(1:length(crewCO2level),crewCO2level), grid on
% figure, plot(1:(i-1),H2level(1:(i-1)),'LineWidth',2), title('MATLAB H_2 Store'), grid on
% % figure, plot(1:length(H2level),H2level), grid on
% figure, plot(1:length(CH4level),CH4level), grid on
% figure, plot(1:length(crewVaporlevel),crewVaporlevel,'LineWidth',2), grid on, title('MATLAB Crew Quarters Vapor Level')
% figure, plot(1:(i-1),maintVaporlevel(1:(i-1)),'LineWidth',2), grid on, title('MATLAB Maintenance Vapor Level')
% figure, plot(1:(i-1),H2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Potable Water Store'), grid on
% figure, plot(1:(i-1),DirtyH2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Dirty Water Store'), grid on
% % figure, plot(1:length(DirtyH2Ostorelevel),DirtyH2Ostorelevel), grid on
% % figure, plot(1:length(FoodStoreLevel),FoodStoreLevel), grid on
% % figure, plot(1:length(DryWasteStoreLevel),DryWasteStoreLevel), grid on
% figure, plot(1:(i-1),DryWasteStoreLevel(1:(i-1)),'LineWidth',2), title('MATLAB Dry Waste Store'), grid on
% figure, plot(1:(i-1),GreyH2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Grey Water Store'), grid on
% figure, plot(1:(i-1),O2Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB O_2 Store'), grid on
% figure, plot(1:(i-1),CH4Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB Methane Store'), grid on
% figure, plot(1:(i-1),consumedWaterBuffer(1:(i-1)),'LineWidth',2), title('MATLAB Consumed Water Buffer'), grid on
% % figure, plot(1:length(GreyH2Ostorelevel),GreyH2Ostorelevel), grid on
% figure, plot(1:(i-1),FoodStoreLevel(1:(i-1)),'LineWidth',2), title('MATLAB Food Store'), grid on
% figure, plot(1:length(CO2conc),CO2conc), grid on
% figure, plot(1:length(O2conc),O2conc), grid on
% figure, plot(1:length(vaporconc),vaporconc), grid on
% figure, plot(1:length(CO2concMain),CO2concMain), grid on
% figure, plot(1:length(O2concMain),O2concMain), grid on
% figure, plot(1:length(O2levelMain),O2levelMain), grid on
% figure, plot(1:length(pres),pres), grid on
% figure, plot(1:length(CO2storelevel),CO2storelevel), grid on
% figure, plot(1:length(powerlevel),powerlevel), grid on
% % figure, plot(1:length(CO2Storelevel),CO2Storelevel), grid on
% figure, plot(1:(i-1),CO2Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB CO_2 Store'), grid on
% figure, plot(1:length(intensity),intensity)
