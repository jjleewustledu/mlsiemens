classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985  

	%  $Revision$
 	%  was created 06-Feb-2017 21:32:54
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

    properties (Constant)
        INV_EFF_TWILITE = 0.446548 * 1e3
        INV_EFF_MMR = 1.1551
    end
    
    properties
        MAGIC = 1
        canonFlows = 5:5:200 % mL/100 g/min
        useSI = false;
    end
    
    properties (Dependent)
        W
    end
    
    methods (Static)
        function [thisHO,thisOC,thisOO,thisFDG] = constructPhysiologicals(sessd, crv, labs)
            import mlsiemens.*;
            thisHO  = Herscovitch1985.constructCbf(sessd, crv);
            thisOC  = Herscovitch1985.constructCbv(sessd, crv);
            thisOO  = Herscovitch1985.constructCmro2(sessd, crv, labs);
            thisFDG = Herscovitch1985.constructCmrglc(sessd, labs);
        end   
        function this = constructCbf(sessd, crv)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'HO';
            this = Herscovitch1985.constructTracerState(sessd, crv);
            this = this.buildA1A2;
            this = this.buildCbfMap;
            view(this.product);
            save(this.product);
        end
        function this = constructCbv(sessd, crv)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'OC';            
            this = Herscovitch1985.constructTracerState(sessd, crv);
            this = this.buildCbvMap;
            view(this.product);
            save(this.product); 
        end     
        function this = constructCmro2(sessd, crv, labs)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'OO';            
            this = Herscovitch1985.constructTracerState(sessd, crv);
            this = this.buildB1B2;
            this = this.buildB3B4;
            this = this.buildOefMap;
            view(this.product);
            save(this.product);
            this = this.buildCmro2Map(labs);
            view(this.product);
            save(this.product);        
        end
        function this = constructCmrglc(sessd, labs)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'FDG';            
            this = Herscovitch1985.constructTracerState(sessd);   
            this = this.buildCmrglcMap(labs);
            view(this.product);
            save(this.product);   
        end
        function this = constructTracerState(sessd, varargin)
            import mlsiemens.*;
            [aif,scanner,mask] = Herscovitch1985.configAcquiredData(sessd, varargin{:});
 			this = mlsiemens.Herscovitch1985( ...
                'sessionData', sessd, ...
                'scanner', scanner, ...
                'aif', aif, ...
                'mask', mask); % 'timeDuration', scanner.timeDuration, ...
        end
        function [sessd,ct4rb,aa] = resolveOpFdg(varargin)
            %  @deprecated
            
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
            %  @deprecated
            
            assert(isa(sessd, 'mlpipeline.ISessionData'));
            sessd.rnumber = 1;
            sessd.tracer = 'FDG'; fdgSumt = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.snumber = 1;
            sessd.tracer = 'HO';  hoSumt1 = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.tracer = 'OO';  ooSumt1 = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.tracer = 'OC';  ocSumt1 = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.snumber = 2;
            sessd.tracer = 'HO';  hoSumt2 = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.tracer = 'OO';  ooSumt2 = sessd.tracerResolvedFinalSumt('typ','fqfp');
            sessd.tracer = 'OC';  ocSumt2 = sessd.tracerResolvedFinalSumt('typ','fqfp');
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
            %  @deprecated
            
            if (lexist(sessd.aparcAsegBinarized('typ','.4dfp.ifh'), 'file'))
                aa = mlfourd.ImagingContext(sessd.aparcAsegBinarized('typ','.4dfp.ifh'));
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
        function fwhh = petPointSpread
            fwhh = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
    end
    
	methods
        
        %% GET
        
        function g = get.W(this)
            g = this.scanner.invEfficiency;
        end
        
        %%
        
 		function this = Herscovitch1985(varargin)
 			this = this@mlpet.AbstractHerscovitch1985(varargin{:});
            if (strcmp(this.sessionData.tracer, 'HO') || strcmp(this.sessionData.tracer, 'OO'))
                this = this.deconvolveAif;
            end
            this.aif_ = this.aif_.setTime0ToInflow;
            this.aif_.timeDuration = this.configAifTimeDuration(this.sessionData.tracer);    
            %if (~strcmp(this.sessionData.tracer, 'FDG'))
                this.scanner_ = this.scanner.setTime0ToInflow;
            %end
            this.scanner_.timeDuration = this.aif.timeDuration;
        end        
         
        function rho    = estimatePetdyn(this, aif, cbf)
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
                rho_ = (1/this.W)*f(r)*conv(aifbi, exp(-(f(r)/lam + lamd)*aifti));
                rho(r,:) = rho_(1:length(aifti));
            end
        end        
        function petobs = estimatePetobs(this, aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));
            
            rho = this.estimatePetdyn(aif, cbf);
            petobs = aif.dt*trapz(rho, 2);
        end
        
        function this = buildCalibrated(this)
            this.aif_ = this.aif.buildCalibrated;
            this.scanner_ = this.scanner.buildCalibrated;
        end
        function this = buildCbfMap(this)
            assert(~isempty(this.a1));
            assert(~isempty(this.a2));
            
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;            
            sc.img = this.a1*sc.img.*sc.img + this.a2*sc.img;
            sc = sc.blurred(this.petPointSpread);
            %sc = sc.uthresh(this.CBF_UTHRESH);
            sc.fileprefix = this.sessionData.cbfOpFdg('typ','fp');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCbvMap(this)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC; 
            sc.img = 100*sc.img*this.W/(this.RBC_FACTOR*this.BRAIN_DENSITY*this.aif.specificActivityIntegral);
            sc = sc.blurred(this.petPointSpread);
            %sc = sc.uthresh(this.CBV_UTHRESH);
            sc.fileprefix = this.sessionData.cbvOpFdg('typ','fp');        
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildOefMap(this)
            assert(~isempty(this.b1));
            assert(~isempty(this.b2));
            assert(~isempty(this.b3));
            assert(~isempty(this.b4));          
            this = this.ensureAifHOMetab;
            this = this.ensureAifOO;
            this = this.ensureAifOOIntegral;
            
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;
            nimg = this.oefNumer(sc.img);
            dimg = this.oefDenom;
            sc.img = this.is0to1(nimg./dimg);
            sc = sc.blurred(this.petPointSpread);
            sc.fileprefix = this.sessionData.oefOpFdg('typ','fp');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCmro2Map(this, labs)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;
            cbf = this.sessionData.cbfOpFdg('typ','mlfourd.ImagingContext');
            oef = this.sessionData.oefOpFdg('typ','mlfourd.ImagingContext');
            sc.img = 0.01*labs.o2Content*oef.niftid.img.*cbf.niftid.img;
            sc.fileprefix = this.sessionData.cmro2OpFdg('typ', 'fp');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCmrglcMap(this, labs)
            cbv = this.sessionData.cbvOpFdg('typ', 'numericalNiftid');
            this.scanner_ = this.scanner.blurred(this.petPointSpread);
            this = this.downsampleScanner;
%             bk  = mlkinetics.BlomqvistKinetics( ...
%                 'aif', this.aif, ...
%                 'scanner', this.scanner_, ...
%                 'cbv', this.downsampleNii(cbv), ...
%                 'glc', labs.glc);
%             this.scanner_.img = bk.buildCmrglcMap;
            tmp = mlfourd.NIfTId.load(fullfile(this.sessionData.tracerLocation, 'mlsiemens_Herscovitch_builCmrglcMap_bk_buildCmrglcMap.nii.gz'));
            this.scanner_.img = tmp.img;
            if (this.useSI)
                this.scanner_.img = 0.0555 * thius.scanner_.img;
            end
            this = this.upsampleScanner;
            this.product_ = mlfourd.ImagingContext(this.scanner_.component);
            this.product_.fileprefix = this.sessionData.cmrglcOpFdg('typ', 'fp');
        end
        function this = downsampleScanner(this)
            this.samplingRef_ = this.scanner_;
            down = this.downsampleNii(this.scanner_);
            this.scanner_.img = down.img;
            this.scanner_.fqfilename = down.fqfilename;     
            this.scanner_.mmppix = down.mmppix;
            if (~isempty(this.scanner_.mask))
                this.scanner_.mask = this.downsampleNii(this.samplingRef_.mask);
            end
        end
        function this = upsampleScanner(this)
            assert(~isempty(this.samplingRef_));            
            up = this.upsampleNii(this.scanner_, this.samplingRef_);
            this.scanner_.img = up.img;
            this.scanner_.fqfilename = up.fqfilename;   
            this.scanner_.mmppix = up.mmppix;          
            this.scanner_.mask = this.samplingRef_.mask;
        end
        function nii  = downsampleNii(~, nii0)
            nii0.filesuffix = '.nii.gz';
            nii0.save;
            fqfn444 = [nii0.fqfileprefix '_444.nii.gz'];
            mlbash(sprintf( ...
                'flirt -interp nearestneighbour -in %s -ref %s -out %s -nosearch -applyisoxfm 4', ...
                nii0.fqfilename, nii0.fqfilename, fqfn444));
            nii = mlfourd.NIfTId.load(fqfn444);           
        end
        function nii  = upsampleNii(~, nii0, niiRef)
            fqfn222 = [nii0.fqfileprefix '_222.nii.gz'];
            mlbash(sprintf( ...
                'flirt -interp nearestneighbour -in %s -ref %s -out %s -nosearch -applyxfm', ...
                nii0.fqfilename, niiRef.fqfilename, fqfn222));
            nii = mlfourd.NIfTId.load(fqfn222);          
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
            %plot(this.aif);
            a = this.aif;
            idxF = a.indexF;
            figure;
            plot(a.times(a.index0:idxF), a.specificActivity(a.index0:idxF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            %plot(this.aifHOMetab);
            a = this.aifHOMetab;
            idxF = a.indexF;
            figure;
            plot(a.times(a.index0:idxF), a.specificActivity(a.index0:idxF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            %plot(this.aifOO);
            a = this.aifOO;
            idxF = a.indexF;
            figure;
            plot(a.times(a.index0:idxF), a.specificActivity(a.index0:idxF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifOO:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotCaprac(this)
            %plot(this.aif);
            a = this.aif;
            idxF = a.indexF;
            figure;
            plot(a.times(a.index0:idxF), a.specificActivity(a.index0:idxF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotCaprac:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotScannerWholebrain(this)
            s = this.scanner;
            s = s.volumeAveraged(s.mask);            
            
%             this  = this.ensureMask;
%             mskvs = this.mask.volumeSummed;
%             
%             s    = this.scanner;
%             lent = s.indexF - s.index0 + 1;
%             wc   = zeros(1, lent);
%             for ti = s.index0:s.indexF
%                 wc(ti) = squeeze( ...
%                     sum(sum(sum(s.specificActivity(:,:,:,ti).*this.mask.niftid.img))))/ ...
%                     this.MAGIC/mskvs.double;
%             end
            
            plot(s.times(s.index0:s.indexF)-s.times(s.index0), s.specificActivity(s.index0:s.indexF));
            hold on   
            a = this.aif;
            plot(a.times(a.index0:a.indexF)-a.times(a.index0), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotScannerWholebrain:\n%s %s', sd.sessionPath, sd.tracer));
        end 
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        samplingRef_
    end
    
    methods (Static, Access = private)
        function [aif,scanner,mask] = configAcquiredData(sessd, varargin)  
            ip = inputParser;
            addOptional(ip, 'crv', '', @ischar);
            parse(ip, varargin{:});
            
            import mlsiemens.*;
            tracer_ = sessd.tracer;
            if (strcmp(tracer_, 'FDG'))
                [aif,scanner,mask] = Herscovitch1985.configAcquiredFdg(sessd);
                return
            end
            sessdFdg = sessd;
            sessdFdg.tracer = 'FDG';
            
            mand = XlsxObjScanData('sessionData', sessd);
            aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        fullfile(mand.filepath, ip.Results.crv), ...
                'invEfficiency',     Herscovitch1985.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'isotope', '15O');
            mask = sessdFdg.brainmaskBinarizeBlended('typ','mlfourd.ImagingContext');
            scanner = mlsiemens.BiographMMR( ...
                sessd.tracerResolvedFinalOpFdg('typ','niftid'), ...
                'sessionData',       sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'invEfficiency',     Herscovitch1985.INV_EFF_MMR, ...
                'manualData',        mand, ...
                'mask',              mask);
            scanner.dt = 1;
            scanner.isDecayCorrected = false;
        end
        function [aif,scanner,mask] = configAcquiredFdg(sessd)  
            tracer_ = 'FDG';
            sessd.tracer = tracer_;
            
            import mlsiemens.*;
            mand = XlsxObjScanData('sessionData', sessd);
            aif = mlcapintec.Caprac( ...
                'fqfilename',        sessd.CCIRRadMeasurements, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'isotope', '18F');
            mask = sessd.brainmaskBinarizeBlended('typ','mlfourd.ImagingContext');
            scanner = mlsiemens.BiographMMR( ...
                sessd.tracerResolvedFinal('typ','niftid'), ...
                'sessionData',       sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'invEfficiency',     Herscovitch1985.INV_EFF_MMR, ...
                'manualData',        mand, ...
                'mask',              mask);
            scanner.dt = 1;
            scanner.isDecayCorrected = false;
        end
        function tD = configAifTimeDuration(tracer_)
            switch (tracer_)
                case 'HO'
                    tD = 40;
                case 'OO'
                    tD = 40;
                case {'OC' 'CO'}
                    tD = 60;
                case 'FDG'
                    tD = 3540;
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
    end
    
    methods (Access = private)
        function this = deconvolveAif(this)
            if (lexist(sprintf('mlsiemens_Herscovitch1985_deconvolveAif_%s.mat', this.aif.tracer), 'file'))
                load(  sprintf('mlsiemens_Herscovitch1985_deconvolveAif_%s.mat', this.aif.tracer))
                this.aif_ = a; %#ok<NODEF>
                return
            end
            
            a = this.aif;
            plaif = mlswisstrace.DeconvolvingPLaif.runPLaif( ...
                a.times(1:a.indexF), a.specificActivity(1:a.indexF), this.aif.tracer);
            a.specificActivity(1:a.indexF) = plaif.itsDeconvSpecificActivity;
            a.counts = a.specificActivity / a.counts2specificActivity;
            a.time0 = plaif.t0;
            save(sprintf('mlsiemens_Herscovitch1985_deconvolveAif_%s.mat', this.aif.tracer), 'a', '-v7.3');
            this.aif_ = a;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

