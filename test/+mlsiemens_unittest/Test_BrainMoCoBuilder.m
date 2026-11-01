classdef Test_BrainMoCoBuilder < matlab.unittest.TestCase
    %% Platform-independent tests of mlsiemens.BrainMoCoBuilder's cross-calibration manifest.
    %  Staging itself runs on vglab2 (Test_JSReconBuilder_Win.test_BMCBuilder_build_crosscal*).
    %
    %  Created 01-Nov-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.

    methods (Test)
        function test_read_crosscal_manifest(this)
            T = mlsiemens.BrainMoCoBuilder.read_crosscal_manifest();
            this.verifyTrue(all(ismember(["108293", "108284", "108250", "108254", "108306", "108237"], T.sub)))
            this.verifyTrue(all(ismember(T.status, ["ready", "staged", "blocked_no_ct", "blocked_no_lm"])))

            r = T(T.sub == "108284", :);
            this.verifyTrue(ismember(r.status, ["ready", "staged"]), r.status)
            this.verifyEqual(r.ct_series, "3")
            this.verifyEqual(r.series_pet{1}, ["2", "3"])
            this.verifyEqual(r.ses, "20230220122457")

            r = T(T.sub == "108293", :);
            this.verifyEqual(r.ct_series, "16")
            this.verifyEqual(r.series_pet{1}, ["15", "16", "17", "18"])

            % rows that can be staged must name listmode, DICOM and CT
            ok = ismember(T.status, ["ready", "staged"]);
            this.verifyTrue(all(strlength(T.lm_folder(ok)) > 0 & strlength(T.dcm_folder(ok)) > 0 & ...
                strlength(T.ct_series(ok)) > 0))
        end

        function test_stage_skips_blocked_rows(this)
            % blocked rows are reported as skipped with their reason, and nothing is staged;
            % rows are chosen from the manifest's current statuses, which change as phantoms unblock
            T = mlsiemens.BrainMoCoBuilder.read_crosscal_manifest();
            blocked = T(startsWith(T.status, "blocked"), :);
            this.assumeNotEmpty(blocked, "no blocked rows left in the manifest")
            report = mlsiemens.BrainMoCoBuilder.stage_crosscal_phantoms(subs=blocked.sub');
            this.verifyEqual(sort(report.sub), sort(blocked.sub))
            this.verifyTrue(all(report.outcome == "skipped"))
            for si = 1:height(blocked)
                this.verifyEqual(report.detail(report.sub == blocked.sub(si)), blocked.status(si))
            end
        end

        function test_stage_unknown_sub_fails_loudly(this)
            this.verifyError(@() mlsiemens.BrainMoCoBuilder.stage_crosscal_phantoms(subs="999999"), ...
                "mlsiemens:ValueError")
        end
    end
end
