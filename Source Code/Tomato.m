classdef Tomato < handle
    %Tomato Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Tomato'
        Type = 'Planophile'
        taInitialValue = 1200
        initialPPFValue = 625       % per m^2 of crop area
        initialCO2Value = 1200
        CarbonUseEfficiency24 = 0.65
        BCF = 0.43
        CUEmax = 0.65
        CUEmin = 0
        Photoperiod = 12                % days
        NominalPhotoperiod = 12         % days
        TimeAtOrganFormation = 41       % days
        N = 2.5
        CQYMin = 0.01;
        TimeAtCanopySenescence = 56     % days
        TimeAtCropMaturity = 85         % days
        OPF = 1.09;
        FractionOfEdibleBiomass = 0.45
        CaloriesPerKilogram = 220;
        EdibleFreshBasisWaterContent = 0.94
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = Tomato%(cropArea,AirSource,AirSink)
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(1) = 627740;
            canopyClosureConstants(2) = 3172.4;
            canopyClosureConstants(7) = 24.281;
            canopyClosureConstants(11) = 0.44686;
            canopyClosureConstants(12) = 0.0056276;
            canopyClosureConstants(17) = -0.0000030690;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.040061;
            canopyQYConstants(8) = 0.00005688;
            canopyQYConstants(9) = -0.000000022598;
            canopyQYConstants(13) = -0.00000001182;
            canopyQYConstants(14) = 0.00000000000550264;
            canopyQYConstants(17) = -0.0000000071241;
            
            obj.CanopyQuantumYieldConstants = canopyQYConstants;

        end        
        
    end
    
end

