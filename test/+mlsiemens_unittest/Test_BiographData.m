classdef Test_BiographData < matlab.unittest.TestCase
	%% TEST_BIOGRAPHDATA 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_BiographData)
 	%          >> result  = run(mlsiemens_unittest.Test_BiographData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 13-Mar-2020 22:55:55 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        doseAdminDatetime1st = datetime(2019,5,23,11,29,21, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeOC  = datetime(2019,5,23,12,22,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeOO  = datetime(2019,5,23,12,40,17, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeHO  = datetime(2019,5,23,13,0,52,  'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeFDG = datetime(2019,5,23,13,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);        
        fqfnRadMeas = fullfile(getenv('HOME'), 'Documents/private/CCIRRadMeasurements 2019may23.xlsx')
        radMeas
 		registry        
        sesd_fdg
        sesf_fdg = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC';
        sesp_fdg = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC'); 
        sesd_ho
        sesf_ho  = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC';
        sesp_ho  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC');        
        sesd_oo
        sesf_oo  = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC';
        sesp_oo  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC');        
        sesd_oc
        sesf_oc  = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC';
        sesp_oc  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC');
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
            disp(this.testObj)
        end
        function test_imagingContext(this)
            nii = this.testObj.imagingContext.nifti;
            this.verifyEqual(dipmax(nii.img(:,:,:,end)), 44171.1640625, 'RelTol', 1e-4)
            %this.testObj.imagingContext.fsleyes
        end
        function test_activityDensity_diff_ho(this)
            ho = mlsiemens.BiographMMRData.createFromSession(this.sesd_ho);
            ad = ho.activityDensity('volumeAveraged', true);
            figure
            plot(ho.times, ad, ':o')
            xlabel('times / s')
            ylabel('activity density / (Bq/mL)')
            title('volume averaged over FOV')
            dad = ho.activityDensity('volumeAveraged', true, 'diff', true);
            figure
            plot(ho.times, [dad dad(end)], ':o')
            xlabel('times / s')
            ylabel('diff activity density / (Bq/mL)')
            title('volume averaged over FOV')
        end
        function test_activityDensity_fdg(this)
            fdg = mlsiemens.BiographMMRData.createFromSession(this.sesd_fdg);
            ic = mlfourd.ImagingContext2(fdg.activityDensity);
            this.verifyFalse(fdg.decayCorrected)
            nii = ic.nifti;
            this.verifyEqual(dipmax(nii.img(:,:,:,end)), 30410.41015625, 'RelTol', 1e-4)
            %ic.fsleyes
        end
        function test_activityDensity_oc(this)
            oc = mlsiemens.BiographMMRData.createFromSession(this.sesd_oc);
            ic = mlfourd.ImagingContext2(oc.activityDensity);
            this.verifyFalse(oc.decayCorrected)
            nii = ic.nifti;
            this.verifyEqual(dipmax(nii.img(:,:,:,end)), 32427.08203125, 'RelTol', 1e-4)
            ic.fsleyes
        end
        function test_activityDensity_oo(this)
            oo = mlsiemens.BiographMMRData.createFromSession(this.sesd_oo);
            ic = mlfourd.ImagingContext2(oo.activityDensity);
            this.verifyFalse(oo.decayCorrected)
            nii = ic.nifti;
            this.verifyEqual(dipmax(nii.img(:,:,:,end)), 12970.8154296875, 'RelTol', 1e-4)
            ic.fsleyes
        end
        function test_activityDensity_ho(this)
            ho = mlsiemens.BiographMMRData.createFromSession(this.sesd_ho);
            ic = mlfourd.ImagingContext2(ho.activityDensity);
            this.verifyFalse(ho.decayCorrected)
            nii = ic.nifti;
            this.verifyEqual(dipmax(nii.img(:,:,:,end)), 22115.287109375, 'RelTol', 1e-4)
            ic.fsleyes
        end
        function test_countRate_fdg(this)
            fdg = mlsiemens.BiographMMRData.createFromSession(this.sesd_fdg);
            ic = mlfourd.ImagingContext2(fdg.countRate);
            this.verifyTrue(fdg.decayCorrected)
            ic = ic.volumeAveraged();
            nii = ic.nifti;
            this.verifyEqual(nii.img(end), single(5.2259735e+02), 'RelTol', 1e-4)
            plot(nii.img)
        end
        function test_countRate_oc(this)
            oc = mlsiemens.BiographMMRData.createFromSession(this.sesd_oc);
            ic = mlfourd.ImagingContext2(oc.countRate);
            this.verifyTrue(oc.decayCorrected)
            ic = ic.volumeAveraged();
            nii = ic.nifti;
            this.verifyEqual(nii.img(end), single(1.7175701e+03), 'RelTol', 1e-4)
            plot(nii.img)
        end
        function test_countRate_oo(this)
            oo = mlsiemens.BiographMMRData.createFromSession(this.sesd_oo);
            ic = mlfourd.ImagingContext2(oo.countRate);
            this.verifyTrue(oo.decayCorrected)
            ic = ic.volumeAveraged();
            nii = ic.nifti;
            this.verifyEqual(nii.img(end), single(1.7039740e+03), 'RelTol', 1e-4)
            plot(nii.img)
        end
        function test_countRate_ho(this)
            ho = mlsiemens.BiographMMRData.createFromSession(this.sesd_ho);
            ic = mlfourd.ImagingContext2(ho.countRate);
            this.verifyTrue(ho.decayCorrected)
            ic = ic.volumeAveraged();
            nii = ic.nifti;
            this.verifyEqual(nii.img(end), single(3.2051624e+03), 'RelTol', 1e-4)
            plot(nii.img)
        end
        function test_plot(this)
            this.testObj.plot()
        end
        function test_plot_ho(this)
            o = mlsiemens.BiographMMRData.createFromSession(this.sesd_ho);
            plot(o)
        end
        function test_plot_oo(this)
            o = mlsiemens.BiographMMRData.createFromSession(this.sesd_oo);
            plot(o)
        end
        function test_plot_oc(this)
            o = mlsiemens.BiographMMRData.createFromSession(this.sesd_oc);
            plot(o)
        end
        function test_shiftWorldlines(this)            
            this.testObj.plot()
            this.testObj.shiftWorldlines(1000)            
            this.testObj.plot()
            title('Test\_BiographData.test\_shiftWorldlines()')
        end
	end

 	methods (TestClassSetup)
		function setupBiographData(this)
            this.sesd_fdg = mlraichle.SessionData.create(this.sesf_fdg);
            this.sesd_fdg.rnumber = 2;
            this.sesd_ho  = mlraichle.SessionData.create(this.sesf_ho);
            this.sesd_ho.rnumber  = 2;
            this.sesd_oo  = mlraichle.SessionData.create(this.sesf_oo);
            this.sesd_oo.rnumber  = 2;
            this.sesd_oc  = mlraichle.SessionData.create(this.sesf_oc);
            this.sesd_oc.rnumber  = 2;
            this.radMeas  = mlpet.RadMeasurements.createFromSession('sessionData', this.sesd_fdg);
 		end
	end

 	methods (TestMethodSetup)
		function setupBiographDataTest(this) 			
 			import mlsiemens.*;			
 			this.testObj = BiographMMRData.createFromSession(this.sesd_fdg);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

