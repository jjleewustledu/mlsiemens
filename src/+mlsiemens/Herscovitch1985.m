classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985  

	%  $Revision$
 	%  was created 06-Feb-2017 21:32:54
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

    properties
        MAGIC = 1
        canonFlows = 10:10:100 % mL/100 g/min
    end
    
    methods (Static)
        function [sessd,ct4rb,aa] = resolveOpFdg(varargin)
            ip = inputParser;
            addRequired(ip, 'obj', @isstruct);
            %addOptional(ip, 'tracer', 'FDG', @ischar);
            parse(ip, varargin{:});
            
            try
                sessf = ip.Results.obj.sessf;
                v = ip.Results.obj.v;
                
                import mlraichle.* mlsiemens.*;
                studyd = StudyData;
                vloc = fullfile(studyd.subjectsDir, sessf, sprintf('V%i', v), '');
                assert(isdir(vloc));
                sessd = SessionData('studyData', studyd, 'sessionPath', fileparts(vloc));
                sessd.vnumber = v;
                sessd.attenuationCorrected = true;
                %sessd.tracer = ip.Results.tracer;

                pushd(vloc);
                diary(sprintf('Herscovitch1985.resolveOpFdg_%s_V%i.log', sessf, v));
                imgs = Herscovitch1985.theImages(sessd);
                ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                    'sessionData', sessd, 'theImages', imgs, 'NRevisions', 1);
                ct4rb.resolve;
                ct4rb.t4img_4dfp(imgs{2}, sessd.ho('typ','fqfp'));
                ct4rb.t4img_4dfp(imgs{3}, sessd.oo('typ','fqfp'));
                ct4rb.t4img_4dfp(imgs{4}, sessd.oc('typ','fqfp'));
                aa = Herscovitch1985.aparcAseg(sessd, ct4rb);
                popd(vloc);
            catch ME
                handwarning(ME);
            end
        end
        function imgs = theImages(sessd)
            assert(isa(sessd, 'mlpipeline.ISessionData'));
            sessd.rnumber = 1;
            sessd.tracer = 'FDG'; fdgSumt = sessd.tracerResolvedSumt1('typ','fqfp');
            sessd.snumber = 1;
            sessd.tracer = 'HO';  hoSumt1 = sessd.tracerRevisionSumt('typ','fqfp');
            sessd.tracer = 'OO';  ooSumt1 = sessd.tracerRevisionSumt('typ','fqfp');
            sessd.tracer = 'OC';  ocSumt1 = sessd.tracerRevisionSumt('typ','fqfp');
            sessd.snumber = 2;
            sessd.tracer = 'HO';  hoSumt2 = sessd.tracerRevisionSumt('typ','fqfp');
            sessd.tracer = 'OO';  ooSumt2 = sessd.tracerRevisionSumt('typ','fqfp');
            sessd.tracer = 'OC';  ocSumt2 = sessd.tracerRevisionSumt('typ','fqfp');
            lns_4dfp(fdgSumt);
            lns_4dfp(hoSumt1);
            lns_4dfp(ooSumt1);
            lns_4dfp(ocSumt1);
            lns_4dfp(hoSumt2);
            lns_4dfp(ooSumt2);
            lns_4dfp(ocSumt2);
                                  T1      = sessd.T1('typ','fqfp');
            imgs = cellfun(@(x) mybasename(x), {fdgSumt hoSumt1 ooSumt1 ocSumt1 T1}, 'UniformOutput', false);
            %imgs = cellfun(@(x) mybasename(x), {fdgSumt hoSumt1 hoSumt2 ooSumt1 ooSumt2 ocSumt1 ocSumt2 T1}, 'UniformOutput', false);
        end
        function aa = aparcAseg(sessd, ct4rb)
            if (lexist(sessd.aparcAsegBinarized('typ','.4dfp.ifh'), 'file'))
                aa = mlpet.PETImagingContext(sessd.aparcAsegBinarized('typ','.4dfp.ifh'));
                return
            end
            
            aa = sessd.aparcAseg('typ', 'mgz');
            aa = sessd.mri_convert(aa, 'aparcAseg.nii.gz');
            aa = mybasename(aa);
            sessd.nifti_4dfp_4(aa);
            aa = ct4rb.t4img_4dfp(sessd.T1('typ','fp'), aa, 'opts', '-n'); 
            aa = mlfourd.ImagingContext([aa '.4dfp.ifh']);
            aa.numericalNiftid;
            aa = aa.binarized;
            aa.saveas(['aparcAsegBinarized_' ct4rb.resolveTag '.4dfp.ifh']);
        end 
        function rho    = estimatePetdyn(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));  
            
            import mlpet.*;
            f     = AbstractHerscovitch1985.cbfToInvs(cbf);
            lam   = AbstractHerscovitch1985.LAMBDA;
            lamd  = LAMBDA_DECAY;  
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
            sc = sc.blurred(this.petPointSpread);
            sc = sc.uthresh(this.CBV_UTHRESH);
            sc.fileprefix = this.sessionData.cbv('typ','fp','suffix',this.resolveTag);        
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildCmro2Map(this, labs)
            sc = this.scanner;
            sc =sc.petobs;
            sc.img = sc.img*this.MAGIC;
            cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','suffix',this.resolveTag);
            oef = obj.sessionData.oef('typ','mlpet.PETImagingContext','suffix',this.resolveTag);
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
            
            import mlpet.*;
            aif.specificActivity = aif.specificActivity*(Blood.PLASMADN/Blood.BLOODDEN);
        end
        function aifi = estimateAifOOIntegral(this)
            aifi = 0.01*this.SMALL_LARGE_HCT_RATIO*this.BRAIN_DENSITY*this.aifOO.specificActivityIntegral;
        end
        function buildT4Resolved(this)
            import mlfourdfp.*;
            fv = FourdfpVisitor;
            sessFdg = this.sessionData;
            sessFdg.tracer = 'FDG';
            fv.lns_4dfp([sessd.tracerRevision('typ','fqfp') '_on_resolved_sumt'], ...
                        [sessd.tracerRevision('typ','fqfp') 'OnResolved_sumt']);
            
            ct4rb = CompositeT4ResolveBuilder();
        end
        function buildResolvedAndPasted(this)
        end
        function buildResolvedOpFdg(this)
        end
        
        %% plotting support 
        
        function plotAif(this)
            figure;
            a = this.aif;
            idxF = a.indexF + 40;
            plot(a.times(a.index0:idxF), a.becquerelsPerCC(a.index0:idxF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            figure;
            a = this.aifHOMetab;
            idxF = a.indexF + 40;
            plot(a.times(a.index0:idxF), a.becquerelsPerCC(a.index0:idxF)/10e3);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            figure;
            a = this.aifOO;
            idxF = a.indexF + 40;
            plot(a.times(a.index0:idxF), a.becquerelsPerCC(a.index0:idxF)/10e3);
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

