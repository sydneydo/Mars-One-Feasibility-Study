%% EVAtick

% During model setup
UrineManagement.type = 'UCTA' || 'MAG';

if strcmpi(UrineManagement.type,'UCTA')
    EVAenvironment.DirtyWaterStore = DirtyWaterStore;     % dump urine to dirty water store for processing by UPA
elseif strcmpi(UrineManagement.type,'MAG')
    EVAenvironment.DirtyWaterStore = StoreImpl('Urine Dumped','Environmental');     % dump urine overboard
end


EVAenvironment = SimEnvironmentImpl('EVA Environment',EMUpressure,O2Store||CO2Store,1,0,0,0,0,EMUleakPercentage,PotableWaterStore,...
    EMUfeedwaterReservoir,DirtyWaterStore,DryWasteStore,CarriedFoodStore);





%% During execution

% Don't tick EVA environment
% EVAenvironment.tick;        % Leak the EMU as you would normally

% 1. Fill feedwater tank

CO2removal.type = 'METOX' || 'RCA';

% load values from a .mat file


% Determine amount of atmospheric constituents remaining within each EMU
% after EVA

% We skip breathing in CrewPersonImpl if current activity is breathing -
% this is then captured by the remaining elements within the EMUs

if strcmpi(CO2removal.type,'METOX')
    finalEMUo2level = 0.662983240111286;
    finalEMUco2level = 0.004364102772051;
    finalFeedwaterTanklevel = 0.925892853496746;    % also corresponds to total humidity level consumed, this captures any thermal control leakage
    plssO2TankLevel = 8.011314797554896;        % set corresponding StoreImpl.currentLevel to this value
    totalCO2removed = 7.781437800427120;
elseif strcmpi(CO2removal.type,'RCA')
    finalEMUo2level = 0.660784844570202;
    finalEMUco2level = 0.006562498313135;
    finalFeedwaterTanklevel = 2.852763554861143;
    plssO2TankLevel = 8.044150559539300;        % set corresponding StoreImpl.currentLevel to this value
    totalCO2removed = 7.752795753051560;
end
finalEMUvaporlevel = 0.013491183419516;

% Add these amounts to the airlock
Airlock.O2Store.add(finalEMUo2level);
Airlock.CO2Store.add(finalEMUco2level);
Airlock.VaporStore.add(finalEMUvaporlevel);

% Potable water - crew consumes as usual from potable water store

% Account for removed CO2 and humidity condensate

