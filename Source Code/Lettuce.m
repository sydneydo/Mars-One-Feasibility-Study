classdef Lettuce < handle%PlantImpl
    %Lettuce Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Wheat'
        Type = 'Planophile'
        taInitialValue = 1200
        initialPPFValue = 295.14       % per m^2 of crop area
        initialCO2Value = 1200
        CarbonUseEfficiency24 = 0.625
        BCF = 0.4
        CUEmax = 0.625
        Photoperiod = 16
        NominalPhotoperiod = 16
        TimeAtOrganFormation = 1
        N = 2.5
        CQYMin = 0;
        TimeAtCanopySenescence = 31
        TimeAtCropMaturity = 28
        OPF = 1.08;
        FractionOfEdibleBiomass = 0.9
        CaloriesPerKilogram = 180;
        EdibleFreshBasisWaterContent = 0.95
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants %= [95488,1068.6,zeros(1,4),15.977,zeros(1,3),0.3419,0.00019733,zeros(1,3),-0.00019076,zeros(1,9)]
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = Lettuce%(cropArea,AirSource,AirSink)
            
%             % Initial PPF Value
%             initialPPFValue = 1597.22;
%             
%             % Initial CO2 Value
%             initialCO2Value = 1200;
% 
%             % Initial TA Value (find out what TA is!)
%             TAInitialValue = 1200;
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(2) = 10289;
            canopyClosureConstants(3) = -3.7018;
            canopyClosureConstants(5) = .00000036648;
            canopyClosureConstants(7) = 1.7571;
            canopyClosureConstants(9) = .0000023127;
            canopyClosureConstants(11) = 1.876;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.044763;
            canopyQYConstants(8) = 0.00005163;
            canopyQYConstants(9) = -0.00000002075;
            canopyQYConstants(12) = -0.000011701;
            canopyQYConstants(18) = -0.000000000019731;
            canopyQYConstants(19) = 0.0000000000000089265;
            
            obj.CanopyQuantumYieldConstants = canopyQYConstants;
%             % Construct Parent Class
%             obj@PlantImpl(cropArea,AirSource,AirSink,initialPPFValue,initialCO2Value,...
%                 TAInitialValue,canopyClosureConstants,canopyQYConstants);
            
%             % Update value of taInitialValue
%             obj.taInitialValue = TAInitialValue;
        end
        
        %% Tick
%         function obj = tick(obj)
%             tick@PlantImpl(obj);        % Access tick method within PlantImpl class
%         end
        
        
%             public Wheat(ShelfImpl pShelfImpl) {
%         super(pShelfImpl);
%         canopyClosureConstants(0) = 95488;
%         canopyClosureConstants(1) = 1068.6;
%         canopyClosureConstants(6) = 15.977;
%         canopyClosureConstants(10) = 0.3419;
%         canopyClosureConstants(11) = 0.00019733;
%         canopyClosureConstants(15) = -0.00019076;
% 
%         canopyQYConstants(6) = 0.044793;
%         canopyQYConstants(7) = 0.000051583;
%         canopyQYConstants(8) = -0.000000020724;
%         canopyQYConstants(11) = -0.0000051946;
%         canopyQYConstants(17) = -0.0000000000049303;
%         canopyQYConstants(18) = 0.0000000000000022255;
        
        
    end
    
end

