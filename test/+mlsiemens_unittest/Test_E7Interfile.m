classdef Test_E7Interfile < matlab.unittest.TestCase
    %% Tests mlsiemens.E7Interfile and its use by mlsiemens.BrainMoCo2:  NIfTI headers and json
    %  sidecars from the e7 recon itself (not the [15O]O2 template vision_zeros_440x440x159), and
    %  build_clean() deleting only duplicate listmode.  Synthetic fixtures; runs on any platform.
    %
    %  Created 31-Oct-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.

    properties
        tmp  % per-test folder
        v_fqfn
    end

    methods (Test)
        function test_parse(this)
            m = mlsiemens.E7Interfile.parse({ ...
                '!INTERFILE:=', ...
                'isotope name:=F-18', ...
                '%decay correction:=reftime', ...
                '!image duration (sec):=305', ...
                'no separator here', ...
                'isotope name:=duplicate ignored'});
            this.verifyEqual(m('isotope name'), 'F-18')
            this.verifyEqual(m('decay correction'), 'reftime')
            this.verifyEqual(m('image duration (sec)'), '305')
            this.verifyEqual(m('INTERFILE'), '')
            this.verifyFalse(isKey(m, 'no separator here'))
        end

        function test_mhdr_for(this)
            this.verifyEqual(mlsiemens.E7Interfile.mhdr_for("a/lm-BMC-LM-00-dynamic_mc0_000_000.v"), ...
                "a/lm-BMC-LM-00-dynamic_mc0.mhdr")
            this.verifyEqual(mlsiemens.E7Interfile.mhdr_for("a/lm-BMC-LM-00-ac_mc_000_000.v"), ...
                "a/lm-BMC-LM-00-ac_mc.mhdr")
        end

        function test_sizes_and_json(this)
            e7 = mlsiemens.E7Interfile(this.v_fqfn);
            this.verifyEqual(e7.matrix_size, [4 6 3])
            this.verifyEqual(e7.mmppix, [0.825 0.825 1.64557], AbsTol=1e-12)
            this.verifyNotEmpty(e7.mhdr)

            j = e7.json_metadata();
            this.verifyEqual(j.TracerRadionuclide, "F-18")
            this.verifyEqual(j.Radiopharmaceutical, "Solution")
            this.verifyEqual(j.RadionuclideHalfLife, 6586.2)
            this.verifyEqual(j.InjectedRadioactivity, 7.03e7)
            this.verifyEqual(j.InjectionStartDateTime, "2021-04-21T22:45:00")  % console clock, no "Z"
            this.verifyEqual(j.DecayCorrectionReferenceDateTime, "2021-04-21T23:08:22")
            this.verifyEqual(j.InjectionStartRelativeToStudy, -1402)
            this.verifyEqual(j.DecayCorrectionReferenceRelativeToStudy, 0)
            this.verifyTrue(j.ImageDecayCorrected)
            this.verifyEqual(j.Units, "Bq/ml")
            this.verifyEqual(j.ReconMethodParameterValues, [4 5])
            this.verifyEqual(j.FrameTimesStart, 0)
            this.verifyEqual(j.FrameDuration, 305)
            this.verifyEqual(j.E7Interfile.v, string(this.v_fqfn))

            j0 = e7.json_metadata(include_frame=false);
            this.verifyFalse(isfield(j0, "FrameDuration"))
            this.verifyFalse(isfield(j0, "TotalPrompts"))
        end

        function test_missing_header_fails_loudly(this)
            this.verifyError(@() mlsiemens.E7Interfile(fullfile(this.tmp, "absent_000_000.v")), ...
                "mlsiemens:FileNotFoundError")
            this.verifyError(@() mlsiemens.BrainMoCo2.ic_prototype(v_fqfn=""), ...
                "mlsiemens:FileNotFoundError")
        end

        function test_nifti_hdr(this)
            e7 = mlsiemens.E7Interfile(this.v_fqfn);
            ifc = mlfourd.ImagingFormatContext2(zeros(e7.matrix_size, "single"));
            h = e7.nifti_hdr(ifc.hdr);
            this.verifyEqual(h.dime.pixdim(2:4), [0.825 0.825 1.64557], AbsTol=1e-6)
            this.verifyEqual(h.hist.sform_code, 1)
            this.verifyEqual(h.hist.srow_x, [-0.825 0 0 0.825*1.5], AbsTol=1e-6)
            this.verifyEqual(h.hist.srow_y, [0 0.825 0 -0.825*2.5], AbsTol=1e-6)
            this.verifyEqual(h.hist.srow_z, [0 0 1.64557 -1.64557], AbsTol=1e-6)
        end

        function test_ic_prototype_without_template(this)
            % no vision_zeros template is reachable
            setenv("SINGULARITY_HOME", this.tmp)
            setenv("PROJECT_FOLDER", "NoSuchProject")

            proto = mlsiemens.BrainMoCo2.ic_prototype(v_fqfn=this.v_fqfn);
            ifc = proto.imagingFormat;
            this.verifyEqual(size(ifc.img), [4 6 3])
            this.verifyEqual(ifc.json_metadata.Radiopharmaceutical, "Solution")
            this.verifyFalse(isfield(ifc.json_metadata, "FrameDuration"))

            ifc.img = ones(4, 6, 3, 2, "single");
            ifc.filepath = this.tmp;
            ifc.fileprefix = "proto";
            ifc.save();
            this.verifyTrue(isfile(fullfile(this.tmp, "proto.nii.gz")))
            j = jsondecode(fileread(fullfile(this.tmp, "proto.json")));
            this.verifyEqual(j.TracerRadionuclide, 'F-18')
            this.verifyNotEqual(j.Radiopharmaceutical, 'Oxygen')
        end

        function test_sidecar_keeps_backslashes_and_percent(this)
            % Windows paths and "%" must survive mlfourd's json writer as valid JSON
            proto = mlsiemens.BrainMoCo2.ic_prototype(v_fqfn=this.v_fqfn);
            ifc = proto.imagingFormat;
            ifc.json_metadata.E7Interfile.v = "D:\CCIR_01211\sourcedata\sub-108293\x_000_000.v";
            ifc.json_metadata.Note = "100% of counts \n literal";
            ifc.filepath = this.tmp;
            ifc.fileprefix = "winpath";
            ifc.save();
            j = jsondecode(fileread(fullfile(this.tmp, "winpath.json")));
            this.verifyEqual(j.E7Interfile.v, 'D:\CCIR_01211\sourcedata\sub-108293\x_000_000.v')
            this.verifyEqual(j.Note, '100% of counts \n literal')
        end

        function test_logger_keeps_backslashes(this)
            lg = mlpipeline.Logger2(fullfile(this.tmp, "lg"));
            lg.add("D:\CCIR_01211\sourcedata");
            this.verifyTrue(contains(string(lg.char), "D:\CCIR_01211\sourcedata"))
            lg.add("%s=%g", "x", 2);
            this.verifyTrue(contains(string(lg.char), "x=2"))
        end

        function test_find_v_prototype(this)
            ses = fullfile(this.tmp, "ses-1");
            dyn = fullfile(ses, "lm-start0-DynamicBMC");
            mkdir(dyn);
            copyfile(this.v_fqfn + "*", dyn);
            copyfile(mlsiemens.E7Interfile.mhdr_for(this.v_fqfn), dyn);
            v = mlsiemens.BrainMoCo2.find_v_prototype(ses, lm_prefix="lm", tag="-start");
            this.verifyTrue(startsWith(v, string(dyn)))
            this.verifyError(@() mlsiemens.BrainMoCo2.find_v_prototype(ses, folder_tag="-StaticBMC"), ...
                "mlsiemens:FileNotFoundError")
        end

        function test_build_clean_keeps_text_and_lm(this)
            setenv("PROJECT_FOLDER", "CCIR_01211")
            ses = fullfile(this.tmp, "sub-1", "ses-1");
            files = [ ...
                "lm/a.LISTMODE.ptd"; ...                                         % kept: source
                "lm-start0/a.LISTMODE.ptd"; ...                                  % duplicate
                "lm-start0/params.txt"; ...
                "lm-start0-BMC/a.LISTMODE.ptd"; ...                              % duplicate
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/x.l"; ...           % duplicate
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/x.l.hdr"; ...
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/log_e7_recon_19.txt"; ...
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/Run-99-All.bat"; ...
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/x-sino-0.s"; ...    % deep only
                "lm-start0-BMC-Converted/lm-start0-BMC-LM-00/x-sino-0.s.hdr"; ...
                "lm-start0-DynamicBMC/x-dynamic_mc0_000_000.v"; ...              % deep only
                "lm-start0-DynamicBMC/x-dynamic_mc0_000_000.v.hdr"; ...
                "lm-start0-DynamicBMC/x-dynamic_mc0.mhdr"];
            for f = asrow(files)
                ensuredir(myfileparts(fullfile(ses, f)));
                writelines("x", fullfile(ses, f));
            end
            bmc = mlsiemens.BrainMoCo2(source_lm_path=fullfile(ses, "lm"));

            r = bmc.build_clean(dry_run=true);
            this.verifyEqual(height(r), 3)
            this.verifyTrue(all(arrayfun(@(f) isfile(fullfile(ses, f)), files)))  % nothing deleted

            r = bmc.build_clean();
            this.verifyEqual(height(r), 3)
            deleted = files([2 4 5]);
            kept = files(setdiff(1:numel(files), [2 4 5]));
            this.verifyFalse(any(arrayfun(@(f) isfile(fullfile(ses, f)), deleted)))
            this.verifyTrue(all(arrayfun(@(f) isfile(fullfile(ses, f)), kept)))
            this.verifyTrue(isfolder(fullfile(ses, "lm-start0")))

            r = bmc.build_clean(deep=true);
            this.verifyEqual(height(r), 2)
            this.verifyFalse(isfile(fullfile(ses, files(9))))
            this.verifyFalse(isfile(fullfile(ses, files(11))))
            this.verifyTrue(all(arrayfun(@(f) isfile(fullfile(ses, f)), files([1 3 6 7 8 10 12 13]))))
        end
    end

    methods (TestMethodSetup)
        function setupTest(this)
            env0 = struct("SINGULARITY_HOME", getenv("SINGULARITY_HOME"), ...
                "PROJECT_FOLDER", getenv("PROJECT_FOLDER"));
            this.addTeardown(@() setenv("SINGULARITY_HOME", env0.SINGULARITY_HOME))
            this.addTeardown(@() setenv("PROJECT_FOLDER", env0.PROJECT_FOLDER))

            this.tmp = string(tempname);
            mkdir(this.tmp);
            this.addTeardown(@() rmdir(this.tmp, "s"))

            % synthetic e7 image, 4 x 6 x 3, with headers modeled on sub-108293's bottle phantom
            this.v_fqfn = fullfile(this.tmp, "lm-start0-BMC-LM-00-ac_mc_000_000.v");
            fid = fopen(this.v_fqfn, "w", "ieee-le");
            fwrite(fid, ones(1, 4*6*3, "single"), "single");
            fclose(fid);
            writelines([ ...
                "!INTERFILE:="
                "!originating system:=1208"
                "%study date (yyyy:mm:dd):=2021:04:21"
                "%study time (hh:mm:ss GMT+00:00):=23:08:22"
                "isotope name:=F-18"
                "isotope gamma halflife (sec):=6586.2"
                "isotope branching factor:=0.9673"
                "radiopharmaceutical:=Solution"
                "tracer activity at time of injection (Bq):=7.03e+007"
                "%tracer injection date (yyyy:mm:dd):=2021:04:21"
                "%tracer injection time (hh:mm:ss GMT+00:00):=22:45:00"
                "%patient orientation:=HFS"
                "matrix size[1]:=4"
                "matrix size[2]:=6"
                "matrix size[3]:=3"
                "scale factor (mm/pixel) [1]:=0.825"
                "scale factor (mm/pixel) [2]:=0.825"
                "scale factor (mm/pixel) [3]:=1.64557"
                "quantification units:=Bq/ml"
                "%decay correction:=reftime"
                "%decay correction reference date (yyyy:mm:dd):=2021:04:21"
                "%decay correction reference time (hh:mm:ss GMT+00:00):=23:08:22"
                "method of reconstruction:=TOF-PSF-OP-OSEM"
                "number of iterations:=4"
                "%number of subsets:=5"
                "!image duration (sec):=305"
                "!image relative start time (sec):=0"
                "total prompts:=1000"], this.v_fqfn + ".hdr");
            writelines([ ...
                "!INTERFILE:="
                "number of time frames:=1"], mlsiemens.E7Interfile.mhdr_for(this.v_fqfn));
        end
    end
end
