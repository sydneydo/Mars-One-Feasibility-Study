classdef WhitePotato < handle%PlantImpl
    %WhitePotato Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'White Potato'
        Type = 'Planophile'
        taInitialValue = 1200
        initialPPFValue = 648.15       % per m^2 of crop area
        initialCO2Value = 1200
        CarbonUseEfficiency24 = 0.625
        BCF = 0.41
        CUEmax = 0.625
        CUEmin = 0
        Photoperiod = 12
        NominalPhotoperiod = 12
        TimeAtOrganFormation = 45
        N = 2
        CQYMin = 0.02;
        TimeAtCanopySenescence = 75
        TimeAtCropMaturity = 132
        OPF = 1.02;
        FractionOfEdibleBiomass = 0.3
        CaloriesPerKilogram = 760;
        EdibleFreshBasisWaterContent = 0.8
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = WhitePotato%(cropArea,AirSource,AirSink)
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(1) = 657730;
            canopyClosureConstants(2) = 8562.6;
            canopyClosureConstants(12) = 0.042749;
            canopyClosureConstants(13) = 0.00000088437;
            canopyClosureConstants(17) = -0.000017905;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.046929;
            canopyQYConstants(8) = 0.000050910;
            canopyQYConstants(9) = -0.000000021878;
            canopyQYConstants(15) = 0.0000000000000043976;
            canopyQYConstants(18) = -0.000000000015272;
            canopyQYConstants(22) = -0.000000000019602;
            
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

