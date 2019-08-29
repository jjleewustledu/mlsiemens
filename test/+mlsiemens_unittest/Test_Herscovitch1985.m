classdef Test_Herscovitch1985 < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_Herscovitch1985)
 	%          >> result  = run(mlsiemens_unittest.Test_Herscovitch1985, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Feb-2017 21:46:26
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	properties
        a1 =  9.801275343313559e-12
        a2 =  3.401076359921338e-05
        b1 = -1.335246820068828
        b2 =  8.993914369193620e+02
        b3 = -42.857285062758898
        b4 =  2.322990715719311e+04
        fracHOMetab = 153/263
        ooFracTime  = 120
        ooPeakTime  = 0  
        
        aif
        ccirRadMeasurementsDir = fullfile(getenv('HOME'), 'Documents', 'private', '')
        crv = 'HYGLY28_VISIT_2_23sep2016_D1.crv'
        crvCal = 'HYGLY28_VISIT_2_23sep2016_twilite_cal_D1.crv'
        mand
        mask
        scanner
        sessd 
        sessf = 'HYGLY28'
        t1
 		testObj
        vnum = 2
        
        doseAdminDatetimeOC  = datetime(2016,9,23,10,47,33-15, 'TimeZone', 'America/Chicago');
        doseAdminDatetimeOO  = datetime(2016,9,23,11,13,05-15, 'TimeZone', 'America/Chicago');
        doseAdminDatetimeHO  = datetime(2016,9,23,11,30,01-15, 'TimeZone', 'America/Chicago');
        doseAdminDatetimeFDG = datetime(2016,9,23,12,43,52-15, 'TimeZone', 'America/Chicago');
 	end

	methods (Test)
        function test_ctor(this)
            this = this.configTracerState('FDG');
            this.verifyClass(this.aif, 'mlswisstrace.Twilite');
            this.verifyClass(this.scanner, 'mlsiemens.BiographMMR');
            this.verifyClass(this.testObj, 'mlsiemens.Herscovitch1985');
        end
        function test_configT1001(this)
            this = this.configTracerState('HO');
            [t,f] = this.testObj.configT1001;
            mlfourdfp.Viewer.view({f t});
        end
        function test_configMask(this)
            this = this.configTracerState('HO');
            [m,f] = this.testObj.configMask;
            mlfourdfp.Viewer.view({f m});
        end
        
        function test_calibrated(this)
            this = this.configTracerState('HO');
            plot(this.testObj.aif);
            plot(this.testObj.scanner);
            this.verifyEqual(sum(this.testObj.aif.counts), 2.538281818181829e+04, 'RelTol', 1e-10);
            this.verifyEqual(sum(sum(sum(sum(this.testObj.scanner.counts)))), 3.227361903087533e+09, 'RelTol', 1e-10);
            this.testObj = this.testObj.calibrated;            
            this.verifyEqual(sum(this.testObj.aif.specificActivity), 1.122809320988796e+04, 'RelTol', 1e-10);
            this.verifyEqual(sum(sum(sum(sum(this.testObj.scanner.specificActivity)))), 6.966239350203043e+11, 'RelTol', 1e-10);
        end
        function test_aifs(this)
            this = this.configTracerState('OC');
            twilite.OC.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OC.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF); 
            this = this.configTracerState('HO');
            twilite.HO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.HO.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF);          
            this = this.configTracerState('OO');
            twilite.OO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OO.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF);  %#ok<STRNU>
            save('twilite', fullfile(mlraichle.StudyRegistry.instance.subjectsDir, 'HYGLY28', 'V2', 'twilite.mat'));
        end
        function test_plotAifHO(this)
            this = this.configTracerState('HO');
            this.testObj.plotAif;
        end
        function test_plotAifOC(this)
            this = this.configTracerState('OC');
            this.testObj.plotAif;
        end
        function test_plotAifOO(this)
            this = this.configTracerState('OO');
            this.testObj.plotAifOO;
            this.testObj.plotAifHOMetab;
        end
        function test_runPLaif(this)
            this = this.configTracerState('HO');
            a = this.aif;
            plaif = mlswisstrace.DeconvolvingPLaif.runPLaif(a.times(1:a.indexF), a.specificActivity(1:a.indexF), 'HO');
            plot(plaif);
        end
        function test_plotScanner(this)
            this = this.configTracerState('HO');
            this.testObj.plotScanner;
        end
        
        function test_buildA1A2(this)
            this = this.configTracerState('HO');
            obj = this.testObj.buildA1A2;
            this.verifyEqual(obj.product(1), this.a1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.a2, 'RelTol', 0.01);
        end
        function test_buildB1B2(this)
            this = this.configTracerState('OO');
            obj = this.testObj;
            obj = obj.buildB1B2;
            this.verifyEqual(obj.product(1), this.b1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b2, 'RelTol', 0.01);
        end
        function test_buildB3B4(this)
            this = this.configTracerState('OO');
            obj = this.testObj;
            obj = obj.buildB3B4;
            this.verifyEqual(obj.product(1), this.b3, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b4, 'RelTol', 0.01);
        end
        
        function test_buildCbfMap(this)
            this = this.configTracerState('HO');
            obj    = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj    = obj.buildCbfMap;
            this.verifyTrue(isa(obj.product, 'mlfourd.ImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.cbfOpFdg('typ','fqfn'));
        end
        function test_buildCbfWholebrain(this)
            this = this.configTracerState('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 37.6902047008641, 'RelTol', 0.01); % brainmaskBinarized
        end        
        function test_buildCbvMap(this)
            this = this.configTracerState('OC');
            obj  = this.testObj.buildCbvMap;
            this.verifyTrue(isa(obj.product, 'mlfourd.ImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.cbvOpFdg('typ','fqfn'));
        end
        function test_buildCbvWholebrain(this)
            this = this.configTracerState('OC');
            obj = this.testObj.buildCbvWholebrain;            
            this.verifyEqual(obj.product, 5.121371012070974, 'RelTol', 0.01); % brainmaskBinarized
        end
        function test_buildCmro2Map(this)
            %labs.pH = 7.36;
            %labs.pCO2 = 44;
            %labs.pO2 = 109;
            %labs.totalCO2 = 26;
            %labs.AaGradient = nan;
            %labs.pcnt_iO2Art = nan;
            %labs.vol_iO2Art = nan;
            %labs.totalHgb = 13.5;
            %labs.oxyHgb = 82.3;
            %labs.carboxyHgb = 4.7;
            %labs.metHgb = 1.4;
            labs.o2Content = this.sessd.o2Content;
            this = this.configTracerState('OO');
            obj = this.testObj;
            obj = obj.buildCmro2Map(labs);            
            this.verifyTrue(isa(obj.product, 'mlfourd.ImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.cmro2OpFdg('typ','fqfn'));
        end
        function test_buildCmro2Wholebrain(this)
            this = this.configTracerState('OO');
            obj = this.testObj.buildCmro2Wholebrain;            
            this.verifyEqual(obj.product, nan, 'RelTol', 0.01);
        end 
        function test_buildOefMap(this)
            this = this.configTracerState('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbfOpFdg('typ','mlfourd.ImagingContext');
            obj.cbv = obj.sessionData.cbvOpFdg('typ','mlfourd.ImagingContext');
            obj = obj.buildOefMap;
            this.verifyTrue(isa(obj.product, 'mlfourd.ImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.oefOpFdg('typ','fqfn'));
        end
        function test_buildOefWholebrain(this)
            this = this.configTracerState('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbfOpFdg('typ','mlfourd.ImagingContext');
            obj.cbv = obj.sessionData.cbvOpFdg('typ','mlfourd.ImagingContext');
            obj = obj.buildOefWholebrain;
            this.verifyEqual(obj.product, 0.2699, 'RelTol', 0.01);
        end  
        
        %% ATTN:  GLC EXPOSED
        function test_constructAifs(this)
            mlsiemens.Herscovitch1985.constructAifs(this.sessd);
        end
        function test_constructCmrglc(this)
            labs.o2Content = this.sessd.o2Content;
            labs.glc = 308;
            labs.hct = 37.55;
            mlsiemens.Herscovitch1985_FDG.constructCmrglc(this.sessd, labs);
        end      
        function test_constructOxygenOnly(this)
            labs.o2Content = this.sessd.o2Content;
            mlsiemens.Herscovitch1985.constructOxygenOnly(this.sessd, labs);
        end
        function test_constructPhysiologicals(this)
            mlsiemens.Herscovitch1985.constructPhysiologicals(this.sessd);
        end  
        function test_updownsampleScanner(this)
           
            import mlsiemens.*;
            sd = this.sessd;
            sd.tracer = 'FDG';            
            thisFDG = Herscovitch1985.constructTracerState(sd); 
            thisFDG.scanner.fileprefix = 'Test_Herscovitch_test_updownsampleScanner';
            thisFDG = thisFDG.downsampleScanner;
            thisFDG.scanner.view;
            thisFDG.scanner.mask.view;
            thisFDG = thisFDG.upsampleScanner;
            thisFDG.scanner.view;
            thisFDG.scanner.mask.view;
        end
        function test_readLaboratories(this)
            import mlsiemens.*;
            sd = this.sessd;
            sd.tracer = 'FDG';            
            testObj_ = Herscovitch1985.constructTracerState(sd); 
            labs = testObj_.readLaboratories;
            this.verifyEqual(labs.glc, 308.5);
            this.verifyEqual(labs.hct, 37.8);
        end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
            import mlraichle.* mlsiemens.*;
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            setenv('TEST_HERSCOVITCH1985', '1');
            this.sessd = HerscovitchContext( ...
                'studyData', mlraichle.StudyData, ...
                'sessionFolder', this.sessf);
%             , ...
%                 'tracer', 'HO', ...
%                 'rnumber', 1, ...
%                 'snumber', 1, ...
%                 'ac', true);
            this.mand = mlsiemens.XlsxObjScanData('sessionData', this.sessd);
            cd(this.sessd.vallLocation);
            this.addTeardown(@this.teardownHerscovitch1985);            
             
            this.t1   = this.sessd.T1001OpFdg;
            this.mask = this.sessd.MaskOpFdg;
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985Test(~)
 			%this.testObj = this.testObj_;
 			%this.addTeardown(@this.cleanFiles);
 		end
    end

    %% PRIVATE
    
	properties (Access = private)
 		%testObj_
 	end

	methods (Access = private)
		function cleanFiles(~)
 		end
        function this = configAifState(this, tracer_)
            this = this.configAifData(tracer_);
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessd, ...
                'aif', this.aif);
            this.testObj.ooPeakTime  = this.ooPeakTime;
            this.testObj.ooFracTime  = this.ooFracTime;
            this.testObj.fracHOMetab = this.fracHOMetab;
        end
        function this = configAifData(this, tracer_)
            this.sessd.tracer =  tracer_;
            this.sessd.attenuationCorrected = true;
            this.mand = mlsiemens.XlsxObjScanData('sessionData', this.sessd);
            this.aif = mlswisstrace.Twilite( ...
                'fqfilename',        fullfile(getenv('HOME'), 'Documents', 'private', this.crv), ...
                'invEfficiency',     this.sessd.INV_EFF_TWILITE, ...
                'sessionData',       this.sessd, ...
                'manualData',        this.mand, ...
                'doseAdminDatetime', this.doseAdminDatetimeActive(tracer_), ...
                'isotope', '15O');
            this.aif.time0 = this.configAifTime0(tracer_);
            this.aif.timeF = this.configAifTimeF(tracer_);
        end
        function this = configTracerState(this, tracer_)
            this = this.configAcquiredData(tracer_);
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessd, ...
                'scanner', this.scanner, ...
                'aif', this.aif, ...
                'timeWindow', this.scanner.timeWindow, ...
                'mask', mlfourd.ImagingContext(this.scanner.mask));
            this.testObj.ooPeakTime  = this.ooPeakTime;
            this.testObj.ooFracTime  = this.ooFracTime;
            this.testObj.fracHOMetab = this.fracHOMetab;
        end
        function this = configAcquiredData(this, tracer_)
            this.sessd.tracer =  tracer_;
            this.sessd.attenuationCorrected = true;
            sessdFdg = this.sessd;
            sessdFdg.tracer = 'FDG';
            this.mand = mlsiemens.XlsxObjScanData('sessionData', this.sessd);
            this.aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        fullfile(getenv('HOME'), 'Documents', 'private', this.crv), ...
                'invEfficiency',     this.sessd.INV_EFF_TWILITE, ...
                'sessionData',       this.sessd, ...
                'manualData',        this.mand, ...
                'doseAdminDatetime', this.doseAdminDatetimeActive(tracer_), ...
                'isotope', '15O');
            this.aif.time0 = this.configAifTime0(tracer_);
            this.aif.timeF = this.configAifTimeF(tracer_);
            this.scanner = mlsiemens.BiographMMR( ...
                this.sessd.tracerResolvedFinal('typ','niftid'), ...
                'sessionData',       this.sessd, ...
                'doseAdminDatetime', this.doseAdminDatetimeActive(tracer_), ...
                'invEfficiency',     this.sessd.INV_EFF_MMR, ...
                'manualData',        this.mand, ...
                'mask',              this.mask);
            this.scanner.time0 = this.configScannerTime0(tracer_);
            this.scanner.timeWindow = this.aif.timeWindow;
            this.scanner.dt = 1;
            this.scanner.isDecayCorrected = false;
        end
        function t0 = configAifTime0(~, tracer_)
            switch (tracer_)
                case 'HO'
                    t0 = 20;
                case 'OO'
                    t0 = 0;
                case {'OC' 'CO'}
                    t0 = 120;
                case 'FDG'
                    t0 = 0;
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
        function tF = configAifTimeF(this, tracer_)
            switch (tracer_)
                case 'HO'
                    tF = 60;
                case 'OO'
                    tF = 40;
                case {'OC' 'CO'}
                    tF = 120+180;
                case 'FDG'
                    tF = this.sessd.times(end);
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
        function t0 = configScannerTime0(~, tracer_)
            switch (tracer_)
                case 'HO'
                    t0 = 10;
                case 'OO'
                    t0 = 0;
                case {'OC' 'CO'}
                    t0 = 120;
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
        function tF = configScannerTimeF(~, tracer_)
            switch (tracer_)
                case 'HO'
                    tF = 50;
                case 'OO'
                    tF = 40;
                case {'OC' 'CO'}
                    tF = 120+180;
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', ...
                        'Test_Herscovitch1985.doseAdminDatetimeActive');
            end
        end
        function dt_ = doseAdminDatetimeActive(this, tracer_)
            try
                dt_ = this.(sprintf('doseAdminDatetime%s', upper(tracer_)));
            catch ME
                dispexcept(ME);
            end
        end
        function teardownHerscovitch1985(~)
            setenv('TEST_HERSCOVITCH1985', '0');
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

