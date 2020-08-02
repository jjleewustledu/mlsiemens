classdef BiographDevice < handle & mlpet.AbstractDevice
	%% BIOGRAPHDEVICE  

	%  $Revision$
 	%  was created 26-Mar-2020 10:24:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
 		calibrationAvailable
        imagingContext
 	end

    methods (Static)
        function this = createFromSession(varargin)
            if isa(sesd, 'mlraichle.SessionData')
                this = mlsiemens.BiographMMRDevice.createFromSession(sesd, varargin{:});
                return
            end
            this = [];
        end
        function ie = invEfficiencyf(sesd)
            this = mlsiemens.BiographDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
        end
        function g = get.imagingContext(this)
            g = this.data_.imagingContext;
        end
        
        %%        
        
        function a = activity(this, varargin)
            %% is calibrated to ref-source; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.invEfficiency_*this.data_.activity(varargin{:});
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.invEfficiency_*this.data_.activityDensity(varargin{:});
        end
        function this = blurred(this, varargin)
            this.data_ = this.data_.blurred(varargin{:});
        end
        function c = countRate(this, varargin)
            %% has no calibrations; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.            
            
            c = this.data_.countRate(varargin{:});
        end	
        function this = masked(this, varargin)
            this.data_ = this.data_.masked(varargin{:});
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity'}.
            
            h = this.data_.plot(varargin{:});
        end  
        function this = timeAveraged(this, varargin)
            this.data_ = this.data_.timeAveraged(varargin{:});
        end
        function this = volumeAveraged(this, varargin)
            this.data_ = this.data_.volumeAveraged(varargin{:});
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
    end
    
    methods (Access = protected)
 		function this = BiographDevice(varargin)
 			%% BIOGRAPHDEVICE
            
            import mlcapintec.RefSourceCalibration

 			this = this@mlpet.AbstractDevice(varargin{:});
            
            this.invEfficiency_ = mean(this.calibration_.invEfficiency) * RefSourceCalibration.invEfficiencyf();
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

