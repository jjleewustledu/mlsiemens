classdef BiographData < handle & mlpet.AbstractTracerData
	%% BIOGRAPHDATA  

	%  $Revision$
 	%  was created 07-Mar-2020 17:57:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent)
        imagingContext
        radMeasurements
 		visibleVolume
    end
    
    methods (Static)
        function this = createFromSession(sesd, varargin)
            if isa(sesd, 'mlraichle.SessionData')
                this = mlsiemens.BiographMMRData.createFromSession(sesd, varargin{:});
                return
            end
            this = [];
        end
    end

	methods 
        
        %% GET/SET
        
        function g = get.imagingContext(this)
            g = this.imagingContext_;
        end
        function     set.imagingContext(this, s)
            assert(isa(s, 'mlfourd.ImagingContext2') || isa(s, 'mlfourd.ImagingFormatContext'))
            this.imagingContext_ = s;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g = get.visibleVolume(this)
            %% mL
            
            g = this.imagingContext.nifti;
            g = prod(g.mmppix)/1e3;
        end
        
        %%
        
        function a = activity(this, varargin)
            %% Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical.
            %  @param volumeAveraged is logical.
            %  @param diff is logical.
            
            a = this.activityDensity(varargin{:})*this.visibleVolume;
        end
        function a = activityDensity(this, varargin)
            %% Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical.
            %  @param volumeAveraged is logical.
            %  @param diff is logical.
            
            ip = inputParser;
            addParameter(ip, 'decayCorrected', false, @islogical)
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isnat(x) || isdatetime(x))
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            addParameter(ip, 'timeAveraged', false, @islogical)
            addParameter(ip, 'volumeAveraged', false, @islogical)
            addParameter(ip, 'diff', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isdatetime(ipr.datetimeForDecayCorrection) && ...
                    ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end  
            if ~ipr.decayCorrected && this.decayCorrected
                this = this.decayUncorrect();
            end
            
            that = copy(this);
            if ipr.index0 ~= this.index0 || ipr.indexF ~= this.indexF
                that = that.selectIndex0IndexF(ipr.index0, ipr.indexF);
            end
            if ipr.timeAveraged
                that.imagingContext_ = that.imagingContext_.timeAveraged();
            end
            if ipr.volumeAveraged
                that.imagingContext_ = that.imagingContext_.volumeAveraged();                
                a = that.imagingContext_.nifti.img;
                if ipr.diff
                    a = diff(a);
                end
            else                
                if ipr.diff
                    that.imagingContext_ = diff(that.imagingContext_);
                end
                a = that.imagingContext_.nifti.img;
            end
        end
        function c = countRate(this, varargin)
            %% Bq/mL, decay-corrected.
            %  @param decayCorrected, default := true.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param index0 is numeric.
            %  @param indexF is numeric.
            %  @param timeAveraged is logical.
            %  @param volumeAveraged is logical.
            %  @param diff is logical.
            
            c = this.activityDensity('decayCorrected', true, varargin{:});
        end
        function this = decayCorrect(this)
            if ~this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat .* this.decayCorrectionFactors;
                ifc.img = this.reshape_2d_to_native(mat);
                
                this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                    'fileprefix', sprintf('%s_decayCorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
                this.decayCorrected_ = true;
            end
        end
        function f = decayCorrectionFactors(this, varargin)
            %% DECAYCORRECTIONFACTORS
            %  @return f is vector with same shape at this.times.
            %  See also:  https://niftypet.readthedocs.io/en/latest/tutorials/corrqnt.html
            
            ip = inputParser;
            addParameter(ip, 'timeShift', 0, @isscalar)
            parse(ip, varargin{:})
            
            lambda = log(2)/this.halflife;
            times1 = this.times - this.timeForDecayCorrection - ip.Results.timeShift;
            Dtimes = (times1(2:end) - times1(1:end-1));
            Dtimes = [Dtimes this.taus(end)];
            f = lambda*Dtimes ./ (exp(-lambda*times1).*(1 - exp(-lambda*Dtimes)));
            f = reshape(f, size(asrow(times1)));
        end
        function this = decayUncorrect(this)
            if this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat ./ this.decayCorrectionFactors;
                ifc.img = this.reshape_2d_to_native(mat);
                
                this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                    'fileprefix', sprintf('%s_decayUncorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
                this.decayCorrected_ = false;
            end
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity'}.
            
            that = copy(this);
            that.imagingContext_ = that.imagingContext_.volumeAveraged();
            h = plot@mlpet.AbstractTracerData(that, varargin{:});
        end
        function this = read(this, varargin)
            this.imagingContext_ = mlfourd.ImagingContext2(varargin{:});
        end
        function img  = reshape_native_to_2d(this, img)
            sz  = size(this.imagingContext.nifti);
            switch length(sz)
                case 2
                    return
                case 3                    
                    img = reshape(img, [sz(1)*sz(2) sz(3)]);
                case 4
                    img = reshape(img, [sz(1)*sz(2)*sz(3) sz(4)]);
                otherwise
                    error('mlsiemens:RuntimeError', 'BiographData.reshape_native_to_2d')
            end
        end
        function img  = reshape_2d_to_native(this, img)
            sz  = size(this.imagingContext.nifti);
            switch length(sz)
                case 2
                    return
                case 3                    
                    img = reshape(img, [sz(1) sz(2) sz(3)]);
                case 4
                    img = reshape(img, [sz(1) sz(2) sz(3) sz(4)]);
                otherwise
                    error('mlsiemens:RuntimeError', 'BiographData.reshape_2d_to_native')
            end
        end
        function stageResamplingRestricted(this, fqfn)
            assert(isfile(fqfn))
            this.imagingContext_ = mlfourd.ImagingContext2(fqfn);
        end
        function this = shiftWorldlines(this, timeShift)
            %% shifts worldline of internal data self-consistently
            %  @param timeShift is numeric:  timeShift > 0 shifts into future; timeShift < 0 shifts into past.
            
            assert(isnumeric(timeShift))
            ifc = this.imagingContext.nifti;
            ifc.img = ifc.img * 2^(-timeShift/this.halflife);
            
            this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_shiftWorldlines%g', ifc.fileprefix, timeShift));
            this.datetimeMeasured = this.datetimeMeasured + seconds(timeShift);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        imagingContext_
        radMeasurements_
    end
    
	methods (Access = protected)	  
 		function this = BiographData(varargin)
 			%% BIOGRAPHDATA

 			this = this@mlpet.AbstractTracerData(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.decayCorrected_ = true;
            if ~isempty(ipr.radMeasurements)
                this.radMeasurements_ = ipr.radMeasurements;
            else
                this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromDate(this.datetimeMeasured);
            end
            this.datetimeMeasured = this.datetimeMeasured - this.clocksTimeOffsetWrtNTS;
        end
         
        function sec  = clocksTimeOffsetWrtNTS(this)
            try
                sec = seconds(this.radMeasurements_.clocks.TimeOffsetWrtNTS____s('mMR console'));
            catch ME
                handwarning(ME)
                sec = seconds(this.radMeasurements_.clocks.TIMEOFFSETWRTNTS____S('mMR console'));
            end
        end 
        function this = selectIndex0IndexF(this, index0, indexF)
            nii = this.imagingContext.nifti;
            switch nii.ndims
                case 2
                    nii.img = nii.img(index0:indexF);
                case 3
                    nii.img = nii.img(:,:,index0:indexF);
                case 4
                    nii.img = nii.img(:,:,:,index0:indexF);
                otherwise
                    error('mlsiemens:ValueError', 'BiographData.selectIndex0IndexF')
            end
            this.imagingContext_ = mlfourd.ImagingContext2(nii);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

