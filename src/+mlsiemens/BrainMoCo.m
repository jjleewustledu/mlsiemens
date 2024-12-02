classdef BrainMoCo < handle & mlsystem.IHandle
    %% builds PET imaging with JSRecon12 & e7 & Inki Hong's BrainMotionCorrection
    %  
    %  Created 03-Jan-2023 01:19:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Constant)
        N_PROC = 10
    end

    properties
        bin_version_folder = "bin.win64-VG80"
    end

    properties (Dependent)
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
        function g = get.inki_home(this)
            g = fullfile("C:", "Inki");
        end
        function g = get.jsrecon_home(this)
            g = fullfile("C:", "JSRecon12");
        end
        function g = get.jsrecon_js(this)
            g = fullfile(this.jsrecon_home, "BrainMotionCorrection", "BMC.js");
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
        function this = BrainMoCo(opts)
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
                this mlsiemens.BrainMoCo
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:10,10,10"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.filepath {mustBeFolder} = this.source_pet_path % for BMC params file (.txt)
                opts.tag {mustBeTextScalar} = ""
                opts.is_dyn logical = true
            end
            copts = namedargs2cell(opts);
            opts.tag = string(opts.tag);
            if ~isemptytext(opts.tag) && ~startsWith(opts.tag, "-")
                opts.tag = "-"+opts.tag;
            end

            this.check_env();

            pwd0 = pushd(this.source_pet_path);
            bmcp = mlsiemens.BrainMoCoParams(copts{:});
            bmcp.writelines();
            [~,r] = mysystem(sprintf("cscript %s %s %s", ...
                this.jsrecon_js, ...
                this.source_lm_path, ...
                bmcp.fqfilename));
            disp(r)
            try
                rmdir(fullfile(this.source_ses_path, "lm"+opts.tag), "s");
                rmdir(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC"), "s");
            catch ME
                handwarning(ME)
            end
            try
                delete(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.l"));
                delete(fullfile(this.source_ses_path, "lm"+opts.tag+"-BMC-Converted", "lm"+opts.tag+"-BMC-LM-00", "*.v"));
            catch ME
                handwarning(ME)
            end
            g = asrow(globFolders(fullfile(this.output_path, '*')));
            for gidx = 1:length(g)
                try
                    movefile(g{gidx}, this.source_ses_path)
                catch ME
                    handwarning(ME)
                end
            end
            popd(pwd0);
        end
        function build_static(this)
            pwd0 = pushd(this.source_pet_path);
            [~,r] = mysystem(sprintf("cscript C:\JSRecon12\StaticRecon\StaticRecon.js %s", ...
                this.jsrecon_js, ...
                this.source_lm_path));
            disp(r)
            popd(pwd0);
        end
        function this = build_test(this, opts)
            arguments
                this mlsiemens.BrainMoCo
                opts.LMFrames {mustBeTextScalar} = "0:60,60,60,60,60"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.filepath {mustBeFolder} = this.test_project_path
            end
            copts = namedargs2cell(opts);

            this.check_env();
            this.check_test_env();

            pwd0 = pushd(this.test_project_path);
            bmcp = mlsiemens.BrainMoCoParams(copts{:});
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
                'mlsiemens.{JSRecon,BrainMoCo} require e7 in Microsoft Windows 64-bit')
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
        function ic = create_nifti_hires(sub, ses)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
            end

            % get nifti static as prototype
            ic_static = mlsiemens.BrainMoCo.create_nifti_static(sub, ses);
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
                    ifc.img(:,:,:,vi) = mlsiemens.BrainMoCo.vread(vglobbed{vi});                    
                end
                ics{tagi} = mlfourd.ImagingContext2(ifc);
            end
            ic = ics{1}.timeInterleaved(ics(2:end));
            ic.fileprefix = strrep(ic.fileprefix, "lm"+lmtag, "lm-all-starts");
        end
        function ic = create_nifti_static(sub, ses)
            arguments
                sub {mustBeTextScalar}
                ses {mustBeTextScalar}
            end    

            lmtag = "-start0";
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
        function [ic_dyn,ic_static] = create_nifti(sub, ses, trc)
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
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,29), start=start);
                this.build_all(LMFrames=lmframes, tracer="co", tag="-start"+start);
            end
        end
        function create_oo(source_lm_path)
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,12), start=start);
                this.build_all(LMFrames=lmframes, tracer="oo", tag="-start"+start);
            end
        end
        function create_ho(source_lm_path)
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,12), start=start);
                this.build_all(LMFrames=lmframes, tracer="ho", tag="-start"+start);
            end
        end
        function create_fdg(source_lm_path)
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,30), start=start);
                this.build_all(LMFrames=lmframes, tracer="fdg", tag="-start"+start);
            end
            that = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+300);
            lmframes = that.mat2lmframes(60*ones(1,55), start=300);
            that.build_all(LMFrames=lmframes, tracer="fdg", tag="-start"+300);
        end
        function create_fdg_hires(source_lm_path)
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,359), start=start);
                this.build_all(LMFrames=lmframes, tracer="fdg", tag="-hires-start"+start);
            end
        end
        function create_fdg_phantom(source_lm_path)
            arguments
                source_lm_path {mustBeFolder}
            end

            parfor (start = 0:9, mlsiemens.BrainMoCo.N_PROC)
                this = mlsiemens.BrainMoCo.create_tagged(source_lm_path, "-start"+start);
                lmframes = this.mat2lmframes(10*ones(1,29), start=start);
                this.build_all(LMFrames=lmframes, tracer="fdg", tag="-start"+start);
            end
        end
        function this = create_tagged(source_lm_path, tag)
            arguments
                source_lm_path string
                tag string = ""
            end

            source_lm_path_tagged = source_lm_path+tag;
            if ~isfolder(source_lm_path_tagged)
                copyfile(source_lm_path, source_lm_path_tagged)
            end
            this = mlsiemens.BrainMoCo(source_lm_path=source_lm_path_tagged);
        end
        function s = mat2lmframes(taus, opts)
            arguments
                taus {mustBeInteger} = ones(1,3)
                opts.start {mustBeInteger} = 0
            end
            frame_durations = mat2str(asrow(taus));
            frame_durations = strrep(frame_durations, ' ', ',');
            frame_durations = frame_durations(2:end-1);
            s = num2str(opts.start)+":"+frame_durations;
        end
        function v = vread(filename, shape)
            arguments
                filename {mustBeFile}
                shape double = [440 440 159]
            end

            fid = fopen(filename, "r", "ieee-le");
            v = fread(fid, Inf, "single");
            v = reshape(v, shape);
        end
    end

    %% PROTECTED

    properties (Access = protected)
        source_lm_path_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
