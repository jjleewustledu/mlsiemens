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
        twiliteEff = 0.304*147.95/0.9181
        MMREff = 1;
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
        crv = 'HYGLYL28_VISIT_2_23sep2016_D1.crv'
        doseAdminDatetimeOC = datetime(2016,9,23,10,49-2,57-24);
        doseAdminDatetimeOO = datetime(2016,9,23,11,15-2,29-24);
        doseAdminDatetimeHO = datetime(2016,9,23,11,32-2,25-24);
        scanner
        sessionData 
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this = this.configTracer('HO');
            this.verifyClass(this.aif, 'mlpet.Twilite');
            this.verifyClass(this.scanner, 'mlsiemens.BiographMMR');
            this.verifyClass(this.testObj, 'mlsiemens.Herscovitch1985');
        end
        function test_aifs(this)
            this = this.configTracer('OC');
            twilite.OC.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OC.becquerelsPerCC = this.aif.becquerelsPerCC(this.aif.index0:this.aif.indexF); 
            this = this.configTracer('HO');
            twilite.HO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.HO.becquerelsPerCC = this.aif.becquerelsPerCC(this.aif.index0:this.aif.indexF);          
            this = this.configTracer('OO');
            twilite.OO.times = this.aif.times(this.aif.index0:this.aif.indexF);
            twilite.OO.becquerelsPerCC = this.aif.becquerelsPerCC(this.aif.index0:this.aif.indexF);  %#ok<STRNU>
            save('twilite', fullfile(getenv('PPG'), 'jjlee', 'HYGLY28', 'V2', 'twilite.mat'));
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
            obj.product.saveas(this.sessionData.cbf('typ','fqfn','suffix','op_fdg'));
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
            obj.product.saveas(this.sessionData.cbv('typ','fqfn','suffix','op_fdg'));
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
            obj.product.saveas(this.sessionData.cmro2('typ','fqfn','suffix','op_resolved'));
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
            obj.product.saveas(this.sessionData.oef('typ','fqfn','suffix','op_fdg'));
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
            this.sessionData = SessionData( ...
                'studyData', studyd, 'sessionPath', sessp, 'resolveTag', 'op_fdg', ...
                'tracer', '', 'snumber', 1, 'vnumber', 2, 'ac', true);
            cd(this.sessionData.vLocation);
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
            import mlpet.* mlsiemens.*;
            switch (tr)
                case 'HO'
                    this.sessionData.tracer = 'HO';
                    pic = this.sessionData.ho( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'consoleClockOffset', -duration(0,0,8), ...
                        'doseAdminDatetime', this.doseAdminDatetimeHO, ...
                        'efficiencyFactor', this.MMREff);
                    this.scanner.time0 = 0;
                    this.scanner.timeDuration = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'efficiencyFactor', this.twiliteEff, ...
                        'aifTimeShift', -20);
                case 'OO'
                    this.sessionData.tracer = 'OO';
                    pic = this.sessionData.oo( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'consoleClockOffset', -duration(0,0,8), ...
                        'doseAdminDatetime', this.doseAdminDatetimeOO, ...
                        'efficiencyFactor', this.MMREff);            
                    this.scanner.time0 = 0;
                    this.scanner.timeDuration = 60;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'efficiencyFactor', this.twiliteEff, ...
                        'aifTimeShift', -8);
                case 'OC'
                    this.sessionData.tracer = 'OC';
                    pic = this.sessionData.oc( ...
                        'typ', 'mlpet.PETImagingContext');
                    this.sessionData.attenuationCorrected = true;
                    this.scanner = BiographMMR(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'consoleClockOffset', -duration(0,0,8), ...
                        'doseAdminDatetime', this.doseAdminDatetimeOC, ...
                        'efficiencyFactor', this.MMREff);              
                    this.scanner.time0 = 120;
                    this.scanner.timeDuration = 180;
                    this.scanner.dt = 1;
                    this.aif = Twilite( ...
                        'scannerData', this.scanner, ...
                        'twiliteCrv', fullfile(this.sessionData.vLocation, this.crv), ...
                        'efficiencyFactor', this.twiliteEff, ...
                        'aifTimeShift', 0);
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessionData, ...
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

