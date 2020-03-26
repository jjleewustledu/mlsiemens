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
        session
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
        
        function test_calibrationAvailable(this)
            obj = mlsiemens.BiographCalibration.createFromSession(this.session);
            this.verifyEqual(obj.calibrationAvailable, true)
        end
        function test_invEfficiencyf(this)
            obj = mlsiemens.BiographCalibration.createFromSession(this.session);
            this.verifyEqual(obj.invEfficiencyf, [], 'RelTol', 1e-4)
        end
        function test_census(this)
            singularity = getenv('SINGULARITY_HOME');
            for proj = globFoldersT(fullfile(singularity, 'CCIR_*'))
                for ses = globFoldersT(fullfile(proj{1}, 'ses-E*'))
                    for fdg = globFoldersT(fullfile(ses{1}, 'FDG_DT*-Converted-AC'))
                        str = fullfile(mybasename(proj{1}), mybasename(ses{1}), mybasename(fdg{end}));
                        sesd = mlraichle.SessionData.create(str);
                        try
                            if datetime(sesd) > datetime(2016, 4, 1, 'TimeZone', 'America/Chicago')
                                disp(sesd)
                                bcal = mlsiemens.BiographCalibration.createFromSession(sesd);
                                this.verifyTrue(isrow(bcal.invEfficiencyf(sesd)));
                                bcal.plot()
                            end
                        catch ME
                            handwarning(ME)
                        end
                    end
                end
            end
        end
	end

 	methods (TestClassSetup)
		function setupBiographCalibration(this)
 			import mlsiemens.*;
            this.session = mlraichle.SessionData.create('CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC');
 			this.testObj_ = BiographCalibration.createFromSession(this.session);
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

