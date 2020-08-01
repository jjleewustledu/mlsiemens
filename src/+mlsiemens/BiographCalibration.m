classdef BiographCalibration < handle & mlpet.AbstractCalibration
	%% BIOGRAPHCALIBRATION  

	%  $Revision$
 	%  was created 23-Feb-2020 18:31:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
 		invEfficiency
        calibrationAvailable
    end
    
    methods (Static)        
        function buildCalibration()
        end
        function this = createFromSession(sesd, varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  @param offset is numeric & searches for alternative SessionData.
            
            import mlsiemens.BiographCalibration
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sesd', @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'offset', 1, @isnumeric)
            parse(ip, sesd, varargin{:})
            ipr = ip.Results;
            
            try
                this = BiographCalibration(sesd, varargin{:});
                
                % get Biograph calibration from most time-proximal calibration measurements
                if ~this.calibrationAvailable
                    error('mlsiemens:ValueError', 'BiographCalibration.calibrationAvailable -> false')
                end
            catch ME
                handwarning(ME)
                sesd = BiographCalibration.findProximalSession(sesd, ipr.offset);
                this = BiographCalibration.createFromSession(sesd, 'offset', ipr.offset+1);
            end
        end
        function ie = invEfficiencyf(sesd)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.ISessionData
            
            assert(isa(sesd, 'mlpipeline.ISessionData'))
            this = mlsiemens.BiographCalibration.createFromSession(sesd);
            ie = this.invEfficiency;
            ie = asrow(ie);
        end
    end

	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(this)
            try
                rm = this.radMeasurements_;
                g1 = isnice(rm.mMR{'NiftyPET','ROIMean_KBq_mL'});                
                g2 = any(strcmp(rm.wellCounter.TRACER, '[18F]DG') & ...
                    isnice(rm.wellCounter.MassSample_G) & ...
                    isnice(rm.wellCounter.Ge_68_Kdpm));
                g = g1 && g2;
            catch ME
                handwarning(ME)
                g = false;
            end
        end
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        
        %%
        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        biographData_
        invEfficiency_
    end
    
    methods (Access = protected)        
 		function this = BiographCalibration(sesd, varargin)
            this = this@mlpet.AbstractCalibration(varargin{:});
            
            % get activity density from Caprac
            if isempty(this.radMeasurements_)
                this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromSession(sesd);
            end
            rm = this.radMeasurements_;
            rowSelect = strcmp(rm.wellCounter.TRACER, '[18F]DG') & ...
                isnice(rm.wellCounter.MassSample_G) & ...
                isnice(rm.wellCounter.Ge_68_Kdpm);
            mass = rm.wellCounter.MassSample_G(rowSelect);
            ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect); 
            
            try
                shift = seconds( ...
                    rm.mMR.scanStartTime_Hh_mm_ss(1) - ...
                    seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                    rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted            
                capCal = mlcapintec.CapracCalibration.createFromSession(sesd, 'radMeasurements', rm);
                activityDensityCapr = capCal.activityDensity('mass', mass, 'ge68', ge68, 'solvent', 'water');
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.radionuclide_.halflife);
                activityDensityBiograph = 1e3 * rm.mMR.ROIMean_KBq_mL('NiftyPET'); % Bq/mL   
                this.invEfficiency_ = mean(activityDensityCapr)/mean(activityDensityBiograph);
                assert(isscalar(this.invEfficiency_))
            catch ME
                handwarning(ME)
                this.invEfficiency_ = NaN;
            end
            
            this.biographData_ = mlsiemens.BiographData.createFromSession(sesd, 'radMeasurements', rm);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
