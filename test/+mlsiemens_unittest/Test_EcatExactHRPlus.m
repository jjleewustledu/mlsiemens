classdef Test_EcatExactHRPlus < matlab.unittest.TestCase 
	%% TEST_ECATEXACTHRPLUS  

	%  Usage:  >> results = run(mlsiemens_unittest.Test_EcatExactHRPlus)
 	%          >> result  = run(mlsiemens_unittest.Test_EcatExactHRPlus, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
 		testObj 
        home = '/data/cvl/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1_frames'
        tracerResolved = 'p7267ho1'
        pie = 5.2038
        mask
 	end 

	methods (Test) 
        function test_ctor(this)
            %this.verifyEqual(this.testObj., )
            this.verifyEqual(this.testObj.fqfilename, fullfile(this.home, [this.tracerResolved '.nii.gz']));
            this.verifyEqual(this.testObj.isDecayCorrected, false);
            this.verifyEqual(this.testObj.scanIndex, 1);
            this.verifyEqual(this.testObj.length, 60);
            this.verifyEqual(this.testObj.scanDuration, 1.613330000000000e+02);
            this.verifyEqual(this.testObj.tracer, 'ho');
            this.verifyEqual(this.testObj.wellFactor, 11.314);
            this.verifyEqual(this.testObj.doseAdminDatetime, 41.332999999999998);
            this.verifyEqual(this.testObj.dt, 2);
            this.verifyEqual(this.testObj.time0, 43.332999999999998);
            this.verifyEqual(this.testObj.timeF, 1.613330000000000e+02);
            [~,fn,x] = fileparts(this.testObj.hdrinfoFqfilename);
            this.verifyEqual([fn x], 'p7267ho1_g3.hdrinfo')
        end
        function test_pie(this)
            this.verifyEqual(this.testObj.pie, this.pie);
            this.verifyEqual(this.testObj.efficiencyFactor, 60*this.pie*this.testObj.dt);
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4), 49.332999999999998);
            this.verifyEqual(this.testObj.times(60), 1.613330000000000e+02);
        end
        function test_timesMidpoints(this)
        end
        function test_taus(this)
        end
        function test_timeInterpolants(this)
            this.verifyEqual(this.testObj.timeInterpolants(60), 161.333);
        end
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(64,64,30,4), 63);
            this.verifyEqual(this.testObj.counts(64,64,30,60), 125);
        end
        function test_countInterpolants(this)
            obj = this.testObj;
            obj.counts = obj.counts(64,64,30,:);
            this.verifyEqual(obj.countInterpolants(4), 63, 'RelTol', 1e-5);
        end
        function test_wellCounts(this)
            this.verifyEqual(this.testObj.wellCounts(64,64,30,4), 655.6788);
            this.verifyEqual(this.testObj.wellCounts(64,64,30,60), 1300.95);
            
            this.testObj = this.testObj.volumeSummed;
            this.verifyEqual(max(this.testObj.wellCounts), 285232225.9248, 'RelTol', 1e-8);
            this.verifyEqual(min(this.testObj.wellCounts), 2253151.7316,   'RelTol', 1e-8);
        end
        function test_wellCountInterpolants(this)
            obj = this.testObj;
            obj.counts = obj.counts(64,64,30,:);
            this.verifyEqual(obj.wellCountInterpolants(4), 655.6788, 'RelTol', 1e-5);
        end
        function test_header(this)
            this.verifyEqual(this.testObj.header.doseAdminDatetime, 41.333);
            this.verifyEqual(this.testObj.header.string(1:23), 'rec p7267ho1_frames.img');
            this.verifyEqual(this.testObj.header.frame(4), 5);
            this.verifyEqual(this.testObj.header.start(4), 8); 
            this.verifyEqual(this.testObj.header.duration(4), 2);
        end
        function test_numel(this)
            this.verifyEqual(numel(this.testObj), 128*128*63*60);
        end
        function test_numelMasked(this)
            this.testObj = this.testObj.masked(this.mask);
            this.verifyEqual(numel(this.testObj), 128*128*63*60);
            this.verifyEqual(numelMasked(this.testObj), 1); 
            % manually verified this.testObj.img has only a single voxel over time
        end
 	end 

 	methods (TestClassSetup) 
 		function setupEcatExactHRPlus(this) 
            cd(this.home);
 			this.testObj = mlsiemens.EcatExactHRPlus(mlfourd.NIfTId.load(this.tracerResolved)); 
            this.mask = this.makeMask;
 		end 
 	end 

 	methods (TestClassTeardown) 
    end 
    
    methods 
        function m = makeMask(this)
            m = this.testObj.component;
            m.img = m.img(:,:,:,1);
            m = m.zeros;
            m.img(64,64,32) = 1;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

