classdef E7Interfile
    %% E7INTERFILE reads the Interfile headers that e7 writes beside each reconstructed image,
    %  e.g., lm-start0-BMC-LM-00-dynamic_mc0_000_000.v with its .v.hdr and the series
    %  lm-start0-BMC-LM-00-dynamic_mc0.mhdr, and provides what a NIfTI of that image needs:
    %  matrix size, voxel sizes, a NIfTI header, and a json sidecar describing the recon itself.
    %
    %  Replaces the prototype vision_zeros_440x440x159.{nii.gz,json}, which carried metadata
    %  of one [15O]O2 recon (radiopharmaceutical, half-life, dose, units, slice spacing) into
    %  every product.  Kept apart from BrainMoCo2, which orchestrates recons (SRP).
    %
    %  >> e7 = mlsiemens.E7Interfile("lm-start0-BMC-LM-00-ac_mc_000_000.v");
    %  >> j = e7.json_metadata();
    %
    %  Created 31-Oct-2026 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.

    properties (SetAccess = protected)
        v_fqfn string     % image data file
        vhdr_fqfn string  % image subheader, v_fqfn + ".hdr"
        mhdr_fqfn string  % image main header; "" if absent
        vhdr cell         % raw lines
        mhdr cell         % raw lines
        vmap containers.Map  % normalized key -> value text, from vhdr
        mmap containers.Map  % normalized key -> value text, from mhdr
    end

    properties (Dependent)
        matrix_size  % [nx ny nz]
        mmppix       % [dx dy dz]
    end

    methods %% GET
        function g = get.matrix_size(this)
            g = [this.num("matrix size[1]"), this.num("matrix size[2]"), this.num("matrix size[3]")];
        end
        function g = get.mmppix(this)
            g = [this.num("scale factor (mm/pixel) [1]"), ...
                 this.num("scale factor (mm/pixel) [2]"), ...
                 this.num("scale factor (mm/pixel) [3]")];
        end
    end

    methods
        function this = E7Interfile(v_fqfn)
            arguments
                v_fqfn {mustBeTextScalar}
            end
            this.v_fqfn = string(v_fqfn);
            this.vhdr_fqfn = this.v_fqfn + ".hdr";
            if ~isfile(this.vhdr_fqfn)
                error("mlsiemens:FileNotFoundError", "E7Interfile: no image subheader %s", this.vhdr_fqfn)
            end
            this.vhdr = cellstr(readlines(this.vhdr_fqfn));
            this.vmap = mlsiemens.E7Interfile.parse(this.vhdr);

            this.mhdr_fqfn = mlsiemens.E7Interfile.mhdr_for(this.v_fqfn);
            if isfile(this.mhdr_fqfn)
                this.mhdr = cellstr(readlines(this.mhdr_fqfn));
            else
                this.mhdr_fqfn = "";
                this.mhdr = {};
            end
            this.mmap = mlsiemens.E7Interfile.parse(this.mhdr);

            if any(isnan(this.matrix_size)) || any(isnan(this.mmppix))
                error("mlsiemens:ValueError", ...
                    "E7Interfile: %s lacks matrix size or scale factor (mm/pixel)", this.vhdr_fqfn)
            end
        end

        function s = json_metadata(this, opts)
            %% json sidecar from the recon's own headers.  BIDS-PET names where one fits.  Raw
            %  headers are kept under E7Interfile.
            %
            %  Clock:  *DateTime values are the console's "GMT+00:00" times, without a "Z", because
            %  they are not true UTC during daylight saving time:  the Vision 600 console adds a
            %  fixed 6 h to Central time (sub-108293 listmode, 2021-04-21:  DecayRefTime 17:08:22.74
            %  CDT, header 23:08:23 "GMT"; true UTC 22:08:22).  Intervals between them are exact, so
            %  InjectionStartRelativeToStudy and DecayCorrectionReferenceRelativeToStudy (s) are the
            %  clock-independent quantities for decay arithmetic.
            %  opts.include_frame:  include FrameTimesStart, FrameDuration and counts, which
            %      describe this one image; omit for products assembled from many images.

            arguments
                this mlsiemens.E7Interfile
                opts.include_frame logical = true
            end

            s = struct();
            s.Modality = "PT";
            s.Manufacturer = "Siemens";
            s.ManufacturersModelName = this.str("originating system");
            s.TracerRadionuclide = this.str("isotope name");
            s.Radiopharmaceutical = this.str("radiopharmaceutical");
            s.RadionuclideHalfLife = this.num("isotope gamma halflife (sec)");
            s.RadionuclidePositronFraction = this.num("isotope branching factor");
            s.InjectedRadioactivity = this.num("tracer activity at time of injection (Bq)");
            s.InjectedRadioactivityUnits = "Bq";
            s.InjectionStartDateTime = this.datetime_gmt( ...
                "tracer injection date (yyyy:mm:dd)", "tracer injection time (hh:mm:ss GMT+00:00)");
            s.StudyDateTime = this.datetime_gmt( ...
                "study date (yyyy:mm:dd)", "study time (hh:mm:ss GMT+00:00)");
            s.Units = this.str("quantification units");
            s.DecayCorrection = this.str("decay correction");
            s.ImageDecayCorrected = ~any(strcmpi(s.DecayCorrection, ["", "none", "off"]));
            s.DecayCorrectionReferenceDateTime = this.datetime_gmt( ...
                "decay correction reference date (yyyy:mm:dd)", ...
                "decay correction reference time (hh:mm:ss GMT+00:00)");
            s.InjectionStartRelativeToStudy = this.seconds_between( ...
                "tracer injection date (yyyy:mm:dd)", "tracer injection time (hh:mm:ss GMT+00:00)");
            s.DecayCorrectionReferenceRelativeToStudy = this.seconds_between( ...
                "decay correction reference date (yyyy:mm:dd)", ...
                "decay correction reference time (hh:mm:ss GMT+00:00)");
            s.ClockNote = "DateTimes are the console's GMT+00:00 = Central time + 6 h without DST; " + ...
                "use the *RelativeToStudy seconds (negative = before study start) for decay.";
            s.ScannerQuantificationFactor =this.num("scanner quantification factor (Bq*s/ECAT counts)");
            s.ReconMethodName = this.str("method of reconstruction");
            s.ReconMethodParameterLabels = ["iterations", "subsets"];
            s.ReconMethodParameterValues = [this.num("number of iterations"), this.num("number of subsets")];
            s.ReconFilterType = this.str("filter name");
            s.ReconFilterSize = [this.num("xy-filter (mm)"), this.num("z-filter (mm)")];
            s.PSFAxialSigma = this.num("PSF axial sigma (mm)");
            s.AppliedCorrections = this.str("applied corrections");
            s.AttenuationCorrection = this.str("method of attenuation correction");
            s.ScatterCorrectionMethod = this.str("method of scatter correction");
            s.RandomsCorrectionMethod = this.str("method of random correction");
            s.PatientPosition = this.str("patient orientation");
            s.ImageOrientation = this.str("image orientation");
            s.ImageZoom = this.num("image zoom");
            s.MatrixSize = this.matrix_size;
            s.VoxelSize = this.mmppix;
            s.VoxelSizeUnits = "mm";
            s.ReconstructionDiameter = this.num("reconstruction diameter (mm)");
            s.BedPositionStart = this.num("start horizontal bed position (mm)");
            s.BedPositionEnd = this.num("end horizontal bed position (mm)");
            if opts.include_frame
                s.FrameTimesStart = this.num("image relative start time (sec)");
                s.FrameDuration = this.num("image duration (sec)");
                s.TotalPrompts = this.num("total prompts");
                s.TotalRandoms = this.num("total randoms");
                s.TotalNetTrues = this.num("total net trues");
            end
            s.E7Interfile = struct( ...
                "v", this.v_fqfn, ...
                "vhdr", {this.vhdr}, ...
                "mhdr", {this.mhdr});
        end

        function hdr = nifti_hdr(this, hdr)
            %% updates a NIfTI hdr struct, e.g., from mlfourd.ImagingFormatContext2.hdr, with this
            %  recon's matrix and voxel sizes.  Axes follow mlsiemens.BrainMoCo2.vread(), which
            %  flips e7's x and y:  -x, +y, +z, as before.  The world origin is the center of the
            %  field of view, as for mlfourd's default header; scanner and bed coordinates remain
            %  in the json sidecar.

            arguments
                this mlsiemens.E7Interfile
                hdr struct
            end
            n = this.matrix_size;
            d = this.mmppix;
            hdr.dime.pixdim(2:4) = d;
            hdr.hist.qform_code = 0;
            hdr.hist.sform_code = 1;
            hdr.hist.srow_x = [-d(1) 0 0  d(1)*(n(1) - 1)/2];
            hdr.hist.srow_y = [0  d(2) 0 -d(2)*(n(2) - 1)/2];
            hdr.hist.srow_z = [0 0  d(3) -d(3)*(n(3) - 1)/2];
            hdr.hist.originator = (n - 1)/2;
            hdr.hist.descrip = 'mlsiemens.E7Interfile';
        end

        function v = num(this, key)
            %% numeric value of key from vhdr, else mhdr; NaN if absent or not numeric
            v = str2double(this.str(key));
        end

        function v = str(this, key)
            %% text value of key from vhdr, else mhdr; "" if absent
            k = mlsiemens.E7Interfile.normalize_key(key);
            if isKey(this.vmap, k)
                v = string(this.vmap(k));
            elseif isKey(this.mmap, k)
                v = string(this.mmap(k));
            else
                v = "";
            end
        end

        function v = datetime_gmt(this, date_key, time_key)
            %% ISO 8601 text of the console's "GMT" clock, e.g., "2021-04-21T23:08:23", with no "Z"
            %  because it is not true UTC during DST (see json_metadata); "" if absent
            d = this.str(date_key);
            t = this.str(time_key);
            if isemptytext(d) || isemptytext(t)
                v = "";
                return
            end
            v = replace(d, ":", "-") + "T" + t;
        end

        function dt = seconds_between(this, date_key, time_key)
            %% seconds from study start to the time at date_key/time_key on the same header clock;
            %  negative if earlier; NaN if either is absent
            t0 = this.datetime_gmt("study date (yyyy:mm:dd)", "study time (hh:mm:ss GMT+00:00)");
            t1 = this.datetime_gmt(date_key, time_key);
            if isemptytext(t0) || isemptytext(t1)
                dt = NaN;
                return
            end
            dt = seconds(mlsiemens.E7Interfile.iso2datetime(t1) - mlsiemens.E7Interfile.iso2datetime(t0));
        end
    end

    methods (Static)
        function m = parse(lines)
            %% Interfile "key:=value" lines -> containers.Map of normalized key -> value text

            arguments
                lines cell
            end
            m = containers.Map('KeyType', 'char', 'ValueType', 'char');
            for li = 1:numel(lines)
                ln = char(lines{li});
                idx = strfind(ln, ':=');
                if isempty(idx)
                    continue
                end
                k = mlsiemens.E7Interfile.normalize_key(ln(1:idx(1)-1));
                if isempty(k) || isKey(m, k)
                    continue
                end
                m(k) = strtrim(ln(idx(1)+2:end));
            end
        end

        function dt = iso2datetime(s)
            %% "2021-04-21T23:08:23" or with fractional seconds -> datetime, no time zone
            tok = regexp(string(s), "^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)$", "tokens", "once");
            if isempty(tok)
                error("mlsiemens:ValueError", "E7Interfile.iso2datetime: cannot parse %s", s)
            end
            n = str2double(tok);
            dt = datetime(n(1), n(2), n(3), n(4), n(5), n(6));
        end

        function k = normalize_key(k)
            %% drops Interfile's "!" and "%" markers and surrounding space
            k = strtrim(char(k));
            k = strtrim(regexprep(k, '^[!%]+', ''));
        end

        function fqfn = mhdr_for(v_fqfn)
            %% X_000_000.v -> X.mhdr
            re = regexp(v_fqfn, "^(?<fqfp>.+)_\d{3}_\d{3}\.v$", "names", "once");
            if isempty(re)
                fqfn = "";
                return
            end
            fqfn = string(re.fqfp) + ".mhdr";
        end
    end
end
