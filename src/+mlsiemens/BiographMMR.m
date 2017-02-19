classdef BiographMMR < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData
	%% BiographMMR enables polymorphism of NIfTId over PET data.  It is also a NIfTIdecorator.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    
    properties (Constant)
        HOUR_KLUDGE = -1
        READTABLE_HEADERLINES = 0
        SPECIFIC_ACTIVITY_KIND = 'becquerelsPerCC' %'decaysPerCC'
    end
    
    properties         
        uncorrected = false
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
        becquerels
        isotope
        efficiencyFactor
        
        %% new
        
        becquerelsPerCC
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
            g = this.consoleClockOffset_;
        end
        function this = set.consoleClockOffset(this, s)
            assert(isa(s, 'duration'));
            this.consoleClockOffset_ = s;
        end
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            this.timingData_.datetime0 = s;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.doseAdminDatetime_;
        end
        function this = set.doseAdminDatetime(this, s)
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
            g = this.becquerels2petCounts(this.becquerels);
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            this.component.img = this.petCounts2becquerels(s)/prod(this.mmppix/10);
        end
        function g    = get.becquerels(this)
            assert(~isempty(this.component.img));
            g = this.becquerelsPerCC*prod(this.mmppix/10);
        end
        function this = set.becquerels(this, s)
            assert(isnumeric(s));
            this.becquerelsPerCC = double(s)/prod(this.mmppix/10);
        end
        function g    = get.isotope(this)
            g = this.sessionData.isotope;
        end
        function e    = get.efficiencyFactor(this)
            e = this.efficiencyFactor_;
        end
        
        %% new
        
        function g    = get.becquerelsPerCC(this)
            assert(~isempty(this.component.img));
            g = this.component.img;
            g = double(g);
            g = squeeze(g);
        end
        function this = set.becquerelsPerCC(this, s)
            assert(isnumeric(s));
            this.component.img = double(s);
        end
        function g    = get.decaysPerCC(this)
            if (~isempty(this.decaysPerCC_))
                g = this.decaysPerCC_;
                return
            end
            g = this.becquerelsPerCC;
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
        function w    = get.W(this)
            w = this.efficiencyFactor;
        end
    end

    methods (Static) 
        function this = load(varargin)
            this = mlsiemens.BiographMMR(mlfourd.NIfTId.load(varargin{:}));
        end
        function this = loadSession(sessd, varargin)
            assert(isa(sessd, 'mlpipeline.ISessionData'))      
            this = mlsiemens.BiographMMR.load(varargin{:});
            this.sessionData_ = sessd;
        end
    end
    
	methods		  
 		function this = BiographMMR(cmp, varargin)
            this = this@mlfourd.NIfTIdecoratorProperties(cmp, varargin{:});
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR'))
                this = this.component;
                return
            end
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'consoleClockOffset', 0, @(x) isa(x, 'duration'));
            addParameter(ip, 'doseAdminDatetime', datetime('now'), @(x) isa(x, 'datetime'));
            parse(ip, varargin{:});
            this.sessionData_ = ip.Results.sessionData;
            this.consoleClockOffset_ = ip.Results.consoleClockOffset;
            this.doseAdminDatetime_ = ip.Results.doseAdminDatetime;
            this.doseAdminDatetime_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            
            this.tableSif_    = this.readtable;
            this.timingData_  = mldata.TimingData( ...
                'times',         this.tableSif_{:,'Start_msec_'}/1000, ...
                'timeMidpoints', this.tableSif_{:,'Midpoint_sec_'}, ...
                'taus',          this.tableSif_{:,'Length_msec_'}/1000, ...
                'datetime0',     this.readDatetime0);
            
            dc = mlpet.DecayCorrection(this);            
            tshift = seconds(this.doseAdminDatetime - this.datetime0);
            if (tshift > 3600); tshift = 0; end %% KLUDGE
            if (this.uncorrected && length(this.component.size) == 4 && size(this.component,4) > 1)
                this.component.img = dc.uncorrectedCounts(this.component.img, tshift);
                this.decaysPerCC_ = this.decaysPerCC;
            end
            
            this = this.append_descrip('decorated by BiographMMR');
        end
        
        function this = crossCalibrate(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScanner'));
            addParameter(ip, 'wellCounter', [], @(x) isa(x, 'mlpet.IBloodData'));
            addParameter(ip, 'aifSampler', this, @(x) isa(x, 'mlpet.IAifData'));
            parse(ip, varargin{:});
            
            cc = mlpet.CrossCalibrator(varargin{:});
            this.efficiencyFactor_ = cc.scannerEfficiency;
        end
        function tbl  = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'timingData', this.sessionData.timingData('typ', 'fqfn'), @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            tbl = readtable(...
                ip.Results.timingData, ...
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
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end
        function [t,this] = tauInterpolants(this, varargin)
            [t,this] = this.timingData_.tauInterpolants(varargin{:});
        end        
        function c = countInterpolants(this, varargin)
            c = this.counts;
            c = this.pchip(this.times, c, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function b = becquerelInterpolants(this, varargin)
            b = this.becquerels;
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
        function this = masked(this, msk)
            assert(isa(msk, 'mlfourd.INIfTI'));
            this.mask_ = msk;
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(msk);
            this.component = dyn.component;
        end
        function this = petobs(this)
            this.fileprefix = [this.fileprefix '_obs'];
            idx0 = this.index0;
            idxF = this.indexF;
            assert(idx0 < idxF);
            this.img = trapz(this.times(idx0:idxF), this.specificActivity(:,:,:,idx0:idxF), 4);
        end
        function this = timeSummed(this)
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.timeSummed;
            this.component = dyn.component;
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
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        consoleClockOffset_
        decaysPerCC_ % cache
        doseAdminDatetime_
        efficiencyFactor_ = 1
        mask_
        scannerTimeShift_
        sessionData_
        tableSif_
        timingData_        
    end
    
    methods (Static, Access = protected)
        function yi = pchip(x, y, xi)
            lenxi = length(xi);
            if (xi(end) < x(end) && all(x(1:lenxi) == xi))
                switch (length(size(y)))
                    case 2
                        yi = y(:,1:lenxi);
                    case 3
                        yi = y(:,:,1:lenxi);
                    case 4
                        yi = y(:,:,:,1:lenxi);
                    otherwise
                        error('mlsiemens:unsupportedArrayShape', 'BiographMMR.pchip');
                end
                return
            end
            yi = pchip(x, y, xi);
        end
    end
    
    methods (Access = protected)
        function img = becquerels2petCounts(this, img)
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
                          'size(BiographMMR.becquerels2petCounts.img) -> %s', mat2str(size(img)));
            end
        end
        function img = petCounts2becquerels(this, img)
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
                          'size(BiographMMR.petCounts2becquerels.img) -> %s', mat2str(size(img)));
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

