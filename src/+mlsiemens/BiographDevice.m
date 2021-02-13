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
        function that = blurred(this, varargin)
            that = copy(this);
            that.data_ = that.data_.blurred(varargin{:});
        end
        function c = countRate(this, varargin)
            %% has no calibrations; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.            
            
            c = this.data_.countRate(varargin{:});
        end	
        function ic = decayCorrectLike(this, ic)
            %  @param ic is understood by mlfourd.ImagingContext2.
            
            ic = mlfourd.ImagingContext2(ic);
            ifc = ic.fourdfp;
            mat = this.data_.reshape_native_to_2d(ifc.img);
            mat = mat .* this.data_.decayCorrectionFactors;
            ifc.img = this.data_.reshape_2d_to_native(mat);
                
            ic = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_decayCorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
        end
        function ic = decayUncorrectLike(this, ic)
            ic = mlfourd.ImagingContext2(ic);
            ifc = ic.fourdfp;
            mat = this.data_.reshape_native_to_2d(ifc.img);
            mat = mat ./ this.data_.decayCorrectionFactors;
            ifc.img = this.data_.reshape_2d_to_native(mat);
                
            ic = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_decayUncorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
        end
        function that = masked(this, varargin)
            that = copy(this);
            that.data_ = that.data_.masked(varargin{:});
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'datetimesMid', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity', 'this.activityDensity(''volumeAveraged'', true)'}.
            
            ip = inputParser;
            addOptional(ip, 'abscissa', 'this.datetimesMid', @ischar)
            addOptional(ip, 'ordinate', 'this.activityDensity(''volumeAveraged'', true)', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if length(eval(ipr.abscissa)) < 100
                marks = ':o';
            else
                marks = '.';                
            end
            
            h = figure;
            plot(eval(ipr.abscissa), eval(ipr.ordinate), marks);
            switch strtok(ipr.abscissa, '(')
                case 'this.times'
                    xlabel('time / s')
                otherwise
            end
            switch strtok(ipr.ordinate, '(')
                case 'this.countRate'
                    ylabel('count rate / cps')
                case 'this.activity'
                    ylabel('activity / Bq')
                case 'this.activityDensity'
                    ylabel('activity density / (Bq/mL)')
                otherwise
            end
            title(sprintf('%s.plot(%s)', class(this), this.data_.tracer))
        end 
        function that = timeAveraged(this, varargin)
            that = copy(this);
            that.data_ = that.data_.timeAveraged(varargin{:});
        end
        function that = volumeAveraged(this, varargin)
            that = copy(this);
            that.data_ = that.data_.volumeAveraged(varargin{:});
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

