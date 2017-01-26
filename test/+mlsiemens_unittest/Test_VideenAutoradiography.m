classdef Test_VideenAutoradiography < matlab.unittest.TestCase
	%% TEST_VIDEENAUTORADIOGRAPHY 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_VideenAutoradiography)
 	%          >> result  = run(mlsiemens_unittest.Test_VideenAutoradiography, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 25-Jan-2017 16:17:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
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
 		function test_plotInitialData(this)
            this.testObj.plotInitialData;
 		end 
 		function test_plotParVars(this)
            this.testObj.plotParVars('A0', [0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2]);
            this.testObj.plotParVars('PS', [0.01 0.02 0.03 0.04 0.05]);
            this.testObj.plotParVars('f',  [0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.015 0.02]);
            this.testObj.plotParVars('t0', [0 1 2 4 8 16 32]);
        end 
        function test_simulateItsMcmc(this)
            this.testObj.simulateItsMcmc;
        end
        function test_estimateParameters(this)
            this.testObj3 = this.testObj.estimateParameters;
        end
	end

 	methods (TestClassSetup)
		function setupVideenAutoradiography(this)
 			import mlsiemens.*;
            studyd = mlraichle.SynthStudyData;
            sessp = fullfile(studyd.subjectsDir, 'HYGLY35', '');
            this.sessionData = mlraichle.SynthSessionData('studyData', studyd, 'sessionPath', sessp);
 			this.testObj_ = VideenAutoradiography;
 		end
	end

 	methods (TestMethodSetup)
		function setupVideenAutoradiographyTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

