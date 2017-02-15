classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985  

	%  $Revision$
 	%  was created 06-Feb-2017 21:32:54
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    properties
        MAGIC = 1
        TIME_DURATION = 60
        canonFlows = 10:10:100 % mL/100 g/min
    end
    
    methods (Static)        
        function rho    = estimatePetdyn(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));  
            
            import mlpet.*;
            f     = AbstractHerscovitch1985.cbfToInvs(cbf);
            lam   = AbstractHerscovitch1985.LAMBDA;
            lamd  = AbstractHerscovitch1985.LAMBDA_DECAY;  
            aifti = ensureRowVector(aif.times(           aif.index0:aif.indexF) - aif.times(aif.index0));
            aifbi = ensureRowVector(aif.specificActivity(aif.index0:aif.indexF));
            rho   = zeros(length(f), length(aifti));
            for r = 1:size(rho,1)
                rho_ = (1/aif.W)*f(r)*conv(aifbi, exp(-(f(r)/lam + lamd)*aifti));
                rho(r,:) = rho_(1:length(aifti));
            end
        end        
        function petobs = estimatePetobs(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));
            
            rho = mlsiemens.Herscovitch1985.estimatePetdyn(aif, cbf);
            petobs = aif.dt*trapz(rho, 2);
        end
        function fwhh   = petPointSpread
            fwhh = mlpet.MMRRegistry.instance.petPointSpread;
            fwhh = mean(fwhh);
        end
    end
    
	methods 		  
 		function this = Herscovitch1985(varargin)
 			this = this@mlpet.AbstractHerscovitch1985(varargin{:});
        end
        
        function this = buildCbvMap(this)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC; 
            sc.img = 100*sc.img*this.aif.W/(this.RBC_FACTOR*this.BRAIN_DENSITY*this.aif.specificActivityIntegral);
            sc.fileprefix = this.sessionData.cbv('typ', 'fp');
            sc = sc.blurred(this.petPointSpread);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildCmro2(this, labs)
            sc = this.scanner;
            sc =sc.petobs;
            sc.img = sc.img*this.MAGIC;
            cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','suffix','op_resolved');
            oef = obj.sessionData.oef('typ','mlpet.PETImagingContext','suffix','op_resolved');
            sc.img = 0.01*labs.o2Content*oef.niftid.img*cbf.niftid.img;
            sc.fileprefix = this.sessionData.cmro2('typ', 'fp');
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function aif  = estimateAifOO(this)
            this = this.ensureAifHOMetab;
            aif = this.aif;
            aif.specificActivity = this.aif.specificActivity - this.aifHOMetab.specificActivity;
        end
        function aif  = estimateAifHOMetab(this)
            aif       = this.aif;
            assert(this.ooFracTime > this.ooPeakTime);
            [~,idxP]  = max(aif.times > this.ooPeakTime);
            dfrac_dt  = this.fracHOMetab/(this.ooFracTime - this.ooPeakTime);
            fracVec   = zeros(size(aif.times));
            fracVec(idxP:aif.indexF) = dfrac_dt*(aif.times(idxP:aif.indexF) - aif.times(idxP));            
            aif.specificActivity = this.aif.specificActivity.*fracVec;
        end
        function aifi = estimateAifOOIntegral(this)
            aifi = 0.01*this.SMALL_LARGE_HCT_RATIO*this.BRAIN_DENSITY*this.aifOO.specificActivityIntegral;
        end
        
        %% plotting support 
        
        function plotAif(this)
            figure;
            a = this.aif;
            plot(a.times(a.index0:a.indexF), a.becquerelsPerCC(a.index0:a.indexF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            figure;
            a = this.aifHOMetab;
            plot(a.times(a.index0:a.indexF), a.becquerelsPerCC(a.index0:a.indexF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            figure;
            a = this.aifOO;
            plot(a.times(a.index0:a.indexF), a.becquerelsPerCC(a.index0:a.indexF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifOO:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotScannerWholebrain(this)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            s    = this.scanner;
            lent = s.indexF - s.index0 + 1;
            wc   = zeros(1, lent);
            for ti = s.index0:s.indexF
                wc(ti) = squeeze( ...
                    sum(sum(sum(s.becquerelsPerCC(:,:,:,ti).*this.mask.niftid.img))))/ ...
                    this.MAGIC/mskvs.double;
            end
            plot(s.times(s.index0:s.indexF)-s.times(s.index0), wc/10e3);
            hold on   
            a = this.aif;
            plot(a.times(a.index0:a.indexF)-a.times(a.index0), a.becquerelsPerCC(a.index0:a.indexF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotScannerWholebrain:\n%s %s', sd.sessionPath, sd.tracer));
        end 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

