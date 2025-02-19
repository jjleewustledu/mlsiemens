classdef BrainMoCoBuilder < handle & mlsystem.IHandle
    %% >> bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=pwd)
    %  >> bmcb.build_all
    %  
    %  Created 29-Aug-2023 15:00:03 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        sessions
    end

    properties (Dependent)
        output_path % determined by Judd's BMC.js

        raw_dcm_path % initially unstructured, from external sources
        raw_lm_path % initially unstructured, from external sources
        raw_sub_path

        source_ses_paths
        source_sub_path
    end

    methods % GET
        function g = get.output_path(this)
            g = fullfile(this.source_sub_path, "+Output");
            ensuredir(g)
        end
        function g = get.raw_dcm_path(this)
            g = fullfile(this.raw_sub_path, "dcm");
        end
        function g = get.raw_lm_path(this)
            g = this.raw_lm_path_;
        end
        function g = get.raw_sub_path(this)
            g = myfileparts(this.raw_lm_path);
        end
        function g = get.source_ses_paths(this)
            g = fullfile(this.source_sub_path, this.sessions);
        end
        function g = get.source_sub_path(this)
            g = strrep(this.raw_sub_path, "rawdata", "sourcedata");
        end
    end

    methods
        function this = BrainMoCoBuilder(opts)
            %% opts.raw_lm_path specifies subject for building in properties raw_sub_path, source_sub_path

            arguments
                opts.raw_lm_path {mustBeFolder} = pwd
            end

            this.raw_lm_path_ = this.ensureEndsWithLm(opts.raw_lm_path);
            this.ensureEndsWithLm(opts.raw_lm_path);
            ensuredir(this.raw_lm_path);
            ensuredir(this.raw_dcm_path);            
            fprintf("%s:\nmanually inspect %s and\n%s for appropriate raw data.\n", stackstr(), this.raw_lm_path, this.raw_dcm_path)

            this.sessions = "";
        end
        
        
        function build_all(this)
            %% in rawdata, build dcm and lm folders containing first iteration of organization of files

            this.build_raw_dcm()
            this.build_raw_lm()
            
            map = this.build_map_of_lm();
            keys = map.keys;
            save("map.mat", "map");

            this.build_sourcedata_dcm();    
            for k = asrow(keys) % *LISTMODE* 
                this.build_sourcedata_lm(map(k{1}));
            end
        end

        function build_all_part2(this, opts)
            %% in sourcedata, build
            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.subjects {mustBeText} = ...
                    ["sub-108007", "sub-108238", "sub-108287", "sub-108300", "sub-108306"]
                opts.nproc double = mlsiemens.BrainMoCo2.N_PROC
            end

            if isempty(gcp('nocreate'))
                parpool(opts.nproc)
            end

            % fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co"), ...
            % fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "lm-ho"), ...
            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm-fdg")];
            tracers = ["oo", "fdg"]; % "co", "ho", 
            % 10*ones(1,29), ...
            % 10*ones(1,11), ...
            taus = { ...
                10*ones(1,11), ...                
                10*ones(1,359)};
            for ti = 1:2
                tic
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    paths(ti), tracer=tracers(ti), taus=taus{ti});
                toc
            end

            % %     build_all BMC    
            % bmc = mlsiemens.BrainMoCo2(source_lm_path=this.source_lm_path);
            % switch something
            %     case "fdg_phantom"
            %         bmc.build_fdg_phantom() % phantom
            %     case "co"
            %         bmc.build_co()
            %     case "oo"
            %         bmc.build_oo()
            %     case "ho"                
            %         bmc.build_ho()
            %     case "fdg"
            %         bmc.build_fdg()
            % end
            % 
            % %     apply dcm2niix
            % 
            % this.build_niftis(map(k{1}));
            % 
            % %     reorganize output folders
            % 
            % this.build_output_folders(map(k{1}));            
        end

        function build_sourcedata_dcm(this)
            pwd0 = pushd(this.raw_dcm_path);

            % ensure session folders
            ensuredir(this.source_sub_path);
            dts = this.find_dcm_dates();
            for dtidx = 1:length(dts)
                this.sessions(dtidx) = sprintf("ses-%s", string(datetime(dts(dtidx), Format="yyyyMMdd")));
                ensuredir(fullfile(this.source_sub_path, this.sessions(dtidx) ));
            end

            % populate anat
            for ses = asrow(this.sessions)
                src_anat_pth = fullfile(this.source_sub_path, ses, "anat");
                g = mglob([ ...
                    "sub-*_"+ses+"*ocalizer*.*", ...
                    "sub-*_"+ses+"*FastIR*.*", ...
                    "sub-*_"+ses+"*FLAIR*.*", ...
                    "sub-*_"+ses+"*quick_tof*.*", ...                    
                    "sub-*_"+ses+"*sag_loc*.*", ...                  
                    "sub-*_"+ses+"*tof*.*", ...                
                    "sub-*_"+ses+"*_T1-*.*", ...                
                    "sub-*_"+ses+"*_T1w*vNav*.*", ...              
                    "sub-*_"+ses+"*_T2w*vNav*.*"]);
                if ~isemptytext(g)
                    ensuredir(src_anat_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, src_anat_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            % populate dwi
            for ses = asrow(this.sessions)
                src_dwi_pth = fullfile(this.source_sub_path, ses, "dwi");
                g = mglob([ ...
                    "sub-*_"+ses+"*DTI*.*", ...
                    "sub-*_"+ses+"*DBSI*.*"]);
                if ~isemptytext(g)
                    ensuredir(src_dwi_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, src_dwi_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            % populate fmap
            for ses = asrow(this.sessions)
                src_fmap_pth = fullfile(this.source_sub_path, ses, "fmap");
                g = mglob("sub-*_"+ses+"*FieldMap*.*");
                if ~isemptytext(g)
                    ensuredir(src_fmap_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, src_fmap_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            % populate func
            for ses = asrow(this.sessions)
                src_func_pth = fullfile(this.source_sub_path, ses, "func");
                g = mglob([ ...
                    "sub-*_"+ses+"*ASE*.*", ...
                    "sub-*_"+ses+"*ase*.*", ...
                    "sub-*_"+ses+"*DistortionMap*.*", ...
                    "sub-*_"+ses+"*CBF*.*", ...  
                    "sub-*_"+ses+"*fMRI_REST*.*", ...        
                    "sub-*_"+ses+"*M0*.*", ...       
                    "sub-*_"+ses+"*MoCoSeries*.*", ...      
                    "sub-*_"+ses+"*PC2D*.*", ...         
                    "sub-*_"+ses+"*PCASL*.*", ...        
                    "sub-*_"+ses+"*pcasl*.*", ...           
                    "sub-*_"+ses+"*QSM*.*", ...               
                    "sub-*_"+ses+"*Perfusion_Weighted*.*", ...              
                    "sub-*_"+ses+"*TRUST*.*"]);
                if ~isemptytext(g)
                    ensuredir(src_func_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, src_func_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            % populate pet
            for ses = asrow(this.sessions)
                src_pet_pth = fullfile(this.source_sub_path, ses, "pet");
                g = mglob([ ...
                    "sub-*_"+ses+"*arbon*.*", ...
                    "sub-*_"+ses+"*kvp*ct*.*", ...
                    "sub-*_"+ses+"*CT_Brain*.*", ...
                    "sub-*_"+ses+"*trc-co*.*", ...
                    "sub-*_"+ses+"*trc-oc*.*", ...
                    "sub-*_"+ses+"*trc-oo*.*", ...
                    "sub-*_"+ses+"*trc-ho*.*", ...
                    "sub-*_"+ses+"*trc-fdg*.*", ...
                    "sub-*_"+ses+"*CO*.*", ...
                    "sub-*_"+ses+"*oxide*.*", ...   
                    "sub-*_"+ses+"*Oxygen*.*", ...
                    "sub-*_"+ses+"*FDG*.*", ...      
                    "sub-*_"+ses+"*tatic*.*", ...                 
                    "sub-*_"+ses+"*Topogram*.*", ...                      
                    "sub-*_"+ses+"*Water*.*", ...       
                    "sub-*_"+ses+"*yn*.*", ...             
                    "sub-*_"+ses+"*Phantom*.*"]);
                if ~isemptytext(g)
                    ensuredir(src_pet_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, src_pet_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            popd(pwd0)
        end

        function build_sourcedata_lm(this, s)
            %% links sourcedata to rawdata; use rsync -raL to rsync listmode to Windows/e7
            
            pwd0 = pushd(this.raw_lm_path);
            lm_path = fullfile(this.source_sub_path, "ses-"+string(s.datetimestr), "lm");
            ensuredir(lm_path);
            copyfile(s.ct, fullfile(lm_path, "CT"));
            copyfile(s.norm, lm_path);
            try
                movefile(s.ptd, lm_path);
            catch ME
                handexcept(ME);
            end
            popd(pwd0);
        end

        function m = build_map_of_lm(this)
            %% m(fileprefix) := struct with
            %  fields from this.siemns_get_meta() ~ struct
            %  ptd ~ /home/usr/jjlee/Singularity/CCIR_01211/rawdata/sub-108007/lm/108007.PT.Head_CCIR_1211_FDG_(Adult).602.PET_LISTMODE.2021.02.23.14.04.04.508000.2.0.105550091.ptd
            %  datetime
            %  datetimestr ~ yyyyMMddHHmmss
            %  ct from this.find_ct ~ folder
            %  norm from this.find_norm ~ file.ptd

            pwd0 = pushd(this.raw_lm_path);
            m = containers.Map;

            g = mglob(fullfile(this.raw_lm_path, "**", "*LISTMODE*.ptd"));
            for gidx = 1:length(g)
                fp = mybasename(g(gidx));
                s = this.siemens_get_meta(g(gidx));

                s.ptd = g{gidx};
                s.tracer = this.siemens_get_tracer(s.ptd);
                s.datetime = datetime(s.acquisition.timestamp, ...
                    InputFormat='yyyy-MM-dd''T''HH:mm:ss.SSSXXXXXX', TimeZone=s.acquisition.timezone);
                s.datetimestr = datetime(s.datetime, Format='yyyyMMddHHmmss');
                s.ct = this.find_ct(dt=s.datetimestr);
                s.norm = this.find_norm(dt=s.datetimestr);
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
            source_lm_path__ = strrep(this.raw_lm_path, "raw", "source");
            sesdt8 = "ses-" + string(datetime(s.dt, Format="yyyyMMdd"));
            sesdt14 = "ses-" + string(datetime(s.dt, Format="yyyyMMddHHmmss"));
            source_lm_path__ = strrep(source_lm_path__, sesdt8, sesdt14);

            % def. source_ses_path, source_pet_path := source_lm_path
            source_ses_path_ = myfileparts(source_lm_path__);
            source_pet_path_ = strrep(source_lm_path__, "lm", "pet");

            pwd0 = pushd(source_pet_path_);
            if opts.is_dyn
                dyn_dcm_path = fullfile(source_ses_path_, "lm"+opts.tag+"-DynamicBMC", "lm-BMC-LM-00-dynamic-DICOM");
                mlsiemens.BrainMoCoBuilder.dcm2niix(dyn_dcm_path, f="sub-%n_ses-%t_trc-"+opts.tracer+"_proc-bmc-lm-00-dyn"+opts.tag+"_pet", w=1); % clobber
                rmdir(myfileparts(dyn_dcm_path), "s")
            else
                static_dcm_path = fullfile(source_ses_path_, "lm"+opts.tag+"-StaticBMC", "lm-BMC-LM-00-ac_mc_000_000.v-DICOM");
                mlsiemens.BrainMoCoBuilder.dcm2niix(static_dcm_path, f="sub-%n_ses-%t_trc-"+opts.tracer+"_proc-bmc-lm-00-static_pet", w=1); % clobber
                rmdir(myfileparts(static_dcm_path), "s")
            end
            popd(pwd0);
        end              
        function build_raw_dcm(this)
            pwd0 = pushd(this.raw_dcm_path);
            [~,r] = this.dcm2niix();
            disp(r)
            popd(pwd0);
        end
        function build_raw_lm(this)
            pwd0 = pushd(this.raw_lm_path);
            g = mglob(fullfile("**", "*.ptd"));
            for gi = 1:length(g)
                try
                    movefile(g(gi), this.raw_lm_path);
                catch ME
                    handwarning(ME)
                end
            end
            popd(pwd0)
        end
        
        function [s,r] = copyfile(~, file_obj, dest_pth)
            [~,fp,x] = myfileparts(file_obj);
            dest_obj = fullfile(dest_pth, strcat(fp, x));
            if ~isfile(dest_obj)
                return
            end
            [s,r] = copyfile(file_obj, dest_pth);
        end
        function folder = find_ct(this, opts)
            %% returns folder with ct dicoms.

            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.dt datetime = NaT % datetimes of listmode to match
                opts.ct_series double = 3
            end

            pwd0 = pushd(this.raw_dcm_path);
            
            % glob CTs
            g = glob(fullfile(this.raw_dcm_path, '*_CT_*.nii.gz')); 
            g = g(~contains(g, '_AC_CT_'));
            assert(~isemptytext(g))
            for gidx = 1:length(g)
                % find CT datetimes, series
                re = regexp(mybasename(g{gidx}), "\S+_ses-(?<dt>\d{14})_\S+-(?<series>\d+)", "names");
                ct_dt(gidx) = datetime(re.dt, Format="yyyyMMddHHmmss", TimeZone="local"); %#ok<AGROW>
                series(gidx) = str2double(re.series); %#ok<AGROW>
            end

            % find CT acquired just before listmode
            T = table(ascol(g), minutes(ascol(opts.dt) - ascol(ct_dt)), ascol(series), variableNames={'fqfn', 'dur', 'series'});
            T = sortrows(T, 'dur');
            T = T(minutes(T.dur) >= 0, :);
            nii_fqfn = T.fqfn{1};
            j_fqfn = strrep(nii_fqfn, ".nii.gz", ".json");
            j = readstruct(j_fqfn);
            folder = j.dicom_folder;

            popd(pwd0);
        end
        function dts = find_dcm_dates(this)
            %% unique session dates in this.raw_dcm_path

            pwd0 = pushd(this.raw_dcm_path);
            g = mglob("sub-*_ses-*_*.nii.gz");
            dts = NaT(size(g));
            for idx = 1:length(g)
                re = regexp(g(idx), "sub-\S+_ses-(?<dt>\d{8})\d*\S+.nii.gz", "names");
                dts(idx) = datetime(re.dt, InputFormat="yyyyMMdd");
            end
            dts = unique(dts);
            popd(pwd0);
        end
        function fqfn = find_norm(this, opts)
            %% returns fqfn of calibration ptd.

            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.dt datetime = NaT % datetimes of listmode to match
            end

            pwd0 = pushd(this.raw_lm_path);
            
            % glob CTs
            g = glob(fullfile(this.raw_lm_path, '*CALIBRATION*')); 
            for gidx = 1:length(g)
                % find norm datetimes
                norm_dt(gidx) = this.siemens_meta_to_datetime(g{gidx}); %#ok<AGROW>
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
            %      a : adjacent DICOMs (images from same series always in same folder) for faster conversion (n/y, default n)
            %      ba : anonymize BIDS (y/n, default y)
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
            %      version (numeric):  [] | 20180622 | 20180627 | 20230411
            %      w : write behavior for name conflicts (0,1,2, default 2: 0=skip duplicates, 1=overwrite, 2=add suffix)
            %      z : gz compress images (y/o/i/n/3, default n) [y=pigz, o=optimal pigz, i=internal:zlib, n=no, 3=no,3D]
            %
            %  Returns:
            %      s : mysystem status
            %      r : mysystem command output
            %      fn : list of files nii.gz

            arguments
                folder {mustBeFolder} = pwd % for recursive searching
                opts.a {mustBeTextScalar} = "y"
                opts.ba {mustBeTextScalar} =  "n"
                opts.d {mustBeInteger} = 7
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
            tempfolder = fullfile(folder, "temp");
            
            % select executable dcm2niix & pigz
            switch computer
                case {'MACI64', 'MACA64'}
                    exe = 'dcm2niix';
                    if ~isempty(opts.version)
                        exe = sprintf('dcm2niix_%i', opts.version);
                    end
                case 'GLNXA64'
                    exe  = 'dcm2niix_20230411';
                    if ~isempty(opts.version)
                        exe = sprintf('dcm2niix_%i', opts.version);
                    end
                case 'PCWIN64'
                    exe = 'dcm2niix.exe';
                    if ~isempty(opts.version)
                        exe = sprintf('dcm2niix_%i.exe', opts.version);
                    end
                otherwise
                    exe = 'dcm2niix';
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

            % call mysystem(), depositing .nii.gz in folder
            ensuredir(opts.o)
            ensuredir(tempfolder);
            folders = find_dcm_folders(folder);
            Nfolds = length(folders);
            s = zeros(1, Nfolds);
            r = cell(1, Nfolds);
            for fidx = 1:Nfolds
                [s(fidx),r{fidx}] = mysystem( ...
                    sprintf("%s -a %s -ba %s -f %s -i %s -o %s -d %i -v %i -w %i -z %s %s", ...
                    exe, opts.a, opts.ba, opts.f, opts.i, tempfolder, opts.d, opts.v, opts.w, z, folders{fidx}));
                g = glob(fullfile(tempfolder, '*.nii.gz'));
                if ~isempty(g)
                    j = append_json(g, folders{fidx});
                    cellfun(@(x) movefile(x, folder), g, UniformOutput=false);
                    cellfun(@(x) movefile(x, folder), j, UniformOutput=false);
                end
            end
            
            % adjust filenames folder
            g = glob(convertStringsToChars(fullfile(folder, "*.nii.gz")));
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
                    if isemptytext(mhdr_glob); continue; end
                    if isemptytexxt(vhdr_glob); continue; end

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
                    %handwarning(ME)
                end
            end

            function j = append_json(niigz, dcmfold)
                %% for json correponding to niigz, add field dicom_folder for the source of niigz

                for nidx = 1:length(niigz)
                    j{nidx} = strrep(niigz{nidx}, ".nii.gz", ".json");
                    if isfile(j{nidx})
                        s_ = readstruct(j{nidx});
                        s_.dicom_folder = dcmfold;
                        writestruct(s_, j{nidx});
                    end
                end
            end
            function folds = find_dcm_folders(fold0)
                %% find all unique folders contain dicoms within fold0

                dcms = glob(fullfile(fold0, '**', '*.dcm'));
                dcms = cellfun(@fileparts, dcms, UniformOutput=false);
                folds = unique(dcms);
            end
        end
        function s = siemens_get_meta(ptd)
            %% ptd file -> struct  
            % s = mlsiemens.BrainMoCoBuilder.siemens_get_meta("108293.PT.Head_CCIR_1211_TriplePack_(Adult).602.PET_LISTMODE.2021.04.23.11.59.28.876000.2.0.15804242.ptd")
            %   struct with fields:
            %         subject: [1×1 struct]
            %         session: [1×1 struct]
            %     acquisition: [1×1 struct]
            %            file: [1×1 struct]
            % s.subject
            %   struct with fields:
            %        label: '108293_MAG_20210421'
            %     lastname: '108293'
            %          sex: 'male'
            % s.session
            %   struct with fields:
            %           uid: '1.3.12.2.1107.5.1.4.11009.30000021042114261176500000007'
            %         label: 'Head^CCIR_1211_TriplePack (Adult)'
            %           age: 1.325419200000000e+09
            %        weight: 83.914599124500000
            %     timestamp: '2021-04-21T13:45:36.900-05:00'
            %      timezone: 'America/Chicago'
            % s.acquisition
            %   struct with fields:
            %           uid: '1.3.12.2.1107.5.1.4.11009.30000021042114373330500000054'
            %         label: '602 - PET Raw Data'
            %     timestamp: '2021-04-21T15:57:09.395-05:00'
            %      timezone: 'America/Chicago'
            % s.file
            %   struct with fields:
            %     name: '1.3.12.2.1107.5.1.4.11009.30000021042114373330500000068.PT.ptd'
            %     type: 'ptd'

            arguments
                ptd {mustBeFile}
            end

            meta = py.fw_file.siemens.PTDFile(ptd).get_meta();
            dumps = py.json.dumps(meta.dict);
            s = jsondecode(string(dumps));            
        end
        function m = siemens_get_dicom_map(ptd)
            %% N.B.: m("DerivationDescription")
            %   struct with fields:
            %                      VM: [1×1 py.int]
            %             empty_value: [1×0 py.str]
            %                is_empty: 0
            %              is_private: 0
            %              is_retired: 0
            %                 keyword: [1×21 py.str]
            %                    name: [1×22 py.str]
            %                  repval: [1×17 py.str]
            %                   value: "PETCT-FDG Brain"
            %                      VR: [1×2 py.str]
            %                     tag: [1×1 py.pydicom.tag.BaseTag]
            %                  parent: [1×1 py.NoneType]
            %         validation_mode: [1×1 py.int]
            %               file_tell: [1×1 py.int]
            %     is_undefined_length: 0
            %         private_creator: [1×1 py.NoneType]            

            arguments
                ptd {mustBeFile}
            end

            warning('off', 'MATLAB:structOnObject')
            siemens = py.fw_file.siemens.PTDFile(ptd);
            l = py.list(py.iter(siemens));
            m = containers.Map;
            for idx = 1:length(l)
                try
                    s = struct(l{idx});
                    if isa(s.value, "py.str")
                        s.value = string(s.value);
                    end
                    m(string(l{idx}.keyword)) = s;
                catch %#ok<CTCH>
                end
            end
        end
        function trc = siemens_get_tracer(ptd, opts)
            arguments
                ptd {mustBeFile}
                opts.do_lower logical = false
            end

            m = mlsiemens.BrainMoCoBuilder.siemens_get_dicom_map(ptd);
            v = m("DerivationDescription").value;
            
            if contains(v, "CO", IgnoreCase=true)
                trc = "CO";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            if contains(v, "Oxygen", IgnoreCase=true)
                trc = "OO";
                if opts.do_lower; trc = lower(trc); end
                return
            end            
            if contains(v, "Water", IgnoreCase=true)
                trc = "HO";
                if opts.do_lower; trc = lower(trc); end
                return
            end            
            if contains(v, "FDG", IgnoreCase=true)
                trc = "FDG";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            if contains(v, "RO", IgnoreCase=true) && contains(v, "948")
                trc = "RO948";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            if contains(v, "MK", IgnoreCase=true) && contains(v, "6240")
                trc = "MK6240";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            if contains(v, "ASEM", IgnoreCase=true)
                trc = "ASEM";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            if contains(v, "AZAN", IgnoreCase=true)
                trc = "AZAN";
                if opts.do_lower; trc = lower(trc); end
                return
            end
            trc = "Unknown";
            if opts.do_lower; trc = lower(trc); end
        end
        function [dt,dtstr] = siemens_meta_to_datetime(ptd)
            %% returns datetime, datetime string

            s = mlsiemens.BrainMoCoBuilder.siemens_get_meta(ptd);
            dt = datetime(s.session.timestamp, ...
                InputFormat='yyyy-MM-dd''T''HH:mm:ss.SSSXXXXXX', TimeZone=s.session.timezone);
            dtstr = datetime(dt, Format='yyyyMMddHHmmss');
        end
    end

    %% PRIVATE

    properties (Access = private)
        raw_lm_path_
        source_lm_path_
    end

    methods (Access = private)
        function pth = ensureEndsWithLm(~, pth) 
            if endsWith(pth, "dcm")
                pth = myfileparts(pth);
            end
            if ~endsWith(pth, "lm")
                pth = fullfile(pth, "lm");
            end
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
