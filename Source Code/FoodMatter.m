classdef FoodMatter < handle
    %FoodMatter Summary of this class goes here
    %   Note tha thtis is originally an IDL type file
    
    properties
        Type            % PlantType
        Mass
        WaterContent
        CaloricContent
    end
    
    methods
        function obj = FoodMatter(type,mass,watercontent)
            if nargin > 0
                obj.Type = type;
                obj.Mass = mass;
                obj.WaterContent = watercontent;
                obj.CaloricContent = type.CaloriesPerKilogram * mass;
            end
        end
    end
    
end

