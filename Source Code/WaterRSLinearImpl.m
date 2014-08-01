classdef WaterRSLinearImpl
    %WaterRSLinear Summary of this class goes here
    %   By: Sydney Do (sydneydo@mit.edu)
    %   Date Created: 5/16/2014
    %   Last Updated: 5/16/2014
    %   This is a simple implementation of a water processing system
    %   Taken from comments in BioSim code:
    %   The Water Recovery System takes grey (humidity condensate)/dirty 
    %   (urine) water and refines it to potable water for the crew members 
    %   and grey water for the crops.. 
    %   Class modeled after the paper:. "Intelligent Control of a Water 
    %   Recovery System: Three Years in the Trenches" by Bonasso, 
    %   Kortenkamp, and Thronesbery
    
    %   Note this implementation assumes 100% water processing efficiency
    
    
    properties
        % Consumer/Producer Definitions
        GreyWaterConsumerDefinition
        DirtyWaterConsumerDefinition
        PowerConsumerDefinition
        PotableWaterProducerDefinition
    end
    
    methods
        %% Constructor
        function obj = WaterRSLinearImpl
            obj.GreyWaterConsumerDefinition = ResourceUseDefinitionImpl;
            obj.DirtyWaterConsumerDefinition = ResourceUseDefinitionImpl;
            obj.PowerConsumerDefinition = ResourceUseDefinitionImpl;
            obj.PotableWaterProducerDefinition = ResourceUseDefinitionImpl;
        end
        
        %% tick
        function tick(obj)
            % gatherPower()
            currentPowerConsumed = obj.PowerConsumerDefinition.ResourceStore.take(obj.PowerConsumerDefinition.MaxFlowRate,obj.PowerConsumerDefinition);     % Take power
            
            % gatherWater()
            % This is tuned to requiring 1540 Watts to process 4.26L of
            % water
            waterNeeded = (currentPowerConsumed/1540) * 4.26;
            % Take water from dirty water store first, then if this is not
            % enough, take remainder from grey water store
            currentDirtyWaterConsumed = obj.DirtyWaterConsumerDefinition.ResourceStore.take(waterNeeded,obj.DirtyWaterConsumerDefinition);
            
            % Take remainder of water needed from GreyWater Store (if
            % required)
%             currentGreyWaterConsumed = obj.GreyWaterConsumerDefinition.ResourceStore.take(...
%                 (waterNeeded > currentDirtyWaterConsumed)*(waterNeeded - currentDirtyWaterConsumed),...
%                 obj.GreyWaterConsumerDefinition);
            % Alternative
            currentGreyWaterConsumed = obj.GreyWaterConsumerDefinition.ResourceStore.take(...
                waterNeeded - currentDirtyWaterConsumed,obj.GreyWaterConsumerDefinition);
            
            % Push Potable Water to Potable Water Store
            obj.PotableWaterProducerDefinition.ResourceStore.add(...
                currentDirtyWaterConsumed+currentGreyWaterConsumed,obj.PotableWaterProducerDefinition);
            
        end
        
    end
    
end

