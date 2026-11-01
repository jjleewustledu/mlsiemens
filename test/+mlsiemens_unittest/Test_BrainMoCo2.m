classdef Test_BrainMoCo2 < matlab.unittest.TestCase
    %% Platform-independent tests of mlsiemens.BrainMoCo2 orchestration; synthetic fixtures only.
    %  e7/BMC recons themselves are exercised by Test_JSReconBuilder_Win on the Windows e7 host.
    %
    %  Created 31-Oct-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.

    properties
        tmp
    end

    methods (Test)
        function test_move_own_output(this)
            % parallel workers share sub-*/+Output; each must move only its own results
            ses = fullfile(this.tmp, "sub-1", "ses-1");
            out = fullfile(this.tmp, "sub-1", "+Output");
            mine = ["lm-start1-DynamicBMC", "lm-start1-StaticBMC"];
            others = ["lm-start10-DynamicBMC", "lm-start8-DynamicBMC", "lm-start1x-DynamicBMC"];
            for f = [mine, others]
                mkdir(fullfile(out, f));
                writelines("x", fullfile(out, f, "a.v.hdr"));
            end
            mkdir(fullfile(ses, "lm-start1"));

            bmc = mlsiemens.BrainMoCo2(source_lm_path=fullfile(ses, "lm-start1"));
            moved = bmc.move_own_output();

            this.verifyEqual(sort(mybasename(moved)), sort(mine))
            for f = mine
                this.verifyTrue(isfile(fullfile(ses, f, "a.v.hdr")), f)
                this.verifyFalse(isfolder(fullfile(out, f)), f)
            end
            for f = others
                this.verifyTrue(isfolder(fullfile(out, f)), f)   % left for their own workers
                this.verifyFalse(isfolder(fullfile(ses, f)), f)
            end
        end

        function test_move_own_output_none(this)
            ses = fullfile(this.tmp, "sub-1", "ses-1");
            mkdir(fullfile(ses, "lm-start2"));
            bmc = mlsiemens.BrainMoCo2(source_lm_path=fullfile(ses, "lm-start2"));
            this.verifyEmpty(bmc.move_own_output())
        end
    end

    methods (TestMethodSetup)
        function setupTest(this)
            pf0 = getenv("PROJECT_FOLDER");
            this.addTeardown(@() setenv("PROJECT_FOLDER", pf0))
            setenv("PROJECT_FOLDER", "CCIR_01211")
            this.tmp = string(tempname);
            mkdir(this.tmp);
            this.addTeardown(@() rmdir(this.tmp, "s"))
        end
    end
end
