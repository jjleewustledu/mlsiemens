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
        fast = true
        fqfnman = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'CCIRRadMeasurements 2016sep23.xlsx')
        imgVoxel = [58.2434768676758 1658.99743652344 6142.1376953125 4074.98046875 4250.21337890625 4934.9404296875 4842.73193359375 4862.275390625 4727.00732421875 4778.6591796875 4935.8046875 4926.92822265625 4150.65869140625 4330.95751953125 4470.31298828125 4566.6083984375 4691.92822265625 4704.38623046875 4787.18359375 4979.2861328125 4998.95654296875 5046.90673828125 5120.0546875 5131.08642578125 5240.90576171875 5229.48974609375 5235.5322265625 5292.6494140625 5310.2236328125 5310.328125 5373.00830078125 5340.107421875 5345.13720703125 5379.31884765625 5412.7998046875 5385.89404296875 5387.076171875 5462.439453125 5447.88818359375 5439.6689453125 5517.44140625 5491.05126953125 5544.3251953125 5547.60498046875 5550.63720703125 5547.34765625 5460.4208984375 5559.24169921875 5569.87646484375 5592.14013671875 5571.49755859375 5549.41015625 5636.46240234375 5582.62109375 5630.07666015625 5615.9111328125 5623.47314453125 5569.02685546875 5607.09765625 5662.9404296875 5672.3095703125 5640.005859375 5670.65087890625 5653.4033203125 5666.47900390625 5653.91064453125 5604.58056640625 5657.0517578125 5644.8818359375 5627.35302734375 5592.359375 5690.32958984375 5665.19384765625]
        invEff = 1.155
        msk = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/aparcAsegBinarized_op_fdgv2r1.4dfp.hdr'
 		registry
        sessd
        sessdt = datetime(2016,9,23, 12,43,52);
        sessp = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28'
 		testObj
        tracerResolvedFast = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/fdgv2r2_fast.4dfp.hdr';
    end

	methods (Test)
        function test_ctor(this)
            this.verifyClass(this.testObj, 'mlsiemens.BiographMMR')
            this.verifyEqual(this.testObjImg111, this.imgVoxel, 'RelTol', 1e-6);
        end
        function test_view(this)
            if (this.fast) 
                return
            end
            this.testObj.viewer = '/usr/local/fsl/bin/fsleyes';
            this.testObj.view;
        end
        function test_countsEtc(this)
            this.verifyEqual(this.testObjActivity111, ...
                this.testObj.invEfficiency*this.imgVoxel*this.testObj.voxelVolume, 'RelTol', 1e-6);
            this.verifyEqual(this.testObjCounts111, ...
                this.imgVoxel, 'RelTol', 1e-6);
            this.verifyEqual(this.testObjSpecificActivity111, ...
                this.testObj.invEfficiency*this.imgVoxel, 'RelTol', 1e-6);
        end
        function test_isDecayCorrected(this)
            this.verifyTrue(this.testObj.isDecayCorrected);
            this.testObj.isDecayCorrected = false;
            vxl = this.testObjImg111;
            this.verifyEqual(vxl(1),   this.imgVoxel(1), 'RelTol', 1e-6);
            this.verifyEqual(vxl(end), 3.903163085937500e+03, 'RelTol', 1e-6);   
        end
        
        function test_times(this)
            % get
            this.verifyEqual(this.testObj.times, this.sessd.times);
        end
        function test_taus(this)
            % get
            this.verifyEqual(this.testObj.taus, this.sessd.taus);
            % set
            %this.testObj.taus = 0.01:0.01:1;
            %this.verifyEqual(this.testObj.taus, 0.01:0.01:1);
        end
        function test_datetime(this)
            % get
            dt_ = this.testObj.datetime;
            this.verifyEqual(dt_(1),   this.testObj.datetime0);
            this.verifyEqual(dt_(end), this.testObj.datetime0 + seconds(3540)); % start time of last frame
        end
        function test_setTime0ToInflow(this)
            this.testObj = this.testObj.shiftTimes(30);
            this.verifyEqual(this.testObj.time0, 0);
            this.testObj = this.testObj.setTime0ToInflow;            
            this.verifyEqual(this.testObj.time0, 30);
        end
        
        function test_volumeAveraged(this)
            this.testObj = this.testObj.volumeAveraged;            
            this.verifyEqual( ...
                double(this.testObj.img), this.imgVoxel, 'RelTol', 1e-6);
            this.verifyEqual( ...
                double(this.testObj.counts), this.imgVoxel, 'RelTol', 1e-6);
            this.verifyEqual( ...
                double(this.testObj.specificActivity), this.imgVoxel*this.testObj.invEfficiency, 'RelTol', 1e-6);
        end
        function test_volumeSummed(this)
            this.testObj = this.testObj.volumeSummed;
            this.verifyClass(this.testObj, 'mlsiemens.BiographMMR');
            
            img  = this.testObj.img;
            cnts = this.testObj.counts;
            sa   = this.testObj.specificActivity;
            this.verifyTrue(size(img,2)  > size(img,1));
            this.verifyTrue(size(cnts,2) > size(cnts,1));
            this.verifyTrue(size(sa,2)   > size(sa,1));
        end
        function test_volumeContracted(this)
            this.testObj = this.testObj.volumeContracted;
            this.verifyClass(this.testObj, 'mlsiemens.BiographMMR');
            
            img  = this.testObj.img;
            cnts = this.testObj.counts;
            sa   = this.testObj.specificActivity;
            this.verifyTrue(size(img,2)  > size(img,1));
            this.verifyTrue(size(cnts,2) > size(cnts,1));
            this.verifyTrue(size(sa,2)   > size(sa,1));
        end
	end

 	methods (TestClassSetup)
		function setupBiographMMR(this)
            import mlsiemens.* mlraichle.*;
            warning('off', 'mlfourd:possibleMaskingError');
            this.sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', this.sessp, ...
                'ac', true, ...
                'tracer', 'FDG');
            mand = XlsxObjScanData( ...
                'sessionData', this.sessd, ...
                'fqfilename', this.fqfnman);
 			this.testObj_ = BiographMMR( ...
                mlfourd.NIfTId.load(this.tracerResolvedFast), ...
                'sessionData', this.sessd, ...
                'manualData', mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('[18F]DG'), ...
                'invEfficiency', this.invEff);
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
        function v = testObjActivity111(this)
            v = double(squeeze(this.testObj.activity(1,1,1,:)))';
        end
        function v = testObjCounts111(this)
            v = double(squeeze(this.testObj.counts(1,1,1,:)))';
        end
        function v = testObjImg111(this)
            v = double(squeeze(this.testObj.img(1,1,1,:)))';
        end
        function v = testObjSpecificActivity111(this)
            v = double(squeeze(this.testObj.specificActivity(1,1,1,:)))';
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

