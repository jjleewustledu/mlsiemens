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
        function dispCalibration(cal)
            cal = mlfourd.ImagingContext2(cal);
            assert(isfile(cal.fqfn))
            cal.nifti;
            json = cal.json_metadata;
            b8 = cal.blurred(8);
            b8 = b8.thresh(0.9*dipmax(b8));
            vec = b8.nifti.img(b8.nifti.img > 0);
            dvol = prod(b8.nifti.mmppix); % \muL
            
            fprintf('scan start: %s\n', json.AcquisitionTime)
            fprintf('roi mean (kBq/mL): %g\n', mean(vec)/1e3)
            fprintf('roi std (kBq/mL): %g\n', std(vec)/1e3)
            fprintf('roi vol (mL): %g\n', numel(vec)*dvol/1e3)
            fprintf('roi voxels: %g\n', numel(vec))
            fprintf('roi min (kBq/mL): %g\n', min(vec)/1e3)
            fprintf('roi max (kBq/mL): %g\n', max(vec)/1e3)
        end
        function this = createFromSession(sesd, varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.{ISessionData,ImagingData}.
            
            import mlsiemens.BiographCalibration
            
            this = BiographCalibration(sesd, varargin{:});  
            
            offset = 0;
            while ~this.calibrationAvailable
                if isa(sesd, 'mlpipeline.ImagingMediator')
                    error('mlswisstrace:ValueError', stackstr())
                end
                offset = offset + 1;
                sesd1 = sesd.findProximal(offset);
                this = BiographCalibration(sesd1, varargin{:});
            end
        end
        function ie = invEfficiencyf(sesd)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.{ISessionData,ImagingData}

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
                g = g1 && g2 && ~isnan(this.invEfficiency);
            catch ME %#ok<NASGU>
                %handwarning(ME)
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
        invEfficiency_
    end
    
    methods (Access = protected)        
 		function this = BiographCalibration(sesd, varargin)
            this = this@mlpet.AbstractCalibration(varargin{:});
            
            try                
                % update for new sesd                
                if isempty(this.radMeasurements_) || ...
                        ~strcmp(this.radMeasurements_.sessionData.scanPath, sesd.scanPath)
                    this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromSession(sesd);
                end
            
                % get activity density from Caprac
                
                rm = this.radMeasurements_;
                rowSelect = ...
                    strcmp(rm.wellCounter.TRACER, '[18F]DG') & ...
                    isnice(rm.wellCounter.MassSample_G) & ...
                    isnice(rm.wellCounter.Ge_68_Kdpm);
                mass = rm.wellCounter.MassSample_G(rowSelect);
                ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect);             
                shift = seconds( ...
                    rm.mMR.scanStartTime_Hh_mm_ss(1) - ...
                    seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                    rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted            
                capCal = mlcapintec.CapracCalibration.createFromSession(sesd, 'radMeasurements', rm, 'exactMatch', true);
                activityDensityCapr = capCal.activityDensity('mass', mass, 'ge68', ge68, 'solvent', 'water');
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.radionuclide_.halflife);
                
                % get activity density from rad measurement NiftyPET field && form efficiency^{-1}
                
                activityDensityBiograph = 1e3 * rm.mMR.ROIMean_KBq_mL('NiftyPET'); % Bq/mL   
                this.invEfficiency_ = mean(activityDensityCapr)/mean(activityDensityBiograph);
            catch ME
                
                % calibration data was inadequate, but proximal session may be useable
                handwarning(ME)
                this.invEfficiency_ = NaN;
            end
            assert(isscalar(this.invEfficiency_))
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
