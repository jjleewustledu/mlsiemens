classdef Test_NiftiZSpacingGuard < matlab.unittest.TestCase
    %% Tests mlsiemens.NiftiZSpacingGuard:  repair of dcm2niix z spacing for Siemens Vision console
    %  PET, whose DICOM slice positions are rounded to 0.01 mm so that pixdim[3] and srow_z[2]
    %  read 1.640015 or 1.650024 mm while the json SliceThickness is the true 1.64557 mm.
    %  Synthetic NIfTI-1 fixtures written byte by byte; runs on any platform.
    %
    %  Created 02-Nov-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.

    properties
        tmp  % per-test folder
    end

    properties (Constant)
        THICKNESS = 1.64557
        ROUNDED = 1.640015
        QOFFSET_Z = -130.5
    end

    methods (Test)
        function test_repairs_console_pet(this)
            fqfn = this.make_fixture("pet", this.ROUNDED, "PT", this.THICKNESS);
            data0 = this.voxel_bytes(fqfn);
            rep = mlsiemens.NiftiZSpacingGuard.apply(fqfn);

            this.verifyEqual(rep.state, "repaired")
            h = this.read_header(fqfn);
            this.verifyEqual(h.pixdim(4), single(this.THICKNESS))
            this.verifyEqual(h.srow_z(3), single(this.THICKNESS))
            this.verifyEqual(h.srow_z(4), single(this.QOFFSET_Z))
            this.verifyEqual(h.qoffset_z, single(this.QOFFSET_Z))
            this.verifyEqual(h.quatern, single([0 0 0]))
            this.verifyEqual(this.voxel_bytes(fqfn), data0)

            j = jsondecode(fileread(this.json_for(fqfn)));
            this.verifyTrue(isfield(j, "header_repair"))
            this.verifyEqual(string(j.header_repair.fields), ["pixdim[3]"; "srow_z[2]"])
            this.verifyEqual(j.header_repair.old_value_mm, double(single(this.ROUNDED)), AbsTol=1e-9)
            this.verifyEqual(j.header_repair.new_value_mm, this.THICKNESS, AbsTol=1e-9)
            this.verifySubstring(string(j.header_repair.cause), "rounded to 0.01 mm")
            this.verifySubstring(string(j.header_repair.tool.name), "NiftiZSpacingGuard")
            this.verifyTrue(isfield(j.header_repair.tool, "code_provenance"))
            this.verifyNotEmpty(j.header_repair.date)
            this.verifyEqual(j.Modality, 'PT')  % rest of the sidecar intact
            this.verifyEqual(j.SliceThickness, this.THICKNESS)
        end

        function test_repairs_gz_preserving_voxels(this)
            fqfn = this.make_fixture("petgz", 1.650024, "PT", this.THICKNESS);
            data0 = this.voxel_bytes(fqfn);
            gzfn = string(gzip(fqfn, this.tmp));
            delete(fqfn);
            rep = mlsiemens.NiftiZSpacingGuard.apply(gzfn);

            this.verifyEqual(rep.state, "repaired")
            this.verifyTrue(isfile(gzfn))
            this.verifyFalse(isfile(fqfn))
            this.verifyEmpty(this.leftovers())
            unz = string(gunzip(gzfn, fullfile(this.tmp, "unz")));
            h = this.read_header(unz);
            this.verifyEqual(h.pixdim(4), single(this.THICKNESS))
            this.verifyEqual(h.srow_z(3), single(this.THICKNESS))
            this.verifyEqual(this.voxel_bytes(unz), data0)
        end

        function test_negative_srow_keeps_sign(this)
            fqfn = this.make_fixture("flip", this.ROUNDED, "PT", this.THICKNESS, srow_z_sign=-1);
            rep = mlsiemens.NiftiZSpacingGuard.apply(fqfn);
            this.verifyEqual(rep.state, "repaired")
            h = this.read_header(fqfn);
            this.verifyEqual(h.pixdim(4), single(this.THICKNESS))
            this.verifyEqual(h.srow_z(3), -single(this.THICKNESS))
        end

        function test_nac_3mm_untouched(this)
            fqfn = this.make_fixture("nac", 3.0, "PT", 3.0);
            [b0, j0] = this.snapshot(fqfn);
            rep = this.verifyWarningFree(@() mlsiemens.NiftiZSpacingGuard.apply(fqfn));
            this.verifyEqual(rep.state, "unchanged")
            this.verifyBytesIdentical(fqfn, b0, j0)
        end

        function test_ct_untouched(this)
            fqfn = this.make_fixture("ct", this.ROUNDED, "CT", this.THICKNESS);
            [b0, j0] = this.snapshot(fqfn);
            rep = this.verifyWarningFree(@() mlsiemens.NiftiZSpacingGuard.apply(fqfn));
            this.verifyEqual(rep.state, "not_applicable")
            this.verifyBytesIdentical(fqfn, b0, j0)
        end

        function test_large_mismatch_warns_untouched(this)
            fqfn = this.make_fixture("big", this.THICKNESS + 0.05, "PT", this.THICKNESS);
            [b0, j0] = this.snapshot(fqfn);
            rep = this.verifyWarning(@() mlsiemens.NiftiZSpacingGuard.apply(fqfn), ...
                "mlsiemens:NiftiZSpacingGuard:largeMismatch");
            this.verifyEqual(rep.state, "warned")
            this.verifyBytesIdentical(fqfn, b0, j0)
        end

        function test_rotated_sform_warns_untouched(this)
            fqfn = this.make_fixture("rot", this.ROUNDED, "PT", this.THICKNESS, rotate=true);
            [b0, j0] = this.snapshot(fqfn);
            rep = this.verifyWarning(@() mlsiemens.NiftiZSpacingGuard.apply(fqfn), ...
                "mlsiemens:NiftiZSpacingGuard:notAxisAligned");
            this.verifyEqual(rep.state, "warned")
            this.verifyBytesIdentical(fqfn, b0, j0)
        end

        function test_idempotent(this)
            fqfn = this.make_fixture("idem", this.ROUNDED, "PT", this.THICKNESS);
            mlsiemens.NiftiZSpacingGuard.apply(fqfn);
            [b1, j1] = this.snapshot(fqfn);
            rep = this.verifyWarningFree(@() mlsiemens.NiftiZSpacingGuard.apply(fqfn));
            this.verifyEqual(rep.state, "unchanged")
            this.verifyBytesIdentical(fqfn, b1, j1)
            this.verifyEqual(numel(strfind(fileread(this.json_for(fqfn)), '"header_repair"')), 1)
        end

        function test_no_json_not_applicable(this)
            fqfn = this.make_fixture("nojson", this.ROUNDED, "PT", this.THICKNESS);
            delete(this.json_for(fqfn));
            b0 = this.file_bytes(fqfn);
            rep = mlsiemens.NiftiZSpacingGuard.apply(fqfn);
            this.verifyEqual(rep.state, "not_applicable")
            this.verifyEqual(this.file_bytes(fqfn), b0)
        end

        function test_apply_folder(this)
            a = this.make_fixture("a", this.ROUNDED, "PT", this.THICKNESS);
            b = this.make_fixture("b", 3.0, "PT", 3.0);
            reps = mlsiemens.NiftiZSpacingGuard.apply_folder(this.tmp);
            this.verifyEqual(numel(reps), 2)
            this.verifyEqual(sort([reps.state]), ["repaired", "unchanged"])
            this.verifyEqual(sort([reps.fqfn]), sort([a, b]))
        end
    end

    methods (TestMethodSetup)
        function setupTest(this)
            this.tmp = string(tempname);
            mkdir(this.tmp);
            this.addTeardown(@() rmdir(this.tmp, "s"))
        end
    end

    methods (Access = private)
        function fqfn = make_fixture(this, name, pz, modality, thickness, opts)
            %% 4 x 4 x 5 single NIfTI-1 (.nii, vox_offset 352), qform = sform = 1, plus json sidecar
            arguments
                this
                name {mustBeTextScalar}
                pz double
                modality {mustBeTextScalar}
                thickness double
                opts.srow_z_sign double = 1
                opts.rotate logical = false
            end
            fqfn = fullfile(this.tmp, name + ".nii");
            px = 1.65;
            hdr = zeros(1, 352, "uint8");
            put = @(h, off, v) [h(1:off), typecast(v, "uint8"), h(off+numel(typecast(v, "uint8"))+1:end)];
            hdr = put(hdr, 0, int32(348));
            hdr = put(hdr, 40, int16([3 4 4 5 1 1 1 1]));
            hdr = put(hdr, 70, int16(16));
            hdr = put(hdr, 72, int16(32));
            hdr = put(hdr, 76, single([1 px px pz 0 0 0 0]));
            hdr = put(hdr, 108, single(352));
            hdr = put(hdr, 252, int16(1));
            hdr = put(hdr, 254, int16(1));
            hdr = put(hdr, 256, single([0 0 0]));
            hdr = put(hdr, 268, single([-2.5 -2.5 this.QOFFSET_Z]));
            sx = [px 0 0 -2.5];
            sy = [0 px 0 -2.5];
            sz = [0 0 opts.srow_z_sign*pz this.QOFFSET_Z];
            if opts.rotate
                c = cosd(10); s = sind(10);
                sx = [px*c -px*s 0 -2.5];
                sy = [px*s px*c 0 -2.5];
            end
            hdr = put(hdr, 280, single(sx));
            hdr = put(hdr, 296, single(sy));
            hdr = put(hdr, 312, single(sz));
            hdr = put(hdr, 344, uint8(['n+1' 0]));
            fid = fopen(fqfn, "w", "ieee-le");
            fwrite(fid, hdr, "uint8");
            fwrite(fid, single(reshape(1:80, 4, 4, 5)) * 1.5, "single");
            fclose(fid);

            fid = fopen(this.json_for(fqfn), "w");
            fprintf(fid, '{\n\t"Modality": "%s",\n\t"Manufacturer": "Siemens",\n\t"SliceThickness": %.5f,\n\t"ImageType": ["ORIGINAL", "PRIMARY"]\n}\n', ...
                modality, thickness);
            fclose(fid);
        end

        function h = read_header(~, fqfn)
            fid = fopen(fqfn, "r", "ieee-le");
            cleaner = onCleanup(@() fclose(fid));
            fseek(fid, 76, "bof"); h.pixdim = fread(fid, 8, "single=>single")';
            fseek(fid, 256, "bof"); h.quatern = fread(fid, 3, "single=>single")';
            fseek(fid, 276, "bof"); h.qoffset_z = fread(fid, 1, "single=>single");
            fseek(fid, 312, "bof"); h.srow_z = fread(fid, 4, "single=>single")';
        end

        function b = file_bytes(~, fqfn)
            fid = fopen(fqfn, "r");
            b = fread(fid, Inf, "uint8=>uint8");
            fclose(fid);
        end

        function b = voxel_bytes(this, fqfn)
            b = this.file_bytes(fqfn);
            b = b(353:end);
        end

        function j = json_for(~, fqfn)
            j = regexprep(string(fqfn), "\.nii(\.gz)?$", ".json");
        end

        function [b, j] = snapshot(this, fqfn)
            b = this.file_bytes(fqfn);
            j = this.file_bytes(this.json_for(fqfn));
        end

        function verifyBytesIdentical(this, fqfn, b0, j0)
            this.verifyEqual(this.file_bytes(fqfn), b0)
            this.verifyEqual(this.file_bytes(this.json_for(fqfn)), j0)
        end

        function g = leftovers(this)
            d = dir(this.tmp);
            g = string({d.name});
            g = g(startsWith(g, ".zspacing"));
        end
    end
end
