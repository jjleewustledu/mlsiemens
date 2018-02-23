classdef BiographMMR < mlpet.AbstractScannerData
	%% BiographMMR enables polymorphism of NIfTId for PET data.  It is also a NIfTIdecorator.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    properties (Constant)
        HOUR_KLUDGE = -1
        READTABLE_HEADERLINES = 0
    end
    
    properties (Dependent)
        activity % in Bq := specificActivity*voxelVolume
        counts   % in Bq/mL := specificActivity without efficiency adjustments; native to scanner     
        decays   % in Bq*s := specificActivity*voxelVolume*tau
        invEfficiency
        isDecayCorrected 
        isotope
        specificActivity % activity/volume in Bq/mL
        specificDecays   % decays/volume in Bq*s/mL := specificActivity*tau
        
        mask  
        
    end    

    methods (Static) 
        function this = load(varargin)
            this = mlsiemens.BiographMMR(mlfourd.NIfTId.load(varargin{:}));
        end
        function this = loadSession(sessd, varargin)
            assert(isa(sessd, 'mlpipeline.ISessionData'))      
            this = mlsiemens.BiographMMR(mlfourd.NIfTId.load(varargin{:}), 'sessionData', sessd);
        end
    end
    
    methods 
        
        %% GET, SET
        
        function g    = get.activity(this)
            g = this.specificActivity*this.voxelVolume;
        end
        function g    = get.counts(this)
            g = this.img;
        end
        function g    = get.decays(this)
            g = this.specificActivity.*this.taus*this.voxelVolume;
        end
        function g    = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function this = set.invEfficiency(this, s)
            assert(isnumeric(s));
            this.invEfficiency_ = s;
        end              
        function g    = get.isDecayCorrected(this)
            g = this.isDecayCorrected_;
        end
        function this = set.isDecayCorrected(this, s)
            assert(islogical(s));
            if (this.isDecayCorrected_ == s)
                return
            end
            if (this.isDecayCorrected_)  
                this.img = this.decayCorrection_.uncorrectedActivities(this.img, this.time0);
            else
                this.img = this.decayCorrection_.correctedActivities(this.img, this.time0);
            end     
            this.isDecayCorrected_ = s;
        end
        function g    = get.isotope(this)
            g = this.sessionData.isotope;
        end
        function g    = get.mask(this)
            g = this.mask_;
        end
        function g    = get.specificActivity(this)
            g = double(this.invEfficiency*this.img);
        end
        function g    = get.specificDecays(this)
            g = this.specificActivity;
            for t = 1:length(this.taus)
                g(:,:,:,t) = g(:,:,:,t)*this.taus(t);
            end
        end
        
        %%
        
        function ai   = activityInterpolants(this, varargin)
            ai = this.interpolateMetric(this.activity, varargin{:});
        end  
        function this = buildCalibrated(this)
            this.invEfficiency_ = this.invEfficiency_;
        end
        function ci   = countInterpolants(this, varargin)
            ci = this.interpolateMetric(this.counts, varargin{:});
        end
        function dt_  = datetime(this)
            dt_ = this.timingData_.datetime;
        end
        function di   = decayInterpolants(this, varargin)
            di = this.interpolateMetric(this.decays, varargin{:});
        end
        function info = dicominfo(this)
            pwd0 = pushd(this.sessionData.tracerRawdataLocation);
            dtool = mlsystem.DirTool('*.dcm');
            info = struct([]);
            for idt = 1:length(dtool.fns)
                info__ = dicominfo(dtool.fns{idt});
                assert(info__.InstanceNumber <= length(dtool.fns));
                info(info__.InstanceNumber) = info__;
            end
            popd(pwd0);
        end
        function n    = numel(this)
            n = numel(this.img);
        end
        function n    = numelMasked(this)
            if (isempty(this.mask_))
                n = this.numel;
                return
            end
            if (isa(this.mask_, 'mlfourd.ImagingContext'))
                this.mask_ = this.mask_.niftid;
            end
            assert(isa(this.mask_, 'mlfourd.INIfTI'));
            n = double(sum(sum(sum(this.mask_.img))));            
        end
        function this = petobs(this)
            this.fileprefix = [this.fileprefix '_obs'];
            idx0 = this.index0;
            idxF = this.indexF;
            if (idx0 == idxF)
                this.img = squeeze(this.specificActivity);
                return
            end
            this.img = trapz(this.times(idx0:idxF), this.specificActivity(:,:,:,idx0:idxF), 4);
        end    
        function        plot(this)
            if (isscalar(this.img))
                fprintf(this.img);
                return
            end
            if (isvector(this.img))
                plot(this.times, this.img);
                xlabel(sprintf('%s.times', class(this)));
                ylabel(sprintf('%s.img',   class(this)));
                return
            end
            this.view;
        end
        function this = shiftTimes(this, Dt)
            if (0 == Dt)
                return; 
            end
            if (2 == length(this.size))                
                [this.timingData_.times,this.img] = shiftVector(this.timingData_.times, this.img, Dt);
                return
            end
            [this.timingData_.times,this.img] = shiftTensor(this.timingData_.times, this.img, Dt);
        end
        function this = shiftWorldlines(this, Dt, varargin)
            %% SHIFTWORLDLINES
            %  @param required Dt, or \Delta t of worldline. 
            %  Dt > 0 => event occurs at later time and further away in space; boluses are smaller and arrive later.
            %  Dt < 0 => event occurs at earlier time and closer in space; boluses are larger and arrive earlier.
            %  @param optional tzero sets the Lorentz coord for decay-correction and uncorrection.
            
            ip = inputParser;
            addParameter(ip, 'tzero', this.time0, @isnumeric);
            parse(ip, varargin{:});
            
            if (0 == Dt)
                return; 
            end
            this.img = this.decayCorrection_.correctedActivities(this.img, ip.Results.tzero);
            this = this.shiftTimes(Dt);            
            this.img = this.decayCorrection_.uncorrectedActivities(this.img, ip.Results.tzero);
        end
        function sai  = specificActivityInterpolants(this, varargin)
            sai = this.interpolateMetric(this.specificActivity);
        end
        function sdi  = specificDecayInterpolants(this, varargin)
            sdi = this.interpolateMetric(this.specificDecays);
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end
        
        % borrowed from mlfourd.NumericalNIfTId
        function this = blurred(this, varargin)
            asd = this.blurred@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = masked(this, msk)
            asd = this.masked@mlpet.AbstractScannerData(msk);
            this = mlsiemens.BiographMMR(asd.component, 'mask', msk);
        end   
        function this = thresh(this, varargin)
            asd = this.thresh@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = threshp(this, varargin)
            asd = this.threshp@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = timeContracted(this, varargin)
            asd = this.timeContracted@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = timeSummed(this, varargin)
            asd = this.timeSummed@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = uthresh(this, varargin)
            asd = this.uthresh@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = uthreshp(this, varargin)
            asd = this.uthreshp@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function v    = voxelVolume(this)
            %  @param this.img is at least 3D
            %  @return voxel volume in mL
            
            assert(length(size(this)) >= 3);
            v = prod(this.mmppix/10);
        end
        
 		function this = BiographMMR(cmp, varargin)
            this = this@mlpet.AbstractScannerData(cmp, varargin{:});
            
            % avoid decorator redundancy
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR'))
                this = this.component;
                return
            end
                     
            this.isDecayCorrected_ = true;     
            this = this.append_descrip('decorated by BiographMMR');
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
    end
    
    methods (Access = protected)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

