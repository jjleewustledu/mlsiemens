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

        function test_bmc_js_state(this)
            % lines 1476-1480 of Siemens BMC.js as on MATTA, tab-indented, CRLF
            t = char(9);
            head = [ ...
                string(repmat(t, 1, 4)) + "FName = BMCInput + ""-LM-00-dynamic_mc"" + ii + "".mhdr"";", ...
                string(repmat(t, 1, 4)) + "if( fso.FileExists( FName ) ){", ...
                string(repmat(t, 1, 5)) + "fso.CopyFile( BMCInput + ""-LM-00-dynamic_mc"" + ""*"", OutDYN + ""\\"" );"];
            tail = string(repmat(t, 1, 4)) + "}";
            brk = string(repmat(t, 1, 5)) + "break; // jjlee 2026-10-31: the wildcard copies every frame";

            write = @(name, ls) writelines(join(ls, sprintf('\r\n')), fullfile(this.tmp, name));
            write("orig.js", [head, tail]);
            write("patched.js", [head, brk, tail]);
            write("other.js", ["var x = 1;", "fso.CopyFile( a, b );"]);

            B = @mlsiemens.BrainMoCo2.bmc_js_state;
            this.verifyEqual(B(fullfile(this.tmp, "orig.js")), "unpatched")
            this.verifyEqual(B(fullfile(this.tmp, "patched.js")), "patched")
            this.verifyEqual(B(fullfile(this.tmp, "other.js")), "unrecognized")
            this.verifyEqual(B(fullfile(this.tmp, "absent.js")), "absent")
        end

        function test_umap_source(this)
            % sidecars name the CT series that built the mu-map; absence is "unmeasured", not a pass
            ses = fullfile(this.tmp, "sub-1", "ses-1");
            mkdir(fullfile(ses, "lm"));
            s = mlsiemens.BrainMoCo2.umap_source(ses);
            this.verifyEqual(s.state, "unmeasured")

            mkdir(fullfile(ses, "lm", "CT"));
            ct_sop = '1.2.840.10008.5.1.4.1.1.2';  % CT Image Storage; dicomwrite wants char, not string
            md = struct('SOPClassUID', ct_sop, 'MediaStorageSOPClassUID', ct_sop, ...
                'Modality', 'CT', 'SeriesNumber', 2, 'SeriesDescription', 'AC   CT Brain  3.0  Hr38', ...
                'ReconstructionDiameter', 500, 'ConvolutionKernel', 'Hr38f', 'TableHeight', 99);
            dicomwrite(zeros(4, 4, "uint16"), fullfile(ses, "lm", "CT", "a.dcm"), md, CreateMode="Copy");
            s = mlsiemens.BrainMoCo2.umap_source(ses);
            this.verifyEqual(s.state, "measured")
            this.verifyEqual(double(s.SeriesNumber), 2)
            this.verifyEqual(double(s.ReconstructionDiameter), 500)
            this.verifyTrue(contains(string(s.SeriesDescription), "AC"))
        end

        function test_code_provenance(this)
            s = mlsiemens.BrainMoCo2.code_provenance();
            this.verifyEqual(s.state, "measured")
            this.verifyMatches(s.mlsiemens_commit, "^[0-9a-f]{40}$")
            this.verifyTrue(islogical(s.mlsiemens_modified))
            this.verifyTrue(isfolder(s.mlsiemens_path))
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
