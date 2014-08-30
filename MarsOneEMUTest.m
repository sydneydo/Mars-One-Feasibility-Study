%% EMU Test
% Code to test the EMU function
%   By: Sydney Do (sydneydo@mit.edu)
%   Date Created: 8/29/2014
%   Last Updated: 8/29/2014

%% Habitat Stores
% Dirty water corresponds to Humidity Condensate and Urine 
DirtyWaterStore = StoreImpl('Dirty H2O','Material',18/2.2*1.1,0);        % Corresponds to the UPA waste water tank - 18lb capacity (we increase volume by 10% to avoid loss of dirty water when running UPA in batch mode)

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
EMUleakPercentage = EMUleakmoles*numberOfEVAcrew/EMUtotalMoles;

 
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

EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,EMUvolume,1,0,0,0,0,EMUleakPercentage,EMUdrinkbagVolume,EMUfeedwaterReservoir,DirtyWaterStore,DryWasteStore,CarriedFoodStore);

EMUo2TankCapacity = 1.217*453.592/O2molarMass;      % moles, Converted from 1.217lbs - REF: Section 2.1.3 EMU Handbook
EMUo2Tanks = StoreImpl('EMU O2 Bottles','Material',EMUo2TankCapacity*numberOfEVAcrew,EMUo2TankCapacity*numberOfEVAcrew);

% EMU PCA
EMUPCA = ISSinjectorImpl(EMUpressure,1,EMUo2Tanks,[],EVAenvironment,'EMU');