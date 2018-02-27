classdef BiographMMR0 < mlfourd.NIfTIdecoratorProperties
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
    end
    
    properties
        decays
        isPlasma = false
    end
    
    properties (Dependent)   
        activity
        datetime0 % used with mlpet.DecayCorrection, determines datetime of this.times(1)
        doseAdminDatetime      
        counts
        dt
        index0
        indexF
        invEfficiency
        isDecayCorrected
        isotope    
        mask 
        scannerTimeShift
        sessionData
        specificActivity
        taus 
        time0
        timeDuration
        timeF
        timeMidpoints   
        times 
        W
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
        
        %% GET, SET
        
        function g    = get.activity(this)
            g = this.bmmr_.activity;
        end
        function g    = get.counts(this)
            g = this.bmmr_.counts;
        end
        function g    = get.datetime0(this)
            g = this.bmmr_.datetime0;
        end
        function this = set.datetime0(this, s)
            this.bmmr_.datetime0 = s;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.bmmr_.doseAdminDatetime;
        end
        function this = set.doseAdminDatetime(this, s)
            this.bmmr_.doseAdminDatetime = s;
        end
        function g    = get.dt(this)
            g = this.bmmr_.dt;
        end
        function this = set.dt(this, s)
            this.bmmr_.dt = s;
        end
        function g    = get.index0(this)
            g = this.bmmr_.index0;
        end
        function this = set.index0(this, s)
            this.bmmr_.index0 = s;
        end
        function g    = get.indexF(this)
            g = this.bmmr_.indexF;
        end
        function this = set.indexF(this, s)
            this.bmmr_.indexF = s;
        end     
        function g    = get.invEfficiency(this)
            g = this.bmmr_.invEfficiency;
        end
        function g    = get.isDecayCorrected(this)
            g = this.bmmr_.isDecayCorrected;
        end
        function this = set.isDecayCorrected(this, s)
            this.bmmr_.isDecayCorrected = s;
            this.img = this.bmmr_.img;
        end
        function g    = get.isotope(this)
            g = this.bmmr_.isotope;
        end
        function g    = get.mask(this)
            g = this.bmrr_.mask;
        end
        function g    = get.sessionData(this)
            g = this.bmmr_.sessionData;
        end
        function g    = get.specificActivity(this)
            g = this.bmmr_.specificActivity;
        end
        function g    = get.taus(this)
            g = this.bmmr_.taus;
        end
        function g    = get.time0(this)
            g = this.bmmr_.time0;
        end
        function this = set.time0(this, s)
            this.bmmr_.time0 = s;
        end
        function g    = get.timeDuration(this)
            g = this.bmmr_.timeDuration;
        end
        function this = set.timeDuration(this, s)
            this.bmmr_.timeDuration = s;
        end
        function g    = get.timeF(this)
            g = this.bmmr_.timeF;
        end
        function this = set.timeF(this, s)
            this.bmmr_.timeF = s;
        end
        function g    = get.timeMidpoints(this)
            g = this.bmmr_.timeMidpoints;
        end
        function g    = get.times(this)
            g = this.bmmr_.times;
        end
        function w    = get.W(~)
            w = this.bmmr_.W;
        end

        %%
        
        function b = activityInterpolants(this, varargin)
            b = this.bmmr_.activityInterpolants;
        end
        function c = countInterpolants(this, varargin)
            c = this.bmmr_.countInterpolants;
        end
        function this = buildCalibrated(this)
        end
        function dt_ = datetime(this)
            dt_ = this.bmmr_.datetime;
        end
        function d = decayInterpolants(this)
            d = this.bmmr_.decayInterpolants;
        end
        function this = petobs(this)
            this.bmmr_ = this.bmmr_.petobs;
        end
        function        plot(this)
            plot(this.bmmr_);
        end
        function this = saveas(this, fqfn)
            this.bmmr_ = this.bmmr_.saveas(fqfn);
        end
        function this = shiftTimes(this, Dt)
        end
        function this = shiftWorldlines(this)
        end
        function s = specificActivityInterpolants(this)
            s = this.bmmr_.specificActivityInterpolants;
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.bmmr_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.bmmr_.timeMidpointInterpolants(varargin{:});
        end         
        
        %% borrowed from mlfourd.NumericalNIfTId
        
        function this = blurred(this, blur)
            this = this.bmmr_.blurred(blur);
        end
        function this = masked(this, msk)
            this = this.bmmr_.masked(msk);
        end
        function this = thresh(this, t)
            this = this.bmmr_.thresh(t);
        end
        function this = threshp(this, p)
            this = this.bmmr_.threshp(p);
        end
        function this = timeContracted(this)
            this = this.bmmr_.timeContracted;
        end
        function this = timeSummed(this)
            this = this.bmmr_.timeSummed;
        end 
        function this = uthresh(this, u)
            this = this.bmmr_.uthresh(u);
        end
        function this = uthreshp(this, p)
            this = this.bmmr_.uthreshp(p);
        end
        function this = volumeContracted(this)
            this = this.bmmr_.volumeContracted;
        end
        function this = volumeAveraged(this)
            this = this.bmmr_.volumeAveraged;
        end    
        function this = volumeSummed(this)
            this = this.bmmr_.volumeSummed;
        end    
        function v    = voxelVolume(this)
            v = this.bmmr_.voxelVolume;
        end
        
 		function this = BiographMMR0(cmp, varargin)
            this = this@mlfourd.NIfTIdecoratorProperties(cmp, varargin{:});
            
            % avoid decorator redundancy
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR0'))
                this = this.component;
                return
            end
            
            this = this.append_descrip('decorated by BiographMMR0');
            this.bmmr_ = mlsiemens.BiographMMR(cmp, varargin{:});
        end
        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        bmmr_
    end
    
    methods (Access = protected)
        function img  = activity2petCounts(this, img)
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
        function yi   = pchip(~, x, y, xi)
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
        function img  = petCounts2activity(this, img)
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
    
 end

