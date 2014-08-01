classdef DehumidifierImpl
    %DehumidifierImpl Summary of this class goes here
    %   By: Sydney Do (sydneydo@mit.edu)
    %   Date Created: 5/16/2014
    %   Last Updated: 5/16/2014
    
    properties
        % Consumer/Producer Definitions
        AirConsumerDefinition   % ResourceStore here is set to a SimEnvironment
        DirtyWaterProducerDefinition
    end
    
    properties (Access = private)
        optimal_moisture_concentration = 0.0218910; %in kPA assuming 101 kPa total pressure and air temperature of 23C and relative humidity of 80%
    end
    
    methods
        %% Constructor
        function obj = DehumidifierImpl
            obj.AirConsumerDefinition = ResourceUseDefinitionImpl;
            obj.DirtyWaterProducerDefinition = ResourceUseDefinitionImpl;
        end
        
        %% tick
        % this function followsthe DehumidifierImpl.dehumidifyEnvironment
        % method
        function tick(obj)
            
            % This line follows that of the calculateMolesNeededToRemove
            % method
            currentWaterMolesInEnvironment = obj.AirConsumerDefinition.ResourceStore.VaporStore.currentLevel;
            totalMolesInEnvironment = obj.AirConsumerDefinition.ResourceStore.totalMoles;
%             if obj.AirConsumerDefinition.ResourceStore.VaporPercentage > obj.optimal_moisture_concentration
%                 % Moles to remove = total vapor moles available - vapor
%                 % moles making up optimal vapor concentration in
%                 % environment
%                 molesNeededToRemove = currentWaterMolesInEnvironment-(totalMolesInEnvironment-currentWaterMolesInEnvironment)...
%                     *obj.optimal_moisture_concentration/(1-obj.optimal_moisture_concentration);
%                 
%                 % This assumes optimal vapor concentration to remove is fixed
%                 % according to a fixed ratio of atmospheric vapor to
%                 % remaining atmospheric gas (ie. total moles -vapor moles)
%             else
%                 molesNeededToRemove = 0;
%             end
            
            % Faster implementation of above if statement
            molesNeededToRemove = ((currentWaterMolesInEnvironment/totalMolesInEnvironment) > obj.optimal_moisture_concentration)*...
                (currentWaterMolesInEnvironment-(totalMolesInEnvironment-currentWaterMolesInEnvironment)...
                    *obj.optimal_moisture_concentration/(1-obj.optimal_moisture_concentration));
                
            % Currently this file coded to take air from only one environment
            % Take moles from SimEnvironment
            vaporMolesRemoved = obj.AirConsumerDefinition.ResourceStore.VaporStore.take(molesNeededToRemove,...
                obj.AirConsumerDefinition);
                
%             vaporMolesRemoved = 0;      % INCORRECT implementation that is currently used within BioSim
            
            % Push humidity condensate to dirty water store (note that we
            % convert from water moles to water liters here)
            obj.DirtyWaterProducerDefinition.ResourceStore.add(vaporMolesRemoved*18.01524/1000,...
                obj.DirtyWaterProducerDefinition);
            
        end
    end
    
end

