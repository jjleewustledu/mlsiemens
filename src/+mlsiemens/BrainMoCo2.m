classdef BrainMoCo2 < handle & mlsystem.IHandle
    %% builds PET imaging with JSRecon12 & e7 & Inki Hong's BrainMotionCorrection
    %  
    %  Created 03-Jan-2023 01:19:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        N_PROC = 5
        SHAPE = [440 440 159]
    end

    properties
        bin_version_folder = "bin.win64-VG80"
    end

    properties (Dependent)
        bmc_js
        inki_home
        jsrecon_home
        jsrecon_js
        lm_prefix
        output_path
        project_drive
        project_path
        service_home
        siemens_home
        source_lm_path
        source_pet_path
        source_ses_path
        test_lm_Path
        test_project_path
    end

    methods %% GET
        function g = get.bmc_js(this)
            g = fullfile(this.jsrecon_home, "BrainMotionCorrection", "BMC.js");
        end
        function g = get.inki_home(this)
            g = fullfile("C:", "Inki");
        end
        function g = get.jsrecon_home(this)
            g = fullfile("C:", "JSRecon12");
        end
        function g = get.jsrecon_js(this)
            g = fullfile(this.jsrecon_home, "JSRecon12.js");
        end
        function g = get.lm_prefix(this)
            g = mybasename(this.source_lm_path);
        end
        function g = get.output_path(this)
            g = fullfile( ...
                myfileparts(myfileparts(this.source_lm_path)), "+Output");
        end
        function g = get.project_drive(this)
            ss = strsplit(this.source_lm_path, filesep);
            g = ss(1);
        end
        function g = get.project_path(this)
            ss = strsplit(this.source_lm_path, filesep);
            g = fullfile(ss(1), ss(2));
        end
        function g = get.service_home(this)
            g = fullfile("C:", "Service");
        end
        function g = get.siemens_home(this)
            g = fullfile("C:", "Siemens");
        end
        function g = get.source_lm_path(this)
            g = this.source_lm_path_;
        end
        function g = get.source_pet_path(this)
            g = strrep(this.source_lm_path, "lm", "pet");
            ensuredir(g);
        end
        function g = get.source_ses_path(this)
            g = myfileparts(this.source_lm_path);
        end
        function g = get.test_lm_Path(this)
            g = fullfile(this.project_drive, "MyBMCProject", "+Input", "VisionTestData");
        end
        function g = get.test_project_path(this)
            ss = strsplit(this.test_lm_path, filesep);
            g = fullfile(ss(1), ss(2));
        end
    end

    methods
        function this = BrainMoCo2(opts)
            %  Args:
            %  opts.source_lm_path {mustBeFolder} = pwd

            arguments
                opts.source_lm_path {mustBeFolder} = pwd
            end
            %assert(contains(opts.source_lm_path, "lm"), stackstr())
            this.source_lm_path_ = convertCharsToStrings(opts.source_lm_path);
        end
        function build_all(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:10,10,10,10,10,10,10,10,10,10,10,10"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "oo"
                opts.filepath {mustBeFolder} = this.source_pet_path % for BMC params file (.txt)
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.is_dyn logical = true
                opts.doIF2Dicom logical = false
                opts.clean_up logical = true
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            copts = namedargs2cell(opts);
            opts.tag = string(opts.tag);
            if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                opts.tag = "-"+opts.tag;
            end
            this.check_env();

            % cscript BMC.js
            pwd0 = pushd(this.source_pet_path);
            bmcp = mlsiemens.BrainMoCoParams2(copts{:});
            bmcp.writelines();
            [~,r] = mysystem(sprintf("cscript %s %s %s", ...
                this.bmc_js, ...
                this.source_lm_path, ...
                bmcp.fqfilename));
            disp(r)

            % move output/* to source_ses_path
            g = asrow(globFolders(fullfile(this.output_path, '*')));
            for gidx = 1:length(g)
                try
                    movefile(g{gidx}, this.source_ses_path)
                catch ME
                    handwarning(ME)
                end
            end

            % IF2Dicom & IF2MIP
            if opts.doIF2Dicom && endsWith(opts.tag, "-start0")
                this.build_IF2Dicom( ...
                    source=fullfile(this.source_lm_path+"-BMC-Converted", this.lm_prefix+opts.tag0+"-BMC-LM-00"), ...
                    dest=this.source_ses_path);
            end
            
            % delete large files
            if opts.clean_up
                this.build_clean(tag=opts.tag);
            end
            popd(pwd0);
        end
        function build_clean(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            opts.tag = string(opts.tag);
            
            try    
                if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                    opts.tag = "-"+opts.tag;
                end

                if isfolder(fullfile(this.source_ses_path, this.lm_prefix+opts.tag))
                    rmdir(fullfile(this.source_ses_path, this.lm_prefix+opts.tag), "s");
                end
                if isfolder(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC"))
                    rmdir(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC"), "s");
                end
                if ~strcmp(opts.tag, opts.tag0)
                    if isfolder(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-Conventional"))
                        rmdir(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-Conventional"), "s");
                    end
                end
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.i"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.l"));                
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.s"));                
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.s.hdr"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", "nac*.v"));                
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", "nac*.v.hdr"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*-ac_mc_*_*.v"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*-ac_mc_*_*.v.hdr"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*-dynamic_mc*_*_*.v"));
                % deleteExisting(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*-dynamic_mc*_*_*.v.hdr"));
            catch ME
                handwarning(ME)
            end            
        end
        function build_IF2Dicom(this, opts)
            arguments
                this mlsiemens.BrainMoCo2 %#ok<INUSA>
                opts.source {mustBeFolder}
                opts.dest {mustBeFolder}
                opts.tag0 {mustBeTextScalar} = ""
            end

            pwd0 = pushd(opts.source);
            vhdr = this.lm_prefix+opts.tag0+"-BMC-LM-00-dynamic_mc0_000_000.v.hdr";
            if2dicom_js = fullfile("C:", "JSRecon12", "IF2Dicom.js");
            mysystem(sprintf("cscript %s %s Run-05-lm"+opts.tag0+"-BMC-LM-00-IF2Dicom.txt", ...
                if2dicom_js, vhdr));

            try
                mlsiemens.BrainMoCoBuilder.dcm2niix( ...
                    fullfile(opts.source, mybasename(vhdr)+".v-DICOM"), ...
                    o=opts.dest, ...
                    toglob_mhdr="*-dynamic_mc0.mhdr", ...
                    toglob_vhdr="*-dynamic_mc0_000_000.v.hdr");
                if2mip_js = fullfile("C:", "JSRecon12", "IF2MIP", "IF2MIP.js");
                mysystem(sprintf("cscript %s %s", ...
                    if2mip_js, vhdr));
            catch ME
                handwarning(ME)
            end

            try
                movefile(fullfile(opts.source, "*.png"), opts.dest)
            catch ME
                handwarning(ME)
            end
            popd(pwd0);
        end
        function build_jsr(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:120"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "oo"
                opts.filepath {mustBeFolder} = this.source_pet_path % for BMC params file (.txt)
                opts.tag {mustBeTextScalar} = ""
                opts.is_dyn logical = false
            end
            copts = namedargs2cell(opts);
            opts.tag = string(opts.tag);
            if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                opts.tag = "-"+opts.tag;
            end

            this.check_env();

            % cscript JSRecon12.js
            pwd0 = pushd(this.source_pet_path);
            jsrp = mlsiemens.JSReconParams(copts{:});
            jsrp.writelines();
            [~,r] = mysystem(sprintf("cscript %s %s %s", ...
                this.jsrecon_js, ...
                this.source_lm_path, ...
                jsrp.fqfilename));
            %disp(r)
            popd(pwd0);

            % run Run-99-lm-start*-LM-00-All.bat
            bat_path = fullfile( ...
                this.source_ses_path, this.lm_prefix+opts.tag+"-Converted", this.lm_prefix+opts.tag+"-LM=00");
            pwd1 = pushd(bat_path);
            [~,r] = mysystem("Run-99-lm-"+opts.tag+"-LM-00-All.bat");
            disp(r)

            try
                % rmdir(fullfile(this.source_ses_path, this.lm_prefix+opts.tag), "s");
                % rmdir(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC"), "s");
            catch ME
                handwarning(ME)
            end
            try
                % delete(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.l"));
                % delete(fullfile(this.source_ses_path, this.lm_prefix+opts.tag+"-BMC-Converted", this.lm_prefix+opts.tag+"-BMC-LM-00", "*.v"));
            catch ME
                handwarning(ME)
            end
            popd(pwd1);
        end
        function build_single(this, opts)
            % See also: createNiftiMovingAvgRepair()
            % LMFrames=lmframes, tracer=opts.tracer, tag=tag+starts(ti)+"-repair"

            arguments
                this mlsiemens.BrainMoCo2
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:10"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "oo"
                opts.filepath {mustBeFolder} = this.source_pet_path % for BMC params file (.txt)
                opts.tag {mustBeTextScalar} = "-single-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.is_dyn logical = true
                opts.doIF2Dicom logical = false
                opts.clean_up logical = true
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            copts = namedargs2cell(opts);
            opts.tag = string(opts.tag);
            if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                opts.tag = "-"+opts.tag;
            end
            this.check_env();

            % cscript BMC.js
            pwd0 = pushd(this.source_pet_path);
            bmcp = mlsiemens.BrainMoCoParams2(copts{:});
            bmcp.doConventional = true; % <-
            bmcp.doBMCRecon = false;    % <-
            bmcp.doBMCDynamic = false;  % <-
            bmcp.writelines();
            [~,r] = mysystem(sprintf("cscript %s %s %s", ...
                this.bmc_js, ...
                this.source_lm_path, ...
                bmcp.fqfilename));
            disp(r)

            % move output/* to source_ses_path
            g = asrow(globFolders(fullfile(this.output_path, '*')));
            for gidx = 1:length(g)
                try
                    movefile(g{gidx}, this.source_ses_path)
                catch ME
                    handwarning(ME)
                end
            end

            % IF2Dicom & IF2MIP
            if opts.doIF2Dicom && endsWith(opts.tag, "-start0")
                this.build_IF2Dicom( ...
                    source=fullfile(this.source_lm_path+"-BMC-Converted", this.lm_prefix+opts.tag0+"-BMC-LM-00"), ...
                    dest=this.source_ses_path);
            end
            
            % delete large files
            if opts.clean_up
                this.build_clean(tag=opts.tag);
            end
            popd(pwd0);
        end
        function this = build_test(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.LMFrames {mustBeTextScalar} = "0:60,60,60,60,60"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.filepath {mustBeFolder} = this.test_project_path
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            copts = namedargs2cell(opts);

            this.check_env();
            this.check_test_env();

            pwd0 = pushd(this.test_project_path);
            bmcp = mlsiemens.BrainMoCoParams2(copts{:});
            bmcp.writelines();
            [~,r] = mysystem(sprintf("cscript %s %s %s", ...
                this.jsrecon_js, ...
                fullfile("+Input", "VisionTestData"), ...
                bmcp.fqfilename));
            disp(r)
            popd(pwd0);
        end
        function check_env(this)
            % e7 requirements
            assert(strcmpi('PCWIN64', computer), ...
                'mlsiemens.{JSRecon,BrainMoCo2} require e7 in Microsoft Windows 64-bit')
            assert(isfolder(fullfile('C:', 'JSRecon12')))
            assert(isfolder(fullfile('C:', 'Service')))
            assert(isfolder(fullfile('C:', 'Siemens', 'PET', this.bin_version_folder)))

            % See also "BMC-Install&Test+DYN.docx"
            % BMC requirements, section B.1
            assert(isfile(this.jsrecon_js))
            assert(isfile(fullfile(this.inki_home, 'coregister.exe')))
            assert(isfile(fullfile(getenv("JJL_HOME"), "MyBMCProject", "MyVisionParams.txt")))
        end
        function check_test_env(this)
            % See also "BMC-Install&Test+DYN.docx"
            % BMC requirements, section B.2
            assert(isfile(fullfile(this.test_lm_Path, "VG80-BMCTestData-List-1522.ptd")))
        end
    end

    methods (Static)
        function ic = addJsonMetadata(ic, v_fqfn)
            %% ADDJSONMETADATA to object understood by mlfourd.ImagingContext2
            %  Args:
            %      ic {mustBeNonempty}
            %      v_fqfn {mustBeFile}

            arguments
                ic {mustBeNonempty}
                v_fqfn {mustBeFile}
            end
            ic = mlfourd.ImagingContext2(ic);

            % assign vhdr
            try
                vhdr_fqfn = v_fqfn+".hdr";
                vhdr = readline(vhdr_fqfn);
            catch ME
                handwarning(ME)
                vhdr = "";
            end

            % assign mhdr
            re = regexp(v_fqfn, "(?<fqfp>\S+_mc(\d|))_\d{3}_\d{3}.v", "names");
            try
                mhdr_fqfn = re.fqfp+".mhdr";
                mhdr = readline(mhdr_fqfn);
            catch ME
                handwarning(ME)
                mhdr = "";
            end
            
            % assign struct
            st.(mybasename(re.fqfp)) = struct("mhdr", mhdr, "vhdr", vhdr);
            ic.addJsonMetadata(st);
        end
        function ic = createNiftiCumul2frames(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = [2*ones(1,30) 10*ones(1,24)] % ordered per NIfTI, for easy testing
                opts.time0 double = 0
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            start_times = cumsum(opts.taus) - opts.taus + opts.time0;
            M = length(opts.taus);
            img = zeros([opts.matrix M], "single");
            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);    

            % read prototype from storage
            toglob_niigz = glob(convertStringsToChars(fullfile(ses_path, "*.nii.gz")));
            if ~isempty(toglob_niigz)
                proto_fqfn = toglob_niigz{1};
            else
                proto_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");
            end
            assert(isfile(proto_fqfn), "%s: %s not found", stackstr(), proto_fqfn)
            proto = mlfourd.ImagingContext2(proto_fqfn);
            proto.selectImagingTool();

            % time-averages of activity ~ [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
            for starti = 1:M
                lmtag = opts.tag+start_times(starti);
                cumpath = fullfile(getenv("SINGULARITY_HOME"), ...
                    "CCIR_01211", "sourcedata", sub, ses, this.lm_prefix+lmtag+opts.folder_tag);             
                v_fqfn = convertStringsToChars( ...
                    fullfile(cumpath, this.lm_prefix+lmtag+"-BMC-LM-00-dynamic_mc0_000_000.v"));
                if ~isfile(v_fqfn)
                    continue
                end
                img(:,:,:,starti)  = mlsiemens.BrainMoCo2.vread(v_fqfn); % [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
            end

            % aufbau ifc with cumulative time-integrals of activity
            ifc = proto.imagingFormat;
            ifc.img = img;
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix+"-bar-alpha";

            ifc.save();

            % differentiate cumulative time-integrals of activity;
            ic = mlfourd.ImagingContext2(ifc);
            ic = mlsiemens.BrainMoCo2.cumul2frames(ic, taus=opts.taus);
            ic.fileprefix = fileprefix;
            ic.save();
        end
        function ic = createNiftiDiffCumul(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = [2*ones(1,30) 10*ones(1,24)] % ordered per NIfTI
                opts.time0 double = 0
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            start_times = cumsum(opts.taus) - opts.taus + opts.time0;
            M = length(opts.taus);
            img = zeros([opts.matrix M], "single");
            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);            

            % read ifc prototype from storage
            ifc_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");            
            ifc = mlfourd.ImagingFormatContext2(ifc_fqfn);

            % reverse-order time-averages;
            % time-averages of activity -> cumulative time-integrals of activity ~ cumulative events
            reversed_taus = flip(opts.taus);
            for taui = 1:M
                lmtag = opts.tag+start_times(M-taui+1);
                cumpath = fullfile(getenv("SINGULARITY_HOME"), ...
                    "CCIR_01211", "sourcedata", sub, ses, this.lm_prefix+lmtag+opts.folder_tag);             
                v_fqfn = convertStringsToChars( ...
                    fullfile(cumpath, this.lm_prefix+lmtag+"-BMC-LM-00-dynamic_mc0_000_000.v"));
                if isempty(v_fqfn)
                    continue
                end
                alpha_avgt = mlsiemens.BrainMoCo2.vread(v_fqfn);
                interval_T = sum(reversed_taus(1:taui));
                img(:,:,:,taui) = interval_T*alpha_avgt;
                % cumul time-integral of mlsiemens.BrainMoCo2.vread(v_fqfn); 
                % ..., T_g*\bar{gamma}, T_b*\bar{beta}, T_a*\bar{alpha}; so time is reversed
            end

            % aufbau ifc with cumulative time-integrals of activity
            ifc.img = img;
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix+"-time-reversed-cumul-intt-at";
            ifc.save();

            % differentiate cumulative time-integrals of activity;
            % reverse-order times, again
            ic = mlfourd.ImagingContext2(ifc);
            ic = mlsiemens.BrainMoCo2.diff_cumul(ic, taus=flip(opts.taus));
            ic = flip(ic, 4); 
            ic.fileprefix = fileprefix;
            ic.save();
        end
        function ic = createNiftiMovingAvgRepair(sub, ses, opts)

            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = 10*ones(1,11) % ordered per NIfTI, for easy testing
                opts.time0 double = 0
                opts.dT double = 10
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.start_times double = 0:9
                opts.lm_prefix {mustBeTextScalar} = "lm-trc"

                opts.source_lm_path {mustBeFolder}
            end
            import mlsiemens.BrainMoCo2
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            starts = opts.start_times;
            taus = opts.taus;

            % load ic with missing frames
            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);
            ic = mlfourd.ImagingContext2( ...
                fullfile(ses_path, strcat(fileprefix, ".nii.gz")));
            ifc = ic.imagingFormat;
            ic_avgxyz = ic.volumeAveraged();
            select_missing = asrow(ic_avgxyz.imagingFormat.img < eps);

            % activity 
            tag = opts.tag;
            img = ifc.img;
            j = ifc.json_metadata;
            timesMid = j.timesMid;
            if isnan(timesMid(1))
                timesMid(1) = taus(1)/2;
            end
            assert(length(timesMid) == length(select_missing))
            for ti = 2:length(select_missing) % ignore empty first frame
                if ~select_missing(ti); continue; end                
                try
                    tau = taus(mod(ti, length(taus)));
                    assert(isnan(timesMid(ti)))
                    timesMid(ti) = timesMid(ti-1) + tau/2;
                    this = BrainMoCo2.create_tagged(source_lm_path, tag=tag+starts(ti)+"-repair"); 
                    lmframes = starts(ti)+":"+tau;
                    ic_single = this.build_single(LMFrames=lmframes, tracer=opts.tracer, tag=tag+starts(ti)+"-repair");
                catch ME
                    handwarning(ME)
                end
                img(:,:,:,ti) = ic_single.imagingFormat.img;
            end
            ifc.img = img;
            ifc.json_metadata.timesMid = timesMid;
            clear img;            

            % aufbau repaired ifc
            movefile(ic.fqfn, ic.fqfp+"-bak.nii.gz")
            ifc.save();
        end
        function ic = createNiftiMovingAvgFrames(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = 10*ones(1,11) % ordered per NIfTI, for easy testing
                opts.time0 double = 0
                opts.dT double = 10
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.start_times double = 0:9
                opts.lm_prefix {mustBeTextScalar} = "lm-trc"
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            starts = opts.start_times;
            taus = opts.taus;
            M = length(starts);
            N = length(taus);

            % memory management
            if M*N*prod(opts.matrix) > 1e10
                copts = namedargs2cell(opts);
                ic = mlsiemens.BrainMoCo2.createNiftiMovingAvgFrames2(sub, ses, copts{:});
                return
            end

            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);    

            % read prototype from storage
            toglob_niigz = glob(convertStringsToChars(fullfile(ses_path, "*.nii.gz")));
            if ~isempty(toglob_niigz)
                proto_fqfn = toglob_niigz{1};
            else
                proto_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");
            end
            assert(isfile(proto_fqfn), "%s: %s not found", stackstr(), proto_fqfn)
            proto = mlfourd.ImagingContext2(proto_fqfn);
            proto.selectImagingTool();

            % activity 
            ifc = proto.imagingFormat;
            img = zeros([opts.matrix M*N], "single");
            timesMidN = cumsum(taus) - taus/2;
            timesMidMN = NaN(1, M*N);
            for m = 1:M
                for n = 1:N
                    try
                        lmtag = opts.tag+starts(m);
                        lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                            "CCIR_01211", "sourcedata", sub, ses, opts.lm_prefix+lmtag+opts.folder_tag);    
    
                        v_fqfn = glob(convertStringsToChars( ...
                            fullfile(lmtagpath, sprintf("%s%s-BMC-LM-00-dynamic_mc%i_*_*.v", opts.lm_prefix, lmtag, n-1))));
                        if isempty(v_fqfn)
                            continue
                        end
                        v_fqfn = v_fqfn{1};
                        if ~isfile(v_fqfn)
                            continue
                        end

                        iidx = m + (n-1)*M;
                        img(:,:,:,iidx) = single(mlsiemens.BrainMoCo2.vread(v_fqfn)); % [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
                        timesMidMN(iidx) = starts(m) + timesMidN(n);
                    catch ME
                        fprintf("%s: %s m->%g, n->%g\n", stackstr(), ME.message, m, n);
                    end
                end
            end
            ifc.img = img;
            clear img;

            % aufbau ifc and ic with cumulative time-integrals of activity
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix;
            js = struct( ...
                "start_times", asrow(starts), ...
                "taus", asrow(taus), ...
                "timesMid", asrow(timesMidMN));
            ifc.addJsonMetadata(js)
            ifc.save();
            ic = mlfourd.ImagingContext2(ifc);
        end
        function ic = createNiftiMovingAvgFrames2(sub, ses, opts)
            %% splits the NIfTI into two parts to half memory requirements;
            %  returns ic1 only, the first half of time series

            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = 10*ones(1,11) % ordered per NIfTI, for easy testing
                opts.time0 double = 0
                opts.dT double = 10
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = ""
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.start_times double = 0:9
                opts.lm_prefix {mustBeTextScalar} = "lm-trc"
            end
            if isemptytext(opts.tag0)
                opts.tag0 = opts.tag+"0";
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            starts = opts.start_times;
            taus = opts.taus;
            M = length(starts);
            N = length(taus);
            N1 = ceil(N/2);
            N2 = N - N1;

            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);    
            cumtaus = cumsum(taus) - taus/2;

            % read prototype from storage
            toglob_niigz = glob(convertStringsToChars(fullfile(ses_path, "*.nii.gz")));
            if ~isempty(toglob_niigz)
                proto_fqfn = toglob_niigz{1};
            else
                proto_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");
            end
            assert(isfile(proto_fqfn), "%s: %s not found", stackstr(), proto_fqfn)
            proto = mlfourd.ImagingContext2(proto_fqfn);
            proto.selectImagingTool();

            % activity part 1
            ifc = proto.imagingFormat;
            img = zeros([opts.matrix M*N1], "single");
            timesMidN1 = cumtaus(1:N1) - taus/2;
            timesMidMN1 = NaN(1, M*N1);
            for m = 1:M
                for n = 1:N1
                    try
                        lmtag = opts.tag+starts(m);
                        lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                            "CCIR_01211", "sourcedata", sub, ses, opts.lm_prefix+lmtag+opts.folder_tag);    
    
                        v_fqfn = glob(convertStringsToChars( ...
                            fullfile(lmtagpath, sprintf("%s%s-BMC-LM-00-dynamic_mc%i_*_*.v", opts.lm_prefix, lmtag, n-1))));
                        if isempty(v_fqfn)
                            continue
                        end
                        v_fqfn = v_fqfn{1};
                        if ~isfile(v_fqfn)
                            continue
                        end
    
                        iidx = m + (n-1)*M;
                        img(:,:,:,iidx) = single(mlsiemens.BrainMoCo2.vread(v_fqfn)); % [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
                        timesMidMN1(iidx) = starts(m) + timesMidN1(n);
                    catch ME
                        fprintf("%s: %s m->%g, n->%g\n", stackstr(), ME.message, m, n);
                    end
                end
            end
            ifc.img = img;
            clear img;

            % aufbau ifc with cumulative time-integrals of activity
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix + "-times" + timesMidMN1(1) + "-" + timesMidMN1(end);
            js = struct( ...
                "start_times", asrow(starts), ...
                "taus", asrow(taus(1:N1)), ...
                "timesMid", asrow(timesMidMN1));
            ifc.addJsonMetadata(js)
            ifc.save();
            clear ifc;

            % activity part 2
            ifc = proto.imagingFormat;
            img = zeros([opts.matrix M*N2], "single");
            timesMidN2 = cumtaus(N1+1:N) - taus/2;
            timesMidMN2 = NaN(1, M*N2);
            for m = 1:M
                for n = N1+1:N2
                    try
                        lmtag = opts.tag+starts(m);
                        lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                            "CCIR_01211", "sourcedata", sub, ses, opts.lm_prefix+lmtag+opts.folder_tag);    
    
                        v_fqfn = glob(convertStringsToChars( ...
                            fullfile(lmtagpath, sprintf("%s%s-BMC-LM-00-dynamic_mc%i_*_*.v", opts.lm_prefix, lmtag, N1+n-1))));
                        if isempty(v_fqfn)
                            continue
                        end
                        v_fqfn = v_fqfn{1};
                        if ~isfile(v_fqfn)
                            continue
                        end
    
                        iidx = m + (n-1)*M;
                        img(:,:,:,iidx) = single(mlsiemens.BrainMoCo2.vread(v_fqfn)); % [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
                        timesMidMN2(iidx) = starts(m) + timesMidN2(n);
                    catch ME
                        fprintf("%s: %s m->%g, n->%g\n", stackstr(), ME.message, m, n);
                    end
                end
            end
            ifc.img = img;
            clear img;

            % aufbau ifc with cumulative time-integrals of activity
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix + "-times" + timesMidMN2(1) + "-" + timesMidMN2(end);
            js = struct( ...
                "start_times", asrow(starts), ...
                "taus", asrow(taus(N1+1:N)), ...
                "timesMid", asrow(timesMidMN2));
            ifc.addJsonMetadata(js)
            ifc.save();
            clear ifc;

            ic = []; % respecting memory limits
        end
        function ic = createNiftiMovingAvgPrevious(sub, ses)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
            end

            % get nifti static as prototype
            ic_static = mlsiemens.BrainMoCo2.create_nifti_static(sub, ses);
            ifc_static = ic_static.imagingFormat;

            ics = cell(1, 10);
            for tagi = 0:9
                lmtag = "-start"+tagi;
                dynpath = fullfile(getenv("SINGULARITY_HOME"), ...
                    "CCIR_01211", "sourcedata", sub, ses, this.lm_prefix+lmtag+"-DynamicBMC");
             
                vglobbed = glob(convertStringsToChars( ...
                    fullfile(dynpath, this.lm_prefix+lmtag+"-BMC-LM-00-dynamic_mc*_*_*.v")));
                ifc = copy(ifc_static);
                ifc.img = zeros([size(ifc) length(vglobbed)]);
                ifc.fileprefix = strrep(ifc_static.fileprefix, "static", "dyn-"+stackstr()+lmtag);
                for vi = 1:length(vglobbed)
                    ifc.img(:,:,:,vi) = mlsiemens.BrainMoCo2.vread(vglobbed{vi});                    
                end
                ics{tagi} = mlfourd.ImagingContext2(ifc);
            end
            ic = ics{1}.timeInterleaved(ics(2:end));
            ic.fileprefix = strrep(ic.fileprefix, this.lm_prefix+lmtag, "lm-all-starts");
        end
        function ic = createNiftiStatic(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.tag {mustBeTextScalar} = "-simple"
                opts.folder_tag {mustBeTextScalar} = "-StaticBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-ac_mc"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.lm_prefix {mustBeTextScalar} = "lm-trc"
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);

            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);    

            % read prototype from storage
            proto_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");
            assert(isfile(proto_fqfn), "%s: %s not found", stackstr(), proto_fqfn)
            proto = mlfourd.ImagingContext2(proto_fqfn);
            proto.selectImagingTool();

            % activity 
            ifc = proto.imagingFormat;
            try
                lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                    "CCIR_01211", "sourcedata", sub, ses, opts.lm_prefix+opts.tag+opts.folder_tag);
                v_fqfn = glob(convertStringsToChars( ...
                    fullfile(lmtagpath, sprintf("%s%s-BMC-LM-00-ac_mc_*_*.v", opts.lm_prefix, opts.tag))));                
                v_fqfn = v_fqfn{1};
                ifc.img = single(mlsiemens.BrainMoCo2.vread(v_fqfn)); 
            catch ME
                fprintf("%s: %s\n", stackstr(), ME.message);
            end

            % aufbau ifc with cumulative time-integrals of activity
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix;
            ifc.save();
            ic = mlfourd.ImagingContext2(ifc);
        end
        function ic = createNiftiSimple(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)] % ordered per NIfTI, for easy testing
                opts.tag {mustBeTextScalar} = "-simple"
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.lm_prefix {mustBeTextScalar} = "lm-trc"
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);            
            taus = opts.taus;
            N = length(taus);

            fileprefix = sub+"_"+ses+"_trc-"+opts.tracer+"_proc-"+stackstr(use_dashes=true);    

            % read prototype from storage
            toglob_niigz = glob(convertStringsToChars(fullfile(ses_path, "*.nii.gz")));
            if ~isempty(toglob_niigz)
                proto_fqfn = toglob_niigz{1};
            else
                proto_fqfn = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz");
            end
            assert(isfile(proto_fqfn), "%s: %s not found", stackstr(), proto_fqfn)
            proto = mlfourd.ImagingContext2(proto_fqfn);
            proto.selectImagingTool();

            % activity 
            ifc = proto.imagingFormat;
            img = zeros([opts.matrix N], "single");
            timesMid = cumsum(taus) - taus/2;
            for n = N:-1:1
                try
                    lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                        "CCIR_01211", "sourcedata", sub, ses, opts.lm_prefix+opts.tag+opts.folder_tag);    

                    v_fqfn = glob(convertStringsToChars( ...
                        fullfile(lmtagpath, sprintf("%s%s-BMC-LM-00-dynamic_mc%i_*_*.v", opts.lm_prefix, opts.tag, n-1))));
                    if isempty(v_fqfn)
                        %img(:,:,:,n) = img(:,:,:,n+1);
                        continue
                    end
                    v_fqfn = v_fqfn{1};
                    if ~isfile(v_fqfn)
                        %img(:,:,:,n) = img(:,:,:,n+1);
                        continue
                    end

                    img(:,:,:,n) = single(mlsiemens.BrainMoCo2.vread(v_fqfn)); 
                catch ME
                    fprintf("%s: %s n->%g\n", stackstr(), ME.message, n);
                end
            end

            ifc.img = img;
            clear img;

            % aufbau ifc with cumulative time-integrals of activity
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix;
            js = struct( ...
                "taus", asrow(taus), ...
                "timesMid", asrow(timesMid));
            ifc.addJsonMetadata(js)
            ifc.save();
            ic = mlfourd.ImagingContext2(ifc);
        end       
        function create_co(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,29), ...
                tracer="co");
        end
        function create_fdg(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,359), ...
                tracer="fdg");
        end
        function create_fdg_phantom(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,29), ...
                tracer="fdg");
        end
        function create_ho(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,11), ...
                tracer="ho");
        end  
        function create_oo(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,11), ...
                tracer="oo");
        end                    
        function create_moving_average(source_lm_path, opts)
            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.taus double = 10*ones(1,11)
                opts.dT double = 10
                opts.tracer {mustBeTextScalar}
                opts.nifti_only logical = false
            end

            import mlsiemens.BrainMoCo2
            if ~opts.nifti_only
                BrainMoCo2.create_v_moving_average( ...
                    source_lm_path, ...
                    tag=opts.tag, ...
                    taus=opts.taus, ...
                    dT=opts.dT, ...
                    tracer=opts.tracer);
            end
            ss = split(source_lm_path, filesep);
            sub = ss(contains(ss, "sub-"));
            ses = ss(contains(ss, "ses-"));
            lm_prefix = mybasename(source_lm_path);
            mlsiemens.BrainMoCo2.createNiftiStatic( ...
                sub{1}, ses{1}, tag=opts.tag+0, tracer=opts.tracer, lm_prefix=lm_prefix);
            mlsiemens.BrainMoCo2.createNiftiMovingAvgFrames( ...
                sub{1}, ses{1}, tag=opts.tag, taus=opts.taus, dT=opts.dT, tracer=opts.tracer, lm_prefix=lm_prefix);
        end
        function create_simple(source_lm_path, opts)
            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-simple"
                opts.taus double = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)]
                opts.dT double = 10
                opts.tracer {mustBeTextScalar}
                opts.nifti_only logical = false
            end

            import mlsiemens.BrainMoCo2
            if ~opts.nifti_only
                BrainMoCo2.create_v( ...
                    source_lm_path, ...
                    tag=opts.tag, ...
                    taus=opts.taus, ...
                    tracer=opts.tracer);
            end
            ss = split(source_lm_path, filesep);
            sub = ss(contains(ss, "sub-"));
            ses = ss(contains(ss, "ses-"));
            lm_prefix = mybasename(source_lm_path);
            mlsiemens.BrainMoCo2.createNiftiStatic( ...
                sub{1}, ses{1}, tag=opts.tag, tracer=opts.tracer, lm_prefix=lm_prefix);
            mlsiemens.BrainMoCo2.createNiftiSimple( ...
                sub{1}, ses{1}, tag=opts.tag, taus=opts.taus, tracer=opts.tracer, lm_prefix=lm_prefix);
        end
        function this = create_tagged(source_lm_path, opts)
            arguments
                source_lm_path string
                opts.tag string = "-start0"
            end

            source_lm_path_tagged = source_lm_path+opts.tag;
            if ~isfolder(source_lm_path_tagged)
                copyfile(source_lm_path, source_lm_path_tagged)
            end
            this = mlsiemens.BrainMoCo2(source_lm_path=source_lm_path_tagged);
        end
        function create_tracer(source_lm_path, opts)
            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.taus double = [2*ones(1,30) 10*ones(1,24)]
                opts.tracer {mustBeTextScalar}
            end

            import mlsiemens.BrainMoCo2
            [starts,T] = BrainMoCo2.taus2starts(opts.taus);
            BrainMoCo2.create_v_cumul(source_lm_path, ...
                tag=opts.tag, starts=starts, T=T, tracer=opts.tracer);
            ss = split(source_lm_path, filesep);
            sub = ss(contains(ss, "sub-"));
            ses = ss(contains(ss, "ses-"));
            mlsiemens.BrainMoCo2.createNiftiCumul2frames( ...
                sub, ses, taus=opts.taus, tracer=opts.tracer);
        end
        function create_v(source_lm_path, opts)
            %% Args:
            % source_lm_path {mustBeFolder}
            % opts.tag {mustBeTextScalar} = "-simple"
            % opts.taus double = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)]
            % opts.dT double = 10
            % opts.tracer {mustBeTextScalar} = "unknown"

            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-simple"
                opts.taus double = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)]
                opts.dT double = 10
                opts.tracer {mustBeTextScalar} = "unknown"
            end

            import mlsiemens.BrainMoCo2
            try
                this = BrainMoCo2.create_tagged(source_lm_path, tag=opts.tag); 
                lmframes = BrainMoCo2.mat2lmframes(opts.taus, start=0);
                this.build_all(LMFrames=lmframes, tracer=opts.tracer, tag=opts.tag);
            catch ME
                handwarning(ME)
            end
        end
        function create_v_cumul(source_lm_path, opts)
            %% Args:
            %     source_lm_path {mustBeFolder}
            %     opts.tag {mustBeTextScalar} = "-start"
            %     opts.starts double = [19,20]
            %     opts.T double = 120
            %     opts.tracer {mustBeTextScalar} = "unknown"

            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.starts double = 0:2:58
                opts.T double = 120
                opts.tracer {mustBeTextScalar} = "unknown"
            end
            tag = opts.tag;
            starts = opts.starts;
            M = length(starts); 
            T = opts.T;            
            tracer = opts.tracer;

            import mlsiemens.BrainMoCo2
            parfor (si = 1:M, BrainMoCo2.N_PROC)
                try
                    this = BrainMoCo2.create_tagged(source_lm_path, tag=tag+starts(si)); 
                    lmframes = sprintf("%i:%i", starts(si), T-starts(si));
                    this.build_all(LMFrames=lmframes, tracer=tracer, tag=tag+starts(si));
                catch ME
                    handwarning(ME)
                end
            end
        end
        function create_v_moving_average(source_lm_path, opts)
            %% Args:
            % source_lm_path {mustBeFolder}
            % opts.tag {mustBeTextScalar} = "-start"
            % opts.taus double = 10*ones(1,11)
            % opts.dT double = 10
            % opts.tracer {mustBeTextScalar} = "unknown"

            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.taus double = 10*ones(1,11)
                opts.dT double = 10
                opts.tracer {mustBeTextScalar} = "unknown"
            end

            import mlsiemens.BrainMoCo2
            tag = opts.tag;
            starts = 0:9;
            M = length(starts);

            parfor (si = 1:M, BrainMoCo2.N_PROC)
                try
                    this = BrainMoCo2.create_tagged(source_lm_path, tag=tag+starts(si)); 
                    lmframes = BrainMoCo2.mat2lmframes(opts.taus, start=starts(si)); %#ok<PFBNS>
                    this.build_all(LMFrames=lmframes, tracer=opts.tracer, tag=tag+starts(si));
                catch ME
                    handwarning(ME)
                end
            end
        end
        function ic = cumul2frames(ic, opts)
            arguments
                ic mlfourd.ImagingContext2
                opts.taus double = [2*ones(1,30) 10*ones(1,24)] % for easy testing
            end

            S = size(ic);
            S_ = S(1:rank(ic)-1);
            M = length(opts.taus);
            L = zeros(M, M);
            for m = 1:M
                for n = m:M
                    L(m,n) = opts.taus(n);
                end
                T = sum(opts.taus(m:M));
                L(m,:) = L(m,:)/T;
            end

            ifc = ic.imagingFormat;
            mat = ifc.img;
            mat = reshape(double(mat), [prod(S_) M]); % voxels x \hat{alpha}

            B = mat'; % voxels x times -> times x voxels
            X = zeros(size(B));
            Nvoxels = size(B, 2);
            for v = 1:Nvoxels
                X(:,v) = lsqnonneg(L, B(:,v));
            end

            mat = X'; % times x voxels -> voxels x times
            ifc.img = single(reshape(mat, [S_ M]));
            ic = mlfourd.ImagingContext2(ifc);
            ic.fileprefix = strcat(ic.fileprefix, "-", stackstr(use_dashes=true));
        end
        function ic = cumul2frames4d(ic, opts)
            arguments
                ic mlfourd.ImagingContext2
                opts.taus double = [2*ones(1,30) 10*ones(1,24)]
                opts.blur double = 3.567 % fwhh
            end

            import mlsiemens.BrainMoCo2.make_mask
            S = size(ic);
            S_ = S(1:rank(ic)-1);
            M = length(opts.taus);
            L = zeros(M, M);
            for m = 1:M
                for n = m:M
                    L(m,n) = opts.taus(n);
                end
                T = sum(opts.taus(m:M));
                L(m,:) = L(m,:)/T;
            end

            vec_mask = reshape(logical(make_mask(ic)), [prod(S_), 1]);
            Nmask = sum(vec_mask);

            ic = ic.blurred(opts.blur);
            ifc = ic.imagingFormat;
            mat = reshape(double(ifc.img), [prod(S_), M]); % voxels x \hat{alpha}
            mat1 = zeros(Nmask, M);
            for m = 1:M
                mat1(:,m) = mat(vec_mask, m);
            end

            B = mat1'; % voxels x times -> times x voxels
            X = zeros(size(B));
            Nmask = size(B, 2);
            for v = 1:Nmask
                X(:,v) = lsqnonneg(L, B(:,v));
            end

            mat1 = X'; % times x voxels -> voxels x times
            for m = 1:M
                mat(vec_mask, m) = mat1(:,m); 
            end
            ifc.img = single(reshape(mat, [S_, M]));
            ifc.fileprefix = strcat(ifc.fileprefix, "-", stackstr(use_dashes=true));
            ic = mlfourd.ImagingContext2(ifc);
        end
        function ic = deconv_moving(ic, opts)
            %% https://stats.stackexchange.com/questions/67907/extract-data-points-from-moving-average
            %  Note fabree's answer only.

            arguments
                ic mlfourd.ImagingContext2
                opts.start_times double = 0:2:8
                opts.taus double = 10*ones(1,29)
            end
            fileprefix = ic.fileprefix;
            sz = size(ic);
            Nvoxels = prod(sz(1:3));
            M = length(opts.start_times);
            N = length(opts.taus);
            P = M*N;
            assert(sz(4) == P, stackstr())
            
            L = tril(ones(P,P), M-1) - tril(ones(P,P), -1);
            L = L/M;

            ifc = ic.imagingFormat;
            img = reshape(ifc.img, [Nvoxels, P]);
            ifc.img = []; % reduce memory
            for vi = 1:Nvoxels
                img(vi,:) = single(lsqnonneg(L, img(vi,:)')');
            end
            sz1 = [sz(1:3) P];
            ifc.img = reshape(img, sz1);
            ifc.fileprefix = fileprefix+"-deconv-moving";
            timesStart = cumsum(opts.taus) - opts.taus;
            timesDeconv = opts.start_times' + timesStart; % M x N matrix
            timesDeconv = reshape(timesDeconv, [1, P]);
            timesDeconv = sort(timesDeconv); % not required, but defensive
            s = struct("timesDeconv", timesDeconv);
            ifc.addJsonMetadata(s);
            ifc.save();
            ic = mlfourd.ImagingContext2(ifc);
        end
        function ic = diff_cumul(ic, opts)
            arguments
                ic mlfourd.ImagingContext2
                opts.taus double = []
            end
            M = size(ic, rank(ic));

            % reshape, time-average -> cumulative time-integral, finite difference in time
            ifc = ic.imagingFormat;
            sz = size(ifc);
            sz_ = sz(1:rank(ifc)-1);
            mat = reshape(double(ifc.img), [prod(sz_) M]); % voxels x \hat{alpha}
            mat = diff(mat, 1, 2);
            if ~isempty(opts.taus)
                assert(M == length(opts.taus))
                dt_ = opts.taus(2:end); % forward finite differencing
                mat = mat./dt_; % \partial_t \int^t dt' tac(t')
            end

            % package product
            ifc.img = single(reshape(mat, [sz_ M-1]));
            ic = mlfourd.ImagingContext2(ifc);
            ic.fileprefix = strcat(ic.fileprefix, "-", stackstr(use_dashes=true));
        end
        function ic = interp1_missing(ic, opts)
            arguments
                ic mlfourd.ImagingContext2
                opts.dt double = 2
            end

            fileprefix = ic.fileprefix;
            timesMid = asrow(ic.json_metadata.timesMid); % expected to have nans
            valid = ~isnan(timesMid);
            if length(valid) == length(timesMid) % no interp1 needed
                return
            end
            timesValid = timesMid(valid);
            t = timesMid(1):opts.dt:timesMid(end);

            ifc = ic.imagingFormat;
            ifc.img(:,:,:,~valid) = [];
            ic = mlfourd.ImagingContext2(ifc);
            ic = ic.interp1(timesValid, t);
            ic.addJsonMetadata(struct("timesMid", t));
            ic.fileprefix = fileprefix + "-interp1";
        end
        function ic = make_mask(ic, opts)
            %% using first frame of 4D data, then blurring, threshing, binarizing,
            %  and removing inferior Nscatter frames corrupted by scattering.

            arguments
                ic mlfourd.ImagingContext2
                opts.blur double = 10
                opts.thresh double = 1000
                opts.Nscatter double = 5
            end
            fp = ic.fileprefix;
            
            if rank(ic) < 3
                ic = ones(ic);
                return
            end
            if rank(ic) == 4
                % reduce to 3D
                ifc = ic.nifti;
                ifc.img = ifc.img(:,:,:,1);
                ic = mlfourd.ImagingContext2(ifc);
            end
            ic = ic.blurred(opts.blur);
            ic = ic.thresh(opts.thresh);
            ic = ic.binarized();
            ifc = ic.nifti;
            ifc.img(:,:,1:opts.Nscatter) = 0; % remove scattering below neck
            ic = mlfourd.ImagingContext2(ifc);
            ic.fileprefix = fp + "_" + stackstr();
        end
        function s = mat2lmframes(taus, opts)
            arguments
                taus {mustBeInteger} = 60
                opts.start {mustBeInteger} = 0
            end
            frame_durations = mat2str(asrow(taus));
            frame_durations = strrep(frame_durations, ' ', ',');
            if strcmp(frame_durations(1), '[')
                frame_durations = frame_durations(2:end);
            end
            if strcmp(frame_durations(end), ']')
                frame_durations = frame_durations(1:end-1);
            end
            s = num2str(opts.start)+":"+frame_durations;
        end
        function s = sread(filename, shape)
            %% Args:
            %     filename {mustBeFile}
            %     shape double = [440 440 159]

            arguments
                filename {mustBeFile}
                shape double = [520 50 815 33]
            end

            fid = fopen(filename, "r", "ieee-le");
            s = fread(fid, Inf, "single");
            s = single(s);
            s(s < 0) = 0;
            s = reshape(s, shape);
            s = flip(flip(s, 1), 2);
        end
        function [st,T] = taus2starts(taus)
            arguments
                taus double = [2*ones(1,30) 10*ones(1,24)]
            end
            cumsums = cumsum(taus);
            st = [0 cumsums(1:end-1)];
            T = cumsums(end);
        end
        function ic = v2ic(varargin)
            %% Args follow vread.
            ifc = mlfourd.ImagingFormatContext2(fullfile( ...
                getenv("SINGULARITY_HOME"), "CCIR_01211", "vision_zeros_440x440x159.nii.gz"));
            ifc.img = mlsiemens.BrainMoCo2.vread(varargin{:});
            ifc.fileprefix = mybasename(varargin{1});
            ifc.filepath = fullfile(pwd, myfileparts(varargin{1}));
            ic = mlfourd.ImagingContext2(ifc);
        end
        function v = vread(filename, shape)
            %% Args:
            %     filename {mustBeFile}
            %     shape double = [440 440 159]

            arguments
                filename {mustBeFile}
                shape double = mlsiemens.BrainMoCo2.SHAPE
            end

            fid = fopen(filename, "r", "ieee-le");
            v = fread(fid, Inf, "single");
            v = single(v);
            v(v < 0) = 0;
            v = reshape(v, shape);
            v = flip(flip(v, 1), 2);
        end
    end

    %% PROTECTED

    properties (Access = protected)
        source_lm_path_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
