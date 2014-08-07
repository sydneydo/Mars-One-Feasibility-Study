classdef ISSinjectorImpl < handle
    %ISSinjectorImpl Summary of this class goes here
    %   By: Sydney Do (sydneydo@mit.edu)
    %   Date Created: 8/5/2014
    %   Last Updated: 8/5/2014
    %   This is the same implementation as that of the AccumulatorImpl
    %   In BioSim, both InjectorImpl and AccumulatorImpl reference a parent
    %   class called ResourceMover
    %   Comments within the InjectorImpl class code provide the following
    %   description:
    %   * The basic Accumulator Implementation. Can be configured to take any modules
    %   * as input, and any modules as output. It takes as much as it can (max taken
    %   * set by maxFlowRates) from one module and pushes it into another module.
    %   * Functionally equivalent to an Accumulator at this point.
    
    %   File modified from BioSim injector class on 8/5/2014
    
    %   The PCA vents air, rather than individual atmospheric constituents
    %   As a result, we model this class as a PCA, rather than an injector
    
    %   This code focuses on maintaining O2 partial pressure and total
    %   pressure
    %   We adjust O2 partial pressure first, then total pressure
    
    
    properties
        %         Gas         % Gas species (either N2 or O2)
        TargetTotalPressure      % Target absolute pressure to be maintained within cabin
        TargetO2PartialPressure        % Target O2 partial pressure for PCA (in kPa)
        TargetO2MolarFraction         % Target O2 molar fraction
        O2Vented = 0            % Total amount of O2 vented (in moles)
        CO2Vented = 0           % Total amount of CO2 vented (in moles)
        N2Vented = 0            % Total amount of N2 vented (in moles)
        VaporVented = 0         % Total amount of Water Vapor vented (in moles)
        OtherGasesVented = 0    % Total amount of Other Gases vented (in moles)
        O2Source    % Source of O2 Make Up Gas
        N2Source    % Source of N2 Make Up Gas
        Environment  % Environment whose atmosphere is being monitored and controlled
    end
    
    properties (SetAccess = private)
        UpperPPO2PercentageLimit = 0.3;     % PPO2 can reach 30% (flammability limit) for 70.3kPa/26.5% O2 atmospheres (REF: Section 5.1 EAWG)
        PartialPressureBoundingBox = 1.37895146     % in kPa (converted from 0.2psia), extent of control box around which
        VentPortDiameter = 0.056         % in meters (vent port diameter of Vent Relief Valve of the ISS PCA, REF: pg 89, Living Together in Space)
        MarsMeanAtmPressure = 6.36*0.1   % in kPa, Mean atmospheric pressure at Mars surface (REF: http://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html)
        MarsMeanAtmDensity = 0.02        % in kg/m^3, Mean atmospheric density at Mars surface (REF: http://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html)
        idealGasConstant = 8.314;        % J/K/mol
        O2molarMass = 2*15.999;          % g/mol
        CO2molarMass = 12.011+2*15.999;   % g/mol
        N2molarMass = 2*14.007           % g/mol
        VapormolarMass = 2*1.008+15.999; % g/mol
        OthermolarMass =  0.265*2*15.999 + (1-0.265)*2*14.007;	% g/mol (assuming that it is equal to the average molecular mass of the ideal 70.3kPa/26.5% O2 mixture
    end
    
    
    methods
        %% Constructor
        function obj = ISSinjectorImpl(targetTotalPressure,targetO2molarFraction,O2source,N2source,environment)
            
            if nargin > 0
                if ~(strcmpi(class(O2source),'StoreImpl') || strcmpi(class(N2source),'StoreImpl'))
                    error('Third and Fourth Input arguments must be of type "StoreImpl"')
                end
                
                %                 obj.Gas = GasType;
                obj.TargetTotalPressure = targetTotalPressure;
                obj.TargetO2MolarFraction = targetO2molarFraction;
                obj.TargetO2PartialPressure = targetO2molarFraction*targetTotalPressure;
                
                limitingFlowRateInKg = 0.09*60;     % Limiting Flow Rate of ISS Pressure Control Assembly is 0.09kg/min (REF: pg 92, Living Together in Space)
                
                %                 % Determine molar mass
                %                 if strcmpi(GasType,'O2')
                %                     molarMass = 2*15.999;
                %                 elseif strcmpi(GasType,'N2')
                %                     molarMass = 2*14.007;
                %                 else
                %                     error('Gas Type must be set to either "O2" or "N2"')
                %                 end
                
                O2molarmass = 2*15.999;
                N2molarmass = 2*14.007;
                
                O2limitingFlowRateInMoles = limitingFlowRateInKg*1E3/O2molarmass;
                N2limitingFlowRateInMoles = limitingFlowRateInKg*1E3/N2molarmass;
                
                obj.O2Source = ResourceUseDefinitionImpl(O2source,O2limitingFlowRateInMoles,O2limitingFlowRateInMoles);
                obj.N2Source = ResourceUseDefinitionImpl(N2source,N2limitingFlowRateInMoles,N2limitingFlowRateInMoles);
                %                 obj.Environment = ResourceUseDefinitionImpl(environment,limitingFlowRateInMoles,limitingFlowRateInMoles);
                obj.Environment = environment;
                
            end
        end
        
        %% tick
        function action = tick(obj,previousAction)
            
            % Need to build memory of previous timestep to allow for consecutive
            % actions to be performed to bring the atmospheric conditions back to a
            % desired state - we introduce the variable previousAction to account for
            % this - this is a 4x1 column vector, carrying the same information as the
            % "action" variable, but taken from the previous timestep
            
            % Variable tracking actions taken
            action = zeros(4,1);
            
            %% Implement power consumption for each if statement!
                       
            %% Nominal PCA checks
            
            %% Check for O2 Flammability Limit
            % If ppO2 is above flammability limit, add N2 to bring ppO2
            % to target value (since we can't selectively vent O2)
            if obj.Environment.O2Percentage > obj.UpperPPO2PercentageLimit     % if currentPPO2 is > upper bound of ppO2 bounding box, vent gas
                n2MolesToIntroduce = obj.Environment.O2Store.currentLevel/obj.TargetO2MolarFraction - obj.Environment.totalMoles; % Total N2 moles needed to be introduced to bring O2 molar percentage to desired value
                makeupN2taken = obj.N2Source.ResourceStore.take(n2MolesToIntroduce,obj.N2Source);     % Take required makeup N2 amount from N2 Source
                obj.Environment.NitrogenStore.add(makeupN2taken);         % add take makeup N2 to environment

                action(1) = 1;      % Record action taken
                
            end
            
            %% Check for overpressure
            % Vent if total pressure is greater than target pressure +
            % bounding box
            if obj.Environment.pressure > (obj.TargetTotalPressure + obj.PartialPressureBoundingBox)
                currentTargetTotalMoles = obj.TargetTotalPressure * obj.Environment.volume / (obj.idealGasConstant*(obj.Environment.temperature+273.15));   % No. of moles corresopnding to target absolute pressure
                airToVent = obj.Environment.totalMoles - currentTargetTotalMoles;
                
                % Calculate current maximum vent rate based on pressure
                % difference between cabin and Martian environment
                currentAverageDensity = (obj.Environment.O2Store.currentLevel*obj.O2molarMass + obj.Environment.CO2Store.currentLevel*obj.CO2molarMass...
                    + obj.Environment.NitrogenStore.currentLevel*obj.N2molarMass + obj.Environment.VaporStore.currentLevel*obj.VapormolarMass...
                    + obj.Environment.OtherStore.currentLevel*obj.OthermolarMass) / obj.Environment.volume;        % Density in g/L = kg/m^3
                
                currentMaxVentRate = sqrt(2*(obj.Environment.pressure - obj.MarsMeanAtmPressure)*1E3/currentAverageDensity);    % in meters per second (m/s)
                currentVolumetricFlowRate = currentMaxVentRate*pi*obj.VentPortDiameter^2/4*3600;      % in m^3/hr (hence the *3600 factor)
                maxVentRate = obj.Environment.pressure*currentVolumetricFlowRate*1E3/(obj.idealGasConstant*(obj.Environment.temperature+273.15));       % maximum venting rate in moles/hr
                
                finalAmountVented = min([airToVent,maxVentRate]);   % Final amount that can be vented is the minimum of the maximum possible vent rate, and the desired amount of air to vent
                
                currentO2percentage = obj.Environment.O2Percentage;
                currentCO2percentage = obj.Environment.CO2Percentage;
                currentN2percentage = obj.Environment.N2Percentage;
                currentVaporpercentage = obj.Environment.VaporPercentage;
                currentOtherpercentage = obj.Environment.OtherPercentage;
                
                % Take corresponding airToVent from Environment atmosphere
                O2ToVent = obj.Environment.O2Store.take(currentO2percentage*finalAmountVented);
                CO2ToVent = obj.Environment.CO2Store.take(currentCO2percentage*finalAmountVented);
                N2ToVent = obj.Environment.NitrogenStore.take(currentN2percentage*finalAmountVented);
                VaporToVent = obj.Environment.VaporStore.take(currentVaporpercentage*finalAmountVented);
                OtherToVent = obj.Environment.OtherStore.take(currentOtherpercentage*finalAmountVented);
                
                % Update object properties
                obj.O2Vented = obj.O2Vented + O2ToVent;
                obj.CO2Vented = obj.CO2Vented + CO2ToVent;
                obj.N2Vented = obj.N2Vented + N2ToVent;
                obj.VaporVented = obj.VaporVented + VaporToVent;
                obj.OtherGasesVented = obj.OtherGasesVented + OtherToVent;
                
                action(2) = 1;      % Record action taken
                
            end
                        
            %% Check to see if current O2 partial pressure is within desired
            % range
            
            % This if statement corresponds to a continuation from the
            % previous timestep was activated. This is necessary because
            % the flow rate of O2 introdcued into the cabin is limited by
            % the PCA hardware. Once the ppO2 is brought within the desired
            % range, it takes two activations of the PCA to bring ppO2 to
            % the desired set pressure
            if previousAction(3) == 1
                % Note that we now ignore the bounding box as we
                % are trying to bring the pressure back to a
                % nominal state
                if (obj.Environment.pressure*obj.Environment.O2Percentage) < obj.TargetO2PartialPressure    % in kPa
                    currentTargetO2Moles = obj.TargetO2PartialPressure * obj.Environment.volume / (obj.idealGasConstant*(obj.Environment.temperature+273.15));      % Number of moles corresponding to desired ppO2
                    makeupO2MolesRequired = currentTargetO2Moles - obj.Environment.O2Store.currentLevel;       % Determine makeup O2 required (in moles)
                    makeupO2taken = obj.O2Source.ResourceStore.take(makeupO2MolesRequired,obj.O2Source);     % Take required makeup O2 amount from O2 Source
                    obj.Environment.O2Store.add(makeupO2taken);         % add take makeup O2 to environment
                end
            end
            
            % Check to see if ppO2 is within desired bounding box
            if (obj.Environment.pressure*obj.Environment.O2Percentage) < (obj.TargetO2PartialPressure - obj.PartialPressureBoundingBox)     % in kPa
                currentTargetO2Moles = obj.TargetO2PartialPressure * obj.Environment.volume / (obj.idealGasConstant*(obj.Environment.temperature+273.15));      % Number of moles corresponding to desired ppO2
                makeupO2MolesRequired = currentTargetO2Moles - obj.Environment.O2Store.currentLevel;       % Determine makeup O2 required (in moles)
                makeupO2taken = obj.O2Source.ResourceStore.take(makeupO2MolesRequired,obj.O2Source);     % Take required makeup O2 amount from O2 Source
                obj.Environment.O2Store.add(makeupO2taken);         % add take makeup O2 to environment
                
                action(3) = 1;      % Record action taken
                
            end
                
            %% Check for under pressure condition - add N2 to bring total pressure back to desired value
            % This is the last step given that O2 values have been modified
            % prior to this
            
            % Check for influence of previous actions - to command PCA to drive atmospheric constituents back to a constant state
            if previousAction(4) == 1
                % Note that we now ignore the bounding box as we
                % are trying to bring the pressure back to a
                % nominal state
                if obj.Environment.pressure < obj.TargetTotalPressure
                    targetTotalMoles = obj.TargetTotalPressure * obj.Environment.volume / (obj.idealGasConstant*(obj.Environment.temperature+273.15));      % Number of moles corresponding to desired total pressure
                    makeupN2MolesRequired = targetTotalMoles - obj.Environment.totalMoles;       % Determine makeup N2 required (in moles)
                    makeupN2taken = obj.N2Source.ResourceStore.take(makeupN2MolesRequired,obj.N2Source);     % Take required makeup N2 amount from N2 Source
                    obj.Environment.NitrogenStore.add(makeupN2taken);         % add take makeup N2 to environment
                end
                
            end
            
            % Check to see if total pressure is within desired bounding box
            if obj.Environment.pressure < (obj.TargetTotalPressure - obj.PartialPressureBoundingBox)
                targetTotalMoles = obj.TargetTotalPressure * obj.Environment.volume / (obj.idealGasConstant*(obj.Environment.temperature+273.15));      % Number of moles corresponding to desired total pressure
                makeupN2MolesRequired = targetTotalMoles - obj.Environment.totalMoles;       % Determine makeup N2 required (in moles)
                makeupN2taken = obj.N2Source.ResourceStore.take(makeupN2MolesRequired,obj.N2Source);     % Take required makeup N2 amount from N2 Source
                obj.Environment.NitrogenStore.add(makeupN2taken);         % add take makeup N2 to environment
                
                action(4) = 1;      % Record action taken
                
            end
            
        end
        
    end
    
    
    
end

