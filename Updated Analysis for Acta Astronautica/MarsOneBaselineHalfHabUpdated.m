%%  Mars One Default Simulation Case
%   By: Sydney Do (sydneydo@mit.edu)
%   Date Created: 6/28/2014
%   Last Updated: 12/22/2014
%
%   UPDATE 12/21/2014
%   - Corrected plant model code (ShelfImpl3.m - updated 12/20/2014) incorporated
%   - Updated plant growth profile incorporated (calculated 12/21/2014 - see Modified
%   Energy Cascade Low CO2 Correction.docx for details)
%
%   Code to simulate the baseline architecture of the Mars One Mission
%   Errors within BioSim code have been removed from the class files
%   accessed by this file
%
%   NOTE:
%   This simulation represents the 26month mission of the first Mars One
%   Crew. Here, we assume that the potable water and oxygen stores have
%   already been filled by the ISRU system prior to the crew arriving
%   Here, HALF the Mars One Hab is modeled.
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
missionDurationInHours = 19000;
numberOfEVAdaysPerWeek = 5;
numberOfCrew = 4;
missionDurationInWeeks = ceil(missionDurationInHours/24/7);

TotalAtmPressureTargeted = 70.3;        % targeted total atmospheric pressure, in kPa
O2FractionHypoxicLimit = 0.23;          % lower bound for a 70.3kPa atm based on EAWG Fig 4.1.1 and Advanced Life Support Requirements Document Fig 4-3
TargetO2MolarFraction = 0.265; 
% TotalPPO2Targeted = TargetO2MolarFraction*TotalAtmPressureTargeted;               % targeted O2 partial pressure, in kPa (converted from 26.5% O2)

% ISRU Production Rates
isruAddedWater = 0.02;      % Liters/hour
isruAddedCropWater = 1.11;  % Liter/hour
isruAddedO2 = 0;            % moles/hour
isruAddedN2 = 1.7;          % moles/hour

isruAddedWater = 0;      % Liters/hour
isruAddedCropWater = 0;  % Liter/hour
isruAddedO2 = 0;            % moles/hour
isruAddedN2 = 0;          % moles/hour

% EMU
EMUco2RemovalTechnology = 'RCA';  % options are RCA or METOX
EMUurineManagementTechnology = 'UCTA';  % options are MAG or UCTA

%% Initialize Stores
% Potable Water Store within Life Support Units (note water store capacity
% measured in liters)
PotableWaterStore = StoreImpl('Potable H2O','Material',1500,1500);      % 1500L Potable Water Store Capacity according to: http://www.mars-one.com/faq/health-and-ethics/will-the-astronauts-have-enough-water-food-and-oxygen#sthash.aCFnUUFk.dpuf
% PotableWaterStore = StoreImpl('Potable H2O','Material',56.7,56.7);      %
% WPA Product Water tank has a capacity of 56.7L (ref: SAE 2008-01-2007).
% Note that on ISS, the WPA Product Water Tank feeds the Potable Water
% Dispenser, the OGA, and the WHC flush and hygiene hose.

% O2 Store within Life Support Units (note O2 capacity measured in moles)
initialO2TankCapacityInKg = 120; %100.2;      % Calculated initial O2 tank capacity based on support crew for 60 days, note that another source on the Mars One webpage suggests a 60kg initial capacity for each living unit tank <http://www.mars-one.com/mission/roadmap/2023>
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

% We ramp up the 

% Gas Stores

H2Store = StoreImpl('H2 Store','Material',10000,0);     % H2 store for output of OGS - note that currently on the ISS, there is no H2 store, it is sent directly to the Sabatier reactor 
% CO2Store = StoreImpl('CO2 Store','Material',1000,0);    % CO2 store for VCCR - refer to accumulator attached to CDRA

% From: "Analyses of the Integration of Carbon Dioxide Removal Assembly, Compressor, Accumulator 
% and Sabatier Carbon Dioxide Reduction Assembly" SAE 2004-01-2496
% "CO2 accumulator � The accumulator volume was set at 0.7 ft3, based on an assessment of available 
% space within the OGA rack where the CRA will reside. Mass balance of CO2 pumped in from the 
% compressor and CO2 fed to the Sabatier CO2 reduction system is used to calculate the CO2 pressure. 
% Currently the operating pressure has been set to 20 � 130 psia."

% From SAE 2004-01-2496, on CDRA bed heaters - informs temp of CO2 sent to
% accumulator
% "During the first 10 min of the heat cycle, ullage air is pumped out back to the cabin. After this time, the bed is
% heated to approximately 250 �F and is exposed to space vacuum for desorption of the bed."
% ...
% "The heaters were OFF during the �night time�, or when the desorb bed temperature reached its set point
% of 400 �F, or when it was an adsorb cycle."

% (Ref: Functional Performance of an Enabling Atmosphere Revitalization Subsystem Architecture for Deep Space Exploration Missions (AIAA 2013-3421)
% Quote: �Because the commercial compressor discharge pressure was 414 kPa compared to the flight CO2 Reduction Assembly (CRA)
% compressor�s 827 kPa, the accumulator volume was increased from 19.8 liters to 48.1 liters�

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
numberOfN2Tanks = 292/91;      % We ramp the number up by a factor of 4 to make up for N2 leakage (which will be ultimately addressed by ISRU)
initialN2TankCapacityInKg = numberOfN2Tanks*91;
n2MolarMass = 2*14.007; %g/mol;
initialN2StoreMoles = initialN2TankCapacityInKg*1E3/n2MolarMass;
N2Store = StoreImpl('N2 Store','Material',initialN2StoreMoles,initialN2StoreMoles);     

% Power Stores
MainPowerStore = StoreImpl('Power','Material',1000000,1000000);

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

%% Food Stores
% carry along 120days worth of calories - initial simulations show an
% average crew metabolic rate of 3040.1 Calories/day
% Note that 120 days is equivalent to the longest growth cycle of all the
% plants grown
CarriedFood = Wheat;
AvgCaloriesPerCrewPerson = 3040.1;
CarriedCalories = numberOfCrew*AvgCaloriesPerCrewPerson*120;    % 120 days worth of calories
CarriedTotalMass = CarriedCalories/CarriedFood.CaloriesPerKilogram; % Note that calories per kilogram is on a wet mass basis

initialfood = FoodMatter(Wheat,CarriedTotalMass,CarriedFood.EdibleFreshBasisWaterContent*CarriedTotalMass); % xmlFoodStoreLevel is declared within the createFoodStore method within SimulationInitializer.java

CarriedFoodStore = FoodStoreImpl(CarriedTotalMass,initialfood);

LocallyGrownFoodStore = FoodStoreImpl(15000);

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

Inflatable1 = SimEnvironmentImpl('Inflatable 1',70.3,500000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);     %Note volume input is in Liters.
% Inflatable2 = SimEnvironmentImpl('Inflatable 2',70.3,500000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);     
LivingUnit1 = SimEnvironmentImpl('Living Unit 1',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);   % Note that here we assume that the internal volume of the Dragon modules sent to the surface is 25m^3
% LivingUnit2 = SimEnvironmentImpl('Living Unit 2',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
LifeSupportUnit1 = SimEnvironmentImpl('Life Support Unit 1',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
% LifeSupportUnit2 = SimEnvironmentImpl('Life Support Unit 2',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
CargoUnit1 = SimEnvironmentImpl('Cargo Unit 1',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
% CargoUnit2 = SimEnvironmentImpl('Cargo Unit 2',70.3,25000,0.265,0.003,0.731,0,0.001,hourlyLeakagePercentage,PotableWaterStore,GreyWaterStore,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);

%% Set up EVA environment
% Size EVA for two people - include airlock losses when EVA is executed

% That currently, CrewPersonImpl is only configured to exchange air with
% the environment that their activity is in

% EVAs last for eight hours continuously

% EVA essentially consumes gases from the O2 storage tank - since these
% recharge the PLSS tanks

%% EVA Consumable Consumption
% EVAs occur over eight ticks
numberOfEVAcrew = 2;
idealGasConstant = 8.314;       % J/K/mol
O2molarMass = 2*15.999;          % g/mol
EMUpressure = 29.6; % in kPa - equates to 4.3psi - same as Shuttle EMU and is quoted in EAWG Section 5.1 for dexterous tasks
EMUvolume = 2*28.3168*numberOfEVAcrew; % Generally between 1.5 and 2 cubic feet [L] - EMU Handbook Section 1.5.5      % in Liters, for two crew members
EMUtotalMoles = EMUpressure*EMUvolume/(idealGasConstant*(273.15+23));   % Total moles within both EMUs
% EMUleakmoles = 0.005*1E3/O2molarMass;       % From BVAD Section 5.2.2 - EMU leakage is 0.005kg/h (which is higher than the value quoted within Figure 1.8 of the Hamilton Sundstand EMU Handbook (36.2cubic cm/min)
Vleakrate = 36.2*1E-3*60;   % (L/hr) Maximum volumetric leakage rate of the PGA is calculated as 36.2 cubic cm/min (Figure 1.8) [2] [L/hr]
EMUleakmoles = EMUpressure*Vleakrate/(idealGasConstant*(273.15+23));      % Maximum mass leakage rate of the PGA [kg/s]
EMUleakPercentage = EMUleakmoles*numberOfEVAcrew/EMUtotalMoles;

% EMUco2RemovalTechnology = 'METOX';  % other option is RCA
% EMUurineManagementTechnology = 'UCTA';  % other option is MAG

load EVAPLSSoutput

% Define end of EVA EMU gaseous parameters
if strcmpi(EMUco2RemovalTechnology,'METOX')
    finalEMUo2level = emuO2levelMETOX*numberOfEVAcrew;
    finalEMUco2level = emuCO2levelMETOX*numberOfEVAcrew;
    finalFeedwaterTanklevel = plssfeedwatertanklevelMETOX*numberOfEVAcrew;    % also corresponds to total humidity level consumed, this captures any thermal control leakage
    plssO2TankLevel = plssO2TanklevelMETOX*numberOfEVAcrew;        % set corresponding StoreImpl.currentLevel to this value
    totalCO2removed = plssCO2removedlevelMETOX*numberOfEVAcrew;
    METOXregeneratorLoad = StoreImpl('METOX adsorbed CO2','Environmental');
    metoxCO2regenRate = totalCO2removed/10;         % 10 hours to completely regenerate a METOX canister
elseif strcmpi(EMUco2RemovalTechnology,'RCA')
    finalEMUo2level = emuO2levelRCA*numberOfEVAcrew;
    finalEMUco2level = emuCO2levelRCA*numberOfEVAcrew;
    finalFeedwaterTanklevel = plssfeedwatertanklevelRCA*numberOfEVAcrew;
    plssO2TankLevel = plssO2TanklevelRCA*numberOfEVAcrew;        % set corresponding StoreImpl.currentLevel to this value
    totalCO2removed = plssCO2removedlevelRCA*numberOfEVAcrew;
end
finalEMUvaporlevel = emuVaporlevelcommon*numberOfEVAcrew;

 
% Thermal control = {sublimator,radiator,cryogenic} = water usage = [0.57kg/hr,0.19kg/h,0]      REF:
% BVAD Section 5.2.2
% Note: Cryogenic cooling refers to cryogenic storage of O2
% O2 use: metabolic + leakage - 0.076kg/h, Note: O2 leakage alone is
% 0.005kg/h - REF BVAD Section 5.2.2 (compare this with EMU data)
% EVAco2removal = [METOX, Amine Swingbed]
% Amine Swingbed O2 loss rate is 0.15kg/h


% EMUdrinkbagVolume = 32*0.0295735;  % L, converted from 32 ounces (REF: Section 1.3.9 EMU Handbook)
% EMUinsuitDrinkBag = StoreImpl('EMU Drink Bag','Material',EMUdrinkbagVolume*numberOfEVAcrew,0);

EMUfeedwaterCapacity = 10*0.453592;  % (L), converted from 10 pounds of water, assuming a water density of 1000kg/m^3 = 1kg/L, REF - Section 2.1.4 EMU Handbook
EMUfeedwaterReservoir = StoreImpl('PLSS Feedwater Reservoir','Material',EMUfeedwaterCapacity*numberOfEVAcrew,0);

% Two options for liquid metabolic waste - either throw it away (as in the
% EMU MAG), or collect urine and feed it back into the UPA - as in Apollo
% EMU - find a reference for this!)
if strcmpi(EMUurineManagementTechnology,'UCTA')
    EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,EMUvolume,1,0,0,0,0,EMUleakPercentage,PotableWaterStore,EMUfeedwaterReservoir,DirtyWaterStore,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
elseif strcmpi(EMUurineManagementTechnology,'MAG')
    EMUmetabolicWaste = StoreImpl('EVA MAG','Environmental');       % This is to replace the dirty water store if water is collected within the MAG
    EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,EMUvolume,1,0,0,0,0,EMUleakPercentage,PotableWaterStore,EMUfeedwaterReservoir,EMUmetabolicWaste,DryWasteStore,[LocallyGrownFoodStore,CarriedFoodStore]);
end

EMUo2TankCapacity = 1.217*453.592/O2molarMass;      % moles, Converted from 1.217lbs - REF: Section 2.1.3 EMU Handbook
EMUo2Tanks = StoreImpl('EMU O2 Bottles','Material',EMUo2TankCapacity*numberOfEVAcrew,0);

% % EMU PCA
% EMUPCA = ISSinjectorImpl(EMUpressure,1,EMUo2Tanks,[],EVAenvironment,'EMU');

% Note: EMU Food bar is no longer flown (REF:
% http://spaceflight.nasa.gov/shuttle/reference/faq/eva.html)

%% Airlock Environment
% This environment is modeled to represent airlock depressurization losses
% and O2 consumed during EVA prebreathe

% Include airlock PCA (to recharge airlock)
% Remember to vent airlock for only first tick of EVA
% Remove this amount of air from the hab everytime an EVA occurs

airlockFreegasVolume = 3.7*1E3;     % L (converted from 3.7m^3) REF: BVAD Section 5.2.1 - this is equivalent to shuttle airlock - total volume is 4.25m^3 (pg 230 - The New Field of Space Architecture)
Airlock = SimEnvironmentImpl('Airlock',70.3,airlockFreegasVolume,0.265,0,0.734,0,0.001);

airlockCycleLoss = 13.8*airlockFreegasVolume/(idealGasConstant*(273.15+Airlock.temperature));    % REF: ISS Airlock depress pump is operated down to 13.8kPa, so the rest of the air is vented overboard - REF: "Trending of Overboard Leakage of ISS Cabin Atmosphere" (AIAA 2011-5149)

% EMU Prebreathe per CrewPerson
% This is the same as that employed for the space shuttle (going from a
% 70.3kPa 26.5% O2 atmosphere to a 29.6kPa 100% O2 atmosphere
% - Prebreathe lasts for 40 minutes and is performed in suit (REF: Table
% 3.1-1 EAWG Report)
% On ISS, an in-suit prebreath lasts 240 minutes (REF: Table 3.1-1 EAWG
% Report) and consumes 4.53kg per EVA (REF: Methodology and Assumptions
% of Contingency Shuttle Crew Support (CSCS) Calculations Using ISS ECLSS -
% SAE 2006-01-2061)
% Therefore, for Mars One, prebreathe O2 for two crew persons is:

% prebreatheO2 = 4.53*40/240 * 1E3/O2molarMass;   % moles of O2... supplied from O2 tanks

% Modified value according to more updated data:
% A typical suit purge on the ISS will achieve ? 95% O2 after 8 minutes and requires about 0.65 lb of O2."
% REF: Fifteen-minute EVA Prebreathe Protocol Using NASA's Exploration
% Atmosphere - AIAA2013-3525 - 0.65lb O2 used per EMU (includes inflation)
prebreatheO2 = 0.65*453.592/O2molarMass*numberOfEVAcrew;   % moles of O2... supplied from O2 tanks

%% Initialize Key Activity Parameters

% Baseline Activities and Location Mappings
lengthOfExercise = 2;                       % Number of hours spent on exercise activity

% Generate distribution of habitation options from which IVA activities
% will take place
HabDistribution = [repmat(Inflatable1,1,2),repmat(LivingUnit1,1,2),repmat(LifeSupportUnit1,1,2),CargoUnit1];

IVAhour = ActivityImpl('IVA',2,1,HabDistribution);          % One hour of IVA time (corresponds to generic IVA activity)
Sleep = ActivityImpl('Sleep',0,8,Inflatable1);          % Sleep period
Exercise = ActivityImpl('Exercise',5,lengthOfExercise,Inflatable1);    % Exercise period
EVA = ActivityImpl('EVA',4,8,EVAenvironment);              % EVA - fixed length of 8 hours

% Vector of baselin activities:
ActivityList = [IVAhour,Sleep,Exercise,EVA];

% Auto-Generate Crew Schedule
[crewSchedule, missionEVAschedule,crewEVAScheduleLogical] = CrewScheduler(numberOfEVAdaysPerWeek,numberOfCrew,missionDurationInWeeks,ActivityList);

%% Initialize CrewPersons
astro1 = CrewPersonImpl2('Male 1',35,75,'Male',[crewSchedule{1,:}]);%,O2FractionHypoxicLimit);
astro2 = CrewPersonImpl2('Female 1',35,55,'Female',[crewSchedule{2,:}]);
astro3 = CrewPersonImpl2('Male 2',35,72,'Male',[crewSchedule{3,:}]);
astro4 = CrewPersonImpl2('Female 2',35,55,'Female',[crewSchedule{4,:}]);

%% Clear crewSchedule to save ~2MB memory
clear crewSchedule

%% Biomass Stores
BiomassStore = BiomassStoreImpl(100000);
% Set more crop type for FoodMatter somewhere later on

%% Initialize crop shelves

CropWaterStore = StoreImpl('Grey Crop H2O','Material',100000,100000);   % Initialize a 9200L water buffer

WhitePotatoShelf = ShelfImpl3(WhitePotato,5/2,Inflatable1,CropWaterStore,CropWaterStore,MainPowerStore,BiomassStore);
PeanutShelf = ShelfImpl3(Peanut,72.68/2,Inflatable1,CropWaterStore,CropWaterStore,MainPowerStore,BiomassStore);
SoybeanShelf = ShelfImpl3(Soybean,39.7/2,Inflatable1,CropWaterStore,CropWaterStore,MainPowerStore,BiomassStore);
SweetPotatoShelf = ShelfImpl3(SweetPotato,9.8/2,Inflatable1,CropWaterStore,CropWaterStore,MainPowerStore,BiomassStore);
WheatShelf = ShelfImpl3(Wheat,72.53/2,Inflatable1,CropWaterStore,CropWaterStore,MainPowerStore,BiomassStore);

% Initialize Staggered Shelves
WhitePotatoShelves = ShelfStagger(WhitePotatoShelf,WhitePotatoShelf.Crop.TimeAtCropMaturity,0);
PeanutShelves = ShelfStagger(PeanutShelf,PeanutShelf.Crop.TimeAtCropMaturity,0);
SoybeanShelves = ShelfStagger(SoybeanShelf,SoybeanShelf.Crop.TimeAtCropMaturity,0);
SweetPotatoShelves = ShelfStagger(SweetPotatoShelf,SweetPotatoShelf.Crop.TimeAtCropMaturity,0);
WheatShelves = ShelfStagger(WheatShelf,WheatShelf.Crop.TimeAtCropMaturity,0);

% Single Shelves for Testing
% WhitePotatoShelves = ShelfStagger(WhitePotatoShelf,1,0);
% PeanutShelves = ShelfStagger(PeanutShelf,1,0);
% SoybeanShelves = ShelfStagger(SoybeanShelf,1,0);
% SweetPotatoShelves = ShelfStagger(SweetPotatoShelf,1,0);
% WheatShelves = ShelfStagger(WheatShelf,1,0);

%% Initialize FoodProcessor
FoodProcessor = FoodProcessorImpl;
FoodProcessor.BiomassConsumerDefinition = ResourceUseDefinitionImpl(BiomassStore,1000,1000);
FoodProcessor.PowerConsumerDefinition = ResourceUseDefinitionImpl(MainPowerStore,1000,1000);
FoodProcessor.FoodProducerDefinition = ResourceUseDefinitionImpl(LocallyGrownFoodStore,1000,1000);
FoodProcessor.WaterProducerDefinition = ResourceUseDefinitionImpl(CropWaterStore,1000,1000);        % FoodProcessor now outputs back to crop water store
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

% IMV between Inflatable and Living Unit
inflatable2LivingUnitFan = ISSFanImpl2(Inflatable1,LivingUnit1,MainPowerStore);

% IMV between Living Unit and Life Support Unit
livingUnit2LifeSupportFan = ISSFanImpl2(LivingUnit1,LifeSupportUnit1,MainPowerStore);

% IMV between Life Support Unit and Cargo Unit
lifeSupport2CargoUnitFan = ISSFanImpl2(LifeSupportUnit1,CargoUnit1,MainPowerStore);

% IMV between Life Support Unit and Airlock
livingUnit2AirlockFan = ISSFanImpl2(LivingUnit1,Airlock,MainPowerStore);

% IMV between Living Units
% livingUnit2livingUnitFan = ISSFanImpl2(LivingUnit1,LivingUnit2,MainPowerStore);

% IMV between Inflatable 2 and Living Unit 2
% inflatable2LivingUnitFan2 = ISSFanImpl2(Inflatable2,LivingUnit2,MainPowerStore);

% IMV between Living Unit 2 and Life Support Unit 2
% livingUnit2LifeSupportFan2 = ISSFanImpl2(LivingUnit2,LifeSupportUnit2,MainPowerStore);

% IMV between Life Support Unit 2 and Cargo Unit 2
% lifeSupport2CargoUnitFan2 = ISSFanImpl2(LifeSupportUnit2,CargoUnit2,MainPowerStore);

%% Initialize Injectors (Models ISS Pressure Control Assemblies)
% See accompanying word doc for rationale behind PCA locations

% Inflatable PCA
inflatablePCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Inflatable1);

% Inflatable2 PCA 
% inflatable2PCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Inflatable2);

% Living Unit PCA
livingUnitPCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LivingUnit1);

% Living Unit 2 PCA
% livingUnit2PCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LivingUnit2);

% Life Support Unit PCA
lifeSupportUnitPCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LifeSupportUnit1);

% Life Support Unit 2 PCA
% lifeSupportUnit2PCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,LifeSupportUnit2);

% Cargo Unit PPRV
cargoUnitPPRV = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,CargoUnit1,'PPRV');

% Cargo Unit 2 PPRV
% cargoUnit2PPRV = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,CargoUnit2,'PPRV');

% Airlock PCA
airlockPCA = ISSinjectorImpl(TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,N2Store,Airlock);

%% Initialize Temperature and Humidity Control (THC) Technologies
% Insert CCAA within Inflatable, Living Unit, and Life Support Unit
% Placement of CCAAs is based on modules with a large period of continuous
% human presence (i.e. large sources of humidity condensate)

% Inflatable CCAA
inflatableCCAA = ISSDehumidifierImpl(Inflatable1,DirtyWaterStore,MainPowerStore);

% Inflatable 2 CCAA
% inflatable2CCAA = ISSDehumidifierImpl(Inflatable2,DirtyWaterStore,MainPowerStore);

% Living Unit/Airlock CCAA
livingUnitCCAA = ISSDehumidifierImpl(LivingUnit1,DirtyWaterStore,MainPowerStore);

% Living Unit 2
% livingUnit2CCAA = ISSDehumidifierImpl(LivingUnit2,DirtyWaterStore,MainPowerStore);

% Life Support Unit CCAA
lifeSupportUnitCCAA = ISSDehumidifierImpl(LifeSupportUnit1,DirtyWaterStore,MainPowerStore);

% Life Support Unit 2 CCAA
% lifeSupportUnit2CCAA = ISSDehumidifierImpl(LifeSupportUnit2,DirtyWaterStore,MainPowerStore);

%% Initialize Air Processing Technologies

% Initialize Main VCCR (Linear)
CDRAsetpoint = 1500;    % Set CDRA set point to 1500ppm
% mainvccr = ISSVCCRLinearImpl(LifeSupportUnit1,LifeSupportUnit1,CO2Store,MainPowerStore);
mainvccr = ISSVCCRLinearImpl(LifeSupportUnit1,LifeSupportUnit1,CO2Store,MainPowerStore,CDRAsetpoint);

% Initialize OGS
ogs = ISSOGA(TotalAtmPressureTargeted,TargetO2MolarFraction,LifeSupportUnit1,PotableWaterStore,MainPowerStore,H2Store);

% Initialize CRS (Sabatier Reactor)
crs = ISSCRSImpl(H2Store,CO2Store,GreyWaterStore,MethaneStore,MainPowerStore);

% Initialize Oxygen Removal Assembly
% inflatableORA = O2extractor(Inflatable2,TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store,'Molar Fraction');

% Initialize CO2 Injector
targetCO2conc = 1200*1E-6;
co2Injector = CO2Injector(Inflatable1,CO2Store,targetCO2conc);

% lifeSupportUnitORA = O2extractor(LifeSupportUnit1,TotalAtmPressureTargeted,TargetO2MolarFraction,O2Store);

% Condensed Water Removal System
inflatable1WaterExtractor = CondensedWaterRemover(Inflatable1,CropWaterStore);

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

simtime = missionDurationInHours;
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
carriedfoodstorelevel = zeros(1,simtime);
grownfoodstorelevel = zeros(1,simtime);
dryfoodlevel = zeros(1,simtime);
caloriccontent = zeros(1,simtime);
biomassstorelevel = zeros(1,simtime);
cropwaterstorelevel = zeros(1,simtime);
powerlevel = zeros(1,simtime);
metoxregenstore = zeros(1,simtime);
dumpedEVAdirtywater = zeros(1,simtime);
plssfeedwatertanklevel = zeros(1,simtime);
plsso2tanklevel = zeros(1,simtime);
reservoirFillLevel = zeros(1,simtime);

inflatablePressure = zeros(1,simtime);
inflatableO2level = zeros(1,simtime);
inflatableCO2level = zeros(1,simtime);
inflatableN2level = zeros(1,simtime);
inflatableVaporlevel = zeros(1,simtime);
inflatableOtherlevel = zeros(1,simtime);
inflatableTotalMoles = zeros(1,simtime);
inflatableCondensedVaporMoles = zeros(1,simtime);

% inflatable2Pressure = zeros(1,simtime);
% inflatable2O2level = zeros(1,simtime);
% inflatable2CO2level = zeros(1,simtime);
% inflatable2N2level = zeros(1,simtime);
% inflatable2Vaporlevel = zeros(1,simtime);
% inflatable2Otherlevel = zeros(1,simtime);
% inflatable2TotalMoles = zeros(1,simtime);
% inflatable2CondensedVaporMoles = zeros(1,simtime);

livingUnitPressure = zeros(1,simtime);
livingUnitO2level = zeros(1,simtime);
livingUnitCO2level = zeros(1,simtime);
livingUnitN2level = zeros(1,simtime);
livingUnitVaporlevel = zeros(1,simtime);
livingUnitOtherlevel = zeros(1,simtime);
livingUnitTotalMoles = zeros(1,simtime);

% livingUnit2Pressure = zeros(1,simtime);
% livingUnit2O2level = zeros(1,simtime);
% livingUnit2CO2level = zeros(1,simtime);
% livingUnit2N2level = zeros(1,simtime);
% livingUnit2Vaporlevel = zeros(1,simtime);
% livingUnit2Otherlevel = zeros(1,simtime);
% livingUnit2TotalMoles = zeros(1,simtime);

lifeSupportUnitPressure = zeros(1,simtime);
lifeSupportUnitO2level = zeros(1,simtime);
lifeSupportUnitCO2level = zeros(1,simtime);
lifeSupportUnitN2level = zeros(1,simtime);
lifeSupportUnitVaporlevel = zeros(1,simtime);
lifeSupportUnitOtherlevel = zeros(1,simtime);
lifeSupportUnitTotalMoles = zeros(1,simtime);

% lifeSupportUnit2Pressure = zeros(1,simtime);
% lifeSupportUnit2O2level = zeros(1,simtime);
% lifeSupportUnit2CO2level = zeros(1,simtime);
% lifeSupportUnit2N2level = zeros(1,simtime);
% lifeSupportUnit2Vaporlevel = zeros(1,simtime);
% lifeSupportUnit2Otherlevel = zeros(1,simtime);
% lifeSupportUnit2TotalMoles = zeros(1,simtime);

cargoUnitPressure = zeros(1,simtime);
cargoUnitO2level = zeros(1,simtime);
cargoUnitCO2level = zeros(1,simtime);
cargoUnitN2level = zeros(1,simtime);
cargoUnitVaporlevel = zeros(1,simtime);
cargoUnitOtherlevel = zeros(1,simtime);
cargoUnitTotalMoles = zeros(1,simtime);

% cargoUnit2Pressure = zeros(1,simtime);
% cargoUnit2O2level = zeros(1,simtime);
% cargoUnit2CO2level = zeros(1,simtime);
% cargoUnit2N2level = zeros(1,simtime);
% cargoUnit2Vaporlevel = zeros(1,simtime);
% cargoUnit2Otherlevel = zeros(1,simtime);
% cargoUnit2TotalMoles = zeros(1,simtime);

airlockPressure = zeros(1,simtime);
airlockO2level = zeros(1,simtime);
airlockCO2level = zeros(1,simtime);
airlockN2level = zeros(1,simtime);
airlockVaporlevel = zeros(1,simtime);
airlockOtherlevel = zeros(1,simtime);
airlockTotalMoles = zeros(1,simtime);

ogsoutput = zeros(1,simtime);
inflatablePCAaction = zeros(4,simtime+1);
% inflatable2PCAaction = zeros(4,simtime+1);
livingUnitPCAaction = zeros(4,simtime+1);
% livingUnit2PCAaction = zeros(4,simtime+1);
lifeSupportUnitPCAaction = zeros(4,simtime+1);
% lifeSupportUnit2PCAaction = zeros(4,simtime+1);
cargoUnitPPRVaction = zeros(4,simtime+1);
% cargoUnit2PPRVaction = zeros(4,simtime+1);
airlockPCAaction = zeros(4,simtime+1);

inflatableCCAAoutput = zeros(1,simtime);
livingUnitCCAAoutput = zeros(1,simtime);
lifeSupportUnitCCAAoutput = zeros(1,simtime);
% inflatable2CCAAoutput = zeros(1,simtime);
% livingUnit2CCAAoutput = zeros(1,simtime);
% lifeSupportUnit2CCAAoutput = zeros(1,simtime);

condensedWaterRemoved = zeros(1,simtime);
co2injected = zeros(1,simtime);

whitePotatoShelfWaterLevel = zeros(1,simtime);
peanutShelfWaterLevel = zeros(1,simtime);
soybeanShelfWaterLevel = zeros(1,simtime);
sweetPotatoShelfWaterLevel = zeros(1,simtime);
wheatShelfWaterLevel = zeros(1,simtime);

crsH2OProduced = zeros(1,simtime);
crsCompressorOperation = zeros(2,simtime);
co2accumulatorlevel = zeros(1,simtime);
co2removed = zeros(1,simtime);
inflatableO2extracted = zeros(1,simtime);

hoursOnEVA = zeros(1,simtime);     % Flag to indicate whether or not the Airlock should be depressurized
currentEVAcrew = zeros(1,4);    % Current crewpersons on EVA

h = waitbar(0,'Please wait...');

toc

%% Time Loop

tic

timestamp = datestr(clock);
timestamp(timestamp==':') = '-';
% Start recording command window
diary(['HabNet Log ',timestamp,'.txt'])
disp(['Simulation Run Started: ',datestr(clock)]);

for i = 1:simtime
        
    if astro1.alive == 0 || astro2.alive == 0 || astro3.alive == 0 || astro4.alive == 0 ||...
            sum([WhitePotatoShelves.Shelves.hasDied]) >= 1 ||...
            sum([PeanutShelves.Shelves.hasDied]) >= 1 || ...
            sum([SoybeanShelves.Shelves.hasDied]) >= 1 || ...
            sum([SweetPotatoShelves.Shelves.hasDied]) >= 1 || ...
            sum([WheatShelves.Shelves.hasDied]) >= 1
        
        % Remove all trailing zeros from recorded data vectors
        o2storelevel = o2storelevel(1:(i-1));
        co2storelevel = co2storelevel(1:(i-1));
        n2storelevel = n2storelevel(1:(i-1));
        h2storelevel = h2storelevel(1:(i-1));
        ch4storelevel = ch4storelevel(1:(i-1));
        potablewaterstorelevel = potablewaterstorelevel(1:(i-1));
        dirtywaterstorelevel = dirtywaterstorelevel(1:(i-1));
        greywaterstorelevel = greywaterstorelevel(1:(i-1));
        drywastestorelevel = drywastestorelevel(1:(i-1));
        carriedfoodstorelevel = carriedfoodstorelevel(1:(i-1));
        cropwaterstorelevel = cropwaterstorelevel(1:(i-1));
        powerlevel = powerlevel(1:(i-1));
        if strcmpi(EMUco2RemovalTechnology,'METOX')
            metoxregenstore = metoxregenstore(1:(i-1));
        end
        
        if strcmpi(EMUurineManagementTechnology,'MAG')
            dumpedEVAdirtywater = dumpedEVAdirtywater(1:(i-1));
        end
        plssfeedwatertanklevel = plssfeedwatertanklevel(1:(i-1));
        plsso2tanklevel = plsso2tanklevel(1:(i-1));
        
        hoursOnEVA = hoursOnEVA(1:(i-1));
    
        % Record Inflatable Unit Atmosphere
        inflatablePressure = inflatablePressure(1:(i-1));
        inflatableO2level = inflatableO2level(1:(i-1));
        inflatableCO2level = inflatableCO2level(1:(i-1));
        inflatableN2level = inflatableN2level(1:(i-1));
        inflatableVaporlevel = inflatableVaporlevel(1:(i-1));
        inflatableOtherlevel = inflatableOtherlevel(1:(i-1));
        inflatableTotalMoles = inflatableTotalMoles(1:(i-1));
        inflatableCondensedVaporMoles = inflatableCondensedVaporMoles(1:(i-1));
        
%         inflatable2Pressure = inflatable2Pressure(1:(i-1));
%         inflatable2O2level = inflatable2O2level(1:(i-1));
%         inflatable2CO2level = inflatable2CO2level(1:(i-1));
%         inflatable2N2level = inflatable2N2level(1:(i-1));
%         inflatable2Vaporlevel = inflatable2Vaporlevel(1:(i-1));
%         inflatable2Otherlevel = inflatable2Otherlevel(1:(i-1));
%         inflatable2TotalMoles = inflatable2TotalMoles(1:(i-1));
%         inflatable2CondensedVaporMoles = inflatable2CondensedVaporMoles(1:(i-1));
    
        % Record Living Unit Atmosphere
        livingUnitPressure = livingUnitPressure(1:(i-1));
        livingUnitO2level = livingUnitO2level(1:(i-1));
        livingUnitCO2level = livingUnitCO2level(1:(i-1));
        livingUnitN2level = livingUnitN2level(1:(i-1));
        livingUnitVaporlevel = livingUnitVaporlevel(1:(i-1));
        livingUnitOtherlevel = livingUnitOtherlevel(1:(i-1));
        livingUnitTotalMoles = livingUnitTotalMoles(1:(i-1));
        
        % Record Living Unit 2 Atmosphere
%         livingUnit2Pressure = livingUnit2Pressure(1:(i-1));
%         livingUnit2O2level = livingUnit2O2level(1:(i-1));
%         livingUnit2CO2level = livingUnit2CO2level(1:(i-1));
%         livingUnit2N2level = livingUnit2N2level(1:(i-1));
%         livingUnit2Vaporlevel = livingUnit2Vaporlevel(1:(i-1));
%         livingUnit2Otherlevel = livingUnit2Otherlevel(1:(i-1));
%         livingUnit2TotalMoles = livingUnit2TotalMoles(1:(i-1));
       
        % Record Life Support Unit Atmosphere
        lifeSupportUnitPressure = lifeSupportUnitPressure(1:(i-1));
        lifeSupportUnitO2level = lifeSupportUnitO2level(1:(i-1));
        lifeSupportUnitCO2level = lifeSupportUnitCO2level(1:(i-1));
        lifeSupportUnitN2level = lifeSupportUnitN2level(1:(i-1));
        lifeSupportUnitVaporlevel = lifeSupportUnitVaporlevel(1:(i-1));
        lifeSupportUnitOtherlevel = lifeSupportUnitOtherlevel(1:(i-1));
        lifeSupportUnitTotalMoles = lifeSupportUnitTotalMoles(1:(i-1));
           
        % Record Life Support Unit 2 Atmosphere
%         lifeSupportUnit2Pressure = lifeSupportUnit2Pressure(1:(i-1));
%         lifeSupportUnit2O2level = lifeSupportUnit2O2level(1:(i-1));
%         lifeSupportUnit2CO2level = lifeSupportUnit2CO2level(1:(i-1));
%         lifeSupportUnit2N2level = lifeSupportUnit2N2level(1:(i-1));
%         lifeSupportUnit2Vaporlevel = lifeSupportUnit2Vaporlevel(1:(i-1));
%         lifeSupportUnit2Otherlevel = lifeSupportUnit2Otherlevel(1:(i-1));
%         lifeSupportUnit2TotalMoles = lifeSupportUnit2TotalMoles(1:(i-1));
        
        % Record Cargo Unit Atmosphere
        cargoUnitPressure = cargoUnitPressure(1:(i-1));
        cargoUnitO2level = cargoUnitO2level(1:(i-1));
        cargoUnitCO2level = cargoUnitCO2level(1:(i-1));
        cargoUnitN2level = cargoUnitN2level(1:(i-1));
        cargoUnitVaporlevel = cargoUnitVaporlevel(1:(i-1));
        cargoUnitOtherlevel = cargoUnitOtherlevel(1:(i-1));
        cargoUnitTotalMoles = cargoUnitTotalMoles(1:(i-1));

        % Record Cargo Unit 2 Atmosphere
%         cargoUnit2Pressure = cargoUnit2Pressure(1:(i-1));
%         cargoUnit2O2level = cargoUnit2O2level(1:(i-1));
%         cargoUnit2CO2level = cargoUnit2CO2level(1:(i-1));
%         cargoUnit2N2level = cargoUnit2N2level(1:(i-1));
%         cargoUnit2Vaporlevel = cargoUnit2Vaporlevel(1:(i-1));
%         cargoUnit2Otherlevel = cargoUnit2Otherlevel(1:(i-1));
%         cargoUnit2TotalMoles = cargoUnit2TotalMoles(1:(i-1));
        
        % Record Airlock Atmosphere
        airlockPressure = airlockPressure(1:(i-1));
        airlockO2level = airlockO2level(1:(i-1));
        airlockCO2level = airlockCO2level(1:(i-1));
        airlockN2level = airlockN2level(1:(i-1));
        airlockVaporlevel = airlockVaporlevel(1:(i-1));
        airlockOtherlevel = airlockOtherlevel(1:(i-1));
        airlockTotalMoles = airlockTotalMoles(1:(i-1));
        
        ogsoutput = ogsoutput(1:(i-1));
        inflatableO2extracted = inflatableO2extracted(1:(i-1));
        condensedWaterRemoved = condensedWaterRemoved(1:(i-1));
        
        whitePotatoShelfWaterLevel = whitePotatoShelfWaterLevel(1:(i-1));
        peanutShelfWaterLevel = peanutShelfWaterLevel(1:(i-1));
        soybeanShelfWaterLevel = soybeanShelfWaterLevel(1:(i-1));
        sweetPotatoShelfWaterLevel = sweetPotatoShelfWaterLevel(1:(i-1));
        wheatShelfWaterLevel = wheatShelfWaterLevel(1:(i-1));
    
        % Common Cabin Air Assemblies
        inflatableCCAAoutput = inflatableCCAAoutput(1:(i-1));
        livingUnitCCAAoutput = livingUnitCCAAoutput(1:(i-1));
        lifeSupportUnitCCAAoutput = lifeSupportUnitCCAAoutput(1:(i-1));
%         inflatable2CCAAoutput = inflatable2CCAAoutput(1:(i-1));
%         livingUnit2CCAAoutput = livingUnit2CCAAoutput(1:(i-1));
%         lifeSupportUnit2CCAAoutput = lifeSupportUnit2CCAAoutput(1:(i-1));
        
        % Pressure Control Assemblies
        inflatablePCAaction = inflatablePCAaction(:,1:(i-1));
%         inflatable2PCAaction = inflatable2PCAaction(:,1:(i-1));
        livingUnitPCAaction = livingUnitPCAaction(:,1:(i-1));
%         livingUnit2PCAaction = livingUnit2PCAaction(:,1:(i-1));
        lifeSupportUnitPCAaction = lifeSupportUnitPCAaction(:,1:(i-1));
%         lifeSupportUnit2PCAaction = lifeSupportUnit2PCAaction(:,1:(i-1));
        cargoUnitPPRVaction = cargoUnitPPRVaction(:,1:(i-1));
%         cargoUnit2PPRVaction = cargoUnit2PPRVaction(:,1:(i-1));
        airlockPCAaction = airlockPCAaction(:,1:(i-1));
        
        % Run Waste Processing ECLSS Hardware
        co2removed = co2removed(1:(i-1));
        crsH2OProduced = crsH2OProduced(1:(i-1));
        co2accumulatorlevel = co2accumulatorlevel(1:(i-1));
        
        t = 1:(length(o2storelevel));
        
        toc
        
        % Record and save command window display
        disp(['Simulation Run Ended: ',datestr(clock)]);
        diary off
        
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
    biomassstorelevel(i) = BiomassStore.currentLevel;
    powerlevel(i) = MainPowerStore.currentLevel;
    if strcmpi(EMUco2RemovalTechnology,'METOX')
        metoxregenstore(i) = METOXregeneratorLoad.currentLevel;
    end
    
    if strcmpi(EMUurineManagementTechnology,'MAG')
        dumpedEVAdirtywater(i) = EMUmetabolicWaste.currentLevel;
    end

    % Record PLSS Tanks
    plssfeedwatertanklevel(i) = EMUfeedwaterReservoir.currentLevel;
    plsso2tanklevel(i) = EMUo2Tanks.currentLevel;
    
    % Record Inflatable Unit Atmosphere
    inflatablePressure(i) = Inflatable1.pressure;
    inflatableO2level(i) = Inflatable1.O2Store.currentLevel;
    inflatableCO2level(i) = Inflatable1.CO2Store.currentLevel;
    inflatableN2level(i) = Inflatable1.NitrogenStore.currentLevel;
    inflatableVaporlevel(i) = Inflatable1.VaporStore.currentLevel;
    inflatableOtherlevel(i) = Inflatable1.OtherStore.currentLevel;
    inflatableTotalMoles(i) = Inflatable1.totalMoles;
    
    % Record Inflatable2 Unit Atmosphere
%     inflatable2Pressure(i) = Inflatable2.pressure;
%     inflatable2O2level(i) = Inflatable2.O2Store.currentLevel;
%     inflatable2CO2level(i) = Inflatable2.CO2Store.currentLevel;
%     inflatable2N2level(i) = Inflatable2.NitrogenStore.currentLevel;
%     inflatable2Vaporlevel(i) = Inflatable2.VaporStore.currentLevel;
%     inflatable2Otherlevel(i) = Inflatable2.OtherStore.currentLevel;
%     inflatable2TotalMoles(i) = Inflatable2.totalMoles;
    
    % Record Living Unit Atmosphere
    livingUnitPressure(i) = LivingUnit1.pressure;
    livingUnitO2level(i) = LivingUnit1.O2Store.currentLevel;
    livingUnitCO2level(i) = LivingUnit1.CO2Store.currentLevel;
    livingUnitN2level(i) = LivingUnit1.NitrogenStore.currentLevel;
    livingUnitVaporlevel(i) = LivingUnit1.VaporStore.currentLevel;
    livingUnitOtherlevel(i) = LivingUnit1.OtherStore.currentLevel;
    livingUnitTotalMoles(i) = LivingUnit1.totalMoles;
    
    % Record Living Unit 2 Atmosphere
%     livingUnit2Pressure(i) = LivingUnit2.pressure;
%     livingUnit2O2level(i) = LivingUnit2.O2Store.currentLevel;
%     livingUnit2CO2level(i) = LivingUnit2.CO2Store.currentLevel;
%     livingUnit2N2level(i) = LivingUnit2.NitrogenStore.currentLevel;
%     livingUnit2Vaporlevel(i) = LivingUnit2.VaporStore.currentLevel;
%     livingUnit2Otherlevel(i) = LivingUnit2.OtherStore.currentLevel;
%     livingUnit2TotalMoles(i) = LivingUnit2.totalMoles;
    
    % Record Life Support Unit Atmosphere
    lifeSupportUnitPressure(i) = LifeSupportUnit1.pressure;
    lifeSupportUnitO2level(i) = LifeSupportUnit1.O2Store.currentLevel;
    lifeSupportUnitCO2level(i) = LifeSupportUnit1.CO2Store.currentLevel;
    lifeSupportUnitN2level(i) = LifeSupportUnit1.NitrogenStore.currentLevel;
    lifeSupportUnitVaporlevel(i) = LifeSupportUnit1.VaporStore.currentLevel;
    lifeSupportUnitOtherlevel(i) = LifeSupportUnit1.OtherStore.currentLevel;
    lifeSupportUnitTotalMoles(i) = LifeSupportUnit1.totalMoles;
    
    % Record Life Support Unit 2 Atmosphere
%     lifeSupportUnit2Pressure(i) = LifeSupportUnit2.pressure;
%     lifeSupportUnit2O2level(i) = LifeSupportUnit2.O2Store.currentLevel;
%     lifeSupportUnit2CO2level(i) = LifeSupportUnit2.CO2Store.currentLevel;
%     lifeSupportUnit2N2level(i) = LifeSupportUnit2.NitrogenStore.currentLevel;
%     lifeSupportUnit2Vaporlevel(i) = LifeSupportUnit2.VaporStore.currentLevel;
%     lifeSupportUnit2Otherlevel(i) = LifeSupportUnit2.OtherStore.currentLevel;
%     lifeSupportUnit2TotalMoles(i) = LifeSupportUnit2.totalMoles;
    
    % Record Cargo Unit Atmosphere
    cargoUnitPressure(i) = CargoUnit1.pressure;
    cargoUnitO2level(i) = CargoUnit1.O2Store.currentLevel;
    cargoUnitCO2level(i) = CargoUnit1.CO2Store.currentLevel;
    cargoUnitN2level(i) = CargoUnit1.NitrogenStore.currentLevel;
    cargoUnitVaporlevel(i) = CargoUnit1.VaporStore.currentLevel;
    cargoUnitOtherlevel(i) = CargoUnit1.OtherStore.currentLevel;
    cargoUnitTotalMoles(i) = CargoUnit1.totalMoles;
    
    % Record Cargo Unit 2 Atmosphere
%     cargoUnit2Pressure(i) = CargoUnit2.pressure;
%     cargoUnit2O2level(i) = CargoUnit2.O2Store.currentLevel;
%     cargoUnit2CO2level(i) = CargoUnit2.CO2Store.currentLevel;
%     cargoUnit2N2level(i) = CargoUnit2.NitrogenStore.currentLevel;
%     cargoUnit2Vaporlevel(i) = CargoUnit2.VaporStore.currentLevel;
%     cargoUnit2Otherlevel(i) = CargoUnit2.OtherStore.currentLevel;
%     cargoUnit2TotalMoles(i) = CargoUnit2.totalMoles;
    
    % Record Airlock Atmosphere
    airlockPressure(i) = Airlock.pressure;
    airlockO2level(i) = Airlock.O2Store.currentLevel;
    airlockCO2level(i) = Airlock.CO2Store.currentLevel;
    airlockN2level(i) = Airlock.NitrogenStore.currentLevel;
    airlockVaporlevel(i) = Airlock.VaporStore.currentLevel;
    airlockOtherlevel(i) = Airlock.OtherStore.currentLevel;
    airlockTotalMoles(i) = Airlock.totalMoles;
    
    %% Tick Modules
    
    % Leak Modules
    Inflatable1.tick;
%     Inflatable2.tick;
    LivingUnit1.tick;
%     LivingUnit2.tick;
    LifeSupportUnit1.tick;
%     LifeSupportUnit2.tick;
    CargoUnit1.tick;
%     CargoUnit2.tick;
    
    % Run Fans
    inflatable2LivingUnitFan.tick;
%     inflatable2LivingUnitFan2.tick;       % Switch off fan to prevent
%     atmospheric flow between plant growth chamber and the remainder of
%     the hab
    livingUnit2LifeSupportFan.tick;
%     livingUnit2LifeSupportFan2.tick;
    lifeSupport2CargoUnitFan.tick;
%     lifeSupport2CargoUnitFan2.tick;
%     livingUnit2livingUnitFan.tick;
    livingUnit2AirlockFan.tick;
    
    % Run Power Supply
    powerPS.tick; 
    
    % Run ECLSS Hardware       
    ogsoutput(i) = ogs.tick;
    
    % Tick ORA
%     inflatableO2extracted(i) = inflatableORA.tick;
    
    % Pressure Control Assemblies
    inflatablePCAaction(:,i+1) = inflatablePCA.tick(inflatablePCAaction(:,i));
%     inflatable2PCAaction(:,i+1) = inflatable2PCA.tick(inflatable2PCAaction(:,i));
    livingUnitPCAaction(:,i+1) = livingUnitPCA.tick(livingUnitPCAaction(:,i));
%     livingUnit2PCAaction(:,i+1) = livingUnit2PCA.tick(livingUnit2PCAaction(:,i));
    lifeSupportUnitPCAaction(:,i+1) = lifeSupportUnitPCA.tick(lifeSupportUnitPCAaction(:,i));
%     lifeSupportUnit2PCAaction(:,i+1) = lifeSupportUnit2PCA.tick(lifeSupportUnit2PCAaction(:,i));
    cargoUnitPPRVaction(:,i+1) = cargoUnitPPRV.tick(cargoUnitPPRVaction(:,i));
%     cargoUnit2PPRVaction(:,i+1) = cargoUnit2PPRV.tick(cargoUnit2PPRVaction(:,i));
    airlockPCAaction(:,i+1) = airlockPCA.tick(airlockPCAaction(:,i));

    % Common Cabin Air Assemblies
    inflatableCCAAoutput(i) = inflatableCCAA.tick;
    livingUnitCCAAoutput(i) = livingUnitCCAA.tick;
    lifeSupportUnitCCAAoutput(i) = lifeSupportUnitCCAA.tick;
    
%     inflatable2CCAAoutput(i) = inflatable2CCAA.tick;
%     livingUnit2CCAAoutput(i) = livingUnit2CCAA.tick;
%     lifeSupportUnit2CCAAoutput(i) = lifeSupportUnit2CCAA.tick;
    
    % Condensed Water Remover
%     condensedWaterRemoved(i) = inflatable1WaterExtractor.tick;
    
    % Run Waste Processing ECLSS Hardware
    co2removed(i) = mainvccr.tick;
    crsH2OProduced(i) = crs.tick;
    crsCompressorOperation(:,i) = crs.CompressorOperation;
    co2accumulatorlevel(i) = crs.CO2Accumulator.currentLevel;
    waterRS.tick;
    
    %% Food Production System
    cropwaterstorelevel(i) = CropWaterStore.currentLevel;
     
    if CropWaterStore.currentLevel <= 0
        disp(['Crop Water Store is empty at tick: ',num2str(i)])
        break
    end
    
    % ISRU inject water into CropWaterStore (0.565L/hr)
%     CropWaterStore.add(0.565);
    
    % Record shelf water levels
    whitePotatoShelfWaterLevel(i) = WhitePotatoShelf.ShelfWaterLevel;
    peanutShelfWaterLevel(i) = PeanutShelf.ShelfWaterLevel;
    soybeanShelfWaterLevel(i) = SoybeanShelf.ShelfWaterLevel;
    sweetPotatoShelfWaterLevel(i) = SweetPotatoShelf.ShelfWaterLevel;
    wheatShelfWaterLevel(i) = WheatShelf.ShelfWaterLevel;

    % Tick Crop Shelves
    %% add co2 injector here
    co2injected(i) = co2Injector.tick;
    WhitePotatoShelves.tick;
%     WhitePotatoShelf.tick;
%     co2Injector.tick;
    PeanutShelves.tick;
%     PeanutShelf.tick;
%     co2Injector.tick;
    SoybeanShelves.tick;
%     SoybeanShelf.tick;
%     co2Injector.tick;
    SweetPotatoShelves.tick;
%     SweetPotatoShelf.tick;
%     co2Injector.tick;
    WheatShelves.tick;
%     WheatShelf.tick;
    
    FoodProcessor.tick;
    carriedfoodstorelevel(i) = CarriedFoodStore.currentLevel;
    grownfoodstorelevel(i) = LocallyGrownFoodStore.currentLevel;
    if LocallyGrownFoodStore.currentLevel > 0       
        dryfoodlevel(i) = sum(cell2mat({LocallyGrownFoodStore.foodItems.Mass})-cell2mat({LocallyGrownFoodStore.foodItems.WaterContent}));
        caloriccontent(i) = sum([LocallyGrownFoodStore.foodItems.CaloricContent]);
    end    
    
    %% Tick Crew
    astro1.tick;
    astro2.tick;  
    astro3.tick;
    astro4.tick;
   
    %% Run ISRU
%     PotableWaterStore.add(isruAddedWater);
%     CropWaterStore.add(isruAddedCropWater);
% %     O2Store.add(isruAddedO2);
%     N2Store.add(isruAddedN2);
    
    %% EVA
    CrewEVAstatus = [strcmpi(astro1.CurrentActivity.Name,'EVA'),...
        strcmpi(astro2.CurrentActivity.Name,'EVA'),...
        strcmpi(astro3.CurrentActivity.Name,'EVA'),...
        strcmpi(astro4.CurrentActivity.Name,'EVA')];
    
    % Regenerate METOX canisters if required
    % Add CO2 removed from METOX canister to Airlock
    if strcmpi(EMUco2RemovalTechnology,'METOX')
        Airlock.CO2Store.add(METOXregeneratorLoad.take(metoxCO2regenRate));
    end
    
    % if any astro has a current activity that is EVA
    if sum(CrewEVAstatus) > 0
        % identify first crewmember
        hoursOnEVA(i) = hoursOnEVA(i-1)+1;
        if hoursOnEVA(i) == 1
            % Store EVA status
            currentEVAcrew = CrewEVAstatus;

            % Error
            if O2Store.currentLevel < prebreatheO2
                disp(['Insufficient O2 for crew EVA prebreathe or EMU suit fill at tick: ',num2str(i)])
                disp('Current EVA has been skipped')
                % Advance activities for all astronauts
                astro1.skipActivity;
                astro2.skipActivity;
                astro3.skipActivity;
                astro4.skipActivity;
                continue
            end
            
            % perform airlock ops
            % purge and fill EVA suits with O2 from O2Store 
            EVAsuitfill = EVAenvironment.O2Store.add(O2Store.take(prebreatheO2));              % Fill two EMUs with 100% O2
            reservoirFillLevel(i) = EMUfeedwaterReservoir.fill(PotableWaterStore);                                      % fill feedwater tanks
            EMUo2Tanks.fill(O2Store);                                                           % fill PLSS O2 tanks
            
            % Vent lost airlock gases
            airlockGasVented = Airlock.vent(airlockCycleLoss);
            
        elseif hoursOnEVA(i) == 8      % end of EVA
            % Empty EMU and add residual gases within EMU to Airlock
            EVAenvironment.O2Store.currentLevel = 0;
            EVAenvironment.CO2Store.currentLevel = 0;
            EVAenvironment.VaporStore.currentLevel = 0;
            
            Airlock.O2Store.add(finalEMUo2level);
            Airlock.CO2Store.add(finalEMUco2level);
            Airlock.VaporStore.add(finalEMUvaporlevel);
            
            % Define PLSS Store levels
            EMUfeedwaterReservoir.currentLevel = finalFeedwaterTanklevel;
            EMUo2Tanks.currentLevel = plssO2TankLevel;       
            
            % For METOX case, add PLSS removed CO2 back to Airlock 
            % (equivalent to METOX oven baking) 
            if strcmpi(EMUco2RemovalTechnology,'METOX')
                METOXregeneratorLoad.add(totalCO2removed);
            end
            
            % For humidity condensate: for RCA, the loss is captured in 
            % finalEMUvaporlevel, while for the METOX, all humidity
            % condensate is sitting within the feedwater tank
        end
    end
    % If the crew is no longer on EVA, reset hoursOnEVA
    if ~isequal(CrewEVAstatus,currentEVAcrew)
        % if identified crewmember's current activity is not EVA
        hoursOnEVA(i) = 0;
    end
    
    %% Tick Waitbar
    if mod(i,100) == 0
        waitbar(i/simtime,h,['Current tick: ',num2str(i),' | Time Elapsed: ',num2str(round(toc)),'sec']);
    end

%     value(i) = hoursOnEVA;
end

toc

beep

close(h)

diary off

%% Random plot commands used in code validation exercise
% Atmospheric molar fractions
figure, 
subplot(2,2,1), plot(t,inflatableO2level(t)./inflatableTotalMoles,t,inflatableCO2level./inflatableTotalMoles,t,inflatableN2level./inflatableTotalMoles,t,inflatableVaporlevel./inflatableTotalMoles,t,inflatableOtherlevel./inflatableTotalMoles,'LineWidth',2), title('Inflatable 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
subplot(2,2,2), plot(t,livingUnitO2level(t)./livingUnitTotalMoles,t,livingUnitCO2level./livingUnitTotalMoles,t,livingUnitN2level./livingUnitTotalMoles,t,livingUnitVaporlevel./livingUnitTotalMoles,t,livingUnitOtherlevel./livingUnitTotalMoles,'LineWidth',2), title('Living Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
subplot(2,2,3), plot(t,lifeSupportUnitO2level(t)./lifeSupportUnitTotalMoles,t,lifeSupportUnitCO2level./lifeSupportUnitTotalMoles,t,lifeSupportUnitN2level./lifeSupportUnitTotalMoles,t,lifeSupportUnitVaporlevel./lifeSupportUnitTotalMoles,t,lifeSupportUnitOtherlevel./lifeSupportUnitTotalMoles,'LineWidth',2), title('Life Support Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
subplot(2,2,4), plot(t,cargoUnitO2level(t)./cargoUnitTotalMoles(t),t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t),t,cargoUnitN2level(t)./cargoUnitTotalMoles(t),t,cargoUnitVaporlevel(t)./cargoUnitTotalMoles(t),t,cargoUnitOtherlevel(t)./cargoUnitTotalMoles(t),'LineWidth',2), title('Cargo Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
% subplot(3,3,5), plot(t,inflatable2O2level(t)./inflatable2TotalMoles,t,inflatable2CO2level./inflatable2TotalMoles,t,inflatable2N2level./inflatable2TotalMoles,t,inflatable2Vaporlevel./inflatable2TotalMoles,t,inflatable2Otherlevel./inflatable2TotalMoles,'LineWidth',2), title('Inflatable 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
% subplot(3,3,6), plot(t,livingUnit2O2level(t)./livingUnit2TotalMoles,t,livingUnit2CO2level./livingUnit2TotalMoles,t,livingUnit2N2level./livingUnit2TotalMoles,t,livingUnit2Vaporlevel./livingUnit2TotalMoles,t,livingUnit2Otherlevel./livingUnit2TotalMoles,'LineWidth',2), title('Living Unit 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
% subplot(3,3,7), plot(t,lifeSupportUnit2O2level(t)./lifeSupportUnit2TotalMoles,t,lifeSupportUnit2CO2level./lifeSupportUnit2TotalMoles,t,lifeSupportUnit2N2level./lifeSupportUnit2TotalMoles,t,lifeSupportUnit2Vaporlevel./lifeSupportUnit2TotalMoles,t,lifeSupportUnit2Otherlevel./lifeSupportUnit2TotalMoles,'LineWidth',2), title('Life Support Unit 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
% subplot(3,3,8), plot(t,cargoUnit2O2level(t)./cargoUnit2TotalMoles(t),t,cargoUnit2CO2level(t)./cargoUnit2TotalMoles(t),t,cargoUnit2N2level(t)./cargoUnit2TotalMoles(t),t,cargoUnit2Vaporlevel(t)./cargoUnit2TotalMoles(t),t,cargoUnit2Otherlevel(t)./cargoUnit2TotalMoles(t),'LineWidth',2), title('Cargo Unit 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')
% subplot(3,3,9), plot(t,airlockO2level(t)./airlockTotalMoles,t,airlockCO2level./airlockTotalMoles,t,airlockN2level./airlockTotalMoles,t,airlockVaporlevel./airlockTotalMoles,t,airlockOtherlevel./airlockTotalMoles,'LineWidth',2), title('Airlock'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Molar Fraction')

% Partial Pressures
figure, 
subplot(2,2,1), plot(t,inflatableO2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),t,inflatableCO2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),t,inflatableN2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),t,inflatableVaporlevel(t)./inflatableTotalMoles(t).*inflatablePressure(t),t,inflatableOtherlevel(t)./inflatableTotalMoles(t).*inflatablePressure(t),'LineWidth',2), title('Inflatable 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
subplot(2,2,2), plot(t,livingUnitO2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),t,livingUnitCO2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),t,livingUnitN2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),t,livingUnitVaporlevel(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),t,livingUnitOtherlevel(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitO2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),t,lifeSupportUnitCO2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),t,lifeSupportUnitN2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),t,lifeSupportUnitVaporlevel(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),t,lifeSupportUnitOtherlevel(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
subplot(2,2,4), plot(t,cargoUnitO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitN2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitVaporlevel(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitOtherlevel(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
% subplot(3,3,5), plot(t,inflatable2O2level(t)./inflatable2TotalMoles(t).*inflatable2Pressure(t),t,inflatable2CO2level(t)./inflatable2TotalMoles(t).*inflatable2Pressure(t),t,inflatable2N2level(t)./inflatable2TotalMoles(t).*inflatable2Pressure(t),t,inflatable2Vaporlevel(t)./inflatable2TotalMoles(t).*inflatable2Pressure(t),t,inflatable2Otherlevel(t)./inflatable2TotalMoles(t).*inflatable2Pressure(t),'LineWidth',2), title('Inflatable 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
% subplot(3,3,6), plot(t,livingUnit2O2level(t)./livingUnit2TotalMoles(t).*livingUnit2Pressure(t),t,livingUnit2CO2level(t)./livingUnit2TotalMoles(t).*livingUnit2Pressure(t),t,livingUnit2N2level(t)./livingUnit2TotalMoles(t).*livingUnit2Pressure(t),t,livingUnit2Vaporlevel(t)./livingUnit2TotalMoles(t).*livingUnit2Pressure(t),t,livingUnit2Otherlevel(t)./livingUnit2TotalMoles(t).*livingUnit2Pressure(t),'LineWidth',2), title('Living Unit 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
% subplot(3,3,7), plot(t,lifeSupportUnit2O2level(t)./lifeSupportUnit2TotalMoles(t).*lifeSupportUnit2Pressure(t),t,lifeSupportUnit2CO2level(t)./lifeSupportUnit2TotalMoles(t).*lifeSupportUnit2Pressure(t),t,lifeSupportUnit2N2level(t)./lifeSupportUnit2TotalMoles(t).*lifeSupportUnit2Pressure(t),t,lifeSupportUnit2Vaporlevel(t)./lifeSupportUnit2TotalMoles(t).*lifeSupportUnit2Pressure(t),t,lifeSupportUnit2Otherlevel(t)./lifeSupportUnit2TotalMoles(t).*lifeSupportUnit2Pressure(t),'LineWidth',2), title('Life Support Unit 2'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
% subplot(3,3,8), plot(t,cargoUnit2O2level(t)./cargoUnit2TotalMoles(t).*cargoUnit2Pressure(t),t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitN2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitVaporlevel(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),t,cargoUnitOtherlevel(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')
% subplot(3,3,9), plot(t,airlockO2level(t)./airlockTotalMoles(t).*airlockPressure(t),t,airlockCO2level./airlockTotalMoles.*airlockPressure(t),t,airlockN2level(t)./airlockTotalMoles(t).*airlockPressure(t),t,airlockVaporlevel(t)./airlockTotalMoles(t).*airlockPressure(t),t,airlockOtherlevel(t)./airlockTotalMoles(t).*airlockPressure(t),'LineWidth',2), title('Airlock'),legend('O2','CO2','N2','Vapor','Other'), grid on, xlabel('Time (hours)'), ylabel('Partial Pressure')

t = 1:(length(o2storelevel));

% Airlock ppCO2
figure, plot(t,airlockCO2level./airlockTotalMoles.*airlockPressure,'LineWidth',2),grid on, title('Airlock ppCO2')

% O2 molar fraction 
figure, 
subplot(2,2,1), plot(t,inflatableO2level(t)./inflatableTotalMoles(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Molar Fraction')
subplot(2,2,2), plot(t,livingUnitO2level(t)./livingUnitTotalMoles(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Molar Fraction')
subplot(2,2,3), plot(t,lifeSupportUnitO2level(t)./lifeSupportUnitTotalMoles(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Molar Fraction')
subplot(2,2,4), plot(t,cargoUnitO2level(t)./cargoUnitTotalMoles(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Molar Fraction')

% O2 Partial Pressure
figure, 
subplot(2,2,1), plot(t,inflatableO2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Partial Pressure')
subplot(2,2,2), plot(t,livingUnitO2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Partial Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitO2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Partial Pressure')
subplot(2,2,4), plot(t,cargoUnitO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('O2 Partial Pressure')


% CO2 molar fraction (ppm)
figure, 
subplot(2,2,1), plot(t,inflatableCO2level(t)./inflatableTotalMoles(t)*1E6,'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Molar Fraction')
subplot(2,2,2), plot(t,livingUnitCO2level(t)./livingUnitTotalMoles(t)*1E6,'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Molar Fraction')
subplot(2,2,3), plot(t,lifeSupportUnitCO2level(t)./lifeSupportUnitTotalMoles(t)*1E6,'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Molar Fraction')
subplot(2,2,4), plot(t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t)*1E6,'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Molar Fraction')

% CO2 Partial Pressure
figure, 
subplot(2,2,1), plot(t,inflatableCO2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Partial Pressure')
subplot(2,2,2), plot(t,livingUnitCO2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Partial Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitCO2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Partial Pressure')
subplot(2,2,4), plot(t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Partial Pressure')

subplot(2,2,3),line([1 length(t)],0.482633011*ones(1,2),'LineWidth',2,'Color','r')

figure, 
plot(t,cargoUnitCO2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',1), 
title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('CO2 Partial Pressure')
line([1 length(t)],0.482633011*ones(1,2),'LineWidth',2,'Color','r')

% N2 Partial Pressure
figure, 
subplot(2,2,1), plot(t,inflatableN2level(t)./inflatableTotalMoles(t).*inflatablePressure(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('N2 Partial Pressure')
subplot(2,2,2), plot(t,livingUnitN2level(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('N2 Partial Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitN2level(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('N2 Partial Pressure')
subplot(2,2,4), plot(t,cargoUnitN2level(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('N2 Partial Pressure')

% Vapor Partial Pressure
figure, 
subplot(2,2,1), plot(t,inflatableVaporlevel(t)./inflatableTotalMoles(t).*inflatablePressure(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('Vapor Partial Pressure')
subplot(2,2,2), plot(t,livingUnitVaporlevel(t)./livingUnitTotalMoles(t).*livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Vapor Partial Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitVaporlevel(t)./lifeSupportUnitTotalMoles(t).*lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Vapor Partial Pressure')
subplot(2,2,4), plot(t,cargoUnitVaporlevel(t)./cargoUnitTotalMoles(t).*cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Vapor Partial Pressure')

% Total Pressure
figure, 
subplot(2,2,1), plot(t,inflatablePressure(t),'LineWidth',2), title('Inflatable 1'), grid on, xlabel('Time (hours)'), ylabel('Total Pressure')
subplot(2,2,2), plot(t,livingUnitPressure(t),'LineWidth',2), title('Living Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Total Pressure')
subplot(2,2,3), plot(t,lifeSupportUnitPressure(t),'LineWidth',2), title('Life Support Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Total Pressure')
subplot(2,2,4), plot(t,cargoUnitPressure(t),'LineWidth',2), title('Cargo Unit 1'), grid on, xlabel('Time (hours)'), ylabel('Total Pressure')

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
