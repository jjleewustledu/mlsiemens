classdef BiographMMR < mlpet.AbstractScannerData
	%% BiographMMR enables polymorphism of NIfTId over PET data.  It is also a NIfTIdecorator.

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
        activity
        counts
        datetime0 % used with mlpet.DecayCorrection, determines datetime of this.times(1)         
        decays
        doseAdminDatetime  
        dt
        index0
        indexF 
        invEfficiency
        isDecayCorrected 
        isotope
        mask
        sessionData    
        specificActivity
        specificDecays
        taus  
        time0
        timeMidpoints
        timeDuration
        timeF
        times
        W
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
            assert(~isempty(this.component.img));
            g = this.specificActivity*prod(this.mmppix/10);
        end
        function this = set.activity(this, s)
            assert(isnumeric(s));
            this.specificActivity = double(s)/prod(this.mmppix/10);
        end
        function g    = get.counts(this)
            g = this.activity2counts(this.activity);
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            this.component.img = this.counts2activity(s)/prod(this.mmppix/10);
        end
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            assert(isa(s, 'datetime'));
            s.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            this.timingData_.datetime0 = s;
        end
        function g    = get.decays(this)
            g = this.activity.*this.taus;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.doseAdminDatetime_;
        end
        function this = set.doseAdminDatetime(this, s)
            assert(isa(s, 'datetime'));
            s.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            this.doseAdminDatetime_ = s;
        end
        function g    = get.dt(this)
            g = this.timingData_.dt;
        end
        function this = set.dt(this, s)
            this.timingData_.dt = s;
        end
        function g    = get.index0(this)
            g = this.timingData_.index0;
        end
        function this = set.index0(this, s)
            this.timingData_.index0 = s;
        end
        function g    = get.indexF(this)
            g = this.timingData_.indexF;
        end
        function this = set.indexF(this, s)
            this.timingData_.indexF = s;
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
            dc = mlpet.DecayCorrection.factoryFor(this);   
            this.isDecayCorrected_ = s;
            if (~this.isDecayCorrected_ && length(this.component.size) == 4 && size(this.component,4) > 1)
                this.component.img = dc.uncorrectedActivities(this.component.img, 0);
                this.specificDecays_ = this.specificDecays;
            end            
        end
        function g    = get.isotope(this)
            g = this.sessionData.isotope;
        end
        function g    = get.mask(this)
            g = this.mask_;
        end
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
        end
        function g    = get.specificActivity(this)
            assert(~isempty(this.component.img));
            g = this.component.img;
            g = double(g);
            g = squeeze(g);
        end
        function this = set.specificActivity(this, s)
            assert(isnumeric(s));
            this.component.img = double(s);
        end
        function g    = get.specificDecays(this)
            if (~isempty(this.specificDecays_))
                g = this.specificDecays_;
                return
            end
            g = this.specificActivity;
            for t = 1:length(this.taus)
                g(:,:,:,t) = g(:,:,:,t)*this.taus(t);
            end
        end
        function this = set.specificDecays(this, s)
            assert(isnumeric(s) && size(s) == this.component.size);
            s = double(s);
            for t = 1:length(this.taus)
               s(:,:,:,t) = s(:,:,:,t)/this.taus(t);
            end
            this.component.img = s;
        end   
        function g    = get.taus(this)
            g = this.timingData_.taus;
        end 
        function g    = get.time0(this)
            g = this.timingData_.time0;
        end
        function this = set.time0(this, s)
            this.timingData_.time0 = s;
        end
        function g    = get.timeDuration(this)
            g = this.timingData_.timeDuration;
        end
        function this = set.timeDuration(this, s)
            this.timingData_.timeDuration = s;
        end
        function g    = get.timeF(this)
            g = this.timingData_.timeF;
        end
        function this = set.timeF(this, s)
            this.timingData_.timeF = s;
        end
        function g    = get.timeMidpoints(this)
            g = this.timingData_.timeMidpoints;
        end
        function g    = get.times(this)
            g = this.timingData_.times;
        end
        function this = set.times(this, s)
            this.timingData_.times = s;
        end
        function w    = get.W(~)
            w = 1;
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
        function s    = datetime2sec(this, dt)
            s = this.timingData_.datetime2sec(dt);
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
        function [m,n] = mskt(this)
            import mlfourdfp.*;
            sessd = this.sessionData;
            f = [sessd.tracerRevision('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeFileprefix(f));
            lns_4dfp(f, f1);
            
            ct4rb = CompositeT4ResolveBuilder('sessionData', sessd);
            ct4rb.msktgenImg(f1);          
            m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
            n = m.numericalNiftid;
            n.img = n.img/n.dipmax;
            n.fileprefix = [f1 '_msktNorm'];
            n.filesuffix = '.4dfp.ifh';
            n.save;
            n = mlfourd.ImagingContext(n);
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
            n = double(sum(sum(sum(this.mask_.img)))); % sum_{x,y,z}, returning nonsingleton t in mask               
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
        function dt   = sec2datetime(this, s)
            dt = this.timingData_.sec2datetime(s);
        end
        function this = shiftTimes(this, Dt)
            if (0 == Dt)
                return; 
            end
            if (2 == length(this.component.size))                
                [this.times_,this.component.img] = shiftVector(this.times_, this.component.img, Dt);
                return
            end
            [this.times_,this.component.img] = shiftTensor(this.times_, this.component.img, Dt);
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
            this.component.img = this.decayCorrection_.correctedActivities(this.component.img, ip.Results.tzero);
            this = this.shiftTimes(Dt);            
            this.component.img = this.decayCorrection_.uncorrectedActivities(this.component.img, ip.Results.tzero);
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
        function sai  = specificActivityInterpolants(this, varargin)
            sai = this.interpolateMetric(this.specificActivity);
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
        function this = volumeContracted(this, varargin)
            asd = this.volumeContracted@mlpet.AbstractScannerData(varargin{:});
            this = mlsiemens.BiographMMR(asd.component);
        end
        function this = volumeSummed(this)
            asd = this.volumeSummed@mlpet.AbstractScannerData;
            this = mlsiemens.BiographMMR(asd.component);
        end
        
 		function this = BiographMMR(cmp, varargin)
            this = this@mlpet.AbstractScannerData(cmp, varargin{:});
            
            % avoid decorator redundancy
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR'))
                this = this.component;
                return
            end
            
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        doseAdminDatetime_
        invEfficiency_
        isDecayCorrected_ = true;
        specificDecays_ % cache
    end
    
    methods (Access = protected)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

