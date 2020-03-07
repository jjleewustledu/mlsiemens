classdef Test_BiographCalibration < matlab.unittest.TestCase
	%% TEST_BIOGRAPHCALIBRATION 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_BiographCalibration)
 	%          >> result  = run(mlsiemens_unittest.Test_BiographCalibration, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 05-Mar-2020 16:04:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		registry
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
            this.verifyEqual(this.testObj.invEfficiency, 1, 'RelTol', 1e-4)
        end
	end

 	methods (TestClassSetup)
		function setupBiographCalibration(this)
 			import mlsiemens.*;
            ses = mlraichle.SessionData.create('CCIR_00559/ses-E03056');
 			this.testObj_ = BiographCalibration.createBySession(ses);
 		end
	end

 	methods (TestMethodSetup)
		function setupBiographCalibrationTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

