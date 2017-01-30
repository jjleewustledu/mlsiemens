classdef BiographMMR < mlfourd.NIfTIdecoratorProperties & mlpet.IScannerData
	%% BiographMMR enables polymorphism of NIfTId over PET data.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    
    properties (Dependent)
        
        %% IScannerData
        
        sessionData
        doseAdminTime  
        dt
        time0
        timeF      
        times
        timeMidpoints
        taus        
        counts
        becquerels
        
        %% new
        
        mask
        nPixels
    end    
    
    methods %% GET
        
        %% IScannerData
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.sessionData_ = s;
        end
        function g    = get.doseAdminTime(this)
            error('mlsiemens:notImplmented', 'BiographMMR.get.dosAdminTime');
        end
        function g    = get.dt(this)
            if (~isempty(this.dt_))
                g = this.dt_;
                return
            end            
            g = min(this.taus)/2;
        end
        function this = set.dt(this, s)
            assert(isnumeric(s));
            this.dt_ = s;
        end
        function g    = get.time0(this)
            if (~isempty(this.time0_))
                g = this.time0_;
                return
            end            
            g = this.times(1);
        end
        function this = set.time0(this, s)
            assert(isnumeric(s));
            this.time0_ = s;
        end
        function g    = get.timeF(this)
            if (~isempty(this.timeF_))
                g = this.timeF_;
                return
            end            
            g = this.times(end);
        end
        function this = set.timeF(this, s)
            assert(isnumeric(s));
            this.timeF_ = s;
        end
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        function tmp  = get.timeMidpoints(this)
            assert(~isempty(this.timeMidpoints_));
            tmp = this.timeMidpoints_;
        end
        function t    = get.taus(this)
            assert(~isempty(this.taus_));
            t = this.taus_;
        end
        function c    = get.counts(this)
            c = this.becquerels2petCounts(this.becquerels);
        end
        function b    = get.becquerels(this)
            assert(~isempty(this.component.img));
            if (size(this.component.img,4) > length(this.times)) 
                warning('mlsiemens:unexpectedDataSize', ...
                        'BiographMMR.get.becquerels found size(this.component)->%s, length(this.times)->%i', ...
                        num2str(size(this.component)), length(this.times)); 
                this.component.img = this.component.img(:,:,:,1:length(this.times)); 
            end
            b = this.component.img;
            b = double(b);
            b = squeeze(b);
        end
        function this = set.becquerels(this, b)
            assert(isnumeric(b));
            this.component.img = double(b);
        end
        
        %% new
        
        function m   = get.mask(this)
            m = this.mask_;
        end
        function n   = get.nPixels(this)
            if (isempty(this.mask_))
                n = prod(this.component.size(1:3));
            else
                assert(1 == max(max(max(this.mask_.img))));
                assert(0 == min(min(min(this.mask_.img))));
                n = sum(sum(sum(this.mask_.img)));
            end
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
            this = this.append_descrip('decorated by BiographMMR');
            this.tableSif_ = this.readTableSif__;
            this.times_ = (this.tableSif_{:,'Start_msec_'}/1000)';
            this.timeMidpoints_ = this.tableSif_{:,'Midpoint_sec_'}';
            this.taus_ = (this.tableSif_{:,'Length_msec_'}/1000)';
        end
        
        function this = save(this)
            this.component.fqfileprefix = sprintf('%s_%s', this.component.fqfileprefix, datestr(now, 30));
            this.component.save;
        end
        function this = saveas(this, fqfn)
            this.component.fqfilename = fqfn;
            this.save;
        end
        
        function [t,this] = timeInterpolants(this, varargin)
            if (~isempty(this.timesInterpolants_))
                t = this.timesInterpolants_;
                return
            end
            
            t = this.time0:this.dt:this.timeF;
            this.timesInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            if (~isempty(this.timeMidpointInterpolants_))
                t = this.timeMidpointInterpolants_;
                return
            end
            
            t = this.time0+this.dt/2:this.dt:this.timeF+this.dt/2;
            this.timeMidpointInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function [t,this] = tauInterpolants(this, varargin)
            if (~isempty(this.tauInterpolants_))
                t = this.tauInterpolants_;
                return
            end
            
            t = this.dt*ones(1, length(this.timeInterpolants));
            this.tauInterpolants_ = t;
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
        function c = countInterpolants(this, varargin)
            c = pchip(this.times, this.counts, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function b = becquerelInterpolants(this, varargin)
            b = pchip(this.times, this.becquerels, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        
        function i    = guessIsotope(this)
            tr = lower(this.sessionData.tracer);
            if (lstrfind(tr, {'ho' 'oo' 'oc' 'co'}))
                i = '15O';
                return
            end
            if (lstrfind(tr, 'fdg'))
                i = '18F';
                return
            end 
            if (lstrfind(tr, 'g'))
                i = '11C';
                return
            end            
            error('mlsiemens:indeterminatePropertyValue', ...
                'BiographMMR.guessIsotope could not recognize the isotope of %s', this.sessionData.tracer);
        end
        function this = masked(this, msk)
            assert(isa(msk, 'mlfourd.INIfTI'));
            this.mask_ = msk;
            dyn = mlfourd.DynamicNIfTId(this.component); %% KLUDGE to work-around faults with decorators in matlab
            dyn = dyn.masked(msk);
            this.component = dyn.component;
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
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
        dt_
        time0_
        timeF_
        times_
        timeMidpoints_
        taus_
        timeInterpolants_
        timeMidpointInterpolants_
        tauInterpolants_
        tableSif_
        
        mask_
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
        function tab = readTableSif__(this, varargin)
            ip = inputParser;
            addOptional(ip, 'tracerSif', [this.sessionData.tracerSif '.4dfp.img.rec'], @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            tab = readtable(...
                ip.Results.tracerSif, ...
                'FileType', 'text', 'ReadVariableNames', true, 'ReadRowNames', true, 'CommentStyle', 'endrec');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

