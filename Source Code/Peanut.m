classdef Peanut < handle%PlantImpl
    %Peanut Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Peanut'
        Type = 'Legume'
        taInitialValue = 1200
        initialPPFValue = 625       % per m^2 of crop area
        initialCO2Value = 1200
        BCF = 0.6
        CUEmax = 0.65
        CUEmin = 0.3
        Photoperiod = 12
        NominalPhotoperiod = 12
        TimeAtOrganFormation = 49
        N = 2
        CQYMin = 0.02;
        TimeAtCanopySenescence = 65
        TimeAtCropMaturity = 104
        OPF = 1.19;
        FractionOfEdibleBiomass = 0.25
        CaloriesPerKilogram = 5680;
        EdibleFreshBasisWaterContent = 0.056
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = Peanut%(cropArea,AirSource,AirSink)
            
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
            canopyClosureConstants(1) = 3748700;
            canopyClosureConstants(2) = 2920;
            canopyClosureConstants(5) = .000000094008;
            canopyClosureConstants(6) = -18840;
            canopyClosureConstants(7) = 23.912;
            canopyClosureConstants(11) = 51.256;
            canopyClosureConstants(16) = -0.05963;
            canopyClosureConstants(17) = .0000055180;
            canopyClosureConstants(21) = .000025969;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.041513;
            canopyQYConstants(8) = 0.000051157;
            canopyQYConstants(9) = -0.000000020992;
            canopyQYConstants(13) = 0.000000040864;
            canopyQYConstants(17) = -0.000000021582;
            canopyQYConstants(18) = -0.00000000010468;
            canopyQYConstants(23) = 0.000000000000048541;
            canopyQYConstants(25) = 0.0000000000000000000039259;
            
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

