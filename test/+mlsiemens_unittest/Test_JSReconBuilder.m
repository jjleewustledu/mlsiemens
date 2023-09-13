classdef Test_JSReconBuilder < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 21-Nov-2022 12:16:41 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        bk
        dtor
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlsiemens.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end

        function test_BidsKit(this)
            med = this.bk.make_bids_med();

            this.verifyEqual(med.scansDir, ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211/rawdata/sub-108306/ses-20230227"))
            this.verifyEqual(med.scansPath, ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211/rawdata/sub-108306/ses-20230227"))
            this.verifyEqual(med.scansFolder, "ses-20230227")
            this.verifyEqual(med.scanPath, ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211/rawdata/sub-108306/ses-20230227/etc"))
            this.verifyEqual(med.scanFolder, "etc")
        end
        function test_vision_test_data(this)
            bmc = mlsiemens.BrainMoCo();
            call_test(bmc);
        end
        function test_jsrecon_builder(this)
        end
        function test_brainmoco_builder(this)
        end
        function test_sliding_builder(this)
        end
        function test_jsrecon_director(this)
            b = mlsiemens.JSReconBuilder();
            disp(b)
            d = mlsiemens.JSReconDirector(b);
            disp(d)
        end
        function test_construct_static(this)
            b = mlsiemens.JSReconBuilder();
            disp(b)
            d = mlsiemens.JSReconDirector(b);
            disp(d)

            ic = d.construct_static();
            ic.view()
        end
        function test_construct_dyn(this)
            b = mlsiemens.JSReconBuilder();
            disp(b)
            d = mlsiemens.JSReconDirector(b);
            disp(d)

            ic = d.construct_dyn();
            ic.view()
        end
        function test_construct_sliding(this)
            b = mlsiemens.JSReconBuilder();
            disp(b)
            d = mlsiemens.JSReconDirector(b);
            disp(d)

            ic = d.construct_sliding();
            ic.view()
        end
        function test_unpack_rawdata(this)
            this.testObj.unpack_rawdata()
        end
        function test_osem_subsets(this)
        end
        function test_osem_iterations(this)
        end
        function test_abs_scatter(this)
        end
        function test_psf(this)
        end
        function test_decimate(this)
        end
    end
    
    methods (TestClassSetup)
        function setupJSReconBuilder(this)
            import mlsiemens.*
            fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "rawdata", "sub-108306", "ses-20230227", "etc", "session_description.nii.gz");
            if ~isfile(fqfn)
                ensuredir(myfileparts(fqfn));
                mysystem("touch "+fqfn);
            end
            this.bk = mlkinetics.BidsKit.create( ...
                bids_tags="ccir1211", ...
                bids_fqfn=fqfn);
            this.dtor = JSReconDirector(bids_kit=this.bk);
            this.testObj_ = JSReconBuilder(dtor=this.dtor);
        end
    end
    
    methods (TestMethodSetup)
        function setupJSReconBuilderTest(this)
            this.testObj = copy(this.testObj_);
            this.addTeardown(@this.cleanTestMethod)
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
