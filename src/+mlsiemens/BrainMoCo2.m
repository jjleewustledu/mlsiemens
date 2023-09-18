classdef BrainMoCo2 < handle & mlsystem.IHandle
    %% builds PET imaging with JSRecon12 & e7 & Inki Hong's BrainMotionCorrection
    %  
    %  Created 03-Jan-2023 01:19:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        N_PROC = 5
        SHAPE = mlsiemens.BrainMoCoParams2.SHAPE
    end

    properties
        bin_version_folder = "bin.win64-VG80"
    end

    properties (Dependent)
        bmc_js
        inki_home
        jsrecon_home
        jsrecon_js
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
        function call(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:10,10,10,10,10,10,10,10,10,10,10,10"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "oo"
                opts.filepath {mustBeFolder} = this.source_pet_path % for BMC params file (.txt)
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = "-start0"
                opts.is_dyn logical = true
                opts.doIF2Dicom logical = false
                opts.clean_up logical = true
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
            if opts.doIF2Dicom && strcmp(opts.tag, "-start0")
                this.call_IF2Dicom( ...
                    source=fullfile(this.source_lm_path+"-BMC-Converted", "lm-start0-BMC-LM-00"), ...
                    dest=this.source_ses_path);
            end
            
            % delete large files
            if opts.clean_up
                this.call_clean(tag=opts.tag);
            end
            popd(pwd0);
        end
        function call_clean(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = "-start0"
            end
            opts.tag = string(opts.tag);
            
            try    
                if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                    opts.tag = "-"+opts.tag;
                end

                if isfolder(fullfile(this.source_ses_path, "lm"+opts.tag))
                    rmdir(fullfile(this.source_ses_path, "lm"+opts.tag), "s");
                end
                if isfolder(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC"))
                    rmdir(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC"), "s");
                end
                if ~strcmp(opts.tag, opts.tag0)
                    if isfolder(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC"))
                        rmdir(fullfile(this.source_ses_path, "lm"+opts.tag+"-StaticBMC"), "s");
                    end
                end
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.i"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.l"));                
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.s"));                
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.s.hdr"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "nac*.v"));                
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "nac*.v.hdr"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*-ac_mc_*_*.v"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*-ac_mc_*_*.v.hdr"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*-dynamic_mc*_*_*.v"));
                deleteExisting(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*-dynamic_mc*_*_*.v.hdr"));
            catch ME
                handwarning(ME)
            end            
        end
        function call_IF2Dicom(this, opts)
            arguments
                this mlsiemens.BrainMoCo2 %#ok<INUSA>
                opts.source {mustBeFolder}
                opts.dest {mustBeFolder}
            end

            pwd0 = pushd(opts.source);
            vhdr = "lm-start0-BMC-LM-00-dynamic_mc0_000_000.v.hdr";
            if2dicom_js = fullfile("C:", "JSRecon12", "IF2Dicom.js");
            mysystem(sprintf("cscript %s %s Run-05-lm-start0-BMC-LM-00-IF2Dicom.txt", ...
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
        function call_jsr(this, opts)
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
            disp(r)
            popd(pwd0);

            % run Run-99-lm-start*-LM-00-All.bat
            bat_path = fullfile( ...
                this.source_ses_path, "lm"+opts.tag+"-Converted", "lm"+opts.tag+"-LM=00");
            pwd1 = pushd(bat_path);
            [~,r] = mysystem("Run-99-lm-"+opts.tag+"-LM-00-All.bat");
            disp(r)

            try
                % rmdir(fullfile(this.source_ses_path, "lm"+opts.tag), "s");
                % rmdir(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC"), "s");
            catch ME
                handwarning(ME)
            end
            try
                % delete(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.l"));
                % delete(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.v"));
            catch ME
                handwarning(ME)
            end
            popd(pwd1);
        end
        function call_static(this)
            pwd0 = pushd(this.source_pet_path);
            [~,r] = mysystem(sprintf("cscript C:\JSRecon12\StaticRecon\StaticRecon.js %s", ...
                this.jsrecon_js, ...
                this.source_lm_path));
            disp(r)
            popd(pwd0);
        end
        function this = call_test(this, opts)
            arguments
                this mlsiemens.BrainMoCo2
                opts.LMFrames {mustBeTextScalar} = "0:60,60,60,60,60"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.filepath {mustBeFolder} = this.test_project_path
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = "-start0"
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
                opts.tag0 {mustBeTextScalar} = "-start0"
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
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
                    "CCIR_01211", "sourcedata", sub, ses, "lm"+lmtag+opts.folder_tag);             
                v_fqfn = convertStringsToChars( ...
                    fullfile(cumpath, "lm"+lmtag+"-BMC-LM-00-dynamic_mc0_000_000.v"));
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
                opts.tag0 {mustBeTextScalar} = "-start0"
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
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
                    "CCIR_01211", "sourcedata", sub, ses, "lm"+lmtag+opts.folder_tag);             
                v_fqfn = convertStringsToChars( ...
                    fullfile(cumpath, "lm"+lmtag+"-BMC-LM-00-dynamic_mc0_000_000.v"));
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
        function ic = createNiftiMovingAvgFrames(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.taus double = 10*ones(1,29) % ordered per NIfTI, for easy testing
                opts.time0 double = 0
                opts.dT double = 10
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = "-start0"
                opts.folder_tag {mustBeTextScalar} = "-DynamicBMC"
                opts.v_tag {mustBeTextScalar} = "-BMC-LM-00-dynamic_mc0"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.matrix double = mlsiemens.BrainMoCo2.SHAPE
                opts.start_times double = 0:2:8
            end
            ses_path = fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "sourcedata", sub, ses);
            starts = opts.start_times;
            taus = opts.taus;
            M = length(starts);
            N = length(taus);
            img = zeros([opts.matrix M*N], "single");
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
            cumtaus = cumsum(taus) - taus/2;
            timesMid = NaN(1, M*N);
            for m = 1:M
                for n = 1:N
                    lmtag = opts.tag+starts(m);
                    lmtagpath = fullfile(getenv("SINGULARITY_HOME"), ...
                        "CCIR_01211", "sourcedata", sub, ses, "lm"+lmtag+opts.folder_tag);    

                    n1 = n - 1;
                    switch n1
                        case num2cell(0:9)
                            v_fqfn = convertStringsToChars( ...
                                fullfile(lmtagpath, sprintf("lm%s-BMC-LM-00-dynamic_mc%i_000_00%i.v", lmtag, n1, n1)));
                        case num2cell(10:99)
                            v_fqfn = convertStringsToChars( ...
                                fullfile(lmtagpath, sprintf("lm%s-BMC-LM-00-dynamic_mc%i_000_0%i.v", lmtag, n1, n1)));
                        case num2cell(100:999)
                            v_fqfn = convertStringsToChars( ...
                                fullfile(lmtagpath, sprintf("lm%s-BMC-LM-00-dynamic_mc%i_000_%i.v", lmtag, n1, n1)));
                        otherwise
                            error("mlsiemens:ValueError", "%s:%g", stackstr(), taus);
                    end
                    if ~isfile(v_fqfn)
                        continue
                    end

                    img__ = mlsiemens.BrainMoCo2.vread(v_fqfn); % [\bar{alpha}, \bar{beta}, \bar{gamma}, ...]
                    iidx = m + (n-1)*M;
                    img(:,:,:,iidx) = img__(:,:,:); 
                    timesMid(iidx) = starts(m) + cumtaus(n);
                end
            end

            % aufbau ifc with cumulative time-integrals of activity
            ifc = proto.imagingFormat;
            ifc.img = img;
            ifc.filepath = ses_path;
            ifc.fileprefix = fileprefix;
            js = struct( ...
                "start_times", starts, ...
                "taus", taus, ...
                "timesMid", timesMid);
            ifc.addJsonMetadata(js)
            ifc.save();
            ic = mlfourd.ImagingContext2(ifc);
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
                    "CCIR_01211", "sourcedata", sub, ses, "lm"+lmtag+"-DynamicBMC");
             
                vglobbed = glob(convertStringsToChars( ...
                    fullfile(dynpath, "lm"+lmtag+"-BMC-LM-00-dynamic_mc*_*_*.v")));
                ifc = copy(ifc_static);
                ifc.img = zeros([size(ifc) length(vglobbed)]);
                ifc.fileprefix = strrep(ifc_static.fileprefix, "static", "dyn-"+stackstr()+lmtag);
                for vi = 1:length(vglobbed)
                    ifc.img(:,:,:,vi) = mlsiemens.BrainMoCo2.vread(vglobbed{vi});                    
                end
                ics{tagi} = mlfourd.ImagingContext2(ifc);
            end
            ic = ics{1}.timeInterleaved(ics(2:end));
            ic.fileprefix = strrep(ic.fileprefix, "lm"+lmtag, "lm-all-starts");
        end
        function ic = createNiftiStatic(sub, ses, opts)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                opts.tag {mustBeTextScalar} = "-start"
            end    

            lmtag = opts.tag+0;
            dicompath = fullfile(getenv("SINGULARITY_HOME"), ...
                "CCIR_01211", "sourcedata", sub, ses, "lm"+lmtag+"-StaticBMC", "lm"+lmtag+"-BMC-LM-00-ac_mc_000_000.v-DICOM");
            staticpath = myfileparts(dicompath);
            
            pwd0 = pushd(staticpath);
            [~,~,fn] = mlsiemens.BrainMoCoBuilder.dcm2niix();
            ic = mlfourd.ImagingContext2(fn);
            g = glob(fullfile(convertStringsToChars(dicompath), '*.ima')); % find DICOM info to add to json metadata
            info = dicominfo(g{1}); % a struct understood by jsonencode
            afield = strrep(mybasename(dicompath), "-", "_");
            afield = strrep(afield, ".", "_");
            ic.addJsonMetadata(struct(afield, info));
            popd(pwd0);
        end
        function [ic_dyn,ic_static] = createNifti(sub, ses, trc)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
                trc {mustBeTextScalar}
            end

            g_static = glob(sprintf('%s_%s-%s-BMC-LM-00-ac_mc*.nii.gz', sub, ses, trc));
            ic_static = mlfourd.ImagingContext2(g_static{1});
            ic_static.nifti;
            ic_static.fileprefix = sprintf('%s_%s_trc-%s_proc-bmc-static_pet', sub, ses, trc);
            ic_static.save();

            g_dyn = glob(sprintf('%s_%s-%s-BMC-LM-00-dynamic_*.nii.gz', sub, ses, trc));
            ifc_dyn = mlfourd.ImagingFormatContext2(g_dyn{1}); % first frame
            idx = 2;
            while idx <= length(g_dyn)
                ifc_ = mlfourd.ImagingFormatContext2(g_dyn{idx});
                sz = size(ifc_);
                if ndims(ifc_) < 4 || sz(4) == 1
                    ifc_dyn.img(:,:,:,idx) = ifc_.img;
                    idx = idx + 1;
                else
                    ifc_dyn.img(:,:,:,idx:idx+sz(4)-1) = ifc_.img;
                    idx = idx + sz(4);
                end
            end
            ic_dyn = mlfourd.ImagingContext2(ifc_dyn);
            ic_dyn.fileprefix = sprintf('%s_%s_trc-%s_proc-bmc-dyn_pet', sub, ses, trc);
            ic_dyn.save();
        end       
        function create_co(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,29), ...
                tracer="co");
        end
        function create_oo(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,29), ...
                tracer="oo");
        end
        function create_ho(source_lm_path)
            mlsiemens.BrainMoCo2.create_moving_average( ...
                source_lm_path, ...
                taus=10*ones(1,29), ...
                tracer="ho");
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
        function create_moving_average(source_lm_path, opts)
            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.taus double = 10*ones(1,12)
                opts.dT double = 10
                opts.tracer {mustBeTextScalar}
            end

            import mlsiemens.BrainMoCo2
            BrainMoCo2.create_v_moving_average( ...
                source_lm_path, ...
                tag=opts.tag, ...
                taus=opts.taus, ...
                dT=opts.dT, ...
                tracer=opts.tracer);
            ss = split(source_lm_path, filesep);
            sub = ss(contains(ss, "sub-"));
            ses = ss(contains(ss, "ses-"));
            mlsiemens.BrainMoCo2.createNiftiMovingAvgFrames( ...
                sub{1}, ses{1}, taus=opts.taus, dT=opts.dT, tracer=opts.tracer);
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
                    this.call(LMFrames=lmframes, tracer=tracer, tag=tag+starts(si));
                catch ME
                    handwarning(ME)
                end
            end
        end
        function create_v_moving_average(source_lm_path, opts)
            %% Args:
            %     source_lm_path {mustBeFolder}
            %     opts.tag {mustBeTextScalar} = "-start"
            %     opts.starts double = [19,20]
            %     opts.T double = 120
            %     opts.tracer {mustBeTextScalar} = "unknown"

            arguments
                source_lm_path {mustBeFolder}
                opts.tag {mustBeTextScalar} = "-start"
                opts.taus double = 10*ones(1,12)
                opts.dT double = 10
                opts.tracer {mustBeTextScalar} = "unknown"
            end

            import mlsiemens.BrainMoCo2
            tag = opts.tag;
            starts = 0:2:8;
            M = length(starts);

            %for si = 1:1
            parfor (si = 1:M, BrainMoCo2.N_PROC)
                try
                    this = BrainMoCo2.create_tagged(source_lm_path, tag=tag+starts(si)); 
                    lmframes = BrainMoCo2.mat2lmframes(opts.taus, start=starts(si)); %#ok<PFBNS>
                    this.call(LMFrames=lmframes, tracer=opts.tracer, tag=tag+starts(si));
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
