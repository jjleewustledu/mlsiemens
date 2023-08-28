classdef BiographDevice < handle & mlpet.AbstractDevice
	%% BIOGRAPHDEVICE represents Siemens Biograph scanners.

	%  $Revision$
 	%  was created 26-Mar-2020 10:24:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee. 	
    
	properties (Constant)
        MAX_NORMAL_BACKGROUND = 20 % Bq/mL
    end

	properties (Dependent)
 		calibrationAvailable
        invEfficiency
    end
    
	methods %% GET
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
        end        
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
    end

    methods
        function a = activity(this, varargin)
            %% is calibrated to ref-source; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.data_.activity(varargin{:})*this.invEfficiency_;
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.data_.activityDensity(varargin{:})*this.invEfficiency_;
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
            ifc = ic.imagingFormat;
            mat = this.data_.reshape_native_to_2d(ifc.img);
            mat = mat .* this.data_.decayCorrectionFactors;
            ifc.img = this.data_.reshape_2d_to_native(mat);
                
            ic = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_decayCorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
        end
        function ic = decayUncorrectLike(this, ic)
            ic = mlfourd.ImagingContext2(ic);
            ifc = ic.imagingFormat;
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
    methods (Static)        
        function sesd = findCalibrationSession(sesd0, varargin)
            %% assumed calibration is performed at end of session

            if isa(sesd0, 'mlnipet.SessionData')
                scanfold = globFoldersT(fullfile(sesd0.sessionPath, 'FDG_DT*-Converted-AC'));
                sesd = sesd0.create(fullfile(sesd0.projectFolder, sesd0.sessionFolder, mybasename(scanfold{end})));
                return
            end
            if isa(sesd0, 'mlpipeline.ImagingMediator')
                scans = glob(fullfile(sesd0.scanPath, '*trc-fdg_proc-static-phantom*_pet.nii.gz'))';
                assert(~isempty(scans), stackstr())
                sesd = sesd0.create(scans{end}); 
                return
            end
            error('mlpet:RuntimeError', stackstr())
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
    end
    
    methods (Access = protected)
 		function this = BiographDevice(varargin)
 			this = this@mlpet.AbstractDevice(varargin{:});            
            this.invEfficiency_ = ...
                mean(this.calibration_.invEfficiency)* ...
                mlcapintec.RefSourceCalibration.invEfficiencyf();
 		end
    end

    %% HIDDEN, DEPRECATED

    methods (Hidden)
        function arterial = idif(this, ~)
            %  Returns:
            %      arterial:  an ImagingContext2->MatlabTool

            ic = mlfourd.ImagingContext2(0);
            ic.fqfp = strcat(this.fqfp, '_BiographDevice_idif');
            N = 0;
            for g = globT(fullfile( ...
                    this.filepath, ...
                    sprintf('ArterialInputFunction_sample_input_function1_%s_on_*-*IC-*to*.nii.gz', this.fileprefix)))
                try
                    if isfile(g{1})
                        ifc = mlfourd.ImagingFormatContext2(g{1});
                        img = ifc.img;
                        assert(max(img(1:length(img)/2)) > max(img(length(img)/2+1:end)))

                        % interpolate temporally
                        ifc.img = interp1(this.data_.timesMid, ifc.img, this.data_.timeInterpolants);

                        ic = ic + mlfourd.ImagingContext2(ifc);
                        N = N + 1;
                    end
                catch 
                end
            end
              
            arterial = ic ./ N;
        end
        function ic = imagingContext(this)
            ic = this.data_.imagingContext;
            ifc = ic.imagingFormat;
            ifc.img = this.invEfficiency_*ifc.img;
            ic = mlfourd.ImagingContext2(ifc);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

