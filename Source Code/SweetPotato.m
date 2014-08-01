classdef SweetPotato < handle
    %Rice Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Sweet Potato'
        Type = 'Planophile'
        taInitialValue = 1200
        initialPPFValue = 432.1       % per m^2 of crop area
        initialCO2Value = 1200
        CarbonUseEfficiency24 = 0.625
        BCF = 0.41
        CUEmax = 0.625
        CUEmin = 0
        Photoperiod = 12                % days
        NominalPhotoperiod = 18         % days
        TimeAtOrganFormation = 33       % days
        N = 1.5
        CQYMin = 0;
        TimeAtCanopySenescence = 121     % days
        TimeAtCropMaturity = 85         % days
        OPF = 1.02;
        FractionOfEdibleBiomass = 0.4
        CaloriesPerKilogram = 1140;
        EdibleFreshBasisWaterContent = 0.71
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = SweetPotato%(cropArea,AirSource,AirSink)
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(1) = 1207000;
            canopyClosureConstants(2) = 4948.4;
            canopyClosureConstants(7) = 4.2978;
            canopyClosureConstants(21) = .00000040109;
            canopyClosureConstants(23) = .0000000000020193;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.039317;
            canopyQYConstants(8) = 0.000056741;
            canopyQYConstants(9) = -0.000000021797;
            canopyQYConstants(12) = -0.000013836;
            canopyQYConstants(13) = -0.0000000063397;
            canopyQYConstants(18) = -0.000000000013464;
            canopyQYConstants(19) = 0.0000000000000077362;
            
            obj.CanopyQuantumYieldConstants = canopyQYConstants;

        end        
        
    end
    
end

