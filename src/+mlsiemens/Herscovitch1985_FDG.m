classdef Herscovitch1985_FDG < mlsiemens.Herscovitch1985
	%% HERSCOVITCH1985_FDG  

	%  $Revision$
 	%  was created 16-Jun-2018 15:33:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
    end
    
    methods (Static)
        function this = constructPhysiologicals2(sessd, varargin)
            
            ip = inputParser;
            parse(ip, varargin{:});
            
            import mlsiemens.*;            
            sessd.attenuationCorrected = true;
            sessd.tracer = 'FDG';
            sessd.attenuationCorrected = true;
            Herscovitch1985_FDG.configT1001(sessd);
            Herscovitch1985_FDG.configMask(sessd);
            if (lexist(sessd.tracerRevision))
                try
                    this = Herscovitch1985_FDG.constructCmrglc(sessd, sessd.cbvOpFdg('avg', true)); 
                    this.checkView
                    cmrglc = sessd.cmrglcOpFdg('typ', 'niftid');
                    cmro2  = sessd.cmro2OpFdg('avg', true, 'typ', 'niftid');

                    if (lexist(cmro2, 'file'))
                        agi = cmrglc;
                        agi.fqfileprefix = sessd.agiOpFdg('typ','fqfp');
                        agi.img = cmrglc.img - (1/6)*cmro2.img; % \mumol/min/hg
                        agi.save;
                        agi.filesuffix = '.4dfp.ifh';
                        agi.save;

                        ogi = cmrglc;
                        ogi.fqfileprefix = sessd.ogiOpFdg('typ','fqfp');
                        ogi.img = cmro2.img ./ cmrglc.img; % \mumol/min/hg
                        ogi.img(isnan(ogi.img)) = 0;
                        ogi.img(~isfinite(ogi.img)) = 0;
                        ogi.save;
                        ogi.filesuffix = '.4dfp.ifh';
                        ogi.save;
                    end
                catch ME
                    dispwarning(ME);
                end
            end
        end  
        function this = constructCmrglc(sessd, cbv_)
            import mlsiemens.*;   
            if (lexist(sessd.cmrglcOpFdg, 'file') && mlsiemens.Herscovitch1985_FDG.REUSE)
                this.product = sessd.cmrglcOpFdg('typ', 'numericalNiftid');
                return
            end                  
            this = Herscovitch1985_FDG.constructTracerState(sessd); 
            labs = this.readLaboratories;
            this = this.buildCmrglcMaps(labs, cbv_);
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
            [aif,scanner,mask] = Herscovitch1985_FDG.configAcquiredData(sessd, varargin{:});
            Herscovitch1985_FDG.writetable( ...
                aif, ...
                fullfile(sessd.vallLocation, ['mlsiemens_Herscovitch1985_constructTracerState_aif_' sessd.tracerRevision('typ','fp') '.csv']))
            this = mlsiemens.Herscovitch1985_FDG( ...
                'sessionData', sessd, ...
                'scanner', scanner, ...
                'aif', aif, ...
                'mask', mask); % 'timeDuration', scanner.timeDuration, ...            
            this.plotAif;
            this.plotScanner
            saveFigures(sprintf('fig_mlsiemens_Herscovitch1985_constructTracerState_%s', sessd.tracerRevision('typ','fp')));  
            
            popd(pwd0);
        end
    end

	methods		
        function this = buildCmrglcMaps(this, labs, cbv_)
            if (lexist(cbv_, 'file'))
                cbv_ = mlfourd.ImagingContext(cbv_);
                downCbv = this.downsampleNii(cbv_.numericalNiftid);
            else
                downCbv = [];
            end
            this.referenceMask_ = mlfourd.NumericalNIfTId(this.scanner_.mask);
            this.referenceMask_ = this.referenceMask_.blurred(this.petPointSpread);
            this.referenceMask_ = this.referenceMask_.binarized;
            this.referenceMask_.fileprefix = 'mlsiemens_Herscovitch1985_buildCmrglcMap_referenceMask_';
            this.aif_.isDecayCorrected = true;
            this.scanner_.isDecayCorrected = true;
            ks = this.scanner_;
            ks.fileprefix = this.sessionData.ksOpFdg('typ', 'fp');
            this = this.downsampleScanner;
            [this,ks] = this.downsampleKs(ks);
            strat = mlkinetics.Huang1980( ...
                'aif', this.aif, ...
                'scanner', this.scanner_, ...
                'cbv', downCbv, ...
                'glc', labs.glc, ...
                'hct', labs.hct);
            [this.scanner_.img,ks.img] = strat.buildCmrglcMap; % [CMRglc] == (mg/dL)(1/min)         
            if (this.useSI)
                % [mg*mL/(dL*hg)] x 0.05551 [\mumol/mL][dL/mg] x 1.05^{-1} [mL/g] == [\mumol/(min hg)]
                this.scanner_.img = 0.05551 * this.BRAIN_DENSITY^(-1) * this.scanner_.img; % [CMRglc] == \mumol/min/hg
            end
            this = this.upsampleScanner;
            [this,ks] = this.upsampleKs(ks);
            this.product_ = {};
            this.product_{1} = mlfourd.ImagingContext(this.scanner_.component);
            this.product_{1} = this.product_{1}.blurred(this.petPointSpread);
            this.product_{1}.fqfilename = this.sessionData.cmrglcOpFdg('typ', 'fqfn');
            this.product_{2} = mlfourd.ImagingContext(ks.component);
            this.product_{2} = this.product_{2}.blurred(this.petPointSpread);
            this.product_{2}.fqfilename = this.sessionData.ksOpFdg('typ', 'fqfn');
        end
        function [this,ks] = downsampleKs(this, ks)
            down = this.downsampleNii(ks);
            ks.img = down.img;
            ks.fqfilename = down.fqfilename;     
            ks.mmppix = down.mmppix;
            if (~isempty(ks.mask))
                ks.mask = this.downsampleNii(this.referenceMask_);
            end
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
        function [this,ks] = upsampleKs(this, ks)
            assert(~isempty(this.referenceMask_));
            up = this.upsampleNii(ks, this.referenceMask_);
            ks.img = up.img;
            ks.fqfilename = up.fqfilename;
            ks.mmppix = up.mmppix;
            ks.mask = this.referenceMask_;
        end  
        function this = upsampleScanner(this)
            assert(~isempty(this.referenceMask_));            
            up = this.upsampleNii(this.scanner_, this.referenceMask_);
            this.scanner_.img = up.img;
            this.scanner_.fqfilename = up.fqfilename;   
            this.scanner_.mmppix = up.mmppix;          
            this.scanner_.mask = this.referenceMask_;
        end 
        
 		function this = Herscovitch1985_FDG(varargin)
 			%% HERSCOVITCH1985_FDG
 			%  @param .

 			this = this@mlsiemens.Herscovitch1985(varargin{:});
 		end
    end 

    %% PROTECTED    
    
    methods (Static, Access = protected)        
        function [aif,scanner,mask] = configAcquiredData(sessd)
            assert(strcmpi(sessd.tracer, 'FDG'), ...
                'mlsiemens:unexpectedParamValue', 'Herscovitch1985_FDG.sessd.tracer->%s', sessd.tracer);
            
            import mlsiemens.*;
            mand = XlsxObjScanData('sessionData', sessd);
            aif = mlcapintec.Caprac( ...
                'fqfilename',        sessd.CCIRRadMeasurements, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'isotope', '18F'); % natively not decay-corrected
            mask = sessd.MaskOpFdg;
            scanner = mlsiemens.BiographMMR( ...
                sessd.tracerResolvedFinal('typ','niftid'), ...
                'sessionData',       sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'invEfficiency',     sessd.INV_EFF_MMR, ...
                'manualData',        mand, ...
                'mask',              mask); % natively decay-corrected
            scanner.dt = 1;
            if (~isempty(sessd.hoursOffsetForced))
                scanner.datetime0 = scanner.datetime0 + hours(sessd.hoursOffsetForced);
            end
            [aif,scanner] = Herscovitch1985_FDG.adjustClocks(aif, scanner);
            [aif,scanner] = Herscovitch1985.writeAcquisitionDiary(sessd, aif, scanner);
        end 
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

