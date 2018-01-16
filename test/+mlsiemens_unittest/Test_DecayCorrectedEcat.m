classdef Test_DecayCorrectedEcat < matlab.unittest.TestCase 
	%% TEST_DECAYCORRECTEDECAT  

	%  Usage:  >> results = run(mlsiemens_unittest.Test_DecayCorrectedEcat)
 	%          >> result  = run(mlsiemens_unittest.Test_DecayCorrectedEcat, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        unittest_home = '/data/nil-bluearc/arbelaez/jjlee/GluT/p8047_JJL/PET/scan1'
 		testObj 
 	end 

	methods (Test) 
        function test_load(this)
            newObj = mlsiemens.DecayCorrectedEcat.load('p8047gluc1');
            this.verifyEqual(this.testObj.counts, newObj.counts);
        end
        function test_ctor(this)
            this.verifyEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p8047gluc1_decayCorrect.nii.gz'));
            this.verifyEqual(this.testObj.scanIndex, 1);
            this.verifyEqual(this.testObj.tracer, 'gluc');
            this.verifyEqual(this.testObj.length, 44);
            this.verifyEqual(this.testObj.scanDuration, 3.618933000000000e+03);
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4),  1.389330000000000e+02, 'RelTol', 1e-6);
            this.verifyEqual(this.testObj.times(44), 3.618933000000000e+03, 'RelTol', 1e-6);
        end
        function test_taus(this)
            this.verifyEqual(this.testObj.taus(4), 30);
            this.verifyEqual(this.testObj.taus(44), 180);
        end
        function test_doseAdminDatetime(this)
            this.verifyEqual(this.testObj.doseAdminDatetime, []);
        end
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(64,64,32,4),  576.776062011719, 'RelTol', 1e-5);
            this.verifyEqual(this.testObj.counts(64,64,32,44), 4774.94970703125, 'RelTol', 1e-5);
        end
        function test_wellCounts(this)
            this.verifyEqual(this.testObj.wellCounts(64,64,32,4),  84440.0154785156, 'RelTol', 1e-5);
            this.verifyEqual(this.testObj.wellCounts(64,64,32,44), 4194315.82265625, 'RelTol', 1e-5);
        end
        function test_header(this)
            this.verifyEqual(this.testObj.header.doseAdminDatetime, 18.933);
            this.verifyEqual(this.testObj.header.string(1:25), 'rec p8047gluc1_frames.img');
            this.verifyEqual(this.testObj.header.frame(4), 5);
            this.verifyEqual(this.testObj.header.start(4), 120);
            this.verifyEqual(this.testObj.header.duration(4), 30);
        end  
        function test_isotope(this)
            this.verifyEqual(this.testObj.isotope, '11C');
        end
        function test_pie(this)            
            this.verifyEqual(this.testObj.pie, 4.88);
        end 
        function test_wellFactor(this)            
            this.verifyEqual(this.testObj.wellFactor, 20.585);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDecayCorrectedEcat(this) 
 		end 
 	end 

 	methods (TestClassTeardown) 
    end 

    methods 
        function this = Test_DecayCorrectedEcat
            this = this@matlab.unittest.TestCase;
            cd(this.unittest_home);
            import mlsiemens.* mlfourd.*;
 			this.testObj = DecayCorrectedEcat(NIfTId.load('p8047gluc1.nii.gz')); 
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

