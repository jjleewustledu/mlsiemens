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
        
        % mlpet.IScannerData, mldata.ITimingData
        datetime0 % used with mlpet.DecayCorrection, determines datetime of this.times(1)
        dt
        time0
        timeF
        timeDuration
        times
        timeMidpoints
        taus  
        
        activity
        counts
        decays
        doseAdminDatetime  
        efficiencyFactor
        isDecayCorrected 
        isotope
        specificActivity
        
        % new    
        consoleClockOffset
        index0
        indexF   
        specificDecays
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
        
        % IScannerData        
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            assert(isa(s, 'datetime'));
            s.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            this.timingData_.datetime0 = s;
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
        function g    = get.time0(this)
            g = this.timingData_.time0;
        end
        function this = set.time0(this, s)
            this.timingData_.time0 = s;
        end
        function g    = get.timeF(this)
            g = this.timingData_.timeF;
        end
        function this = set.timeF(this, s)
            this.timingData_.timeF = s;
        end
        function g    = get.timeDuration(this)
            g = this.timingData_.timeDuration;
        end
        function this = set.timeDuration(this, s)
            this.timingData_.timeDuration = s;
        end
        function g    = get.times(this)
            g = this.timingData_.times;
        end
        function this = set.times(this, s)
            this.timingData_.times = s;
        end
        function g    = get.timeMidpoints(this)
            g = this.timingData_.timeMidpoints;
        end
        function g    = get.taus(this)
            g = this.timingData_.taus;
        end
        function g    = get.counts(this)
            g = this.activity2counts(this.activity);
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            this.component.img = this.counts2activity(s)/prod(this.mmppix/10);
        end
        function g    = get.activity(this)
            assert(~isempty(this.component.img));
            g = this.specificActivity*prod(this.mmppix/10);
        end
        function this = set.activity(this, s)
            assert(isnumeric(s));
            this.specificActivity = double(s)/prod(this.mmppix/10);
        end
        function g    = get.isotope(this)
            g = this.sessionData.isotope;
        end
        function g    = get.efficiencyFactor(this)
            g = this.efficiencyFactor_;
        end
        function g    = get.decays(this)
            g = this.activity.*this.taus;
        end
        function this = set.efficiencyFactor(this, s)
            assert(isnumeric(s));
            this.efficiencyFactor_ = s;
        end
        
        % new        
        function g    = get.consoleClockOffset(this)
            g = this.consoleClockOffset_;
        end
        function this = set.consoleClockOffset(this, s)
            assert(isa(s, 'duration'));
            this.consoleClockOffset_ = s;
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
        function g    = get.isDecayCorrected(this)
            g = this.isDecayCorrected_;
        end
        function this = set.isDecayCorrected(this, s)
            assert(islogical(s));            
            dc = mlpet.DecayCorrection.factoryFor(this);   
            this.isDecayCorrected_ = s;
            if (~this.isDecayCorrected_ && length(this.component.size) == 4 && size(this.component,4) > 1)
                tshift = seconds(this.doseAdminDatetime - this.datetime0);
                if (tshift > 3600); tshift = 0; end %% KLUDGE
                this.component.img = dc.uncorrectedActivities(this.component.img, tshift);
                this.specificDecays_ = this.specificDecays;
            end            
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
        function w    = get.W(~)
            w = 1;
        end
        
        %%
           
        % mlpet.IScannerData, mldata.ITimingData
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end
        
        function s     = datetime2sec(this, dt)
            s = this.timingData_.datetime2sec(dt);
        end
        function info  = dicominfo(this)
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
        function this  = petobs(this)
            this.fileprefix = [this.fileprefix '_obs'];
            idx0 = this.index0;
            idxF = this.indexF;
            if (idx0 == idxF)
                this.img = squeeze(this.specificActivity);
                return
            end
            this.img = trapz(this.times(idx0:idxF), this.specificActivity(:,:,:,idx0:idxF), 4);
        end        
        function dt    = sec2datetime(this, s)
            dt = this.timingData_.sec2datetime(s);
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
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'consoleClockOffset', duration(0,0,0), @(x) isa(x, 'duration'));
            addParameter(ip, 'doseAdminDatetime', NaT, @(x) isa(x, 'datetime'));
            addParameter(ip, 'efficiencyFactor', 1, @isnumeric);
            addParameter(ip, 'timingData', [], @(x) isa(x, 'mldata.ITimingData'));
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.consoleClockOffset_ = ip.Results.consoleClockOffset;
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            this.doseAdminDatetime_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            this.timingData_ = ip.Results.timingData;
            
            if (isempty(this.timingData_))
                this.tableSif_    = this.readtable;
                this.timingData_  = mldata.TimingData( ...
                    'times',         this.tableSif_{:,'Start_msec_'}/1000, ...
                    'timeMidpoints', this.tableSif_{:,'Midpoint_sec_'}, ...
                    'taus',          this.tableSif_{:,'Length_msec_'}/1000, ...
                    'datetime0',     this.readDatetime0);
            end
            if (length(this.times) > size(this, 4))
                this.times = this.times(1:size(this, 4));
            end
            if (length(this.times) < size(this, 4))
                this.img = this.img(:,:,:,1:length(this.times));
            end                     
            
            this.efficiencyFactor_ = ip.Results.efficiencyFactor;
            this.component.img = this.component.img*this.efficiencyFactor;
            
            this = this.append_descrip('decorated by BiographMMR');
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        consoleClockOffset_
        doseAdminDatetime_
        efficiencyFactor_
        isDecayCorrected_ = true;
        specificDecays_ % cache
        tableSif_
    end
    
    methods (Access = protected)
        function img = activity2counts(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = img .* this.taus';
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) * this.taus(t);
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) * this.taus(t);
                    end
                otherwise
                    error('mlsiemens:unsupportedArraySize', ...
                          'size(BiographMMR.activity2counts.img) -> %s', mat2str(size(img)));
            end
        end
        function img = counts2activity(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = img ./ this.taus';
                case 3
                    for t = 1:size(img, 3)
                        img(:,:,t) = img(:,:,t) / this.taus(t);
                    end
                case 4
                    for t = 1:size(img, 4)
                        img(:,:,:,t) = img(:,:,:,t) / this.taus(t);
                    end
                otherwise
                    error('mlsiemens:unsupportedArraySize', ...
                          'size(BiographMMR.counts2activity.img) -> %s', mat2str(size(img)));
            end
        end
        function dt0 = readDatetime0(this)
            mhdr = this.sessionData.tracerListmodeMhdr;
            lp = mlio.LogParser.load(mhdr);
            [dateStr,idx] = lp.findNextCell('%study date (yyyy:mm:dd):=', 1);
             timeStr      = lp.findNextCell('%study time (hh:mm:ss GMT+00:00):=', idx);
            dateNames = regexp(dateStr, '%study date \(yyyy\:mm\:dd\)\:=(?<Y>\d\d\d\d)\:(?<M>\d+)\:(?<D>\d+)', 'names');
            timeNames = regexp(timeStr, '%study time \(hh\:mm\:ss GMT\+00\:00\)\:=(?<H>\d+)\:(?<MI>\d+)\:(?<S>\d+)', 'names');
            Y  = str2double(dateNames.Y);
            M  = str2double(dateNames.M);
            D  = str2double(dateNames.D);
            H  = str2double(timeNames.H) + this.HOUR_KLUDGE;
            MI = str2double(timeNames.MI);
            S  = str2double(timeNames.S);
            dt0 = datetime(Y,M,D,H,MI,S,'TimeZone','UTC') + this.consoleClockOffset;
            dt0.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
        function tbl = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'adhocTimings', this.sessionData.adhocTimings('typ', 'fqfn'), @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            tbl = readtable(...
                ip.Results.adhocTimings, ...
                'FileType', 'text', 'HeaderLines', this.READTABLE_HEADERLINES, 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

