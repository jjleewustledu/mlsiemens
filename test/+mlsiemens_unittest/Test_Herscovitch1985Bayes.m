classdef Test_Herscovitch1985Bayes < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985BAYES 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_Herscovitch1985Bayes)
 	%          >> result  = run(mlsiemens_unittest.Test_Herscovitch1985Bayes, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Jun-2017 13:31:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
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
		function test_afun(this)
 			import mlsiemens.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)            
            this = this.configTracer('HO');
            this.verifyClass(this.aif, 'mlswisstrace.Twilite');
            this.verifyClass(this.scanner, 'mlsiemens.BiographMMR');
            this.verifyClass(this.testObj, 'mlsiemens.Herscovitch1985Bayes');
        end
        function test_aifs(this)
            this = this.configTracer('HO');
            twilite.HO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.HO.specificActivity = this.aif.specificActivity(this.aif.index0:this.aif.indexF); 
            %save('twilite', fullfile(this.sessionData.vLocation, 'twilite.mat'));
        end
        function test_plotAifHO(this)
            this = this.configTracer('HO');
            this.testObj.plotAif;
        end
        function test_plotScannerWholebrain(this)
            this = this.configTracer('HO');
            this.testObj.plotScannerWholebrain;
        end
        
        function test_buildA1A2(this)
            this = this.configTracer('HO');
            obj = this.testObj.buildA1A2;
            this.verifyEqual(obj.product(1), this.a1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.a2, 'RelTol', 0.01);
        end        
        
        function test_buildCbfMap(this)
            this = this.configTracer('HO');
            obj    = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj    = obj.buildCbfMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessionData.cbf('typ','fqfn','suffix','op_fdg'));
        end
        function test_buildCbfWholebrain(this)
            this = this.configTracer('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 55.7551472410379, 'RelTol', 0.01);
        end  
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985Bayes(this)            
            import mlraichle.*;
            studyd = StudyData;
            studyd.subjectsFolder = mlraichle.RaichleRegistry.instance.subjectsFolder;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY28', '');
            this.sessionData = SessionData( ...
                'studyData', studyd, 'sessionPath', sessp, ...
                'tracer', '', 'snumber', 1, 'vnumber', 1, 'ac', true);
            cd(this.sessionData.vLocation);
            setenv(upper('Test_Herscovitch1985Bayes'), '1');
            this.addTeardown(@this.teardownHerscovitch1985Bayes);
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985BayesTest(this)
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
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeHO);
                    this.scanner.time0 = 0;
                    this.scanner.timeDuration = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', -20);
                case 'OO'
                    this.sessionData.tracer = 'OO';
                    pic = this.sessionData.oo( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeOO);            
                    this.scanner.time0 = 0;
                    this.scanner.timeDuration = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', -8);
                case 'OC'
                    this.sessionData.tracer = 'OC';
                    pic = this.sessionData.oc( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'doseAdminDatetime', this.doseAdminDatetimeOC);              
                    this.scanner.time0 = 120;
                    this.scanner.timeDuration = 180;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'invEfficiency', this.twiliteEff, ...
                        'aifTimeShift', 0);
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
 			this.testObj = mlsiemens.Herscovitch1985Bayes( ...
                'sessionData', this.sessionData, ...
                'scanner', this.scanner, ...
                'aif', this.aif, ...
                'timeDuration', this.scanner.timeDuration);
            this.testObj.ooPeakTime  = this.ooPeakTime;
            this.testObj.ooFracTime  = this.ooFracTime;
            this.testObj.fracHOMetab = this.fracHOMetab;
        end
        function teardownHerscovitch1985Bayes(this)
            setenv(upper('Test_Herscovitch1985Bayes'), '0');
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

