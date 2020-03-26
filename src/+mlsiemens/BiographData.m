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
        
        %% GET
        
        function g = get.imagingContext(this)
            g = this.imagingContext_;
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
            
            a = this.activityDensity(varargin{:})*this.visibleVolume;
        end
        function a = activityDensity(this, varargin)
            %% Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            ip = inputParser;
            addParameter(ip, 'decayCorrected', false, @islogical)
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isnat(x) || isdatetime(x))
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isdatetime(ipr.datetimeForDecayCorrection) && ...
                    ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end  
            if ~ipr.decayCorrected && this.decayCorrected
                this = this.decayUncorrect();
            end
            a = this.imagingContext.nifti.img;
            switch this.imagingContext.nifti.ndims
                case 2
                    a = a(ipr.index0:ipr.indexF);
                case 3
                    a = a(:,:,ipr.index0:ipr.indexF);
                case 4
                    a = a(:,:,:,ipr.index0:ipr.indexF);
                otherwise
                    error('mlsiemens:ValueError', 'BiographData.activityDensity')
            end
        end
        function c = countRate(this, varargin)
            %% Bq/mL, synonymous with activityDensity
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            c = this.activityDensity(varargin{:});
        end
        function this = decayCorrect(this)
            if ~this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat .* asrow(2.^( (this.times - this.timeForDecayCorrection)/this.halflife));
                ifc.img = this.reshape_2d_to_native(mat);
                
                this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                    'fileprefix', sprintf('%s_decayCorrect%g', ifc.fileprefix, this.timeForDecayCorrection));
                this.decayCorrected_ = true;
            end
        end
        function this = decayUncorrect(this)
            if this.decayCorrected
                ifc = this.imagingContext.nifti;
                mat = this.reshape_native_to_2d(ifc.img);
                mat = mat .* asrow(2.^(-(this.times - this.timeForDecayCorrection)/this.halflife));
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
        function this = shiftWorldlines(this, Dt)
            %% shifts worldline of internal data self-consistently
            %  @param Dt is numeric.
            
            assert(isnumeric(Dt))
            ifc = this.imagingContext.nifti;
            ifc.img = ifc.img * 2^(-Dt/this.halflife);            
            this.imagingContext_ = mlfourd.ImagingContext2(ifc, ...
                'fileprefix', sprintf('%s_shiftWorldlines%g', ifc.fileprefix, Dt));
            this.datetimeMeasured = this.datetimeMeasured + seconds(Dt);
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
            this.decayCorrected_ = true;
            this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromDate(this.datetimeMeasured);
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
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

