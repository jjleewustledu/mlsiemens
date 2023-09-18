classdef BrainMoCoBuilder < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 29-Aug-2023 15:00:03 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties (Dependent)
        output_path % determined by Judd's BMC.js
        project_path
        raw_lm_path
        raw_pet_path
        source_lm_path
        source_pet_path
    end

    methods % GET
        function g = get.output_path(this)
            g = myfileparts(myfileparts(this.source_lm_path));
            g = fullfile(g, "+Output");
        end
        function g = get.project_path(this)
            ss = split(this.raw_lm_path, filesep);
            g = fullfile(ss(1), ss(2));
        end
        function g = get.raw_lm_path(this)
            g = this.raw_lm_path_;
        end
        function g = get.raw_pet_path(this)
            g = fullfile(myfileparts(this.raw_lm_path), "pet");
        end
        function g = get.source_lm_path(this)
            g = this.source_lm_path_;
        end
        function g = get.source_pet_path(this)
            g = fullfile(myfileparts(this.source_lm_path), "pet");
        end
    end

    methods
        function this = BrainMoCoBuilder(opts)
            arguments
                opts.raw_lm_path {mustBeFolder} = pwd
            end
            this.raw_lm_path_ = opts.raw_lm_path;
        end
        function [s,r] = copyfile(~, file_obj, dest_pth)
            [~,fp,x] = myfileparts(file_obj);
            dest_obj = fullfile(dest_pth, strcat(fp, x));
            if ~isfile(dest_obj)
                return
            end
            [s,r] = copyfile(file_obj, dest_pth);
        end
        function [s,r] = copyfile_ct_dcm(this, ct_nii, dest_pth)
            [~,fp,x] = myfileparts(ct_nii);
            ct_stars = fullfile(this.project_path, "rawdata", "dcm", "**", strcat(fp, x));
            g = glob(convertStringsToChars(ct_stars));

            % find the deepest match
            [~,I] = sort(cellfun(@length, g));
            g = g(I);
        end
        function build_input_folders(this, s)
            raw_sub_path = myfileparts(myfileparts(this.raw_lm_path));
            source_sub_path = strrep(raw_sub_path, "rawdata", "sourcedata");
            ses = sprintf("ses-%s", datetime(s.dt, Format="yyyyMMddHHmmss"));
            this.source_lm_path_ = fullfile(source_sub_path, ses, "lm");

            ensuredir(this.source_lm_path);
            this.copyfile_ct_dcm(s.ct, this.source_lm_path);
            this.copyfile(s.norm, this.source_lm_path);
            this.copyfile(s.lm, this.source_lm_path);

            ensuredir(this.source_pet_path);
        end
        function m = build_map_of_lm(this)
            pwd0 = pushd(this.raw_lm_path);
            m = containers.Map;
            g = glob(fullfile(this.raw_lm_path, "*LIST*"));
            for gidx = 1:length(g)
                fp = mybasename(g{gidx});
                re = regexp(fp, ...
                    "\S+LISTMODE.(?<Y>\d{4}).(?<M>\d{2}).(?<D>\d{2}).(?<H>\d{2}).(?<MI>\d{2}).(?<S>\d{2}).(?<MS>\d{6}).(?<id>[0-9.]+)", "names");
                dt = datetime( ...
                    str2double(re.Y), str2double(re.M), str2double(re.D), str2double(re.H), str2double(re.MI), str2double(re.S), str2double(re.MS)/1e3); 
                s.dt = dt;
                s.ct = this.find_ct(dt=dt);
                s.norm = this.find_norm(dt=dt);
                s.lm = g{gidx};
                s.id = re.id;
                m(char(fp)) = s;
            end
            popd(pwd0);
        end
        function build_niftis(this, s, opts)
            arguments
                this mlsiemens.BrainMoCoBuilder
                s struct
                opts.tag {mustBeTextScalar} = ""
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.is_dyn {mustBeTextScalar} = true
            end

            % source_lm_path ~ "D:\CCIR_01211\sourcedata\sub-108306\ses-20230227134149\lm" ~ 
            % listmode staged by build_input_folders()
            source_lm_path = strrep(this.raw_lm_path, "raw", "source");
            sesdt8 = "ses-" + string(datetime(s.dt, Format="yyyyMMdd"));
            sesdt14 = "ses-" + string(datetime(s.dt, Format="yyyyMMddHHmmss"));
            source_lm_path = strrep(source_lm_path, sesdt8, sesdt14);

            % def. source_ses_path, source_pet_path := source_lm_path
            source_ses_path = myfileparts(source_lm_path);
            source_pet_path = strrep(source_lm_path, "lm", "pet");

            pwd0 = pushd(source_pet_path);
            if opts.is_dyn
                dyn_dcm_path = fullfile(source_ses_path, "lm"+opts.tag+"-DynamicBMC", "lm-BMC-LM-00-dynamic-DICOM");
                mlsiemens.BrainMoCoBuilder.dcm2niix(dyn_dcm_path, f="sub-%n_ses-%t_trc-"+opts.tracer+"_proc-bmc-lm-00-dyn"+opts.tag+"_pet", w=1); % clobber
                rmdir(myfileparts(dyn_dcm_path), "s")
            else
                static_dcm_path = fullfile(source_ses_path, "lm"+opts.tag+"-StaticBMC", "lm-BMC-LM-00-ac_mc_000_000.v-DICOM");
                mlsiemens.BrainMoCoBuilder.dcm2niix(static_dcm_path, f="sub-%n_ses-%t_trc-"+opts.tracer+"_proc-bmc-lm-00-static_pet", w=1); % clobber
                rmdir(myfileparts(static_dcm_path), "s")
            end
            popd(pwd0);

        end
        function build_output_folders(this, s)
        end
        function call(this)
            % build map:  datetime -> struct.{ct, norm, lm}, fields with f.q. filenames; no timezone for simplicity
            map = this.build_map_of_lm();
            keys = map.keys;
            for k = asrow(keys) % co, oo, oo, ho, fdg, fdg_phant
                
                %     create input folder    
                this.build_input_folders(map(k{1}));
    
                %     call BMC    
                bmc = mlsiemens.BrainMoCo(source_lm_path=this.source_lm_path);
                switch something
                    case "fdg_phantom"
                        bmc.call_fdg_phantom() % phantom
                    case "co"
                        bmc.call_co()
                    case "oo"
                        bmc.call_oo()
                    case "ho"                
                        bmc.call_ho()
                    case "fdg"
                        bmc.call_fdg()
                end
    
                %     apply dcm2niix

                this.build_niftis(map(k{1}));

                %     reorganize output folders
    
                this.build_output_folders(map(k{1}));

            end
        end
        function fqfn = find_ct(this, opts)
            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.dt datetime = NaT % datetimes of listmode to match
            end

            pwd0 = pushd(this.raw_pet_path);
            
            % glob CTs
            g = glob(fullfile(this.raw_pet_path, '*_CT_*.nii.gz')); 
            g = g(~contains(g, '_AC_CT_'));
            for gidx = 1:length(g)
                % find CT datetimes
                re = regexp(mybasename(g{gidx}), "\S+_ses-(?<dt>\d{14})_\S+", "names");
                ct_dt(gidx) = datetime(re.dt, InputFormat="yyyyMMddHHmmss"); %#ok<AGROW>
            end

            % find CT acquired just before listmode
            T = table(ascol(g), minutes(ascol(opts.dt) - ascol(ct_dt)), variableNames={'fqfn', 'dur'});
            T = sortrows(T, 'dur', 'ascend');
            T = T(minutes(T.dur) >= 0, :);
            fqfn = T.fqfn{1};

            popd(pwd0);
        end
        function fqfn = find_norm(this, opts)
            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.dt datetime = NaT % datetimes of listmode to match
            end

            pwd0 = pushd(this.raw_lm_path);
            
            % glob CTs
            g = glob(fullfile(this.raw_lm_path, '*CALIBRATION*')); 
            for gidx = 1:length(g)
                % find norm datetimes
                re = regexp(mybasename(g{gidx}), ...
                    "\S+CALIBRATION.(?<Y>\d{4}).(?<M>\d{2}).(?<D>\d{2}).(?<H>\d{2}).(?<MI>\d{2}).(?<S>\d{2}).(?<MS>\d{6}).(?<id>[0-9.]+)", "names");
                norm_dt(gidx) = datetime( ...
                    str2double(re.Y), str2double(re.M), str2double(re.D), str2double(re.H), str2double(re.MI), str2double(re.S), str2double(re.MS)/1e3); %#ok<AGROW>
            end

            % find norm acquired just before listmode
            T = table(ascol(g), minutes(ascol(opts.dt) - ascol(norm_dt)), variableNames={'fqfn', 'dur'});
            T = sortrows(T, 'dur', 'ascend');
            T = T(minutes(T.dur) >= 0, :);
            fqfn = T.fqfn{1};

            popd(pwd0);
        end
    end

    methods (Static)
        function [s,r,fn] = dcm2niix(folder, opts)
            %% https://github.com/rordenlab/dcm2niix
            %  e.g., $ dcm2niix -f sub-%n_ses-%t_%d-%s -i 'n' -o $(pwd) -d 5 -v 0 -w 2 -z y $(pwd)
            %  Args:
            %      folder (folder):  for recursive searching
            %      d : directory search depth. Convert DICOMs in sub-folders of in_folder? (0..9, default 5)
            %      f (text):  filename specification; default 'sub-%n_ses-%t-%d-%s';
            %           %a=antenna (coil) number, 
            %           %b=basename, 
            %           %c=comments, 
            %           %d=description, 
            %           %e=echo number, 
            %           %f=folder name, 
            %           %i=ID of patient, 
            %           %j=seriesInstanceUID, 
            %           %k=studyInstanceUID, 
            %           %m=manufacturer, 
            %           %n=name of patient, 
            %           %p=protocol, 
            %           %r=instance number, 
            %           %s=series number, 
            %           %t=time, 
            %           %u=acquisition number, 
            %           %v=vendor, 
            %           %x=study ID; 
            %           %z=sequence name
            %      i (y/n):  ignore derived, localizer and 2D images (y/n; default n)
            %      o (folder):  output directory (omit to save to input folder); default pwd
            %      terse : omit filename post-fixes (can cause overwrites)
            %      u : up-to-date check
            %      v : verbose (0/1/2, default 0) [no, yes, logorrheic]
            %      version (numeric):  [] | 20180622 | 20180627
            %      w : write behavior for name conflicts (0,1,2, default 2: 0=skip duplicates, 1=overwrite, 2=add suffix)
            %      z : gz compress images (y/o/i/n/3, default n) [y=pigz, o=optimal pigz, i=internal:zlib, n=no, 3=no,3D]
            %
            %  Returns:
            %      s : mysystem status
            %      r : mysystem command output
            %      fn : list of files nii.gz

            arguments
                folder {mustBeFolder} = pwd % for recursive searching
                opts.d {mustBeInteger} = 5
                opts.f {mustBeTextScalar} = "sub-%n_ses-%t_%d-%s"
                opts.i {mustBeTextScalar} = "n"
                opts.o {mustBeFolder} = pwd
                opts.terse logical = false
                opts.u logical = false
                opts.v {mustBeInteger} = 0
                opts.version {mustBeNumeric} = []
                opts.w {mustBeInteger} = 1
                opts.toglob_mhdr {mustBeTextScalar} = "*.mhdr"
                opts.toglob_vhdr {mustBeTextScalar} = "*.v.hdr"
            end
            
            % select executable dcm2niix & pigz
            exe = 'dcm2niix';
            if isempty(opts.version)
                switch computer
                    case 'MACI64'
                        exe = 'dcm2niix_20230411';
                    case 'GLNXA64'
                        exe  = 'dcm2niix_20230411';
                    case 'PCWIN64'
                        exe = 'dcm2niix.exe';
                    otherwise
                        exe = 'dcm2niix';
                end
            end
            [~,wd] = mysystem(sprintf('which %s', exe));
            assert(~isempty(wd))            
            [~,wp] = mysystem('which pigz');
            if ~isempty(wp)
                z = 'y';
            else
                z = 'n';
            end            
            if opts.terse && isempty(opts.version)
                exe = sprintf('%s --terse', exe);
            end
            if opts.u
                exe = sprintf('%s -u', exe);
            end

            % call mysystem(), but keep .nii.gz in folder
            ensuredir(opts.o)
            [s,r] = mysystem( ...
                sprintf("%s -f %s -i %s -o %s -d %i -v %i -w %i -z %s %s", ...
                    exe, opts.f, opts.i, folder, opts.d, opts.v, opts.w, z, folder));
            
            % adjust filenames folder
            g = glob(convertStringsToChars(fullfile(folder, "**.nii.gz")));
            fn = convertCharsToStrings(g);
            fp = myfileprefix(fn);

            % jsonrecode using .mhdr & .v.hdr
            dcm_path = globFolders(convertStringsToChars(folder)); 
            hdr_path = myfileparts(dcm_path); 
            hdr_path = ensureCell(hdr_path);
            for fidx = 1:length(fp)
                try
                    mhdr_glob = glob(convertStringsToChars(fullfile(hdr_path{fidx}, opts.toglob_mhdr))); assert(~isempty(mhdr_glob));
                    vhdr_glob = glob(convertStringsToChars(fullfile(hdr_path{fidx}, opts.toglob_vhdr))); assert(~isempty(vhdr_glob));
                    if isempty(mhdr_glob); continue; end
                    if isempty(vhdr_glob); continue; end
                    tags = mybasename(mhdr_glob);
                    tags = strrep(tags, '-', '_');
    
                    % gather exemplar .mhdr & .v.hdr to build json
                    try
                        mhdr = readlines(mhdr_glob{1});                    
                        vhdr = readlines(vhdr_glob{1});
                        st.(tags{1}) = struct("mhdr", mhdr, "vhdr", vhdr);
                    catch ME
                        handwarning(ME)
                    end
                    fqfn_json = convertStringsToChars(fp(fidx)+".json");
                    jsonrecode(fqfn_json, st, filenameNew=fqfn_json);
    
                    % move .nii.gz and .json from folder to opts.o
                    if ~strcmp(myfileparts(fp(fidx)), opts.o)
                        try
                            movefile(fp(fidx)+".*", opts.o);
                        catch ME
                            handwarning(ME)
                        end
                    end
                catch ME
                    handwarning(ME)
                end
            end
        end
    end

    %% PRIVATE

    properties (Access = private)
        raw_lm_path_
        source_lm_path_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
