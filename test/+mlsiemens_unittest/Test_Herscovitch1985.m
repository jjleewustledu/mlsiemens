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
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties        
        a1 = 1.9819e-06
        a2 = 0.021906
        b1 = -0.415287610631909
        b2 = 281.397582270965
        b3 = -33.2866801445654
        b4 = 15880.6096474159     
        
        aif
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
        function test_plotAif(this)
            this = this.configTracer('OO');
            this.testObj.plotAif;
            if (strcmp(this.sessionData.tracer, 'OO'))
                this.testObj.plotAifHOMetab;
                this.testObj.plotAifOO;
            end
        end
        function test_plotScannerWholebrain(this)
            this = this.configTracer('OO');
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
        
        function test_buildCbfWholebrain(this)
            this = this.configTracer('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 54.6647121712165, 'RelTol', 0.0001);
        end
        function test_buildCbvWholebrain(this)
            this = this.configTracer('OC');
            obj = this.testObj.buildCbvWholebrain;            
            this.verifyEqual(obj.product, 2.174532514791524, 'RelTol', 0.0001);
        end
        function test_buildOefWholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj;            
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext');
            obj = obj.buildOefWholebrain;
            this.verifyEqual(obj.product, nan, 'RelTol', 0.0001);
        end
        
        function test_buildCbfMap(this)
            this = this.configTracer('HO');
            obj    = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj    = obj.buildCbfMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.cbf('typ','fqfn'));
        end
        function test_buildCbvMap(this)
            this = this.configTracer('OC');
            obj  = this.testObj.buildCbvMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.cbv('typ','fqfn'));
        end
        function test_buildOefMap(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext');
            obj = obj.buildOefMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.oef('typ','fqfn'));
        end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
            import mlraichle.*;
            studyd = SynthStudyData;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY35', '');
            sessp = sessp{1};
            this.sessionData = SynthSessionData('studyData', studyd, 'sessionPath', sessp, 'tracer', '');
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
                    pic = this.sessionData.ho('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'HO';
                    this.scanner = BiographMMR(pic.niftid, 'sessionData', this.sessionData);                    
                    this.aif = Twilite('scannerData', this.scanner);
                case 'OO'
                    pic = this.sessionData.oo('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'OO';
                    this.scanner = BiographMMR(pic.niftid, 'sessionData', this.sessionData);                    
                    this.aif = Twilite('scannerData', this.scanner);
                case 'OC'
                    pic = this.sessionData.oc('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'OC';
                    this.scanner = BiographMMR(pic.niftid, 'sessionData', this.sessionData);                    
                    this.aif = Twilite('scannerData', this.scanner);
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
 			this.testObj = mlsiemens.Herscovitch1985( ...
                'sessionData', this.sessionData, ...
                'scanner', this.scanner, ...
                'aif', this.aif, ...
                'timeDuration', 40);
        end
        function teardownHerscovitch1985(this)
            setenv(upper('Test_Herscovitch1985'), '0');
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

