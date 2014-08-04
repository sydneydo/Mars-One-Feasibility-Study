%%  Mars One Default Simulation Case
%   By: Sydney Do (sydneydo@mit.edu)
%   Date Created: 6/28/2014
%   Last Updated: 6/28/2014
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

%% Key Mission Parameters
numberOfEVAdaysPerWeek = 5;
numberOfCrew = 4;
missionDurationInHours = 19000;
missionDurationInWeeks = ceil(missionDurationInHours/24/7);

% Auto-Generate Crew Schedule
[crewSchedule, missionEVAschedule,crewEVAScheduleLogical] = CrewScheduler(numberOfEVAdaysPerWeek,numberOfCrew,missionDurationInWeeks);

%% Initialize SimEnvironments
Inflatable1 = SimEnvironmentImpl('Inflatable 1',70.3,5000000,0.265,0,0.734,0,0.001);     %Note volume input is in Liters
% Inflatable2 = SimEnvironmentImpl('Inflatable 1',70.3,5000000,0.265,0,0.734,0,0.001);     
LivingUnit1 = SimEnvironmentImpl('Living Unit 1',70.3,25000,0.265,0,0.734,0,0.001);   % Note that here we assume that the internal volume of the Dragon modules sent to the surface is 25m^3
% LivingUnit2 = SimEnvironmentImpl('LivingUnit1',70.3,25000,0.265,0,0.734,0,0.001);
LifeSupportUnit1 = SimEnvironmentImpl('Life Support Unit 1',70.3,25000,0.265,0,0.734,0,0.001);
% LifeSupportUnit2 = SimEnvironmentImpl('LifeSupportUnit1',70.3,25000,0.265,0,0.734,0,0.001);
CargoUnit1 = SimEnvironmentImpl('Cargo Unit 1',70.3,25000,0.265,0,0.734,0,0.001);
% CargoUnit2 = SimEnvironmentImpl('CargoUnit2',70.3,25000,0.265,0,0.734,0,0.001);


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

GreyWaterStore = StoreImpl('Grey H2O','Material',45.5,0);
% Note that WPA waste water tank has a 100lb capacity, but is nominally
% operated at 65lb capacity
% Lab Condensate tank has a working capacity of 45.5L

% Gas Stores

H2Store = StoreImpl('H2 Store','Material',10000,0);     % H2 store for output of OGS - note that currently on the ISS, there is no H2 store, it is sent directly to the Sabatier reactor 
% CO2Store = StoreImpl('CO2 Store','Material',1000,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA
CO2Store = StoreImpl('CO2 Store','Material',19.8,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA (volume of 19.8L)
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

%% Initialize CrewPersons
% Assumed crew distribution across habitats

% Number of EVAs per week - drives activity schedule of crew
% We assume two crew per EVA


%% Crew in Crew Quarters (crew)
astro1 = CrewPersonImpl('Male 1',35,75,'Male',[crewSchedule{1,:}]);
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
biomassSystem.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
biomassSystem.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,defaultrate,defaultrate);
% biomassSystem.DirtyWaterProducerDefinition(DirtyWaterStore,defaultrate,defaultrate);      % Note that plant model does not consume dirty water! (Only grey and potable water - grey should be preferred!)			
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

%% Initialize Dehumidifiers
% Insert CCAA within Inflatable, Living Unit, and Life Support Unit
% Placement of CCAAs is based on modules with a large period of continuous
% human presence (i.e. large sources of humidity condensate)

% Inflatable Dehumidifier
inflatableDehumidifier = DehumidifierImpl;
inflatableDehumidifier.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,1000,1000);
inflatableDehumidifier.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);

% Living Unit/Airlock Dehumidifier
livingUnitDehumidifier = DehumidifierImpl;
livingUnitDehumidifier.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,1000,1000);
livingUnitDehumidifier.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);

% Life Support Unit Dehumidifier
lifeSupportUnitDehumidifier = DehumidifierImpl;
lifeSupportUnitDehumidifier.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,1000,1000);
lifeSupportUnitDehumidifier.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,1000,1000);

%% Initialize Fans

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
inflatable2LivingUnitFan = ISSFanImpl;
inflatable2LivingUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(Inflatable1,6800,7035);
inflatable2LivingUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
inflatable2LivingUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Living Unit to Inflatable 1 Fan
livingUnit2InflatableFan = ISSFanImpl;
livingUnit2InflatableFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
livingUnit2InflatableFan.AirProducerDefinition = ResourceUseDefinitionImpl(Inflatable1,6800,7035);
livingUnit2InflatableFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Living Unit to Life Support Unit Fan
livingUnit2LifeSupportFan = ISSFanImpl;
livingUnit2LifeSupportFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
livingUnit2LifeSupportFan.AirProducerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
livingUnit2LifeSupportFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Life Support Unit to Living Unit Fan
lifeSupport2LivingUnitFan = ISSFanImpl;
lifeSupport2LivingUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
lifeSupport2LivingUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(LivingUnit1,6800,7035);
lifeSupport2LivingUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Life Support Unit to Cargo Unit Fan
lifeSupport2CargoUnitFan = ISSFanImpl;
lifeSupport2CargoUnitFan.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
lifeSupport2CargoUnitFan.AirProducerDefinition = ResourceUseDefinitionImpl(CargoUnit1,6800,7035);
lifeSupport2CargoUnitFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...

% Cargo Unit to Life Support Unit Fan
cargoUnit2LifeSupportFan = ISSFanImpl;
cargoUnit2LifeSupportFan.AirConsumerDefinition = ResourceUseDefinitionImpl(CargoUnit1,6800,7035);
cargoUnit2LifeSupportFan.AirProducerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,6800,7035);
cargoUnit2LifeSupportFan.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,55,55);     % Intermodule Ventilation Fan consumes 55W continuous according to Chapter 2, Section 3.2.6, Living Together in Space...


%% Initialize Air Processing Technologies

% Initialize Main VCCR (Linear)
mainvccr = VCCRLinearImpl;
mainvccr.AirConsumerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,10000,10000);
mainvccr.AirProducerDefinition = ResourceUseDefinitionImpl(LifeSupportUnit1,10000,10000);
mainvccr.CO2ProducerDefinition = ResourceUseDefinitionImpl(CO2Store,10000,10000);
mainvccr.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,2000,2000);

% Initialize OGS
ogs = OGSImpl;
ogs.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1000,1000);
ogs.PotableWaterConsumerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,10,10);
ogs.O2ProducerDefinition = ResourceUseDefinitionImpl(O2Store,1000,1000);
ogs.H2ProducerDefinition = ResourceUseDefinitionImpl(H2Store,1000,1000);

% Initialize CRS (Sabatier Reactor)
crs = CRSImpl;
crs.CO2ConsumerDefinition = ResourceUseDefinitionImpl(CO2Store,100,100);
crs.H2ConsumerDefinition = ResourceUseDefinitionImpl(H2Store,100,100);
crs.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,100,100);
crs.PotableWaterProducerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,100,100);
crs.MethaneProducerDefinition = ResourceUseDefinitionImpl(MethaneStore,100,100);

%% Initialize Injectors (Framework BioModule within BioSim)
% Maintenance Oxygen Injector
maintO2inj = InjectorImpl;
maintO2inj.ResourceConsumerDefinition = ResourceUseDefinitionImpl(O2Store,3.3,3.3);
maintO2inj.ResourceProducerDefinition = ResourceUseDefinitionImpl(maint.O2Store,3.5,3.5);

%% Initialize Water Processing Technologies

% Initialize WaterRS (Linear)
waterRS = WaterRSLinearImpl;
waterRS.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl(GreyWaterStore,10,10);
waterRS.DirtyWaterConsumerDefinition = ResourceUseDefinitionImpl(DirtyWaterStore,10,10);
waterRS.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1000,1000);
waterRS.PotableWaterProducerDefinition = ResourceUseDefinitionImpl(PotableWaterStore,1000,1000);

%% Initialize Power Production Systems

% Initialize General Power Producer
powerPS = PowerPSImpl('Nuclear',500000);
powerPS.PowerProducerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1E6,1E6);
powerPS.LightConsumerDefinition = Inflatable1;

% Initialize Fan Battery Source
fanpowerPS = PowerPSImpl('Nuclear',500);        % Default upperPowerGeneration value is set to 500;
fanpowerPS.PowerProducerDefinition = ResourceUseDefinitionImpl(FanPowerStore,1E3,1E3);


%% Time Loop
% tic

simtime = 19000;

H2level = zeros(1,simtime);
CH4level = zeros(1,simtime);
intensity = zeros(1,simtime);
H2Ostorelevel = zeros(1,simtime);
DirtyH2Ostorelevel = zeros(1,simtime);
GreyH2Ostorelevel = zeros(1,simtime);
FoodStoreLevel = zeros(1,simtime);
DryWasteStoreLevel = zeros(1,simtime);
CO2conc = zeros(1,simtime);
O2conc = zeros(1,simtime);
vaporconc = zeros(1,simtime);
CO2storelevel = zeros(1,simtime);
CH4Storelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
pres = zeros(1,simtime);
N2crewStore = zeros(1,simtime);
N2galleyStore = zeros(1,simtime);
N2labsStore = zeros(1,simtime);
N2maintStore = zeros(1,simtime);
O2Storelevel = zeros(1,simtime);

crewO2level = zeros(1,simtime);
crewCO2level = zeros(1,simtime);
crewN2level = zeros(1,simtime);
crewVaporlevel = zeros(1,simtime);
crewOtherlevel = zeros(1,simtime);

maintO2level = zeros(1,simtime);
maintCO2level = zeros(1,simtime);
maintN2level = zeros(1,simtime);
maintVaporlevel = zeros(1,simtime);
maintOtherlevel = zeros(1,simtime);

labsO2level = zeros(1,simtime);
labsCO2level = zeros(1,simtime);
labsN2level = zeros(1,simtime);
labsVaporlevel = zeros(1,simtime);
labsOtherlevel = zeros(1,simtime);

galleyO2level = zeros(1,simtime);
galleyCO2level = zeros(1,simtime);
galleyN2level = zeros(1,simtime);
galleyVaporlevel = zeros(1,simtime);
galleyOtherlevel = zeros(1,simtime);

CO2Storelevel = zeros(1,simtime);
consumedWaterBuffer = zeros(1,simtime);

h = waitbar(0,'Please wait...');
tic
for i = 1:simtime
        
    if astro1.alive == 0 || astro2.alive == 0 || astro3.alive == 0 || astro4.alive == 0
        break
    end

    % Leak Modules
    Inflatable1.tick;
    LivingUnit1.tick;
    LifeSupportUnit1.tick;
    CargoUnit1.tick;
    
    % Run Fans
    inflatable2LivingUnitFan.tick;
    livingUnit2InflatableFan.tick;
    livingUnit2LifeSupportFan.tick;
    lifeSupport2LivingUnitFan.tick;
    lifeSupport2CargoUnitFan.tick;
    cargoUnit2LifeSupportFan.tick;
    
    % Record data
    powerlevel(i) = MainPowerStore.currentLevel; 
    H2level(i) = H2Store.currentLevel;
    H2Ostorelevel(i) = PotableWaterStore.currentLevel;
    CO2Storelevel(i) = CO2Store.currentLevel;
    CH4Storelevel(i) = MethaneStore.currentLevel;
    O2Storelevel(i) = O2Store.currentLevel;
    DirtyH2Ostorelevel(i) = DirtyWaterStore.currentLevel;
    GreyH2Ostorelevel(i) = GreyWaterStore.currentLevel;
    FoodStoreLevel(i) = FoodStore.currentLevel;
    DryWasteStoreLevel(i) = DryWasteStore.currentLevel;
    
%     % Fans consume required air from source SimEnvironments
%     air2main(i) = crew2mainfan.takeAir;
%     air2crew(i) = main2crewfan.takeAir;
%     
%     % Fans send required air to destination SimEnvironments
%     crew2mainfan.sendAir(air2main(i));
%     main2crewfan.sendAir(air2crew(i));
    
    % These ticks are ordered in the same manner as the default BioSim
    % configuration (see BioSIm Inputs and Outputs document)
    mainvccr.tick;
    backupvccr.tick;
    
    ogs.tick;
    crs.tick;
    
    maintO2inj.tick;
    
    waterRS.tick;
    fanpowerPS.tick;
    powerPS.tick; 
    
    CO2conc(i) = Inflatable1.CO2Percentage;
    astro1.tick;
    crewO2level(i) = Inflatable1.O2Store.currentLevel;
    crewCO2level(i) = Inflatable1.CO2Store.currentLevel;
    crewN2level(i) = Inflatable1.NitrogenStore.currentLevel;
    crewVaporlevel(i) = Inflatable1.VaporStore.currentLevel;
    crewOtherlevel(i) = Inflatable1.OtherStore.currentLevel;
    
    astro2.tick;
    galleyO2level(i) = LifeSupportUnit1.O2Store.currentLevel;
    galleyCO2level(i) = LifeSupportUnit1.CO2Store.currentLevel;
    galleyN2level(i) = LifeSupportUnit1.NitrogenStore.currentLevel;
    galleyVaporlevel(i) = LifeSupportUnit1.VaporStore.currentLevel;
    galleyOtherlevel(i) = LifeSupportUnit1.OtherStore.currentLevel;
    
    astro3.tick;
    labsO2level(i) = labs.O2Store.currentLevel;
    labsCO2level(i) = labs.CO2Store.currentLevel;
    labsN2level(i) = labs.NitrogenStore.currentLevel;
    labsVaporlevel(i) = labs.VaporStore.currentLevel;
    labsOtherlevel(i) = labs.OtherStore.currentLevel;
    
    astro4.tick;
    maintO2level(i) = maint.O2Store.currentLevel;
    maintCO2level(i) = maint.CO2Store.currentLevel;
    maintN2level(i) = maint.NitrogenStore.currentLevel;
    maintVaporlevel(i) = maint.VaporStore.currentLevel;
    maintOtherlevel(i) = maint.OtherStore.currentLevel;
    
    inflatableDehumidifier.tick;
    livingUnitDehumidifier.tick;
    

    
%     % Fans consume required air from source SimEnvironments
%     crew2main = crew2mainfan.takeAir;
%     main2crew = main2crewfan.takeAir;
%     crew2galley = crew2galleyfan.takeAir;
%     galley2crew = galley2crewfan.takeAir;
% 
%     % Fans send required air to destination SimEnvironments
%     crew2mainfan.sendAir(crew2main);
%     main2crewfan.sendAir(main2crew);
%     crew2galleyfan.sendAir(crew2galley);
%     galley2crewfan.sendAir(galley2crew);
    
    waitbar(i/simtime);

end

toc

beep

close(h)

% % Random plot commande used in code validation exercise
% figure, 
% subplot(2,2,1), plot(t2,crew_N2EnvLevel(t2),'LineWidth',2), title('Crew Quarters Environmental N2 Level'), grid on
% subplot(2,2,2), plot(t2,galley_N2EnvLevel(t2),'LineWidth',2), title('Galley Environmental N2 Level'), grid on
% subplot(2,2,3), plot(t2,labs_N2EnvLevel(t2),'LineWidth',2), title('Labs Environmental N2 Level'), grid on
% subplot(2,2,4), plot(t2,maint_N2EnvLevel(t2),'LineWidth',2), title('Maintenance Environmental N2 Level'), grid on

% Environmental N2 Store plots
figure, 
subplot(2,2,1), plot(1:simtime,crewN2level,'LineWidth',2), title('Crew Quarters Environmental N2 Level'), grid on
subplot(2,2,2), plot(1:simtime,galleyN2level,'LineWidth',2), title('Galley Environmental N2 Level'), grid on
subplot(2,2,3), plot(1:simtime,labsN2level,'LineWidth',2), title('Labs Environmental N2 Level'), grid on
subplot(2,2,4), plot(1:simtime,maintN2level,'LineWidth',2), title('Maintenance Environmental N2 Level'), grid on

i = i-1;
figure, plot(1:(i-1),crewO2level(1:(i-1)),1:(i-1),crewCO2level(1:(i-1)),...
    1:(i-1),crewN2level(1:(i-1)),1:(i-1),crewOtherlevel(1:(i-1)),1:(i-1),crewVaporlevel(1:(i-1)),'LineWidth',2),...
   legend('O_2','CO_2','N_2','Other','Vapor'), grid on
title('MATLAB Crew Quarters')

figure, plot(1:(i-1),maintO2level(1:(i-1)),1:(i-1),maintCO2level(1:(i-1)),...
    1:(i-1),maintN2level(1:(i-1)),1:(i-1),maintOtherlevel(1:(i-1)),1:(i-1),maintVaporlevel(1:(i-1)),'LineWidth',2),...
   legend('O_2','CO_2','N_2','Other','Vapor'), grid on
title('MATLAB Maintenance Module')

figure, plot(1:(i-1),labsO2level(1:(i-1)),1:(i-1),labsCO2level(1:(i-1)),...
    1:(i-1),labsN2level(1:(i-1)),1:(i-1),labsOtherlevel(1:(i-1)),1:(i-1),labsVaporlevel(1:(i-1)),'LineWidth',2),...
   legend('O_2','CO_2','N_2','Other','Vapor'), grid on
title('MATLAB Labs Module')

figure, plot(1:(i-1),galleyO2level(1:(i-1)),1:(i-1),galleyCO2level(1:(i-1)),...
    1:(i-1),galleyN2level(1:(i-1)),1:(i-1),galleyOtherlevel(1:(i-1)),1:(i-1),galleyVaporlevel(1:(i-1)),'LineWidth',2),...
   legend('O_2','CO_2','N_2','Other','Vapor'), grid on
title('MATLAB Galley Module')

figure, plot(maintN2level,'LineWidth',2),grid on

figure, plot(1:length(crewO2level),crewO2level), grid on
figure, plot(1:length(N2level),N2level), grid on
figure, plot(1:length(crewCO2level),crewCO2level), grid on
figure, plot(1:(i-1),H2level(1:(i-1)),'LineWidth',2), title('MATLAB H_2 Store'), grid on
% figure, plot(1:length(H2level),H2level), grid on
figure, plot(1:length(CH4level),CH4level), grid on
figure, plot(1:length(crewVaporlevel),crewVaporlevel,'LineWidth',2), grid on, title('MATLAB Crew Quarters Vapor Level')
figure, plot(1:(i-1),maintVaporlevel(1:(i-1)),'LineWidth',2), grid on, title('MATLAB Maintenance Vapor Level')
figure, plot(1:(i-1),H2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Potable Water Store'), grid on
figure, plot(1:(i-1),DirtyH2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Dirty Water Store'), grid on
% figure, plot(1:length(DirtyH2Ostorelevel),DirtyH2Ostorelevel), grid on
% figure, plot(1:length(FoodStoreLevel),FoodStoreLevel), grid on
% figure, plot(1:length(DryWasteStoreLevel),DryWasteStoreLevel), grid on
figure, plot(1:(i-1),DryWasteStoreLevel(1:(i-1)),'LineWidth',2), title('MATLAB Dry Waste Store'), grid on
figure, plot(1:(i-1),GreyH2Ostorelevel(1:(i-1)),'LineWidth',2), title('MATLAB Grey Water Store'), grid on
figure, plot(1:(i-1),O2Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB O_2 Store'), grid on
figure, plot(1:(i-1),CH4Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB Methane Store'), grid on
figure, plot(1:(i-1),consumedWaterBuffer(1:(i-1)),'LineWidth',2), title('MATLAB Consumed Water Buffer'), grid on
% figure, plot(1:length(GreyH2Ostorelevel),GreyH2Ostorelevel), grid on
figure, plot(1:(i-1),FoodStoreLevel(1:(i-1)),'LineWidth',2), title('MATLAB Food Store'), grid on
figure, plot(1:length(CO2conc),CO2conc), grid on
figure, plot(1:length(O2conc),O2conc), grid on
figure, plot(1:length(vaporconc),vaporconc), grid on
figure, plot(1:length(CO2concMain),CO2concMain), grid on
figure, plot(1:length(O2concMain),O2concMain), grid on
figure, plot(1:length(O2levelMain),O2levelMain), grid on
figure, plot(1:length(pres),pres), grid on
figure, plot(1:length(CO2storelevel),CO2storelevel), grid on
figure, plot(1:length(powerlevel),powerlevel), grid on
% figure, plot(1:length(CO2Storelevel),CO2Storelevel), grid on
figure, plot(1:(i-1),CO2Storelevel(1:(i-1)),'LineWidth',2), title('MATLAB CO_2 Store'), grid on
figure, plot(1:length(intensity),intensity)
