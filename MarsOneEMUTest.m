%% EMU Test
% Code to test the EMU function
%   By: Sydney Do (sydneydo@mit.edu)
%   Date Created: 8/29/2014
%   Last Updated: 8/29/2014

clear all
clc

%% Initialize Habitat Stores
% Potable Water Store within Life Support Units (note water store capacity
% measured in liters)
PotableWaterStore = StoreImpl('Potable H2O','Material',1500,1500);      % 1500L Potable Water Store Capacity according to: http://www.mars-one.com/faq/health-and-ethics/will-the-astronauts-have-enough-water-food-and-oxygen#sthash.aCFnUUFk.dpuf
% PotableWaterStore = StoreImpl('Potable H2O','Material',56.7,56.7);      %
% WPA Product Water tank has a capacity of 56.7L (ref: SAE 2008-01-2007).
% Note that on ISS, the WPA Product Water Tank feeds the Potable Water
% Dispenser, the OGA, and the WHC flush and hygiene hose

% O2 Store within Life Support Units (note O2 capacity measured in moles)
initialO2TankCapacityInKg = 100.2;      % Calculated initial O2 tank capacity based on support crew for 60 days, note that another source on the Mars One webpage suggests a 60kg initial capacity for each living unit tank <http://www.mars-one.com/mission/roadmap/2023>
o2MolarMass = 2*15.999; % g/mol
initialO2StoreMoles = initialO2TankCapacityInKg*1E3/o2MolarMass;
O2Store = StoreImpl('O2 Store','Material',initialO2StoreMoles,initialO2StoreMoles);

% Dirty water corresponds to Humidity Condensate and Urine 
DirtyWaterStore = StoreImpl('Dirty H2O','Material',18/2.2*1.1,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

% Grey water corresponds to wash water - it is included for the purposes of
% modeling a biological water processor
GreyWaterStore = StoreImpl('Grey H2O','Material',100/2.2,0);
% Note that WPA waste water tank has a 100lb capacity, but is nominally
% operated at 65lb capacity
% Lab Condensate tank has a working capacity of 45.5L

% Waste Stores
DryWasteStore = StoreImpl('Dry Waste','Material',1000000,0);    % Currently waste is discarded via logistics resupply vehicles on ISS

% Food Store
xmlFoodStoreLevel = 10000;
xmlFoodStoreCapacity = 10000;
defaultFoodWaterContent = 5;
% initialfood = FoodMatter(Wheat,CarriedTotalMass,CarriedFood.EdibleFreshBasisWaterContent*CarriedTotalMass); % xmlFoodStoreLevel is declared within the createFoodStore method within SimulationInitializer.java
initialfood = FoodMatter(Wheat,xmlFoodStoreLevel,defaultFoodWaterContent); 

CarriedFoodStore = FoodStoreImpl(xmlFoodStoreCapacity,initialfood);

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
EMUleakPercentage = EMUleakmoles*numberOfEVAcrew/EMUtotalMoles*100;     % multiplied by 100 to make it a percent value

 
% Thermal control = {sublimator,radiator,cryogenic} = water usage = [0.57kg/hr,0.19kg/h,0]      REF:
% BVAD Section 5.2.2
% Note: Cryogenic cooling refers to cryogenic storage of O2
% O2 use: metabolic + leakage - 0.076kg/h, Note: O2 leakage alone is
% 0.005kg/h - REF BVAD Section 5.2.2 (compare this with EMU data)
% EVAco2removal = [METOX, Amine Swingbed]
% Amine Swingbed O2 loss rate is 0.15kg/h

% Liquid Metabolic Waste = [Collect, Vent]
% Collected urine can be sent to the UPA wastewater tank


EMUmetabolicWaste = StoreImpl('EVA MAG','Environmental');       % This is to replace the dirty water store if water is collected within the MAG
% Two options for liquid metabolic waste - either throw it away (as in the
% EMU MAG), or collect urine and feed it back into the UPA - as in Apollo
% EMU - find a reference for this!)

EMUdrinkbagVolume = 32*0.0295735;  % L, converted from 32 ounces (REF: Section 1.3.9 EMU Handbook)
EMUinsuitDrinkBag = StoreImpl('EMU Drink Bag','Material',EMUdrinkbagVolume*numberOfEVAcrew,0);

EMUfeedwaterCapacity = 10*0.453592;  % (L), converted from 10 pounds of water, assuming a water density of 1000kg/m^3 = 1kg/L, REF - Section 2.1.4 EMU Handbook
EMUfeedwaterReservoir = StoreImpl('PLSS Feedwater Reservoir','Material',EMUfeedwaterCapacity,0);

% EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,EMUvolume,1,0,0,0,0,EMUleakPercentage,EMUinsuitDrinkBag,EMUfeedwaterReservoir,DirtyWaterStore,DryWasteStore,CarriedFoodStore);
EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,EMUvolume,1,0,0,0,0,EMUleakPercentage,PotableWaterStore,EMUfeedwaterReservoir,DirtyWaterStore,DryWasteStore,CarriedFoodStore);

EMUo2TankCapacity = 1.217*453.592/O2molarMass;      % moles, Converted from 1.217lbs - REF: Section 2.1.3 EMU Handbook
EMUo2Tanks = StoreImpl('EMU O2 Bottles','Material',EMUo2TankCapacity*numberOfEVAcrew,EMUo2TankCapacity*numberOfEVAcrew);

%% Initialize CrewPerson
% Initialize activity
EVA = ActivityImpl('EVA',4,8,EVAenvironment);              % EVA - fixed length of 8 hours

% Initialize crew person
astro1 = CrewPersonImpl2('Male 1',35,75,'Male',EVA);
astro2 = CrewPersonImpl2('Female 1',35,55,'Female',EVA);

%% Initialize PLSS
emuPLSS = PLSS(EVAenvironment,'METOX');

% EMU PCA
EMUPCA = ISSinjectorImpl(EMUpressure,1,EMUo2Tanks,[],EVAenvironment,'EMU');
%% RUN

% On start of EVA 
% - charge EMUfeedwaterReservoir with potable water 
% - charge EMUo2Tanks from O2 tank
% - charge EMUinsuitDrinkBag with potable water
EMUfeedwaterReservoir.fill(PotableWaterStore);
EMUo2Tanks.fill(O2Store);
EMUinsuitDrinkBag.fill(PotableWaterStore);

% Initialize data arrays
simtime = 8;
t = 1:simtime;

o2storelevel = zeros(1,simtime);
potablewaterstorelevel = zeros(1,simtime);
dirtywaterstorelevel = zeros(1,simtime);
greywaterstorelevel = zeros(1,simtime);
drywastestorelevel = zeros(1,simtime);
foodstorelevel = zeros(1,simtime);

emuPressure = zeros(1,simtime);
emuO2level = zeros(1,simtime);
emuCO2level = zeros(1,simtime);
emuN2level = zeros(1,simtime);
emuVaporlevel = zeros(1,simtime);
emuOtherlevel = zeros(1,simtime);
emuTotalMoles = zeros(1,simtime);

co2removed = zeros(1,simtime);
emuPCAaction = zeros(4,simtime+1);

for i = 1:simtime
    if astro1.alive == 0 || astro2.alive == 0
        return
    end
    
    o2storelevel(i) = O2Store.currentLevel;
    potablewaterstorelevel(i) = PotableWaterStore.currentLevel;
    dirtywaterstorelevel(i) = DirtyWaterStore.currentLevel;
    greywaterstorelevel(i) = GreyWaterStore.currentLevel;
    drywastestorelevel(i) = DryWasteStore.currentLevel;
    foodstorelevel(i) = CarriedFoodStore.currentLevel;
    
    % Record EVA Environment Atmosphere
    emuPressure(i) = EVAenvironment.pressure;
    emuO2level(i) = EVAenvironment.O2Store.currentLevel;
    emuCO2level(i) = EVAenvironment.CO2Store.currentLevel;
    emuN2level(i) = EVAenvironment.NitrogenStore.currentLevel;
    emuVaporlevel(i) = EVAenvironment.VaporStore.currentLevel;
    emuOtherlevel(i) = EVAenvironment.OtherStore.currentLevel;
    emuTotalMoles(i) = EVAenvironment.totalMoles;
    
    %% Tick Modules
    
    % Leak Modules
    EVAenvironment.tick;
        
    % Tick Crew
    astro1.tick;
    
    % Run ECLSS Hardware
    co2removed(i) = emuPLSS.tick;
    emuPCAaction(:,i+1) = EMUPCA.tick(emuPCAaction(:,i));
    
    astro2.tick;  
    
end
    
% At the end of EVA
% - Empty EMU atmosphere into airlock
% - Depending on CO2 removal approach - dump CO2 into airlock