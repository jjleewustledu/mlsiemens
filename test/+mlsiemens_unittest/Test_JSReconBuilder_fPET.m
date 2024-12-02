classdef Test_JSReconBuilder_fPET < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 03-Jul-2024 17:27:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
    %  Developed on Matlab 24.1.0.2628055 (R2024a) Update 4 for MACA64.  Copyright 2024 John J. Lee.
    
    properties
<<<<<<< HEAD
        dtor
=======
>>>>>>> 71f9de38456de2594c377c13a03e9e944d4a839c
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlsiemens.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_BMC_create_simple(this)

<<<<<<< HEAD
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm");
=======
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co");
>>>>>>> 71f9de38456de2594c377c13a03e9e944d4a839c
            tracers = "co";
            taus = {2*ones(1,149)};
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                paths(1), tracer=tracers(1), taus=taus{1}, dt=2);
            toc
            % Elapsed time is 4629.934149 seconds.
        end
<<<<<<< HEAD
        function test_BMC_create_co(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm");
            tracers = "co";
            taus = {3*ones(1,96)};

            for pth = paths
                pwd0 = pushd(pth);
                tic
                mlsiemens.BrainMoCo2.create_moving_average(pth, tracer=tracers, taus=taus{1}, nifti_only=false);
                toc
                popd(pwd0);
            end
        end
        function test_BMC_create_ho_x7(this)
            % lm durations:  
            %   425
            %   425
            %   425
            %   425
            %   425
            %   365
            %   425?

            lm_durations = [425, 425, 425, 425, 425, 365, 425];
            paths = [ ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108237\ses-20221031110638", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108250\ses-20221207102944", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108254\ses-20221116104751", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108284\ses-20230220103226", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108284\ses-20230220112328", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421152358", "lm"), ...
                fullfile("D:\CCIR_01211\sourcedata\sub-108306\ses-20230227113853", "lm")];
            tracers = "ho";

            idx = 0;
            for pth = paths
                idx = idx + 1;
                pwd0 = pushd(pth);
                tic
                taus = {3*ones(1, floor(lm_durations(idx)/3))};  % taus passed as singleton cell containing array
                mlsiemens.BrainMoCo2.create_moving_average(pth, tracer=tracers, taus=taus{1}, nifti_only=false);
                toc
                popd(pwd0);
            end
        end
        function test_BMC_create_co_x5(this)
            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108237", "ses-20221031100910", "lm"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108250", "ses-20221207093856", "lm"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108254", "ses-20221116095143", "lm"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108284", "ses-20230220093702", "lm"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108306", "ses-20230227103048", "lm")];
                % fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm");
            tracers = "co";
            taus = {3*ones(1,96)};

            for pth = paths
                pwd0 = pushd(pth);
                tic
                mlsiemens.BrainMoCo2.create_moving_average(pth, tracer=tracers, taus=taus{1}, nifti_only=false);
                toc
                popd(pwd0);
            end
        end
=======
>>>>>>> 71f9de38456de2594c377c13a03e9e944d4a839c
    end
    
    methods (TestClassSetup)
        function setupJSReconBuilder_fPET(this)
            import mlsiemens.*
<<<<<<< HEAD

            % fqfn = fullfile(getenv("SINGULARITY_HOME"), ...
            %     "CCIR_01211", "rawdata", "sub-108306", "ses-20230227", "etc", "session_description.nii.gz");
            % if ~isfile(fqfn)
            %     ensuredir(myfileparts(fqfn));
            %     mysystem("touch "+fqfn);
            % end
            % this.bk = mlkinetics.BidsKit.create( ...
            %     bids_tags="ccir1211", ...
            %     bids_fqfn=fqfn);
            % this.dtor = JSReconDirector(bids_kit=this.bk);

            this.testObj_ = [];  % JSReconBuilder_fPET(dtor=this.dtor);
=======
            this.testObj_ = JSReconBuilder_fPET();
>>>>>>> 71f9de38456de2594c377c13a03e9e944d4a839c
        end
    end
    
    methods (TestMethodSetup)
        function setupJSReconBuilder_fPETTest(this)
            this.testObj = this.testObj_;
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
