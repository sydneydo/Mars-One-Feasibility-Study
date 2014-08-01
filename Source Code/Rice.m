classdef Rice < handle
    %Rice Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        Name = 'Rice'
        Type = 'Erectophile'
        taInitialValue = 1200
        initialPPFValue = 763.89       % per m^2 of crop area
        initialCO2Value = 1200
        CarbonUseEfficiency24 = 0.64
        BCF = 0.45
        Photoperiod = 12                % days
        NominalPhotoperiod = 12         % days
        TimeAtOrganFormation = 57       % days
        N = 1.5
        CQYMin = 0.01;
        TimeAtCanopySenescence = 61     % days
        TimeAtCropMaturity = 85         % days
        OPF = 1.08;
        FractionOfEdibleBiomass = 0.3
        CaloriesPerKilogram = 3630;
        EdibleFreshBasisWaterContent = 0.12
        InedibleFreshBasisWaterContent = 0.9
        CanopyClosureConstants
        CanopyQuantumYieldConstants

    end
    
    methods
        %% Constructor
        function obj = Rice%(cropArea,AirSource,AirSink)
            
            % Initialize Canopy Closure Constants
            canopyClosureConstants = zeros(1,25);
            canopyClosureConstants(1) = 6591400;
            canopyClosureConstants(2) = 25776;
            canopyClosureConstants(4) = 0.0064532;
            canopyClosureConstants(6) = -3748;
            canopyClosureConstants(8) = -0.043378;
            canopyClosureConstants(13) = 0.00004562;
            canopyClosureConstants(17) = 0.0000045207;
            canopyClosureConstants(18) = -0.000000014936;
            
            obj.CanopyClosureConstants = canopyClosureConstants;
            
            % Initialize Canopy Quantum Yield Constants
            canopyQYConstants = zeros(1,25);
            canopyQYConstants(7) = 0.036186;
            canopyQYConstants(8) = 0.000061457;
            canopyQYConstants(9) = -0.000000024322;
            canopyQYConstants(13) = -0.0000000091477;
            canopyQYConstants(14) = 0.000000000003889;
            canopyQYConstants(17) = -0.0000000026712;
            
            obj.CanopyQuantumYieldConstants = canopyQYConstants;

        end        
        
    end
    
end

