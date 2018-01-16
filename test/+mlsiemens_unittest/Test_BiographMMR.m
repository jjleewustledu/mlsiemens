classdef Test_BiographMMR < matlab.unittest.TestCase
	%% TEST_BIOGRAPHMMR 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_BiographMMR)
 	%          >> result  = run(mlsiemens_unittest.Test_BiographMMR, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 30-Jan-2017 02:09:33
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        sessPath = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28'
 		registry
 		testObj
    end
    
    properties (Dependent)
        ifhFile
    end
    
    methods %% GET
        function g = get.ifhFile(this)
            g = fullfile(this.sessPath, 'V1/FDG_V1-NAC/fdgv1r1.4dfp.ifh');
        end
    end

	methods (Test)
		function test_afun(this)
 			import mlsiemens.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_view(this)
            this.testObj.viewer = '/usr/local/fsl/bin/fsleyes';
            this.testObj.view;
        end
	end

 	methods (TestClassSetup)
		function setupBiographMMR(this)
            import mlsiemens.* mlraichle.*;
            sessd = SessionData( ...
                'studyData', StudyData, 'sessionPath', this.sessPath); % 'ac', false, 'tracer', 'FDG'
 			this.testObj_ = BiographMMR( ...
                mlfourd.NIfTId.load(this.ifhFile), 'sessionData', sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupBiographMMRTest(this)
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

