classdef BiographMMR0 < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData
	%% BIOGRAPHMMR0 enables polymorphism of NIfTId over PET data.  It is also a NIfTIdecorator.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    properties (Constant)
        HOUR_KLUDGE = -1
        READTABLE_HEADERLINES = 0
        SPECIFIC_ACTIVITY_KIND = 'activityPerCC' %'decaysPerCC'
    end
    
    properties
        isPlasma = false
        uncorrected = false
        
        % unused
        decays
        isDecayCorrected = true
    end
    
    properties (Dependent)
        
        %% IScannerData
        
        sessionData
        consoleClockOffset
        datetime0 % used with mlpet.DecayCorrection, determines datetime of this.times(1)
        doseAdminDatetime  
        dt
        index0
        indexF
        time0
        timeF
        timeDuration
        times
        timeMidpoints
        taus        
        counts
        activity
        isotope
        invEfficiency
        
        %% new
        
        activityPerCC
        decaysPerCC
        mask
        nPixels
        scannerTimeShift
        specificActivity
        W
    end    
    
    methods %% GET, SET
        
        %% IScannerData
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
        end
        function g    = get.consoleClockOffset(this)
            g = this.sessionData.consoleClockOffset;
        end
        function this = set.consoleClockOffset(this, s)
            assert(isa(s, 'duration'));
            this.sessionData.consoleClockOffset = s;
        end
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
            g = this.activity2petCounts(this.activity);
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            this.component.img = this.petCounts2activity(s)/prod(this.mmppix/10);
        end
        function g    = get.activity(this)
            assert(~isempty(this.component.img));
            g = this.activityPerCC*prod(this.mmppix/10);
        end
        function this = set.activity(this, s)
            assert(isnumeric(s));
            this.activityPerCC = double(s)/prod(this.mmppix/10);
        end
        function g    = get.isotope(this)
            g = this.sessionData.isotope;
        end
        function g    = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function this = set.invEfficiency(this, s)
            assert(isnumeric(s));
            this.invEfficiency_ = s;
        end
        
        %% new
        
        function g    = get.activityPerCC(this)
            assert(~isempty(this.component.img));
            g = this.component.img;
            g = double(g);
            g = squeeze(g);
        end
        function this = set.activityPerCC(this, s)
            assert(isnumeric(s));
            this.component.img = double(s);
        end
        function g    = get.decaysPerCC(this)
            if (~isempty(this.decaysPerCC_))
                g = this.decaysPerCC_;
                return
            end
            g = this.activityPerCC;
            for t = 1:length(this.taus)
                g(:,:,:,t) = g(:,:,:,t)*this.taus(t);
            end
        end
        function this = set.decaysPerCC(this, s)
            assert(isnumeric(s) && size(s) == this.component.size);
            s = double(s);
            for t = 1:length(this.taus)
               s(:,:,:,t) = s(:,:,:,t)/this.taus(t);
            end
            this.component.img = s;
        end
        function g    = get.mask(this)
            g = this.mask_;
        end
        function g    = get.nPixels(this)
            if (isempty(this.mask_))
                g = prod(this.component.size(1:3));
            else
                assert(1 == max(max(max(this.mask_.img))));
                assert(0 == min(min(min(this.mask_.img))));
                g = sum(sum(sum(this.mask_.img)));
            end
        end  
        function g    = get.scannerTimeShift(this)
            g = this.scannerTimeShift_;
        end
        function g    = get.specificActivity(this)
            g = this.(this.SPECIFIC_ACTIVITY_KIND);
        end
        function this = set.specificActivity(this, s)
            this.(this.SPECIFIC_ACTIVITY_KIND) = s;
        end
        function w    = get.W(~)
            w = 1;
        end
    end

    methods (Static) 
        function this = load(varargin)
            this = mlsiemens.BiographMMR0(mlfourd.NIfTId.load(varargin{:}));
        end
        function this = loadSession(sessd, varargin)
            assert(isa(sessd, 'mlpipeline.ISessionData'))      
            this = mlsiemens.BiographMMR0(mlfourd.NIfTId.load(varargin{:}), 'sessionData', sessd);
        end
    end
    
	methods
 		function this = BiographMMR0(cmp, varargin)
            this = this@mlfourd.NIfTIdecoratorProperties(cmp, varargin{:});
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR0'))
                this = this.component;
                return
            end
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'consoleClockOffset', seconds(8), @(x) isa(x, 'duration'));
            addParameter(ip, 'doseAdminDatetime', datetime('now'), @(x) isa(x, 'datetime'));
            addParameter(ip, 'invEfficiency', 1.155, @isnumeric); % from HYGLY28/V2
            addParameter(ip, 'manualData', [],  @(x) isa(x, 'mldata.IManualMeasurements'));
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.sessionData_.consoleClockOffset = ip.Results.consoleClockOffset;
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            this.doseAdminDatetime_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            this.manualData_ = ip.Results.manualData;
            
            %this.tableSif_    = this.readtable;
            this.timingData_ = mldata.TimingData( ...
                'times',     this.sessionData.times, ...
                'datetime0', this.sessionData.readDatetime0);
            if (length(this.times) > size(this, 4))
                this.times = this.times(1:size(this, 4));
            end
            if (length(this.times) < size(this, 4))
                this.img = this.img(:,:,:,1:length(this.times));
            end
            
            dc = mlpet.DecayCorrection.factoryFor(this);
            if (this.uncorrected && length(this.component.size) == 4 && size(this.component,4) > 1)
                this.component.img = dc.uncorrectedActivities(this.component.img, 0);
                this.decaysPerCC_ = this.decaysPerCC;
            end
            
            this.invEfficiency_ = ip.Results.invEfficiency;
            this.component.img = this.component.img*this.invEfficiency;
            
            this = this.append_descrip('decorated by BiographMMR0');
        end
        
        function this = buildCalibrated(this)
            this.invEfficiency_ = this.invEfficiency_;
        end
        function tbl  = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'adhocTimings', this.sessionData.adhocTimings('typ', 'fqfn'), @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            tbl = readtable(...
                ip.Results.adhocTimings, ...
                'FileType', 'text', 'HeaderLines', this.READTABLE_HEADERLINES, 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
        end
        function this = save(this)
            this.component.fqfileprefix = sprintf('%s_%s', this.component.fqfileprefix, datestr(now, 30));
            this.component.save;
        end
        function this = saveas(this, fqfn)
            this.component.fqfilename = fqfn;
            this.save;
        end
        function this = shiftTimes(this, Dt)
            [this.times_,this.component.img] = shiftTensor(this.times_, this.component.img, Dt);
        end
        function this = shiftWorldlines(this)
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end  
        function c = countInterpolants(this, varargin)
            c = this.counts;
            c = this.pchip(this.times, c, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function b = activityInterpolants(this, varargin)
            b = this.activity;
            b = this.pchip(this.times, b, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        
        function this = blurred(this, blur)
            bl = mlfourd.BlurringNIfTId(this.component);
            bl = bl.blurred(blur);
            this.component = bl.component;
        end
        function len  = length(this)
            len = length(this.times);
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
        function this = masked(this, msk)
            assert(isa(msk, 'mlfourd.INIfTI'));
            this.mask_ = msk;
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(msk);
            this.component = dyn.component;
        end
        function        plot(this)
            if (isscalar(this.img))
                fprintf(this.img);
            end
            if (isvector(this.img))
                plot(this.times, this.img);
                xlabel('BiographMMR0.times');
                ylabel('BiographMMR0.img');
                return
            end
            this.view;
        end
        function this = petobs(this)
            this.fileprefix = [this.fileprefix '_obs'];
            idx0 = this.index0;
            idxF = this.indexF;
            assert(idx0 < idxF);
            this.img = trapz(this.times(idx0:idxF), this.specificActivity(:,:,:,idx0:idxF), 4);
        end
        function this = thresh(this, t)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.thresh(t);
            this.component = nn.component;
        end
        function this = threshp(this, p)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.threshp(p);
            this.component = nn.component;
        end
        function this = timeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.timeSummed;
            this.component = dyn.component;
        end
        function this = uthresh(this, u)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthresh(u);
            this.component = nn.component;
        end
        function this = uthreshp(this, p)
            nn = mlfourd.NumericalNIfTId(this.component);
            nn = nn.uthreshp(p);
            this.component = nn.component;
        end
        function this = volumeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.volumeSummed;
            this.component = dyn.component;
        end
        
        function s    = datetime2sec(this, dt)
            s = this.timingData_.datetime2sec(dt);
        end
        function dt   = sec2datetime(this, s)
            dt = this.timingData_.sec2datetime(s);
        end
        
        % unused
        function this = volumeContracted(this)
        end
        function this = timeContracted(this)
        end
        function this = specificActivityInterpolants(this)
        end
        function this = numelMasked(this)
        end
        function this = numel(this)
        end
        function this = decayInterpolants(this)
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        decaysPerCC_ % cache
        doseAdminDatetime_
        invEfficiency_
        manualData_
        mask_
        scannerTimeShift_
        sessionData_
        %tableSif_
        timingData_        
    end
    
    methods (Static, Access = protected)
        function yi = pchip(x, y, xi)
            lenxi = length(xi);
            if (xi(end) < x(end) && all(xi == x(1:lenxi))) % xi \subset x
                % yi := truncated y
                switch (length(size(y)))
                    case 2
                        yi = y(:,1:lenxi);
                    case 3
                        yi = y(:,:,1:lenxi);
                    case 4
                        yi = y(:,:,:,1:lenxi);
                    otherwise
                        error('mlsiemens:unsupportedArrayShape', 'BiographMMR0.pchip');
                end
                return
            end
            
            yi = pchip(x, y, xi); % understands x = xi
        end
    end
    
    methods (Access = protected)
        function img = activity2petCounts(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = ensureRowVector(img) .* ensureRowVector(this.taus);
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
                          'size(BiographMMR0.activity2petCounts.img) -> %s', mat2str(size(img)));
            end
        end
        function img = petCounts2activity(this, img)
            %% BECQUERELS2PETCOUNTS; does not divide out number of pixels.
            
            img = double(img);
            switch (length(size(img))) 
                case 2
                    img = ensureRowVector(img) ./ ensureRowVector(this.taus);
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
                          'size(BiographMMR0.petCounts2activity.img) -> %s', mat2str(size(img)));
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
    
    %% HIDDEN
    
    methods (Hidden)
        function m = calibrationMeasurement(~, m)
        end
    end
 end

