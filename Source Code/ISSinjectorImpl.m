classdef ISSinjectorImpl
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
    
    
    properties
        Gas         % Gas species (either N2 or O2)
        TargetPartialPressure       % Target partial pressure for PCA (in kPa)
        GasVented   % Total amount of gas vented (in moles)
        GasSource   % Source of Make Up Gas
        EnvironmentControlled  % Environment whose atmosphere is being monitored and controlled
    end
    
    properties (SetAccess = private)
        PartialPressureBoundingBox = 1.37895146     % in kPa (converted from 0.2psia), extent of control box around which 
        VentPortDiameter = 0.056         % in meters (vent port diameter of Vent Relief Valve of the ISS PCA, REF: pg 89, Living Together in Space) 
        MarsMeanAtmPressure = 6.36*0.1   % in kPa, Mean atmospheric pressure at Mars surface (REF: http://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html)
        MarsMeanAtmDensity = 0.02        % in kg/m^3, Mean atmospheric density at Mars surface (REF: http://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html)
    end
    
    
    methods
        %% Constructor
        function obj = ISSinjectorImpl(GasType,TargetPressure,InputTank,OutputSource)
            
            if nargin > 0
                if ~(strcmpi(class(InputTank),'StoreImpl') || strcmpi(class(OutputSource),'StoreImpl'))
                    error('Third and Fourth Input arguments must be of type "StoreImpl"')
                end
                
                obj.Gas = GasType;
                obj.TargetPartialPressure = TargetPressure;
                
                limitingFlowRateInKg = 0.09*60;     % Limiting Flow Rate of ISS Pressure Control Assembly is 0.09kg/min (REF: pg 92, Living Together in Space)
                
                % Determine molar mass
                if strcmpi(GasType,'O2')
                    molarMass = 2*15.999;
                elseif strcmpi(GasType,'N2')
                    molarMass = 2*14.007;
                else
                    error('Gas Type must be set to either "O2" or "N2"')
                end
                    
                limitingFlowRateInMoles = limitingFlowRateInKg*1E3/molarMass;
                
                obj.GasSource = ResourceUseDefinitionImpl(InputTank,limitingFlowRateInMoles,limitingFlowRateInMoles);
                obj.EnvironmentControlled = ResourceUseDefinitionImpl(OutputSource,limitingFlowRateInMoles,limitingFlowRateInMoles);
            
            end
        end
        
        %% tick
        function tick(obj)
            
            % Measure partial pressure of constituent gas within
            % environment and determine amount of gas needed to maintain
            % operating pressure
            currentPressure = obj.EnvironmentControlled.pressure;
            
            if currentPressure
            
            
            % Attempt to get resource from consumer store according to declated
            % maxFlowRate
            resourceGathered = obj.ResourceConsumerDefinition.ResourceStore.take(obj.ResourceConsumerDefinition.MaxFlowRate,...
                obj.ResourceConsumerDefinition);
            
            % Push resourceGathered to producer store
            obj.ResourceProducerDefinition.ResourceStore.add(resourceGathered,obj.ResourceProducerDefinition);
        end
            
    end
    
end

