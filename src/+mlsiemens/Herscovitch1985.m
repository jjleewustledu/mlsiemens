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
        labsTable
        useSI = true;
    end
    
    properties (Dependent)
        W
    end
    
    methods (Static)
        function those = constructAifs(sessd)
            import mlsiemens.*;
            those = {};
            tracers = {'OC' 'OO' 'HO'};
            for t = 1:length(tracers)
                sessd.tracer = tracers{t};
                for s = 1:3
                    sessd.snumber = s;
                    try                        
                        this = Herscovitch1985.constructTracerAifState(sessd);
                        this.plotAif;
                    catch ME
                        fprintf('mlsiemens.Herscovitch1985.constructAifs failed for s->%i\n', s);
                        dispwarning(ME);
                    end
                end
            end
        end
        function those = constructPhysiologicals(sessd)
            import mlsiemens.*;
            sessdFdg = sessd;
            those = {};
            thoseCbf = {};
            thoseCbv = {};
            thoseCmro2 = {};
            for s = 1:3
                sessd.snumber = s;
                try
                    thoseCbf = [thoseCbf Herscovitch1985.constructCbf(sessd)]; %#ok<AGROW>
                catch 
                    fprintf('mlsiemens.Herscovitch1985.constructCbf failed for s->%i\n', s);
                end
            end
            for s = 1:3
                sessd.snumber = s;
                try
                    thoseCbv = [thoseCbv Herscovitch1985.constructCbv(sessd)]; %#ok<AGROW>
                catch 
                    fprintf('mlsiemens.Herscovitch1985.constructCbv failed for s->%i\n', s);
                end
            end
            for s = 1:3
                sessd.snumber = s;
                try
                    thoseCmro2 = [thoseCmro2 Herscovitch1985.constructCmro2( ...
                        sessd, thoseCbf{end}.cbf, thoseCbv{end}.cbv)]; %#ok<AGROW>
                catch 
                    fprintf('mlsiemens.Herscovitch1985.constructCmro2 failed for s->%i\n', s);
                end
            end
            
            return
            
%             thoseCmrglc = Herscovitch1985.constructCmrglc(sessdFdg, thoseCbv{end}.cbv); 
%             if (~isempty(thoseCmrglc))            
%                 dgo = thoseCmrglc.product;
%                 dgo.fqfileprefix = thoseCmrglc.sessionData.agiOpFdg('typ','fqfp');
%                 dgo.img = thoseCmrglc.product.niftid.img - (1/6)*thoseCmro2{end}.product.niftid.img; % \mumol/min/hg
%                 thoseCmrglc.save(dgo);
% 
%                 ogi = thoseCmrglc.product;
%                 ogi.fqfileprefix = thoseCmrglc.sessionData.ogiOpFdg('typ','fqfp');
%                 ogi.img = thoseCmro2{end}.product.niftid.img ./ thoseCmrglc.product.niftid.img; % \mumol/min/hg
%                 thoseCmrglc.save(ogi);
%             end
        end    
        function this = constructCbf(sessd)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'HO';
            if (lexist(sessd.cbfOpFdg, 'file'))
                this.cbf = sessd.cbfOpFdg('typ','mlfourd.ImagingContext');
                return
            end
            this = Herscovitch1985.constructTracerState(sessd);
            this = this.buildA1A2;
            this = this.buildCbfMap;
            %view(this.product);
            this.saveNiigz;
            this.saveFourdfp;
        end
        function this = constructCbv(sessd)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'OC';       
            if (lexist(sessd.cbvOpFdg, 'file'))
                this.cbv = sessd.cbvOpFdg('typ','mlfourd.ImagingContext');
                return
            end
            this = Herscovitch1985.constructTracerState(sessd);    
            this = this.buildCbvMap;
            %view(this.product);
            this.saveNiigz;
            this.saveFourdfp;
        end     
        function this = constructCmro2(sessd, cbf_, cbv_)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'OO';        
            if (lexist(sessd.oefOpFdg, 'file') && lexist(sessd.cmro2OpFdg, 'file'))
                this.product = sessd.cmro2OpFdg('typ', 'numericalNiftid');
                return
            end    
            this = Herscovitch1985.constructTracerState(sessd);
            labs = this.readLaboratories;
            this = this.buildB1B2;
            this = this.buildB3B4;
            this.cbf = cbf_;
            this.cbv = cbv_;
            this = this.buildOefMap;
            %view(this.product);
            save(this.product);
            this = this.buildCmro2Map(labs);
            %view(this.product);
            this.saveNiigz;
            this.saveFourdfp;      
        end
        function this = constructCmrglc(sessd, cbv_)
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'FDG';        
            this = Herscovitch1985.constructTracerState(sessd); 
            if (lexist(sessd.cmrglcOpFdg, 'file'))
                return
            end                  
            labs = this.readLaboratories;
            this = this.buildCmrglcMap(labs, cbv_);
            %view(this.product);
            this.saveNiigz;
            this.saveFourdfp; 
        end
        function this = constructTracerState(sessd, varargin)
            try
                setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
                
                import mlsiemens.*;
                [aif,scanner,mask] = Herscovitch1985.configAcquiredData(sessd, varargin{:});
                this = mlsiemens.Herscovitch1985( ...
                    'sessionData', sessd, ...
                    'scanner', scanner, ...
                    'aif', aif, ...
                    'mask', mask); % 'timeDuration', scanner.timeDuration, ...
            catch ME
                dispwarning(ME);
            end
        end
        function this = constructTracerAifState(sessd, varargin)
            try
                setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
                
                import mlsiemens.*;
                aif = Herscovitch1985.configAcquiredAifData(sessd, varargin{:});
                this = mlsiemens.Herscovitch1985( ...
                    'sessionData', sessd, ...
                    'scanner', [], ...
                    'aif', aif, ...
                    'mask', []); % 'timeDuration', scanner.timeDuration, ...
            catch ME
                dispwarning(ME);
            end
        end
        function [sessd,ct4rb,aa] = resolveOpFdg(sessd)
            %  @deprecated
            
            try
                sessf = sessd.sessionFolder;
                v = sessd.vnumber;
                
                import mlraichle.* mlsiemens.*;
                vloc = sessd.vLocation;
                assert(isdir(vloc));
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
        function molL = percentVolume2molL(fracVol)
            if (1 < fracVol)
                fracVol = fracVol/100;
            end
            P = 101.325; % kPa = J/L
            T = 310.15;  % body temp in degrees Kelvin
            Rtilde = 8.31605; % back-calculated from http://hiq.linde-gas.com/en/specialty_gases/gas_concentration_units_converter.html
            molL = fracVol*P/(Rtilde*T);
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
            this.aif_ = this.aif_.setTime0ToInflow;
            if (strcmp(this.sessionData.tracer, 'HO') || strcmp(this.sessionData.tracer, 'OO'))
                this = this.deconvolveAif;
            end
            this.aif_.timeDuration = this.configAifTimeDuration(this.sessionData.tracer);    
            if (~isempty(this.scanner_))
                %if (~strcmp(this.sessionData.tracer, 'FDG'))
                    this.scanner_ = this.scanner.setTime0ToInflow;
                %end
                this.scanner_.timeDuration = this.aif.timeDuration;
            end
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
            sc.img = this.a1*sc.img.*sc.img + this.a2*sc.img;
            sc = sc.blurred(this.petPointSpread);
            %sc = sc.uthresh(this.CBF_UTHRESH);
            sc.fqfilename = this.sessionData.cbfOpFdg('typ','fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCbvMap(this)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = 100*sc.img*this.W/(this.RBC_FACTOR*this.BRAIN_DENSITY*this.aif.specificActivityIntegral);
            sc = sc.blurred(this.petPointSpread);
            sc.img = 100 * sc.img / max(max(max(sc.img)));
            sc.fqfilename = this.sessionData.cbvOpFdg('typ','fqfn');        
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
            nimg = this.oefNumer(sc.img);
            dimg = this.oefDenom;
            sc.img = this.is0to1(nimg./dimg);
            sc = sc.blurred(this.petPointSpread);
            sc.fqfilename = this.sessionData.oefOpFdg('typ','fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCmro2Map(this, labs)
            sc = this.scanner;
            sc = sc.petobs;
            cbf = this.sessionData.cbfOpFdg('typ','mlfourd.ImagingContext');
            oef = this.sessionData.oefOpFdg('typ','mlfourd.ImagingContext');
            if (this.useSI)
                sc.img = 1e3  * this.percentVolume2molL(labs.o2Content) * oef.niftid.img .* cbf.niftid.img; % \mumol/min/hg
            else                
                sc.img = 0.01 * labs.o2Content *                          oef.niftid.img .* cbf.niftid.img; % mL/min/hg
            end
            sc.fqfilename = this.sessionData.cmro2OpFdg('typ', 'fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCmrglcMap(this, labs, cbv_)
            cbv_ = mlfourd.ImagingContext(cbv_);
            downCbv = this.downsampleNii(cbv_.numericalNiftid);
            this.referenceMask_ = this.scanner_.mask;
            this.referenceMask_.fileprefix = 'mlsiemens_Herscovitch1985_buildCmrglcMap_referenceMask_';
            blurred = this.scanner.blurred(this.petPointSpread);
            this.scanner_.img = blurred.img;
            this = this.downsampleScanner;
            bk  = mlkinetics.BlomqvistKinetics( ...
                'aif', this.aif, ...
                'scanner', this.scanner_, ...
                'cbv', downCbv, ...
                'glc', labs.glc, ...
                'hct', labs.hct);
            this.scanner_.img = bk.buildCmrglcMap;
            %tmp = mlfourd.NIfTId.load(fullfile(this.sessionData.tracerLocation, 'mlsiemens_Herscovitch_builCmrglcMap_bk_buildCmrglcMap.nii.gz'));
            %this.scanner_.img = tmp.img;
            this.scanner_.img = this.scanner_.img .* downCbv.img * (0.6/this.BRAIN_DENSITY); % CMRglc units := mg glc/min/hg           
            this.scanner_.fileprefix = 'mlsiemens_Herscovitch1985_buildCmrglcMap_bk_buildCmrglcMap';
            if (this.useSI)
                this.scanner_.img = 5.55 * this.scanner_.img; % CMRglc units := \mumol glc/min/hg
                this.scanner_.fileprefix = 'mlsiemens_Herscovitch1985_buildCmrglcMap_bk_buildCmrglcMap_useSI';
            end
            this = this.upsampleScanner;
            this.product_ = mlfourd.ImagingContext(this.scanner_.component);
            this.product_.fqfilename = this.sessionData.cmrglcOpFdg('typ', 'fqfn');
        end
        function this = downsampleScanner(this)
            down = this.downsampleNii(this.scanner_);
            this.scanner_.img = down.img;
            this.scanner_.fqfilename = down.fqfilename;     
            this.scanner_.mmppix = down.mmppix;
            if (~isempty(this.scanner_.mask))
                this.scanner_.mask = this.downsampleNii(this.referenceMask_);
            end
        end
        function this = upsampleScanner(this)
            assert(~isempty(this.referenceMask_));            
            up = this.upsampleNii(this.scanner_, this.referenceMask_);
            this.scanner_.img = up.img;
            this.scanner_.fqfilename = up.fqfilename;   
            this.scanner_.mmppix = up.mmppix;          
            this.scanner_.mask = this.referenceMask_;
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
            nii0.filesuffix = '.nii.gz';
            nii0.save;
            niiRef.filesuffix = '.nii.gz';
            niiRef.save;
            fqfn222 = [nii0.fqfileprefix '_222.nii.gz'];
            mlbash(sprintf( ...
                'flirt -interp trilinear -in %s -ref %s -out %s -nosearch -applyxfm', ...
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
            
            if (strcmp(this.sessionData.tracer, 'OO'))
                this.plotAifOO;
                this.plotAifHOMetab;
                return
            end
            
            a = this.aif;
            a.plotDx;
            %figure;
            %plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s %s; idx0->%i, idxF->%i', ...
                sd.sessionPath, sd.tracer, a.index0, a.indexF));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            %plot(this.aifHOMetab);
            a = this.aifHOMetab;
            figure;
            plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s %s; idx0->%i, idxF->%i', ...
                sd.sessionPath, sd.tracer, a.index0, a.indexF));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            %plot(this.aifOO);
            a = this.aifOO;
            figure;
            plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifOO:\n%s %s; idx0->%i, idxF->%i', ...
                sd.sessionPath, sd.tracer, a.index0, a.indexF));
        end
        function plotCaprac(this)
            %plot(this.aif);
            a = this.aif;
            figure;
            plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotCaprac:\n%s %s; idx0->%i, idxF->%i', ...
                sd.sessionPath, sd.tracer, a.index0, a.indexF));
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
            title(sprintf( ...
                'AbstractHerscovitch1985.plotScannerWholebrain:\n%s %s; s.idx0->%i, s.idxF->%i; a.idx0->%i, a.idxF->%i', ...
                sd.sessionPath, sd.tracer, s.index0, s.indexF, a.index0, a.indexF)); 
        end         
        
        function labs = readLaboratories(this)
            tbl = readtable(fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Laboratory census.xlsx'), ...
                'Sheet', 'Sheet 1', ...
                'filetype', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false, 'DatetimeType', 'exceldatenum');            
            
            labs.o2Content = 20;
            for id = 1:length(tbl.date)                
                date_ = this.sessionData.sessionDate;
                date_.Hour = 0;
                date_.Minute = 0;
                date_.Second = 0;
                if (date_ == mldata.TimingData.datetimeConvertFromExcel2(tbl.date(id)))
                    labs.hct = tbl.Hct(id);
                    labs.glc = tbl.glc(id);
                    return
                end
            end
            error('mlsiemens:soughtDataNotFound', 'XlsxObjScanData.crv');
        end        
        
        function save(this, varargin)
            this.saveFourdfp(varargin{:});
            this.saveNiigz(varargin{:});
        end
        function saveFourdfp(this, varargin)
            ip = inputParser;
            addOptional(ip, 'obj', this.product, @(x) isa(x, 'mlfourd.INIfTI') || isa(x, 'mlfourd.ImagingContext'));
            parse(ip, varargin{:});
            obj = ip.Results.obj;
            
            fs0 = obj.filesuffix;
            obj.filesuffix = '.4dfp.ifh';
            obj.save;
            obj.filesuffix = fs0;
        end
        function saveNiigz(this, varargin)
            ip = inputParser;
            addOptional(ip, 'obj', this.product, @(x) isa(x, 'mlfourd.INIfTI') || isa(x, 'mlfourd.ImagingContext'));
            parse(ip, varargin{:});
            obj = ip.Results.obj;
            
            fs0 = obj.filesuffix;
            obj.filesuffix = '.nii.gz';
            obj.save;
            obj.filesuffix = fs0;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        referenceMask_
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
                'fqfilename',        fullfile(mand.filepath, mand.crv), ...
                'invEfficiency',     Herscovitch1985.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'isotope', '15O');
            mask = sessdFdg.brainmaskBinarizeBlended('typ','mlfourd.ImagingContext');
            if (~lexist(sessd.tracerResolvedFinalOpFdg, 'file'))
                error('mlsiemens:fileNotFound', 'Herscovitch.configAcquiredData');
            end
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
        function aif = configAcquiredAifData(sessd, varargin)  
            ip = inputParser;
            addOptional(ip, 'crv', '', @ischar);
            parse(ip, varargin{:});
            
            import mlsiemens.*;
            if (strcmp(sessd.tracer, 'FDG'))
                aif = Herscovitch1985.configAcquiredFdgAif(sessd);
                return
            end
            
            mand = XlsxObjScanData('sessionData', sessd);
            aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        fullfile(mand.filepath, mand.crv), ...
                'invEfficiency',     Herscovitch1985.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeLabel), ...
                'isotope', '15O');
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
        function aif = configAcquiredFdgAif(sessd)  
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
            if (lexist(this.deconvolveAifFn, 'file'))
                load(  this.deconvolveAifFn)
                this.aif_ = a; %#ok<NODEF>
                return
            end
            
            a = this.aif;
            plaif = mlswisstrace.DeconvolvingPLaif.runPLaif( ...
                a.times(1:a.indexF), a.specificActivity(1:a.indexF), this.aif.tracer);
            a.specificActivity(1:a.indexF) = plaif.itsDeconvSpecificActivity;
            a.counts = a.specificActivity / a.counts2specificActivity;
            a.time0 = plaif.t0;
            save(this.deconvolveAifFn, 'a', '-v7.3');
            this.aif_ = a;
        end
        function fqfn = deconvolveAifFn(this)
            fqfn = fullfile(this.aif.sessionData.vLocation, ...
                sprintf('mlsiemens_Herscovitch1985_deconvolveAif_%s.mat', this.aif.tracer));
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

