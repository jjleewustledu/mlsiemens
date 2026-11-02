classdef NiftiZSpacingGuard
    %% NIFTIZSPACINGGUARD repairs the z spacing of dcm2niix conversions of Siemens Vision console PET.
    %  The console rounds DICOM ImagePositionPatient z to 0.01 mm; dcm2niix derives pixdim[3] and
    %  srow_z[2] from those positions, giving 1.640015 or 1.650024 mm while the json sidecar's
    %  SliceThickness is the true 1.64557 mm.  For a PT NIfTI-1 whose sform is axis-aligned and whose
    %  |srow_z[2]| == pixdim[3], a mismatch in (0.001, 0.02) mm is repaired by rewriting only the
    %  8 header bytes of pixdim[3] and srow_z[2] (sign of srow_z[2] kept; srow_z[3], qoffset_z and
    %  the quaternion kept; voxel bytes untouched), and the sidecar gains a "header_repair" record.
    %  Larger mismatches and rotated sforms are warned about, never modified.  CT and other
    %  modalities are not applicable:  their spacing may legitimately differ from SliceThickness.
    %
    %  Every call returns a report whose state is one of "repaired", "unchanged", "warned" or
    %  "not_applicable", so that "did not apply" never reads as "checked and fine".
    %
    %  Created 02-Nov-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.

    properties (Constant)
        MIN_REPAIR_MM = 0.001  % below:  already consistent
        MAX_REPAIR_MM = 0.02   % at or above:  not the 0.01-mm rounding signature; warn only
        AXIS_TOL = 1e-6        % off-diagonal sform terms, and |srow_z[2]| vs pixdim[3]
        CAUSE = "console slice z positions rounded to 0.01 mm; dcm2niix spacing from positions"
        OFF_PIXDIM3 = 88       % 76 + 4*3
        OFF_SROW = 280         % srow_x; srow_y at 296, srow_z at 312
        OFF_SROWZ2 = 320       % 312 + 4*2
    end

    methods (Static)
        function reps = apply_folder(folder, opts)
            %% applies the guard to every *.nii and *.nii.gz in folder (recursively if opts.recursive)
            arguments
                folder {mustBeFolder}
                opts.recursive logical = false
            end
            if opts.recursive
                pat = fullfile(folder, "**");
            else
                pat = string(folder);
            end
            d = [dir(fullfile(pat, "*.nii")); dir(fullfile(pat, "*.nii.gz"))];
            reps = mlsiemens.NiftiZSpacingGuard.report("", "not_applicable", "no NIfTI");
            reps = reps([]);
            for k = 1:numel(d)
                fqfn = string(fullfile(d(k).folder, d(k).name));
                reps(end+1) = mlsiemens.NiftiZSpacingGuard.apply(fqfn); %#ok<AGROW>
            end
        end

        function rep = apply(fqfn)
            %% applies the guard to one .nii or .nii.gz with a json sidecar.  Returns struct with
            %  fqfn, state ("repaired" | "unchanged" | "warned" | "not_applicable"), reason,
            %  old_value_mm, new_value_mm.
            arguments
                fqfn {mustBeTextScalar}
            end
            import mlsiemens.NiftiZSpacingGuard
            fqfn = string(fqfn);
            json = regexprep(fqfn, "\.nii(\.gz)?$", ".json");
            if ~isfile(fqfn)
                rep = NiftiZSpacingGuard.report(fqfn, "not_applicable", "no such file");
                return
            end
            if ~isfile(json)
                rep = NiftiZSpacingGuard.report(fqfn, "not_applicable", "no json sidecar");
                return
            end
            j = jsondecode(fileread(json));
            if ~isfield(j, "Modality") || ~strcmp(string(j.Modality), "PT")
                rep = NiftiZSpacingGuard.report(fqfn, "not_applicable", "Modality is not PT");
                return
            end
            if ~isfield(j, "SliceThickness") || ~isnumeric(j.SliceThickness) || ~isscalar(j.SliceThickness)
                rep = NiftiZSpacingGuard.report(fqfn, "not_applicable", "no scalar SliceThickness");
                return
            end
            thick = double(j.SliceThickness);

            gz = endsWith(fqfn, ".gz");
            if gz
                work = fullfile(fileparts(fqfn), ".zspacing_" + string(java.util.UUID.randomUUID()));
                mkdir(work);
                cleaner = onCleanup(@() rmdir(work, "s"));
                nii = string(gunzip(fqfn, work));
                nii = nii(1);
            else
                nii = fqfn;
            end

            [h, rep] = NiftiZSpacingGuard.inspect(nii, fqfn, thick);
            if rep.state ~= "pending"
                return
            end
            if isfield(j, "header_repair")
                rep = NiftiZSpacingGuard.report(fqfn, "warned", "json already has header_repair");
                rep.old_value_mm = h.pz;
                warning("mlsiemens:NiftiZSpacingGuard:alreadyRepaired", ...
                    "%s: pixdim[3] %.6f mm vs SliceThickness %.6f mm, but json already records a " + ...
                    "header_repair; not modified", fqfn, h.pz, thick)
                return
            end

            % patch 8 header bytes in place
            fid = fopen(nii, "r+", h.machfmt);
            assert(fid > 0, "mlsiemens:NiftiZSpacingGuard:open", "cannot open %s", nii)
            fseek(fid, NiftiZSpacingGuard.OFF_PIXDIM3, "bof");
            fwrite(fid, single(thick), "single");
            fseek(fid, NiftiZSpacingGuard.OFF_SROWZ2, "bof");
            fwrite(fid, single(sign(h.srow_z2) * thick), "single");
            fclose(fid);
            if gz
                tmpgz = string(gzip(nii, work));
                movefile(tmpgz(1), fqfn, "f");  % same folder:  atomic rename
            end

            NiftiZSpacingGuard.append_header_repair(json, h.pz, thick);
            rep = NiftiZSpacingGuard.report(fqfn, "repaired", NiftiZSpacingGuard.CAUSE);
            rep.old_value_mm = h.pz;
            rep.new_value_mm = thick;
        end
    end

    methods (Static, Access = private)
        function [h, rep] = inspect(nii, fqfn, thick)
            %% reads the header fields the guard needs; rep.state "pending" means repairable
            import mlsiemens.NiftiZSpacingGuard
            h = struct();
            fid = fopen(nii, "r", "ieee-le");
            assert(fid > 0, "mlsiemens:NiftiZSpacingGuard:open", "cannot open %s", nii)
            sizeof_hdr = fread(fid, 1, "int32");
            fclose(fid);
            h.machfmt = "ieee-le";
            if sizeof_hdr ~= 348
                h.machfmt = "ieee-be";
                if swapbytes(int32(sizeof_hdr)) ~= 348
                    rep = NiftiZSpacingGuard.report(fqfn, "not_applicable", "not a NIfTI-1 header");
                    return
                end
            end
            fid = fopen(nii, "r", h.machfmt);
            fseek(fid, 254, "bof"); sform_code = fread(fid, 1, "int16");
            fseek(fid, NiftiZSpacingGuard.OFF_PIXDIM3, "bof"); h.pz = double(fread(fid, 1, "single"));
            fseek(fid, NiftiZSpacingGuard.OFF_SROW, "bof"); srow = double(fread(fid, [4 3], "single"))';
            fclose(fid);
            h.srow_z2 = srow(3, 3);

            mismatch = abs(h.pz - thick);
            if mismatch <= NiftiZSpacingGuard.MIN_REPAIR_MM
                rep = NiftiZSpacingGuard.report(fqfn, "unchanged", "pixdim[3] matches SliceThickness");
                return
            end
            R = srow(:, 1:3);
            offdiag = R(~eye(3));
            if sform_code <= 0 || any(abs(offdiag) > NiftiZSpacingGuard.AXIS_TOL) || ...
                    abs(abs(h.srow_z2) - h.pz) > NiftiZSpacingGuard.AXIS_TOL
                rep = NiftiZSpacingGuard.report(fqfn, "warned", "sform not axis-aligned or inconsistent with pixdim[3]");
                rep.old_value_mm = h.pz;
                warning("mlsiemens:NiftiZSpacingGuard:notAxisAligned", ...
                    "%s: pixdim[3] %.6f mm vs SliceThickness %.6f mm, but sform (code %i) is not " + ...
                    "axis-aligned or |srow_z[2]| %.6f ~= pixdim[3]; not modified", ...
                    fqfn, h.pz, thick, sform_code, abs(h.srow_z2))
                return
            end
            if mismatch >= NiftiZSpacingGuard.MAX_REPAIR_MM
                rep = NiftiZSpacingGuard.report(fqfn, "warned", "mismatch >= 0.02 mm");
                rep.old_value_mm = h.pz;
                warning("mlsiemens:NiftiZSpacingGuard:largeMismatch", ...
                    "%s: pixdim[3] %.6f mm differs from SliceThickness %.6f mm by %.4f mm, more than " + ...
                    "0.01-mm position rounding explains; not modified", fqfn, h.pz, thick, mismatch)
                return
            end
            rep = NiftiZSpacingGuard.report(fqfn, "pending", "");
        end

        function append_header_repair(json, old_mm, new_mm)
            %% inserts "header_repair" before the closing brace, leaving all other json text as is
            hr = struct( ...
                "date", string(datetime("now", Format="yyyy-MM-dd'T'HH:mm:ss")), ...
                "fields", {{'pixdim[3]', 'srow_z[2]'}}, ...
                "old_value_mm", old_mm, ...
                "new_value_mm", new_mm, ...
                "kept", {{'srow_z[3]', 'qoffset_z', 'quatern_b', 'quatern_c', 'quatern_d', 'voxel data'}}, ...
                "cause", mlsiemens.NiftiZSpacingGuard.CAUSE, ...
                "tool", struct( ...
                    "name", "mlsiemens.NiftiZSpacingGuard.apply", ...
                    "code_provenance", mlsiemens.BrainMoCo2.code_provenance()));
            txt = string(fileread(json));
            k = find(char(txt) == '}', 1, "last");
            assert(~isempty(k), "mlsiemens:NiftiZSpacingGuard:json", "%s has no closing brace", json)
            head = strip(extractBefore(txt, k), "right");
            if endsWith(head, "{")
                sep = "";
            else
                sep = ",";
            end
            enc = jsonencode(hr, PrettyPrint=true);
            enc = strrep(enc, newline, [newline char(9)]);
            out = head + sep + newline + char(9) + """header_repair"": " + enc + newline + "}" + newline;
            tmp = json + ".tmp";
            fid = fopen(tmp, "w");
            assert(fid > 0, "mlsiemens:NiftiZSpacingGuard:json", "cannot write %s", tmp)
            fwrite(fid, unicode2native(char(out), "UTF-8"), "uint8");
            fclose(fid);
            movefile(tmp, json, "f");
        end

        function rep = report(fqfn, state, reason)
            rep = struct("fqfn", string(fqfn), "state", string(state), "reason", string(reason), ...
                "old_value_mm", NaN, "new_value_mm", NaN);
        end
    end
end
