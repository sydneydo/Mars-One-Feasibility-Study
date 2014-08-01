classdef Soybean < handle
    %Rice Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Soybean'
        Type = 'Legume'
        taInitialValue = 1200
        initialPPFValue = 648.15       % per m^2 of crop area
        initialCO2Value = 1200
%         CarbonUseEfficiency24 = 0.64
        BCF = 0.46
        CUEmax = 0.65
        CUEmin = 0.3
        Photoperiod = 12                % days
        NominalPhotoperiod = 12         % days
        TimeAtOrganFormation = 46       % days
        N = 1.5
        CQYMin = 0.02;
        TimeAtCanopySenescence = 48     % days
        TimeAtCropMaturity = 86         % days
        OPF = 1.16;
        FractionOfEdibleBiomass = 0.4
        CaloriesPerKilogram = 1340;
        EdibleFreshBasisWaterContent = 0.1
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = Soybean%(cropArea,AirSource,AirSink)
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(1) = 6797800;
            canopyClosureConstants(2) = -4365.8;
            canopyClosureConstants(3) = 1.5573;
            canopyClosureConstants(6) = -43260;
            canopyClosureConstants(7) = 33.959;
            canopyClosureConstants(11) = 112.63;
            canopyClosureConstants(14) = -.000000004911;
            canopyClosureConstants(16) = -0.13637;
            canopyClosureConstants(21) = .000066918;
            canopyClosureConstants(22) = -.000000021367;
            canopyClosureConstants(23) = .000000000015467;
            
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

        end        
        
    end
    
end

