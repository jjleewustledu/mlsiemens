classdef Test_JSReconBuilder_fPET < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 03-Jul-2024 17:27:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
    %  Developed on Matlab 24.1.0.2628055 (R2024a) Update 4 for MACA64.  Copyright 2024 John J. Lee.
    
    properties
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

            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co");
            tracers = "co";
            taus = {2*ones(1,149)};
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                paths(1), tracer=tracers(1), taus=taus{1}, dt=2);
            toc
            % Elapsed time is 4629.934149 seconds.
        end
    end
    
    methods (TestClassSetup)
        function setupJSReconBuilder_fPET(this)
            import mlsiemens.*
            this.testObj_ = JSReconBuilder_fPET();
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
