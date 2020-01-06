classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985 uses the model:
    %  rho_ = (1/this.W)*f(r)*conv(aifbi, exp(-(f(r)/lam + lamd)*aifti)).  
    %  See also mlsiemens.Herscovitch1985.estimatePetdyn.

	%  $Revision$
 	%  was created 06-Feb-2017 21:32:54
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Constant)
        REUSE = false
        REUSE_BAYES = false
        CHECK_VIEWS = false
        PS = 0.03169
    end
    
    properties
        MAGIC = 1
        canonFlows = 10:2:100 % mL/100 g/min, not to exceed 110 per Cook's distance in buildModelCbf
        labsTable
        
        useSI = true
    end
    
    properties (Dependent)
        INV_EFF_MMR
        INV_EFF_TWILITE
        W
        referenceWholebrainCbv
        regionTag
    end
    
    methods 
        
        %% GET
        
        function g = get.referenceWholebrainCbv(this)
            g = 3.8; % Ito Eur J Nucl Med Mol Imaging (2004) 31:635-643
        end
    end
    
    methods (Static)
        function [t,f,t4] = configT1001(sessd)
            assert(isa(sessd, 'mlpipeline.ISessionData'));
            pwd0 = pushd(sessd.vallLocation);
            
            f = sessd.reference.tracerRevisionAvgt('typ', 'fqfp');
            t = 'T1001';
            tm = 'T1001_mskt';
            res = mlpipeline.ResourcesRegistry.instance();
            cRB = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'blurArg', 1.5, ...
                'theImages', {f t}, ...
                'maskForImages', {'none' tm}, ...
                'resolveTag', 'op_fdgr1', ...
                'NRevisions', 1, ...
                'logPath', ensuredir(fullfile(sessd.vallLocation, 'Log', '')));
            cRB.neverMarkFinished = res.neverMarkFinished;
            cRB.ignoreFinishfile  = true;
            cRB = cRB.resolve; 
            t4 = cRB.t4s{1}{2};
            t = cRB.product{2};
            f = cRB.product{1};
            
            popd(pwd0);
        end
        function [m,ref] = configMask(sessd)
            assert(isa(sessd, 'mlpipeline.ISessionData'));
            pwd0 = pushd(sessd.vallLocation);
            fv = mlfourdfp.FourdfpVisitor;
                      
            aa = sessd.aparcAseg;
            aa.mgh;
            aa.niftid;
            aa.fourdfp;
            sfp = fullfile(pwd, fv.ensureSafeFileprefix(aa.fileprefix));
            aa.fqfileprefix = sfp;
            aa.save;
            
            import mlfourd.*;
            t4   = 'T1001r1_to_fdgv1r1_sumtr1_op_fdgr1_t4'; % _avgr1
            sfp1 = sprintf('%s_op_fdgr1', sfp);
            ref  = fullfile(pwd, sprintf('fdgr1_sumt'));
            fv.t4img_4dfp(t4, sfp, 'out', sfp1, 'options', ['-n -O' ref]);
            m = ImagingContext([sfp1 '.4dfp.hdr']);
            nn = m.numericalNiftid;
            nn = nn ~= 0 & nn ~= 43 & nn ~= 4 & nn ~= 14 & nn ~= 15; % exclude 4 ventricles
            nn.saveas([sfp1 '_mskb.4dfp.hdr']); 
            m = ImagingContext(nn);
            
            popd(pwd0);
        end
        function those = constructAifs(sessd)
            import mlsiemens.*;
            those = {};
            tracers = {'OC' 'OO' 'HO'};
            for t = 1:length(tracers)
                sessd.tracer = tracers{t};
                for s = 1:3
                    sessd.snumber = s;
                    try                        
                        this = Herscovitch1985.constructMinimalState(sessd);
                        this.plotAif;
                    catch ME
                        fprintf('mlsiemens.Herscovitch1985.constructAifs failed for s->%i\n', s);
                        dispwarning(ME);
                    end
                end
            end
        end
        function those = constructPhysiologicals(sessd, varargin)
            
            ip = inputParser;
            parse(ip, varargin{:});   
            
            import mlsiemens.Herscovitch1985.*;
            those = [constructPhysiologicals1(sessd, varargin{:}) ...
                     constructPhysiologicals2(sessd, varargin{:})];
        end  
        function this  = constructSingle(sessd, varargin)
            warning('off', 'mlsiemens:fileNotFound');   
            warning('off', 'MATLAB:table:ModifiedVarnames');
            import mlsiemens.*;
            if (lexist(sessd.tracerRevision))
                try
                    switch (sessd.tracer)
                        case 'HO'
                            this = Herscovitch1985.constructCbf(sessd, varargin{:});
                            view(this.product);
                        case 'OC'
                            this = Herscovitch1985.constructCbv(sessd, varargin{:});
                            view(this.product);
                        case 'OO'
                            this = Herscovitch1985.constructOef(sessd, varargin{:});
                            view(this.product);
                            this = Herscovitch1985.constructCmro2(sessd, varargin{:});
                            view(this.product);
                        case 'FDG'
                            this = Herscovitch1985_FDG.constructCmrglc(sessd, varargin{:});
                            view(this.product);
                        otherwise
                            error('mlsiemens:unsupportedSwitchcase', 'Herscovitch1985.consructSingle');
                    end
                catch ME
                    dispwarning(ME);
                end
            end
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'mlsiemens:fileNotFound');
        end
        function those = constructPhysiologicals1(sessd, varargin)
            
            ip = inputParser;
            addParameter(ip, 'tracer', {'HO' 'OO' 'OC'}, @(x) ischar(x) || iscell(x));
            parse(ip, varargin{:});            
            tracerRequest = ensureCell(ip.Results.tracer);
            
            import mlsiemens.*;
            sessd.attenuationCorrected = true;
            sessd.tracer = 'HO';
            Herscovitch1985.configT1001(sessd);
            Herscovitch1985.configMask(sessd);
            
            warning('off', 'mlsiemens:fileNotFound');   
            warning('off', 'MATLAB:table:ModifiedVarnames');
            thoseCbf = {};
            thoseCbv = {};
            thoseOef = {};
            thoseCmro2 = {};
            if (lstrfind(tracerRequest, 'HO'))
                for s = 1:3
                    sessd.snumber = s;
                    sessd.tracer = 'HO';
                    if (lexist(sessd.tracerRevision))
                        try
                            this = Herscovitch1985.constructCbf(sessd);
                            this.checkView;
                            thoseCbf = [thoseCbf this]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME);
                        end
                    end
                end
                thoseCbf = Herscovitch1985.productAverage(thoseCbf);
            end
            if (lstrfind(tracerRequest, 'OC'))
                for s = 1:3
                    sessd.snumber = s;
                    sessd.tracer = 'OC';
                    if (lexist(sessd.tracerRevision))
                        try
                            this = Herscovitch1985.constructCbv(sessd);
                            this.checkView;
                            thoseCbv = [thoseCbv this]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME);
                        end
                    end
                end
                thoseCbv = Herscovitch1985.productAverage(thoseCbv);
            end
            if (lstrfind(tracerRequest, 'OO'))
                for s = 1:3
                    sessd.snumber = s;
                    sessd.tracer = 'OO';
                    if (lexist(sessd.tracerRevision))
                        try
                            this = Herscovitch1985.constructOef(sessd, thoseCbf.product, thoseCbv.product);
                            this.checkView;
                            thoseOef = [thoseOef this]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME);
                        end
                    end
                end
                thoseOef = Herscovitch1985.productAverage(thoseOef);
                for s = 1:3
                    sessd.snumber = s;
                    sessd.tracer = 'OO';
                    if (lexist(sessd.tracerRevision))
                        try
                            this = Herscovitch1985.constructCmro2(sessd);
                            this.checkView;
                            thoseCmro2 = [thoseCmro2 this]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME);
                        end
                    end
                end
                thoseCmro2 = Herscovitch1985.productAverage(thoseCmro2);
            end
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'mlsiemens:fileNotFound');
            
            those = [thoseCbf thoseCbv thoseOef thoseCmro2];
        end        
        function this = constructCbf(sessd)
            import mlsiemens.*;
            if (lexist(sessd.cbfOpFdg, 'file') && mlsiemens.Herscovitch1985.REUSE)
                this.product = sessd.cbfOpFdg('typ','mlfourd.ImagingContext');
                return
            end
            this = Herscovitch1985.constructTracerState(sessd);
            this = this.buildA1A2;
            this = this.buildCbfMap;
            this.save;
        end
        function this = constructCbv(sessd)
            import mlsiemens.*;     
            if (lexist(sessd.cbvOpFdg, 'file') && mlsiemens.Herscovitch1985.REUSE)
                this.product = sessd.cbvOpFdg('typ','mlfourd.ImagingContext');
                return
            end
            this = Herscovitch1985.constructTracerState(sessd);    
            this = this.buildCbvMap;
            this.save;
        end     
        function this = constructOef(sessd, cbf_, cbv_)
            import mlsiemens.*;      
            if (lexist(sessd.oefOpFdg, 'file') && lexist(sessd.cmro2OpFdg, 'file') && mlsiemens.Herscovitch1985.REUSE)
                this.product = sessd.cmro2OpFdg('typ', 'numericalNiftid');
                return
            end    
            this = Herscovitch1985.constructTracerState(sessd);
            this = this.buildB1B2;
            this = this.buildB3B4;
            this.cbf_ = cbf_;
            this.cbv_ = cbv_;
            this = this.buildOefMap;
            this.save;     
        end
        function this = constructCmro2(sessd)
            import mlsiemens.*;       
            if (lexist(sessd.cmro2OpFdg, 'file') && lexist(sessd.oefOpFdg, 'file') && mlsiemens.Herscovitch1985.REUSE)
                this.product = sessd.cmro2OpFdg('typ', 'numericalNiftid');
                return
            end    
            this = Herscovitch1985.constructTracerState(sessd);
            labs = this.readLaboratories;
            this = this.buildCmro2Map(labs);
            this.save;       
        end
        function this = constructTracerState(sessd, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessd', @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, sessd, varargin{:});

            setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
            pwd0 = pushd(sessd.vallLocation);
            
            import mlsiemens.*;
            [aif,scanner,mask] = Herscovitch1985.configAcquiredData(sessd, varargin{:});
            Herscovitch1985.writetable( ...
                aif, ...
                fullfile(sessd.vallLocation, ['mlsiemens_Herscovitch1985_constructTracerState_aif_' sessd.tracerRevision('typ','fp') '.csv']))
            this = mlsiemens.Herscovitch1985( ...
                'sessionData', sessd, ...
                'scanner', scanner, ...
                'aif', aif, ...
                'mask', mask); % 'timeWindow', scanner.timeWindow, ...            
            this.plotAif;
            this.plotScanner
            saveFigures(sprintf('fig_mlsiemens_Herscovitch1985_constructTracerState_%s', sessd.tracerRevision('typ','fp')));  
            
            popd(pwd0);
        end
        function this = constructMinimalState(sessd, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sessd', @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, sessd, varargin{:});
            
            setenv('CCIR_RAD_MEASUREMENTS_DIR', fullfile(getenv('HOME'), 'Documents', 'private', ''));
            pwd0 = pushd(sessd.vallLocation);

            import mlsiemens.*;
            this = mlsiemens.Herscovitch1985( ...
                'sessionData', sessd, ...
                'scanner', []); % 'timeWindow', scanner.timeWindow, ...
            
            popd(pwd0);
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
        function writetable(obj, fn, varargin)
            ip = inputParser;
            addRequired( ip, 'obj', @(x) isa(obj, 'mlpet.IAifData') || isa(obj, 'mlpet.IScannerData'));
            addRequired( ip, 'fn', @ischar);
            addParameter(ip, 'range', [], @isnumeric);
            parse(ip, obj, fn, varargin{:});
            
            if (isempty(ip.Results.range))
                t = table( ...
                    obj.times', obj.specificActivity', ...
                    'VariableNames', {'times' 'specificActivity'});
            else
                t = table( ...
                    obj.times(ip.Results.range)', obj.specificActivity(ip.Results.range)', ...
                    'VariableNames', {'times' 'specificActivity'});
            end
            writetable(t, fn);
        end   
    end
    
	methods
        
        %% GET
        
        function g = get.INV_EFF_MMR(this)
            g = this.sessionData.INV_EFF_MMR;
        end
        function g = get.INV_EFF_TWILITE(this)
            g = this.sessionData.INV_EFF_TWILITE;
        end
        function g = get.W(this)
            g = this.scanner.invEfficiency;
        end
        function g = get.regionTag(this)
            g = this.sessionData.regionTag;
        end
        
        %% config and build
        
        function this = calibrated(this)
            this.aif_ = this.aif.calibrated;
            this.scanner_ = this.scanner.calibrated;
        end
        function this = buildCbfMap(this)
            assert(~isempty(this.a1));
            assert(~isempty(this.a2));
            
            this.scanner_.isDecayCorrected = false; % decay-uncorrected with zero-time at bolus inflow
            sc = this.scanner;
            sc = sc.petobs;          
            sc.img = this.a1*sc.img.*sc.img + this.a2*sc.img;
            sc = sc.blurred(this.petPointSpread);
            sc.fqfilename = this.sessionData.cbfOpFdg('typ','fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCbvMap(this)
            this.scanner_.isDecayCorrected = false; % decay-uncorrected with zero-time at bolus inflow
            sc = this.scanner;
            sc.time0 = sc.time0 + 120;
            assert(sc.time0 < sc.timeF, ...
                'mlsiemens:unexpectedParamsErr', 'Herscovitch1985.buildCbvMap');
            sc = sc.petobs;
            this.aif_.isDecayCorrected = false;
            sc.img = 100*sc.img*this.W/(this.RATIO_SMALL_LARGE_HCT*this.aif.specificActivityIntegral);
            sc = sc.blurred(this.petPointSpread);
            
            % rescale to reference value
            wb = mlsiemens.Herscovitch1985.configMask(this.sessionData);
            sc.img = this.referenceWholebrainCbv * sc.img / sc.volumeAveraged(wb.niftid);
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
            
            this.scanner_.isDecayCorrected = false; % decay-uncorrected with zero-time at bolus inflow
            sc = this.scanner;
            sc = sc.petobs;
            nimg = this.oefNumer(sc.img); % blurred
            dimg = this.oefDenom;         % blurred
            sc.img = this.is0to1(nimg./dimg);
            sc.fqfilename = this.sessionData.oefOpFdg('typ','fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function this = buildCmro2Map(this, labs)
            sc = this.scanner;
            sc = sc.petobs;
            cbf = this.sessionData.cbfOpFdg('avg', true, 'typ','mlfourd.ImagingContext');
            oef = this.sessionData.oefOpFdg('avg', true, 'typ','mlfourd.ImagingContext');
            if (this.useSI)
                sc.img = 1e3  * this.percentVolume2molL(labs.o2Content) * oef.niftid.img .* cbf.niftid.img; % \mumol/min/hg
            else                
                sc.img = 0.01 * labs.o2Content *                          oef.niftid.img .* cbf.niftid.img; % mL/min/hg
            end
            sc.fqfilename = this.sessionData.cmro2OpFdg('typ', 'fqfn');
            this.product_ = mlfourd.ImagingContext(sc.component);
        end
        function nii  = downsampleNii(~, nii0)
            nii0.filesuffix = '.nii.gz';
            nii0.save;
            fqfnDown = [nii0.fqfileprefix '_downsmpl.nii.gz'];
            mlbash(sprintf( ...
                'flirt -interp nearestneighbour -in %s -ref %s -out %s -nosearch -applyisoxfm 4', ...
                nii0.fqfilename, nii0.fqfilename, fqfnDown));
            nii = mlfourd.NIfTId.load(fqfnDown);           
        end
        function aif  = estimateAifHOMetab(this)
            aif       = this.aif;
            aif.isDecayCorrected = false;
            assert(this.ooFracTime > this.ooPeakTime);
            [~,idxP]  = max(aif.times > this.ooPeakTime);
            dfrac_dt  = this.fracHOMetab/(this.ooFracTime - this.ooPeakTime);
            fracVec   = zeros(size(aif.times));
            fracVec(idxP:aif.indexF) = dfrac_dt*(aif.times(idxP:aif.indexF) - aif.times(idxP));            
            aif.specificActivity = this.aif.specificActivity.*fracVec;
            
            import mlpet.*;
            aif.specificActivity = aif.specificActivity*(Blood.PLASMADN/Blood.BLOODDEN);
        end
        function aif  = estimateAifOO(this)
            this = this.ensureAifHOMetab;
            aif = this.aif;
            aif.isDecayCorrected = false;
            aif.specificActivity = this.aif.specificActivity - this.aifHOMetab.specificActivity;
        end
        function aifi = estimateAifOOIntegral(this)
            aifi = 0.01*this.RATIO_SMALL_LARGE_HCT*this.DENSITY_BRAIN*this.aifOO.specificActivityIntegral;
        end
        function rho  = estimatePetdyn(this, aif, cbf)
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
                %E    = (1 - exp(-this.PS/f(r)));
                %rho_ = (1/this.W)*f(r)*E*conv(aifbi, exp(-(f(r)/lam + lamd)*aifti*E));
                rho(r,:) = rho_(1:length(aifti));
            end
        end        
        function petobs = estimatePetobs(this, aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));
            
            rho = this.estimatePetdyn(aif, cbf);
            petobs = aif.dt*trapz(rho, 2);
        end
        function nii  = upsampleNii(~, nii0, niiRef)
            nii0.filesuffix = '.nii.gz';
            nii0.save;
            niiRef.filesuffix = '.nii.gz';
            niiRef.save;
            fqfnNative = [nii0.fqfileprefix '_native.nii.gz'];
            mlbash(sprintf( ...
                'flirt -interp trilinear -in %s -ref %s -out %s -nosearch -applyxfm', ...
                nii0.fqfilename, niiRef.fqfilename, fqfnNative));
            nii = mlfourd.NIfTId.load(fqfnNative);          
        end      
        
        %%
        
        function plotAif(this)
            
            if (strcmp(this.sessionData.tracer, 'FDG'))
                this.plotCaprac;
                return
            end
            if (strcmp(this.sessionData.tracer, 'OO'))
                this.plotAifOO;
                this.plotAifHOMetab;
                return
            end
            
            a = this.aif;
            a.isDecayCorrected = false;
            a.plotDx;
            %figure;
            %plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAif:\n%s\n%s; time0->%g, timeF->%g', ...
                sd.sessionPath, sd.tracer, a.time0, a.timeF));
            this.writetable(a, this.serializationFn(['plotAif_' sd.tracerRevision('typ','fp')]))
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            %plot(this.aifHOMetab);
            a = this.aifHOMetab;
            a.isDecayCorrected = false;
            figure;
            plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifHOMetab:\n%s\n%s; time0->%g, timeF->%g', ...
                sd.sessionPath, sd.tracer, a.time0, a.timeF));
            this.writetable(a, this.serializationFn(['plotAifHOMetab_' sd.tracerRevision('typ','fp')]))
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            %plot(this.aifOO);
            a = this.aifOO;
            a.isDecayCorrected = false;
            figure;
            plot(a.times(a.index0:a.indexF), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotAifOO:\n%s\n%s; time0->%g, timeF->%g', ...
                sd.sessionPath, sd.tracer, a.time0, a.timeF));
            this.writetable(a, this.serializationFn(['plotAifOO_' sd.tracerRevision('typ','fp')]))
        end
        function plotCaprac(this)
            %plot(this.aif);
            a = this.aif;
            a.isDecayCorrected = false;
            figure;
            plot(a.times, a.specificActivity);
            sd = this.sessionData;
            title(sprintf('AbstractHerscovitch1985.plotCaprac:\n%s\n%s; time0->%g, timeF->%g', ...
                sd.sessionPath, sd.tracer, a.time0, a.timeF));
            this.writetable(a, this.serializationFn(['plotCaprac_' sd.tracerRevision('typ','fp')]))
        end
        function plotScanner(this)
            s = this.scanner;
            s.isDecayCorrected = false;
            if (s.rank > 2)
                s = s.volumeAveraged(s.mask);
            end
            plot(s.times(s.index0:s.indexF)-s.times(s.index0), s.specificActivity(s.index0:s.indexF));
            hold on   
            a = this.aif;
            plot(a.times(a.index0:a.indexF)-a.times(a.index0), a.specificActivity(a.index0:a.indexF));
            sd = this.sessionData;
            title(sprintf( ...
                'AbstractHerscovitch1985.plotScanner:\n%s\n%s; s.time0->%g, s.timeF->%g; a.time0->%g, a.timeF->%g', ...
                sd.sessionPath, sd.tracer, s.time0, s.timeF, a.time0, a.timeF)); 
            this.writetable(s, this.serializationFn(['plotScannerWholebrain_' sd.tracerRevision('typ','fp')]))
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
                if (date_ == mldata.Xlsx.datetimeConvertFromExcel(tbl.date(id)))
                    labs.hct = tbl.Hct(id);
                    labs.glc = tbl.glc(id);
                    return
                end
            end
            error('mlsiemens:soughtDataNotFound', 'Herscovitch1985.readLaboratories');
        end        
        function save(this, varargin)
            this.saveFourdfp(varargin{:});
            this.saveNiigz(varargin{:});
        end
        function saveFourdfp(this, varargin)
            ip = inputParser;
            addOptional(ip, 'obj', this.product, @(x) isa(x, 'mlfourd.INIfTI') || isa(x, 'mlfourd.ImagingContext') || iscell(x));
            parse(ip, varargin{:});
            obj = ip.Results.obj;
            
            if (iscell(obj))
                for o = 1:length(obj)
                    this.saveFourdfp(obj{o});
                end
                return
            end
            
            fs0 = obj.filesuffix;
            obj.filesuffix = '.4dfp.hdr';
            obj.save;
            obj.filesuffix = fs0;
        end
        function saveNiigz(this, varargin)
            ip = inputParser;
            addOptional(ip, 'obj', this.product, @(x) isa(x, 'mlfourd.INIfTI') || isa(x, 'mlfourd.ImagingContext') || iscell(x));
            parse(ip, varargin{:});
            obj = ip.Results.obj;
            
            if (iscell(obj))
                for o = 1:length(obj)
                    this.saveNiigz(obj{o});
                end
                return
            end
            
            fs0 = obj.filesuffix;
            obj.filesuffix = '.nii.gz';
            obj.save;
            obj.filesuffix = fs0;
        end     
        
        %% ctor
        
 		function this = Herscovitch1985(varargin)
            
 			this = this@mlpet.AbstractHerscovitch1985(varargin{:});
            
            if (strcmpi(this.sessionData.tracer, 'FDG'))
                return
            end
            
            this = this.deconvolveAif;
            this.aif_ = this.aif_.setTime0ToInflow;
            this.aif_.timeWindow = this.configAifTimeDuration(this.sessionData.tracer);
            this.scanner_ = this.scanner.setTime0ToInflow;
            this.scanner_.timeWindow = this.aif.timeWindow;
            
            tzero = seconds(this.scanner_.datetime0 - this.aif_.datetime0); % zero-times in the aif frame
            this.aif_ = this.aif_.shiftWorldlines(tzero, this.aif_.time0); 
            
            % mMR            |   /----------
            %                |  /
            %                | time0
            %     dt00       dt0
            %
            % Twi                        |   |\ deconv
            %                            |  /   \ 
            %                            | time0
            %           dt00             dt0
            %                ^
            %                tzero in Twi frame            
        end  
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        referenceMask_
    end
    
    methods (Access = protected)
        function        checkView(this)
            if (mlsiemens.Herscovitch1985.CHECK_VIEWS)
                view(this.product);
            end
        end
        function aif  = configAcquiredAifData(this)
            sessd = this.sessionData;
            if (strcmp(sessd.tracer, 'FDG'))
                aif = this.configAcquiredFdgAif;
                return
            end            
            mand = mlsiemens.XlsxObjScanData('sessionData', sessd);
            trueAdminTime = mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag);
            aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        sessd.studyCensus.arterialSamplingCrv, ...
                'invEfficiency',     sessd.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', trueAdminTime, ...
                'isotope', '15O');
            %assert(trueAdminTime >= aif.datetime0, 'mlsiemens.Herscovitch.configAcquiredAifData');
        end
        function aif  = configAcquiredFdgAif(this)
            sessd = this.sessionData;
            sessd.tracer = 'FDG';            
            mand = mlsiemens.XlsxObjScanData('sessionData', sessd);
            aif = mlcapintec.Caprac( ...
                'fqfilename',        sessd.CCIRRadMeasurements, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'isotope', '18F');
        end
        function this = deconvolveAif(this)
            
            if (lexist(this.deconvolveAifFn, 'file') && this.REUSE_BAYES)
                load(  this.deconvolveAifFn)
                this.aif_ = a; %#ok<NODEF>
                return
            end
            
            a = this.aif;         
            plaif = mlswisstrace.DeconvolvingOC.runPLaif( ...
                a.times(1:a.indexF), a.specificActivity(1:a.indexF), this.sessionData.tracerRevision('typ','fp'));
            a.specificActivity(1:a.indexF) = plaif.itsDeconvSpecificActivity;
            a.counts = a.specificActivity / a.invEfficiency;
            a.time0 = max(1, plaif.t0);
            save(this.deconvolveAifFn, 'a', '-v7.3');
            this.aif_ = a;
        end
        function fqfn = deconvolveAifFn(this)
            fqfn = fullfile(this.sessionData.vallLocation, ...
                sprintf('mlsiemens_Herscovitch1985_deconvolveAif_%s.mat', ...
                        this.sessionData.tracerRevision('typ', 'fp')));
        end
        function fqfn = serializationFn(this, tag)
            assert(ischar(tag));
            fqfn = fullfile(this.sessionData.vallLocation, ...
                sprintf('mlsiemens_Herscovitch1985_%s_%s.csv', ...
                        tag, this.sessionData.tracerRevision('typ', 'fp')));
        end
    end
    
    methods (Static, Access = protected)
        function [aif,scanner,mask] = configAcquiredData(sessd, varargin)
            import mlsiemens.*;
            assert(strcmpi(sessd.tracer, 'OC') || ...
                   strcmpi(sessd.tracer, 'OO') || ...
                   strcmpi(sessd.tracer, 'HO'), ...
                   'mlsiemens:unexpectedParamValue', 'Herscovitch1985_15O.sessd.tracer->%s', sessd.tracer);
            sessdFdg = sessd;
            sessdFdg.tracer = 'FDG';
            
            mand = XlsxObjScanData('sessionData', sessd);
            COMM = mand.tracerAdmin.COMMENTS(sessd.doseAdminDatetimeTag);
            if (iscell(COMM)) 
                COMM = COMM{1}; 
            end
            if (ischar(COMM))
                COMM = lower(COMM);
                if (~isempty(COMM))
                    if (lstrfind(COMM, 'fail') || lstrfind(COMM, 'missing'))
                        error('mlsiemens:dataAcquisitionFailure', ...
                            'Herscovitch195.configAcquiredData.COMM->%s', COMM);
                    end
                end
            end
            
            aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        sessd.studyCensus.arterialSamplingCrv, ...
                'invEfficiency',     sessd.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'isotope', '15O');
            mask = sessdFdg.MaskOpFdg;
            if (~lexist(sessd.tracerResolvedFinal, 'file'))
                error('mlsiemens:fileNotFound', 'Herscovitch.configAcquiredData');
            end
            scanner = mlsiemens.BiographMMR( ...
                sessd.tracerResolvedFinal('typ','niftid'), ...
                'sessionData',       sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'invEfficiency',     sessd.INV_EFF_MMR, ...
                'manualData',        mand, ...
                'mask',              mask);
            scanner.dt = 1;
            [aif,scanner] = Herscovitch1985.adjustClocks(aif, scanner);
            [aif,scanner] = Herscovitch1985.writeAcquisitionDiary(sessd, aif, scanner);
        end
        function [aif,scanner] = adjustClocks(aif, scanner)
            if (abs(scanner.datetime0 - aif.datetime0) > minutes(10))
                scanner.datetime0 = scanner.datetime0 - hours(1);
                assert(abs(scanner.datetime0 - aif.datetime0) < minutes(10), ...
                    'mlsiemens:datetimeErr', 'Herscovitch1985.adjustClocks');
            end
        end
        function [aif,scanner] = writeAcquisitionDiary(sessd, aif, scanner)
            logfn = fullfile(sessd.vallLocation, 'mlsiemens_Herscovitch1985_configAcquiredData.log');
            deleteExisting(logfn);
            diary(logfn);
            assert( year(scanner.datetime0) == year(aif.datetime0));
            assert(month(scanner.datetime0) == month(aif.datetime0));
            assert(  day(scanner.datetime0) == day(aif.datetime0));
            assert( hour(scanner.datetime0) == hour(aif.datetime0));
            disp(scanner.doseAdminDatetime);
            disp(aif.doseAdminDatetime);
            disp(scanner.datetime0);
            disp(aif.datetime0);
            disp(scanner);
            disp(aif);
            diary off
            if (~isempty(getenv('DEBUG_HERSCOVITCH1985')))
                aif.plotTableTwilite;
                aif.plot;
                aif.plotSpecificActivity;
                s_ = scanner; s_ = s_.volumeAveraged; plot(s_.times, s_.img);
            end
        end
        function tD = configAifTimeDuration(tracer_)
            switch (tracer_)
                case 'HO'
                    tD = 60;
                case 'OO'
                    tD = 60;
                case {'OC' 'CO'}
                    tD = 120 + 60;
                case 'FDG'
                    tD = 3540;
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
        function this = productAverage(those)
            %  @param those is a composite of mlsiemens.Herscovitch1985.
            %  @return this is an mlsiemens.Herscovitch containing product := mean(composite of products).
            
            if (isempty(those))
                this = those;
                return
            end
            avgf = those(1).product.fourdfp;
            assert(~lstrfind(avgf.fileprefix, '_avg'));
            for p = 2:length(those)
                nextf = those(p).product.fourdfp;
                avgf.img = avgf.img + nextf.img;
            end
            avgf.img = avgf.img / length(those);
            avgf.fileprefix = [mlsiemens.Herscovitch1985.scrubSNumber(avgf.fileprefix) '_avg'];
            avgf.save;
            this = those(1);
            this.product_ = mlfourd.ImagingContext(avgf);
        end 
        function s = scrubSNumber(s)
            tracers = {'cbf' 'cbv' 'oef' 'cmro' 'cmrglc' 'ogi' 'agi'};
            for t = 1:length(tracers)
                pos = regexp(s, [tracers{t} '\dv\d_op_fdg']);
                if (~isempty(pos))
                    len = length(tracers{t});
                    s = [s(pos:pos+len-1) s(pos+len+1:end)];
                end
            end
        end 
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

