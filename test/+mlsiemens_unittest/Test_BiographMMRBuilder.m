classdef Test_BiographMMRBuilder < matlab.unittest.TestCase
	%% TEST_BIOGRAPHMMRBUILDER 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_BiographMMRBuilder)
 	%          >> result  = run(mlsiemens_unittest.Test_BiographMMRBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 09-Jan-2018 18:19:55 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
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
	end

 	methods (TestClassSetup)
		function setupBiographMMRBuilder(this)
 			import mlsiemens.*;
 			this.testObj_ = BiographMMRBuilder;
 		end
	end

 	methods (TestMethodSetup)
		function setupBiographMMRBuilderTest(this)
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

