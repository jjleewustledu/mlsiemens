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
                    this = Herscovitch1985_FDG.constructCmrglc(sessd); %, sessd.cbvOpFdg('avg', true)); 
                    return
                    
                    %this.checkView
                    cmrglc = sessd.cmrglcOpFdg('typ', 'niftid');
                    cmro2  = sessd.cmro2OpFdg('avg', true, 'typ', 'niftid');

                    if (lexist(cmro2, 'file'))
                        agi = cmrglc;
                        agi.fqfileprefix = sessd.agiOpFdg('typ','fqfp');
                        agi.img = cmrglc.img - (1/6)*cmro2.img; % \mumol/min/hg
                        agi.save;
                        agi.filesuffix = '.4dfp.hdr';
                        agi.save;

                        ogi = cmrglc;
                        ogi.fqfileprefix = sessd.ogiOpFdg('typ','fqfp');
                        ogi.img = cmro2.img ./ cmrglc.img; % \mumol/min/hg
                        ogi.img(isnan(ogi.img)) = 0;
                        ogi.img(~isfinite(ogi.img)) = 0;
                        ogi.save;
                        ogi.filesuffix = '.4dfp.hdr';
                        ogi.save;
                    end
                catch ME
                    dispwarning(ME);
                end
            end
        end  
        function this = constructCmrglc(sessd, varargin)
            import mlsiemens.*;   
            if (lexist(sessd.cmrglcOpFdg, 'file') && mlsiemens.Herscovitch1985_FDG.REUSE)
                this.product = sessd.cmrglcOpFdg('typ', 'numericalNiftid');
                return
            end                  
            this = Herscovitch1985_FDG.constructTracerState(sessd); 
            labs = this.readLaboratories;
            this = this.buildCmrglcMaps(labs, varargin{:});
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
        function this = buildCmrglcMaps(this, varargin)
            %% BUILDCMRGLCMAPS delegates to strategies VoxelResampler & WholebrainResampler.
            
            switch (lower(this.resamplerType_))
                case 'voxelresampler'
                    this = this.buildCmrglcMaps_voxelResampler(varargin{:});
                case 'wholebrainresampler'
                    this = this.buildCmrglcMaps_wholebrainResampler(varargin{:});
                otherwise
                    error('mlsiemens:unsupportedSwitchcase', 'Herscovitch1985_FDG.buildCmrglcMaps');
            end
        end
        
 		function this = Herscovitch1985_FDG(varargin)
 			%% HERSCOVITCH1985_FDG
 			%  @param .

 			this = this@mlsiemens.Herscovitch1985(varargin{:});            
            this.resamplerType_ = this.sessionData.resamplerType;
 		end
    end 

    %% PROTECTED    
    
    properties (Access = protected)
        resamplerType_
    end
    
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
            [aif,scanner] = Herscovitch1985_FDG.adjustClocks(aif, scanner);
            [aif,scanner] = Herscovitch1985.writeAcquisitionDiary(sessd, aif, scanner);
        end 
    end
    
    methods (Access = protected)
        function this = buildCmrglcMaps_voxelResampler(this, labs, varargin)
            %  @param varargin is for legacy parameters that will be ignored.
            
            import mlfourd.*;
            this.aif_.isDecayCorrected = true;
            this.scanner_.isDecayCorrected = true;            
            cmrglc = VoxelResampler.constructSampledScanner( ...
                this.scanner_, ...
                'fileprefix', this.sessionData.cmrglcOpFdg('typ', 'fp', 'tag', this.dbgTag), ...
                'doEnlargemask', true, ...
                'blur', this.petPointSpread);
            mask2 = this.scanner_; 
            mask2.img = mask2.mask.img;
            ks = VoxelResampler.constructSampledScanner( ...
                mask2, ...
                'fileprefix', this.sessionData.ksOpFdg('typ', 'fp', 'tag', this.dbgTag), ...
                'doEnlargemask', true, ...
                'blur', this.petPointSpread);
            synth = VoxelResampler.constructSampledScanner( ...
                mask2, ...
                'fileprefix', [this.scanner_.fileprefix '_synth'], ...
                'doEnlargemask', true, ...
                'blur', this.petPointSpread);
            
            cmrglc = cmrglc.downsample;
            ks     = ks.downsample;
            synth  = synth.downsample;
            strat = mlkinetics.Huang1980( ...
                'aif', this.aif, ...
                'scanner', this.scanner_, ...
                'resampler', cmrglc, ...
                'glc', labs.glc, ...
                'hct', labs.hct, ...
                'useSI', this.useSI, ...
                varargin{:});
            [cmrglc.img,ks.img,synth.img] = strat.buildCmrglcMap;
            cmrglc = cmrglc.upsample;
            cmrglc.fileprefix = this.sessionData.cmrglcOpFdg('typ','fp','tag','_voxel');
            ks = ks.upsample;         
            ks.fileprefix = this.sessionData.ksOpFdg('typ','fp','tag','_voxel');
            synth = synth.upsample;   
            synth.fileprefix = this.sessionData.cmrglcOpFdg('typ','fp','tag','_synth_voxel');   
            
            this.product_ = {};
            this.product_{1} = cmrglc.dynamic;
            this.product_{1} = this.product_{1}.blurred(this.petPointSpread);
            this.product_{2} = ks.dynamic;
            this.product_{2} = this.product_{2}.blurred(this.petPointSpread);
            this.product_{3} = synth.dynamic;
            this.product_{3} = this.product_{3}.blurred(this.petPointSpread);
        end
        function this = buildCmrglcMaps_wholebrainResampler(this, labs, varargin)
            %  @param varargin is for legacy parameters that will be ignored.
            
            import mlfourd.*;
            this.aif_.isDecayCorrected = true;
            this.scanner_.isDecayCorrected = true;            
            cmrglc = WholebrainResampler.constructSampledScanner( ...
                this.scanner_, ...
                'fileprefix', this.sessionData.cmrglcOpFdg('typ', 'fp', 'tag', this.dbgTag));
            mask2 = this.scanner_; 
            mask2.img = mask2.mask.img;
            ks = WholebrainResampler.constructSampledScanner( ...
                mask2, ...
                'fileprefix', this.sessionData.ksOpFdg('typ', 'fp', 'tag', this.dbgTag));
            synth = WholebrainResampler.constructSampledScanner( ...
                mask2, ...
                'fileprefix', [this.scanner_.fileprefix '_synth']);
            
            cmrglc = cmrglc.downsample;
            ks     = ks.downsample;
            synth  = synth.downsample;
            strat = mlkinetics.Huang1980( ...
                'aif', this.aif, ...
                'scanner', this.scanner_, ...
                'resampler', cmrglc, ...
                'glc', labs.glc, ...
                'hct', labs.hct, ...
                'useSI', this.useSI, ...
                'logger', mlpipeline.Logger([cmrglc.fqfileprefix '_wb']), ...
                varargin{:});
            [cmrglc.img,ks.img,synth.img] = strat.buildCmrglcMap;
            cmrglc = cmrglc.upsample;
            cmrglc.fileprefix = this.sessionData.cmrglcOpFdg('typ','fp','tag','_wb');
            ks = ks.upsample;
            ks.fileprefix = this.sessionData.ksOpFdg('typ','fp','tag','_wb');
            synth = synth.upsample;
            synth.fileprefix = this.sessionData.cmrglcOpFdg('typ','fp','tag','_synth_wb');            
            
            this.product_ = {};
            this.product_{1} = cmrglc.dynamic;
            this.product_{1} = this.product_{1}.blurred(this.petPointSpread);
            this.product_{2} = ks.dynamic;
            this.product_{2} = this.product_{2}.blurred(this.petPointSpread);
            this.product_{3} = synth.dynamic;
            %this.product_{3} = this.product_{3}.blurred(this.petPointSpread);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

