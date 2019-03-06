classdef Test_Herscovitch1985_visit1 < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_Herscovitch1985_visit1)
 	%          >> result  = run(mlsiemens_unittest.Test_Herscovitch1985_visit1, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Feb-2017 21:46:26
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.  Copyright 2017 John Joowon Lee.
 	

	properties    
        twiliteEff = 2.347*147.95/0.7552
        a1 = 9.732e-12 % Twilite eff. 0.5654*0.487/7.775e-3, decays/cc or Bq/cc; => CBF ~ 54
        a2 = 3.4252e-05 % "
        % a1 = 2.012469259834277e-12 % Twilite eff.  223*0.304, decays/cc or Bq/cc; => CBF ~ 25
        % a2 = 1.736454658827487e-05 % "
        % a1 = 4.5595e-12 % decay-adjusted time shifts, Twilite eff. 51.74; => CBF ~ 34
        % a2 = 2.3444e-05 % "
        b1 = -1.1629
        b2 =  703.31
        b3 = -76.244
        b4 =  27251
        fracHOMetab = 153/263
        ooFracTime  = 3661+120
        ooPeakTime  = 3661  
        
        aif
        crv = 'HYGLY28_9sep2016_D1.crv'
        doseAdminDatetimeOC = datetime(2016,9,9,10,11,36) - duration(0,2,17);
        doseAdminDatetimeOO = datetime(2016,9,9,10,27,24) - duration(0,2,17);
        doseAdminDatetimeHO = datetime(2016,9,9,10,43,04) - duration(0,2,17);
        scanner
        sessionData 
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this = this.configTracer('HO');
            this.verifyClass(this.aif, 'mlswisstrace.Twilite');
            this.verifyClass(this.scanner, 'mlsiemens.BiographMMR0');
            this.verifyClass(this.testObj, 'mlsiemens.Herscovitch1985');
        end
        function test_aifs(this)
            this = this.configTracer('OC');
            twilite.OC.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OC.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF); 
            this = this.configTracer('HO');
            twilite.HO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.HO.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF);          
            this = this.configTracer('OO');
            twilite.OO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OO.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF);  %#ok<STRNU>
            save(fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, 'HYGLY28', 'V1', 'twilite.mat'), 'twilite');
        end
        function test_plotAifHO(this)
            this = this.configTracer('HO');
            this.testObj.plotAif;
        end
        function test_plotAifOO(this)
            this = this.configTracer('OO');
            this.testObj.plotAifHOMetab;
            this.testObj.plotAifOO;
        end
        function test_plotScanner(this)
            this = this.configTracer('HO');
            this.testObj.plotScanner;
        end
        
        function test_buildA1A2(this)
            this = this.configTracer('HO');
            obj = this.testObj.buildA1A2;
            this.verifyEqual(obj.product(1), this.a1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.a2, 'RelTol', 0.01);
        end
        function test_buildB1B2(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj = obj.buildB1B2;
            this.verifyEqual(obj.product(1), this.b1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b2, 'RelTol', 0.01);
        end
        function test_buildB3B4(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj = obj.buildB3B4;
            this.verifyEqual(obj.product(1), this.b3, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b4, 'RelTol', 0.01);
        end
        
        function test_buildCbfMap(this)
            this = this.configTracer('HO');
            obj    = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj    = obj.buildCbfMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessionData.cbf('typ','fqfn','tag','op_fdg'));
        end
        function test_buildCbfWholebrain(this)
            this = this.configTracer('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 55.7551472410379, 'RelTol', 0.01);
        end        
        function test_buildCbvMap(this)
            this = this.configTracer('OC');
            obj  = this.testObj.buildCbvMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessionData.cbv('typ','fqfn','tag','op_fdg'));
        end
        function test_buildCbvWholebrain(this)
            this = this.configTracer('OC');
            obj = this.testObj.buildCbvWholebrain;            
            this.verifyEqual(obj.product, 1.4196, 'RelTol', 0.01); % bigger mask
        end
        function test_buildCmro2Map(this)
            labs.pH = 7.36;
            labs.pCO2 = 44;
            labs.pO2 = 109;
            labs.totalCO2 = 26;
            labs.AaGradient = nan;
            labs.pcnt_iO2Art = nan;
            labs.vol_iO2Art = nan;
            labs.totalHgb = 13.5;
            labs.oxyHgb = 82.3;
            labs.carboxyHgb = 4.7;
            labs.metHgb = 1.4;
            labs.o2Content = 17.7;
            this = this.configTracer('OO');
            obj = this.testObj;
            obj = obj.buildCmro2Map;            
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessionData.cmro2('typ','fqfn','tag','op_resolved'));
        end
        function test_buildCmro2Wholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj.buildCmro2Wholebrain;            
            this.verifyEqual(obj.product, nan, 'RelTol', 0.01);
        end 
        function test_buildMask(this)            
            this = this.configTracer('OC');
            [~,n] = this.testObj.scanner.mskt;
            n.view;
        end
        function test_buildOefMap(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','tag','op_fdg');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext','tag','op_fdg');
            obj = obj.buildOefMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessionData.oef('typ','fqfn','tag','op_fdg'));
        end
        function test_buildOefWholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','tag','op_fdg');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext','tag','op_fdg');
            obj = obj.buildOefWholebrain;
            this.verifyEqual(obj.product, 0.3049, 'RelTol', 0.01);
        end        
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
            setenv('PPG', '/data/nil-bluearc/raichle/PPGdata');
            import mlraichle.*;
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY28', '');
            this.sessionData = SessionData( ...
                'studyData', studyd, 'sessionPath', sessp, ...
                'tracer', '', 'snumber', 1, 'ac', true);
            cd(this.sessionData.sessionPath);
            setenv(upper('Test_Herscovitch1985'), '1');
            this.addTeardown(@this.teardownHerscovitch1985);
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985Test(this)
 			%this.testObj = this.testObj_;
 			%this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		%testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
        function this = configTracer(this, tr)
            import mlpet.* mlsiemens.*;
            switch (tr)
                case 'HO'
                    this.sessionData.tracer = 'HO';
                    pic = this.sessionData.ho( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR0(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeHO);
                    this.scanner.time0 = 0;
                    this.scanner.timeWindow = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'filename', this.sessionData.arterialSamplerCrv, ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', -20, ...
                        'manualData', XlsxObjScanData('sessionData', this.sessionData));
                case 'OO'
                    this.sessionData.tracer = 'OO';
                    pic = this.sessionData.oo( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR0(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeOO);            
                    this.scanner.time0 = 0;
                    this.scanner.timeWindow = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'filename', this.sessionData.arterialSamplerCrv, ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', -8, ...
                        'manualData', XlsxObjScanData('sessionData', this.sessionData));
                case 'OC'
                    this.sessionData.tracer = 'OC';
                    pic = this.sessionData.oc( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR0(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeOC);              
                    this.scanner.time0 = 120;
                    this.scanner.timeWindow = 180;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'filename', this.sessionData.arterialSamplerCrv, ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', 0, ...
                        'manualData', XlsxObjScanData('sessionData', this.sessionData));
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessionData, ...
                'scanner', this.scanner, ...
                'aif', this.aif, ...
                'timeWindow', this.scanner.timeWindow);
            this.testObj.ooPeakTime  = this.ooPeakTime;
            this.testObj.ooFracTime  = this.ooFracTime;
            this.testObj.fracHOMetab = this.fracHOMetab;
        end
        function teardownHerscovitch1985(this)
            setenv(upper('Test_Herscovitch1985'), '0');
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

