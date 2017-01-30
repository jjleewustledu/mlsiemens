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
        % from '/Volumes/SeagateBP4/cvl/np755/mm01-007_p7267_2008jun16/bayesian_pet'
        % whole-brain CBF = 56.417 mL/100g/min on vidi, 40% uthresh
        %                 = 0.00987298 1/s        
        %              af = 2.035279E-06 from metcalc
        %              bf = 2.096733E-02 
        % estimated    A0 = 0.290615
        
        dcvShift  = -18
        ecatShift = -6
        pie       = 5.2038;
        sessionData
 		testObj
 	end

	methods (Test)
 		function test_plotInitialData(this)
            this.testObj.plotInitialData;
 		end 
 		function test_plotParVars(this)
            this.testObj.plotParVars('A0', [0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36]);
            this.testObj.plotParVars('f',  [0.005 0.006 0.007 0.008 0.009 0.01 0.011 0.012 0.013]);
        end 
        function test_simulateItsMcmc(this)
            this.testObj.simulateItsMcmc;
        end
        function test_estimateParameters(this)
            this.testObj = this.testObj.estimateParameters;
        end
	end

 	methods (TestClassSetup)
		function setupVideenAutoradiography(this)
 			import mlderdeyn.* mlsiemens.*;
            studyd = StudyDataSingleton.instance;
            sessp = fullfile(studyd.subjectsDir, 'mm01-007_p7267_2008jun16', '');
            this.sessionData = SessionData('studyData', studyd, 'sessionPath', sessp);
 			this.testObj_ = VideenAutoradiography( ...
                'sessionData', this.sessionData, ...
                'concAShift', this.dcvShift, ...
                'concObsShift', this.ecatShift, ...
                'pie', this.pie);
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

