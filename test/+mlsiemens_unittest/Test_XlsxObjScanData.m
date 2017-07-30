classdef Test_XlsxObjScanData < matlab.unittest.TestCase
	%% TEST_XLSXOBJSCANDATA 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_XlsxObjScanData)
 	%          >> result  = run(mlsiemens_unittest.Test_XlsxObjScanData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Jul-2017 18:09:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
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
            this.verifyClass(this.testObj.clocks, 'table');
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('mMR PEVCO lab'), -118);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('hand timers'),  137);
        end
	end

 	methods (TestClassSetup)
		function setupXlsxObjScanData(this)
            dataDir = fullfile(getenv('HOME'), 'Local', 'src', 'mlcvl', 'mlsiemens', 'data', '');
            studyd = mlraichle.StudyData;
            sessd  = mlraichle.SessionData( ...
                'studyData', studyd, ...
                'subjectsDirManual', dataDir, ...
                'sessionPath', fullfile(dataDir, 'HYGLY28', ''));
 			import mlsiemens.*;
 			this.testObj_ = XlsxObjScanData('sessionData', sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupXlsxObjScanDataTest(this)
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

