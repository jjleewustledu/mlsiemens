classdef AutoradiographyBuilder < mlbayesian.AbstractDynamicProblem
	%% AUTORADIOGRAPHYBUILDER  

	%  $Revision$
 	%  was created 25-Jan-2017 17:51:52
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2016 John Joowon Lee. 
 	
    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193
        TIME_SUP = 120          % sec
        REUSE_STORED = true
        USE_RECIRCULATION = false
        INJECTION_RATE = 0.25   % < 0.5 for hand-injections
    end

    properties (Abstract)
        map 
    end
    
    properties
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL)'
    end
    
    properties (Dependent)  
        concentration_a
        concentration_obs
        
        pnum
        aif
        aifShift
        mask
        ecat
        ecatShift
        ecatSumtFilename
        dose
        duration
        volume
        product
    end
    
    methods %% GET
        function cobs = get.concentration_a(this)
            assert(~isempty(this.dependentData1));
            cobs = this.dependentData1;
        end
        function cobs = get.concentration_obs(this)
            assert(~isempty(this.dependentData));
            cobs = this.dependentData;
        end
        
        function p = get.pnum(~)
            p = str2pnum(pwd);
        end
        function a  = get.aif(this)
            assert(~isempty(this.aif_));
            a = this.aif_;
        end
        function a  = get.aifShift(this)
            assert(~isempty(this.aifShift_));
            a = this.aifShift_;
        end
        function m  = get.mask(this)
            assert(~isempty(this.mask_));
            m = this.mask_;
        end
        function e  = get.ecat(this)
            assert(~isempty(this.ecat_));
            e = this.ecat_;
        end
        function a  = get.ecatShift(this)
            assert(~isempty(this.ecatShift_));
            a = this.ecatShift_;
        end
        function fn = get.ecatSumtFilename(this)
            fn = fullfile(this.ecat.filepath, sprintf('%sho1_sumt.nii.gz', this.pnum));
        end
        function d  = get.dose(this)
            assert(~isempty(this.dose_));
            d = this.dose_;
        end
        function d  = get.duration(this)
            assert(~isempty(this.duration_));
            d = this.duration_;
        end
        function d  = get.volume(this)
            assert(~isempty(this.volume_));
            d = this.volume_;
        end
        function p  = get.product(this)
            p = this.product_;
        end
    end
    
    methods (Static)
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecat = ecat.volumeSummed;   
            import mlpet.*;
            [t_a,c_a] = AutoradiographyBuilder.shiftData( aif.times,  aif.wellCounts,               aifShift);
            [t_i,c_i] = AutoradiographyBuilder.shiftData(ecat.times, ecat.becquerels/ecat.nPixels, ecatShift); % well-counts/cc/s     
            dt  = min(min(aif.taus), min(ecat.taus));
            t   = min(t_a(1), t_i(1)):dt:min(t_a(end), t_i(end));
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function this = loadAif(varargin)  %#ok<VANUS>
            this = [];
        end
        function mask = loadMask(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',    [], @(x) lexist(x, 'file'));
            addOptional(p, 'iniftid', [], @(x) isa(x, 'mlfourd.INIfTI'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                mask = mlfourd.MaskingNIfTId.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iniftid))
                mask = p.Results.iniftid;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadMask');
        end      
        function ecat = loadEcat(varargin)
            p = inputParser;
            addOptional(p, 'fqfn', [],  @(x) lexist(x, 'file'));
            addOptional(p, 'ecat', [],  @(x) isa(x, 'mlpet.EcatExactHRPlus'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                ecat = mlpet.EcatExactHRPlus.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.ecat))
                ecat = p.Results.ecat;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadEcat');
        end
        function ecat = loadDecayCorrectedEcat(varargin)
            p = inputParser;
            addOptional(p, 'fqfn', [],  @(x) lexist(x, 'file'));
            addOptional(p, 'ecat', [],  @(x) isa(x, 'mlpet.DecayCorrectedEcat'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                ecat = mlpet.DecayCorrectedEcat.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.ecat))
                ecat = p.Results.ecat;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadDecayCorrectedEcat');
        end
        
        function f = invs_to_mLmin100g(f)
            f = 100 * 60 * f / mlpet.AutoradiographyBuilder.BRAIN_DENSITY;
        end
    end
    
	methods
 		function this = AutoradiographyBuilder(varargin) 
 			%% AUTORADIOGRAPHYBUILDER
            %  @param named sessionData is an mlpipeline.ISessionData

            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'concAShift', 0, @isnumeric);
            addParameter(ip, 'concObsShift', 0, @isnumeric);
            parse(ip, varargin{:});                            
            [times,manifold] = interpolateData(ip.Results);
 			this = this@mlbayesian.AbstractDynamicProblem(times, manifold);
            
            this.ecat_     = ip.Results.sessionData.ecat;
            this.aif_      = mlpet.BloodSucker('scannerData', this.ecat_, 'aifTimeShift', ip.Results.concAShift);
            this.mask_     = ip.Results.sessionData.mask('typ', 'mlfourd.NIfTId');
            this.dose_     = this.itsDose;
            this.duration_ = this.itsDuration;
            this.volume_   = this.itsVolume;
        end
        
        function dose = itsDose(this)
            taus              = this.times(2:end) - this.times(1:end-1);
            taus(this.length) = taus(this.length - 1);                       
            dose = this.concentration_obs * taus'; % time-integral
            dose = dose / this.itsVolume / this.itsDuration;
        end
        function dura = itsDuration(this)
            dura = this.times(end) - ...
                   this.times(this.indexTakeOff(this.concentration_obs));
        end
        function vol  = itsVolume(this)
            vol = this.mask.count * prod(this.mask.mmppix/10); % mL
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
            fprintf('FINAL STATS dose            %g\n', this.dose);
            fprintf('FINAL STATS duration        %g\n', this.duration);
            fprintf('FINAL STATS volume          %g\n', this.volume);
            fprintf('FINAL STATS mtt_obs         %g\n',   this.mtt_obs);
            fprintf('FINAL STATS mtt_a           %g\n',   this.mtt_a);
        end   
 	end     
    
    %% PROTECTED
    
    properties (Access = 'protected')
        aif_
        aifShift_ = 0
        mask_
        ecat_        
        ecatShift_
        dose_ 
        duration_
        volume_        
        product_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

