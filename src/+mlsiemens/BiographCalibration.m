classdef BiographCalibration < handle & mlpet.AbstractCalibration
	%% BIOGRAPHCALIBRATION  

	%  $Revision$
 	%  was created 23-Feb-2020 18:31:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
 		invEfficiency
    end
    
    methods (Static)
        function this = createBySession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  See also:  mlpet.CCIRRadMeasurements.createBySession().
            
            rad = mlpet.CCIRRadMeasurements.createBySession(varargin{:});
            this = mlsiemens.BiographCalibration.createByRadMeasurements(rad);
        end
        function this = createByRadMeasurements(rad)
            %% CREATEBYRADMEASUREMENTS
 			%  @param required radMeasurements is mlpet.CCIRRadMeasurements.

            assert(isa(rad, 'mlpet.CCIRRadMeasurements'))
            this = mlsiemens.BiographCalibration(rad);
        end
        function inveff = invEfficiencyf(varargin)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            
            error('mlsiemens:NotImplementedError')
        end
        
        function a = e7tools_to_NiftyPET(activity)
            a = (activity - 1712.7) / 1.0573;
        end
    end

	methods 
        
        %% GET
        
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
    end
    
    methods (Access = protected)        
 		function this = BiographCalibration(varargin)
            this = this@mlpet.AbstractCalibration(varargin{:});
            
            rm = this.radMeasurements_;
            rowSelect = strcmp(rm.wellCounter.TRACER, '[18F]DG');
            mass = rm.wellCounter.MassSample_G(rowSelect);
            ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect);
            sa = mlcapintec.CapracCalibration.specificActivityf(mass, ge68./mass); % kdpm/g
            shift = seconds( ...
                rm.mMR.scanStartTime_Hh_mm_ss('NiftyPET') - ...
                seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted
            sa = this.shiftWorldLines(sa, shift, this.radionuclide_.halflife);
            activityDensityWell = (1e3/60) * mlcapintec.CapracCalibration.WATER_DENSITY * mean(sa); % Bq/mL
            activityDensityRoi = 1e3 * rm.mMR.ROIMean_KBq_mL('NiftyPET'); % Bq/mL
            
            this.invEfficiency_ = activityDensityWell/activityDensityRoi;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

