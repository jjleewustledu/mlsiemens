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
        invEffTwilite = 0.446548
        invEffMMR = 1.1551
        a1 = 1.0932e-11
        a2 = 3.4579e-5
        b1 = -0.92967
        b2 =  539.71
        b3 = -81.505
        b4 =  28235
        fracHOMetab = 153/263
        ooFracTime  = 3661+120
        ooPeakTime  = 3661  
        
        aif
        ccirRadMeasurementsDir = fullfile(getenv('HOME'), 'Documents', 'private', '')
        crv = 'HYGLY28_VISIT_2_23sep2016_D1.crv'
        crvCal = 'HYGLY28_VISIT_2_23sep2016_twilite_cal_D1.crv'
        doseAdminDatetimeOC = datetime(2016,9,23,10,49-2,57-24);
        doseAdminDatetimeOO = datetime(2016,9,23,11,15-2,29-24);
        doseAdminDatetimeHO = datetime(2016,9,23,11,32-2,25-24);
        mand
        scanner
        sessd 
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this = this.configTracer('HO');
            this.verifyClass(this.aif, 'mlswisstrace.Twilite');
            this.verifyClass(this.scanner, 'mlsiemens.BiographMMR0');
            this.verifyClass(this.testObj, 'mlsiemens.Herscovitch1985');
        end
        function test_buildCalibrated(this)
            this = this.configTracer('HO');
            plot(this.testObj.aif);
            plot(this.testObj.scanner);
            this.verifyEqual(sum(this.testObj.aif.counts), 2.538281818181829e+04, 'RelTol', 1e-10);
            this.verifyEqual(sum(sum(sum(sum(this.testObj.scanner.counts)))), 3.227361903087533e+09, 'RelTol', 1e-10);
            this.testObj = this.testObj.buildCalibrated;            
            this.verifyEqual(sum(this.testObj.aif.specificActivity), 1.122809320988796e+04, 'RelTol', 1e-10);
            this.verifyEqual(sum(sum(sum(sum(this.testObj.scanner.specificActivity)))), 6.966239350203043e+11, 'RelTol', 1e-10);
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
            save('twilite', fullfile(mlraichle.RaichleRegistry.instance.subjectsDir, 'HYGLY28', 'V2', 'twilite.mat'));
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
            obj.product.saveas(this.sessd.cbf('typ','fqfn','suffix','op_fdg'));
        end
        function test_buildCbfWholebrain(this)
            this = this.configTracer('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 59.61, 'RelTol', 0.01);
        end        
        function test_buildCbvMap(this)
            this = this.configTracer('OC');
            obj  = this.testObj.buildCbvMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.cbv('typ','fqfn','suffix','op_fdg'));
        end
        function test_buildCbvWholebrain(this)
            this = this.configTracer('OC');
            obj = this.testObj.buildCbvWholebrain;            
            this.verifyEqual(obj.product, 4.148, 'RelTol', 0.01); % bigger mask
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
            obj.product.saveas(this.sessd.cmro2('typ','fqfn','suffix','op_resolved'));
        end
        function test_buildCmro2Wholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj.buildCmro2Wholebrain;            
            this.verifyEqual(obj.product, nan, 'RelTol', 0.01);
        end 
        function test_buildOefMap(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','suffix','op_fdg');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext','suffix','op_fdg');
            obj = obj.buildOefMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            obj.product.saveas(this.sessd.oef('typ','fqfn','suffix','op_fdg'));
        end
        function test_buildOefWholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext','suffix','op_fdg');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext','suffix','op_fdg');
            obj = obj.buildOefWholebrain;
            this.verifyEqual(obj.product, 0.2699, 'RelTol', 0.01);
        end        
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
            %setenv('PPG', '/Volumes/InnominateHD3/Local/test');
            import mlraichle.*;
            studyd = StudyData;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY28', '');
            this.sessd = SessionData( ...
                'studyData', studyd, ...
                'sessionDate', datetime(2016,9,23), ...
                'sessionPath', sessp, ...
                'resolveTag', 'op_fdg', ...
                'tracer', 'HO', 'snumber', 1, 'vnumber', 2, 'ac', true);
            this.mand = mlsiemens.XlsxObjScanData('sessionData', this.sessd);
            cd(this.sessd.vLocation);
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            setenv('TEST_HERSCOVITCH1985', '1');
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
            import mlpet.* mlsiemens.* mlswisstrace.*;
            crvFqfn  = fullfile(getenv('HOME'), 'Documents', 'private', this.crv);
            switch (tr)
                case 'HO'
                    this.sessd.tracer =  tr;
                    mand = XlsxObjScanData('sessionData', this.sessd);
                    this.sessd.tracer = 'HO';
                    pic = this.sessd.ho( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessd.attenuationCorrected = true;
                    this.scanner = BiographMMR0( ...
                        pic.niftid, ...
                        'sessionData',        this.sessd, ...
                        'doseAdminDatetime',  this.doseAdminDatetimeHO, ...
                        'invEfficiency',      this.invEffMMR, ...
                        'manualData',    mand);
                    this.scanner.time0 = 0;
                    this.scanner.timeF = 70;
                    this.scanner.dt    = 1;
                    this.aif = Twilite( ...
                        'scannerData',   this.scanner, ...
                        'fqfilename',      crvFqfn, ...
                        'invEfficiency', this.invEffTwilite, ...
                        'manualData',    mand, ...
                        'doseAdminDatetime',  this.doseAdminDatetimeHO, ...
                        'isotope', '15O');
                case 'OO'
                    this.sessd.tracer =  tr;
                    mand = XlsxObjScanData('sessionData', this.sessd);
                    this.sessd.tracer = 'OO';
                    pic = this.sessd.oo( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessd.attenuationCorrected = true;
                    this.scanner = BiographMMR0( ...
                        pic.niftid, ...
                        'sessionData',        this.sessd, ...
                        'doseAdminDatetime',  this.doseAdminDatetimeOO, ...
                        'invEfficiency',      this.invEffMMR, ...
                        'manualData',    mand);            
                    this.scanner.time0 = 0;
                    this.scanner.timeF = 70;
                    this.scanner.dt    = 1;
                    this.aif = Twilite( ...
                        'scannerData',   this.scanner, ...
                        'fqfilename',      crvFqfn, ...
                        'invEfficiency', this.invEffTwilite, ...
                        'manualData',    mand, ...
                        'doseAdminDatetime',  this.doseAdminDatetimeHO, ...
                        'isotope', '15O');
                case 'OC'
                    this.sessd.tracer =  tr;
                    mand = XlsxObjScanData('sessionData', this.sessd);
                    this.sessd.tracer = 'OC';
                    pic = this.sessd.oc( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessd.attenuationCorrected = true;
                    this.scanner = BiographMMR0( ...
                        pic.niftid, ...
                        'sessionData', this.sessd, ...
                        'doseAdminDatetime', this.doseAdminDatetimeOC, ...
                        'invEfficiency', this.invEffMMR, ...
                        'manualData',    mand);              
                    this.scanner.time0 = 120;
                    this.scanner.timeF = 120+180;
                    this.scanner.dt    = 1;
                    this.aif = Twilite( ...
                        'scannerData',   this.scanner, ...
                        'fqfilename',      crvFqfn, ...
                        'invEfficiency', this.invEffTwilite, ...
                        'manualData',    mand, ...
                        'doseAdminDatetime',  this.doseAdminDatetimeHO, ...
                        'isotope', '15O');
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessd, ...
                'scanner', this.scanner, ...
                'aif', this.aif, ...
                'timeDuration', this.scanner.timeDuration);
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

