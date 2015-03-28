classdef PressureBalancer < handle
    %PressureBalancer Summary of this class goes here
    %   Note that this code does not work for habitat module arrangments
    %   that are circular and enclosed - in this case, a reference module
    %   needs to be chosen to initiate the analysis
    %   This code is based on iterating through a process of:
    %   1. Determining pressure differences in each module between the
    %   current pressure and the average pressure
    %   2. Identifying source and sink nodes based on rows within the
    %   adjacency matrix with only one entry
    %   3. Adjusting pressures within source and sink nodes until the
    %   pressure difference between their own pressures and the known
    %   average pressure is zero
    
    %   Include this function after fans are initiated
    
    properties
        Modules             % List of modules in the order in which they are captured in the adjacency matrix
        AdjacencyMatrix     % Adjacency matrix of modules and their connections
        TargetPressure      % Average pressure across habitat being targeted
    end
    
    properties (Access = private)
        idealGasConstant = 8.314;   % J/K/mol
        CelsiusToKelvin = 273.15;
    end
    
    methods
        %% Constructor
        function obj = PressureBalancer(modules,adjacencyMatrix)
            if ~strcmpi(class(modules),'SimEnvironmentImpl')
                error('Input must be of class "SimEnvironmentImpl"')
            end
            
            obj.Modules = modules;
            obj.AdjacencyMatrix = adjacencyMatrix;
            
        end
        
        
        %% tick
        function obj = tick(obj)
            
            % Calculate Average Pressure 
            obj.TargetPressure = sum([obj.Modules.totalMoles])*obj.idealGasConstant*(mean([obj.Modules.temperature])+obj.CelsiusToKelvin)/(sum([obj.Modules.volume]));	% Target Pressure in kPa
            
            % Define vector of current pressure differences
            pressureDiff = [obj.Modules.pressure]-obj.TargetPressure;
            
            % Equalize Pressures
            adj = obj.AdjacencyMatrix;      % Copy adjacency matrix so that it can be modified and manipulated during this tick within altering the original data
            count = 1;
            
            while max(abs(pressureDiff)) > 1e-6 && count < 2*length(adj)
            %             for j = 1:length(adj)
                               
                % Find indices of sources and sinks within adjacency matrix
                % Note that sources and sinks only have one connecting pair
                [fromNode,toNode] = find(adj==1);
                sourceSinkIndex = find(sum(adj,2)==1);
                
                sourceIndex = sourceSinkIndex(pressureDiff(sourceSinkIndex)>=0);
                sinkIndex = sourceSinkIndex(pressureDiff(sourceSinkIndex)<0);
                
                % Perform exchanges from source nodes to adjacent nodes
                for k = 1:length(sourceIndex)                   
                    % always move gases from source node to adjacent node -
                    % regardless of difference in magnitudes
                    obj.move(obj.Modules(sourceIndex(k)),obj.Modules(toNode(fromNode==sourceIndex(k))),pressureDiff(sourceIndex(k)));
                    
                    % Recalculate pressure difference vector
                    pressureDiff = [obj.Modules.pressure]-obj.TargetPressure;
                    
                    % remove source nodes from adjacency matrix
                    adj(sourceIndex(k),:) = zeros(1,length(adj));
                    adj(:,sourceIndex(k)) = zeros(length(adj),1);
                end
                
                % Break if max pressure diff is less than 1e-6
                if max(abs(pressureDiff)) < 1e-6
                    break
                end
                
                % Perform exchanges from sink nodes to adjacent nodes
                for m = 1:length(sinkIndex)
                    % Only act - if adjacent node has a positive pressure
                    % difference
                    if pressureDiff(toNode(fromNode==sinkIndex(m))) > 0
                        % Give the source node the maximum of the
                        % magnitudes of the pressure differences between
                        % the two modules
                        if pressureDiff(toNode(fromNode==sinkIndex(m))) < abs(pressureDiff(sinkIndex(m)))
                            % Move all gas from adjacent node
                            obj.move(obj.Modules(toNode(fromNode==sinkIndex(m))),obj.Modules(sinkIndex(m)),pressureDiff(toNode(fromNode==sinkIndex(m))));
                            
                            % Recalculate pressure difference vector
                            pressureDiff = [obj.Modules.pressure]-obj.TargetPressure;
                            
                        else
                            % Take gas required by sink from adjacent node
                            obj.move(obj.Modules(toNode(fromNode==sinkIndex(m))),obj.Modules(sinkIndex(m)),abs(pressureDiff(sinkIndex(m))));
                            
                            % Recalculate pressure difference vector
                            pressureDiff = [obj.Modules.pressure]-obj.TargetPressure;
                        end
                        
                    end
                    
                    % zero out sink nodes from adjacency matrix if
                    % pressureDiff is now zero
                    if ((obj.Modules(sinkIndex(m)).pressure-obj.TargetPressure)^2)^0.5 < 1e-6
                        adj(sinkIndex(m),:) = zeros(1,length(adj));
                        adj(:,sinkIndex(m)) = zeros(length(adj),1);
                    end
                                      
                end
                
                count = count+1;
                
%                 % Break if max pressure diff is less than 1e-6
%                 if max(abs(pressureDiff)) < 1e-6
%                     break
%                 end
                
            end
            
        end
        
        %% Move Gas
        % Function that moves gas from one module to another based on a
        % pressure difference - we assume sourceModule and sinkModule are
        % of class SimEnvironmentImpl
        % sourceModule must have a higher pressure than sinkModule
        function gasTransferred = move(obj,sourceModule,sinkModule,deltaP)
            % Determine number of moles to move by determining constituent
            % gases corresponding to target pressure
            % Target 
                       
            O2molesToMove = deltaP*sourceModule.O2Percentage*sourceModule.volume/(obj.idealGasConstant*(sourceModule.temperature+obj.CelsiusToKelvin));
            CO2molesToMove = deltaP*sourceModule.CO2Percentage*sourceModule.volume/(obj.idealGasConstant*(sourceModule.temperature+obj.CelsiusToKelvin));
            N2molesToMove = deltaP*sourceModule.N2Percentage*sourceModule.volume/(obj.idealGasConstant*(sourceModule.temperature+obj.CelsiusToKelvin));
            VapormolesToMove = deltaP*sourceModule.VaporPercentage*sourceModule.volume/(obj.idealGasConstant*(sourceModule.temperature+obj.CelsiusToKelvin));
            OthermolesToMove = deltaP*sourceModule.OtherPercentage*sourceModule.volume/(obj.idealGasConstant*(sourceModule.temperature+obj.CelsiusToKelvin));
            
            % Move moles from source Modules to sinkModule
            gasTransferred(1) = sinkModule.O2Store.add(sourceModule.O2Store.take(O2molesToMove));
            gasTransferred(2) = sinkModule.CO2Store.add(sourceModule.CO2Store.take(CO2molesToMove));
            gasTransferred(3) = sinkModule.NitrogenStore.add(sourceModule.NitrogenStore.take(N2molesToMove));
            gasTransferred(4) = sinkModule.VaporStore.add(sourceModule.VaporStore.take(VapormolesToMove));
            gasTransferred(5) = sinkModule.OtherStore.add(sourceModule.OtherStore.take(OthermolesToMove));                  
            
        end
        
    end
    
end

