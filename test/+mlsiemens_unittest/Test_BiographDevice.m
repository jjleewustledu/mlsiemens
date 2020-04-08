classdef Test_BiographDevice < matlab.unittest.TestCase
	%% TEST_BIOGRAPHDEVICE 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_BiographDevice)
 	%          >> result  = run(mlsiemens_unittest.Test_BiographDevice, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-Mar-2020 19:40:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        doseAdminDatetime1st = datetime(2019,5,23,11,29,21, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone)
        doseAdminDatetimeOC  = datetime(2019,5,23,12,22,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone)
        doseAdminDatetimeOO  = datetime(2019,5,23,12,40,17, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone)
        doseAdminDatetimeHO  = datetime(2019,5,23,13,0,52,  'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone)
        doseAdminDatetimeFDG = datetime(2019,5,23,13,30,09, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone) 
        datetimeForDecayCorrection = datetime(2019,5,23,13,30,08,0, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone) 
        fqfnRadMeas = fullfile(getenv('HOME'), 'Documents/private/CCIRRadMeasurements 2019may23.xlsx')
        radMeas        
 		registry
        sesd_fdg
        sesf_fdg = 'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC'
        sesd_ho
        sesf_ho = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC'
        sesd_oo
        sesf_oo = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC'
        sesd_oc
        sesf_oc = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC'
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
            o = this.testObj;            
            this.verifyTrue( o.calibrationAvailable)
            this.verifyEqual(o.datetimeForDecayCorrection, this.datetimeForDecayCorrection)
            this.verifyTrue( o.decayCorrected)
            this.verifyEqual(o.datetime0, this.datetimeForDecayCorrection)
            this.verifyEqual(o.datetimeF, this.datetimeForDecayCorrection + seconds(3493))
            this.verifyEqual(o.datetimeMeasured, this.datetimeForDecayCorrection)
            this.verifyEqual(o.datetimeWindow, duration(0,58,13))
            this.verifyEqual(length(o.datetimes), 62)
            this.verifyEqual(o.index0, 1)
            this.verifyEqual(o.indexF, 62)
            this.verifyEqual(o.time0, 0)
            this.verifyEqual(o.timeF, 3493)
            this.verifyEqual(o.times, [0 10 23 37 53 70 89 109 131 154 179 205 233 262 293 325 359 394 431 469 509 550 593 637 683 730 779 829 881 934 990 1047 1106 1166 1228 1291 1356 1422 1490 1559 1630 1702 1776 1852 1930 2009 2090 2172 2256 2341 2428 2516 2607 2699 2793 2888 2985 3083 3183 3284 3388 3493])
            this.verifyEqual(o.timeWindow, 3493)
            disp(o)
        end
        function test_invEfficiencyf(this)
            this.verifyEqual(this.testObj.invEfficiencyf(this.sesd_fdg), 1.151594194977168, 'RelTol', 1e-10)
        end        
        function test_plot(this)
            plot(this.testObj)            
            plot(this.testObj, 'this.datetime', 'this.countRate')
            plot(this.testObj, 'this.datetime', 'this.activityDensity(''decayCorrected'', true)')
        end
        function test_plot_ho(this)
            o = mlsiemens.BiographMMRDevice.createFromSession(this.sesd_ho);
            plot(o)
            plot(o, 'this.datetime', 'this.activityDensity(''decayCorrected'', true)')
        end
        function test_plot_oo(this)
            o = mlsiemens.BiographMMRDevice.createFromSession(this.sesd_oo);
            plot(o)
            plot(o, 'this.datetime', 'this.activityDensity(''decayCorrected'', true)')
        end
        function test_plot_oc(this)
            o = mlsiemens.BiographMMRDevice.createFromSession(this.sesd_oc);
            plot(o)
            plot(o, 'this.datetime', 'this.activityDensity(''decayCorrected'', true)')
        end
	end

 	methods (TestClassSetup)
		function setupBiographDevice(this)
            this.sesd_fdg = mlraichle.SessionData.create(this.sesf_fdg);
            this.sesd_ho  = mlraichle.SessionData.create(this.sesf_ho);
            this.sesd_oo  = mlraichle.SessionData.create(this.sesf_oo);
            this.sesd_oc  = mlraichle.SessionData.create(this.sesf_oc);
            this.radMeas = mlpet.CCIRRadMeasurements.createFromSession(this.sesd_fdg);
 		end
	end

 	methods (TestMethodSetup)
		function setupBiographDeviceTest(this)
 			this.testObj = mlsiemens.BiographMMRDevice.createFromSession(this.sesd_fdg);
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

