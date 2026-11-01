classdef BrainMoCoBuilder < handle & mlsystem.IHandle
    %% Build sourcedata for e7, JSRecon12, and BMC. 
    %  Run on machine equipped with dcm2niix and conda env supporting py.fw_file.siemens.PTDFile.
    %
    %  >> bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=pwd)
    %  >> bmcb.construct_bmcbuilder
    %  
    %  Created 29-Aug-2023 15:00:03 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        ct_series double = []  % if nonempty, find_ct() accepts only these CT series numbers
        lm_pattern {mustBeTextScalar} = "*LISTMODE*.ptd"  % build_map_of_lm() glob, relative to raw_lm_path
        lm_select {mustBeMember(lm_select, ["all", "last"])} = "all"  % "last" keeps only the latest listmode
        sessions
    end

    properties (Dependent)
        output_path % determined by Judd's BMC.js

        raw_dcm_mri_path
        raw_dcm_pet_path
        raw_dcm_path % initially unstructured, from external sources
        raw_lm_path % initially unstructured, from external sources
        raw_sub_path

        source_ses_paths
        source_sub_path

        sourcedata
        sub
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
        function g = get.raw_dcm_mri_path(this)
            g = fullfile(this.raw_sub_path, "dcm", "mri");
        end
        function g = get.raw_dcm_pet_path(this)
            g = fullfile(this.raw_sub_path, "dcm", "pet");
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
        function g = get.sourcedata(~)
            % target for staged sourcedata; consistent with mlsiemens.BrainMoCo2 usage.
            % CHPC retired 2026; set SINGULARITY_HOME (e.g. /vgpool02/data2/jjlee/Singularity)
            % and PROJECT_FOLDER (e.g. CCIR_01211) in the launching environment.
            g = fullfile(getenv("SINGULARITY_HOME"), getenv("PROJECT_FOLDER"), "sourcedata");
            assert(~isemptytext(getenv("SINGULARITY_HOME")) && ~isemptytext(getenv("PROJECT_FOLDER")), ...
                "mlsiemens:ConfigurationError", ...
                "BrainMoCoBuilder.sourcedata requires SINGULARITY_HOME and PROJECT_FOLDER")
            if ~isfolder(g); ensuredir(g); end
        end
        function g = get.sub(this)
            g = mybasename(fileparts(this.raw_lm_path));
        end
    end

    methods
        function this = BrainMoCoBuilder(opts)
            %% opts.raw_lm_path specifies subject for building in properties raw_sub_path, source_sub_path

            arguments
                opts.raw_lm_path {mustBeTextScalar} = ""
                opts.ct_series double = []
                opts.lm_pattern {mustBeTextScalar} = "*LISTMODE*.ptd"
                opts.lm_select {mustBeTextScalar} = "all"
            end

            this.ct_series = opts.ct_series;
            this.lm_pattern = opts.lm_pattern;
            this.lm_select = opts.lm_select;
            if ~isemptytext(opts.raw_lm_path)
                this.raw_lm_path_ = this.ensureEndsWithLm(opts.raw_lm_path);
                ensuredir(this.raw_lm_path);
                ensuredir(this.raw_dcm_path);
            end

            this.sessions = "";

             warning("off", "mfiles:ChildProcessWarning");
        end
        
        
        function build_rawdata(this, opts)
            %% in rawdata, build dcm and lm folders containing first iteration of organization of files
            %  move files needed for e7 to this.sourcedata
            %  copy this.sourcedata/sub-* to Windows machine with e7

            %
            %  opts.series_pet:  DICOM series to convert; "" converts all.
            %  opts.dcm_sessions:  "date" files niftis under ses-yyyyMMdd (build_sourcedata_dcm_2);
            %      "listmode" files them under the ses-yyyyMMddHHmmss of their listmode
            %      (build_sourcedata_dcm_by_lm), so separate scans on one day never share a folder.
            %  opts.do_symlink:  stage listmode, norm and CT in sourcedata as symlinks, not copies;
            %      transfer to e7 with rsync -aL.

            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.do_pet logical = true
                opts.do_mri logical = true
                opts.series_pet {mustBeText} = ""
                opts.dcm_sessions {mustBeMember(opts.dcm_sessions, ["date", "listmode"])} = "date"
                opts.do_symlink logical = false
            end

            this.build_raw_dcm(do_pet=opts.do_pet, do_mri=opts.do_mri, series_pet=opts.series_pet)
            this.build_raw_lm()

            map = this.build_map_of_lm();
            keys = map.keys;
            save(fullfile(this.raw_lm_path, "map.mat"), "map");

            switch opts.dcm_sessions
                case "date"
                    this.build_sourcedata_dcm_2();
                case "listmode"
                    this.build_sourcedata_dcm_by_lm(map);
            end
            for k = asrow(keys) % *LISTMODE*
                this.build_sourcedata_lm(map(k{1}), do_symlink=opts.do_symlink);
            end
        end

        function build_t1ws_parcs(this)
            %% ad hoc for Nick Metcalf's pipeline ca. 20250814

            % init info
            derivsdir = "~/mnt/CHPC_scratch/Singularity/CCIR_01211/derivatives";
            %parcel_path = "PARCEL_PATH";  % Jeremy's DTI
            %schaef_fold = "Jeremy_DTI+Schaeffer";
            %parc_fp = "Jeremy_DTI+Schaeffer";
            %ld = load("~/mnt/CHPC_scratch/Singularity/CCIR_01211/JeremyDTI+Schaeffer_info.mat");
            %T = ld.jeremy_dti_schaeffer_info;  % 47 x 4
            parcel_path = "PARCEL_PATH_0";  % wmparc
            schaef_fold = "Schaefer2018_200Parcels_7Networks_order";
            parc_fp = "Schaefer2018_200Parcels_7Networks_order_T1";
            ld = load("~/mnt/CHPC_scratch/Singularity/CCIR_01211/info_20250905234200.mat");
            T = ld.load;
            T = T(end-12:end, :);  % 13 x 5
            subs = asrow("sub-" + extractBefore(string(T.MRI_ID), "_"));
            sess = asrow("ses-" + this.extract_trailing_dates(T.MRI_ID));
            assert(length(subs) == length(sess));
            
            for sidx = 1:length(subs)
                
                % copy parc and parc-aligned T1 to derivatives/sub-*/ses-*/Parcellations
                parcdir = fullfile(derivsdir, subs(sidx), sess(sidx), "Parcellations");
                ensuredir(parcdir);
                copyfile(myfileparts(T.(parcel_path){sidx}), parcdir);
                schaef_dir = fullfile(parcdir, schaef_fold);
                copyfile(T.T1_PATH{sidx}, schaef_dir);

                % ensure T1w_MPR_vNAV_*_orient-std
                subdir = fullfile(derivsdir, subs(sidx));
                subdir0 = strrep(subdir, "derivatives", "sourcedata");
                sesdir = fullfile(subdir, sess(sidx));
                t1w_orient_std = mglob(fullfile(subdir, "ses-*", "anat", "sub-*_ses-*_T1w_MPR_vNav_4e_RMS*_orient-std.nii.gz"));
                if isempty(t1w_orient_std)
                    t1w = mglob(fullfile(subdir0, "ses-*", "anat", "sub-*_ses-*_T1w_MPR_vNav_4e_RMS*.nii.gz"));
                    assert(~isempty(t1w))
                    t1w_ic = mlfourd.ImagingContext2(t1w(end));
                    t1w_ic = t1w_ic.afni_3dresample(orient_std=true);
                    t1w_ic.filepath = fullfile(sesdir, "anat");
                    t1w_ic.save();
                end
                t1w_orient_std = mglob(fullfile(subdir, "ses-*", "anat", "sub-*_ses-*_T1w_MPR_vNav_4e_RMS*_orient-std.nii.gz"));
                assert(~isempty(t1w_orient_std))
                t1w_orient_std = t1w_orient_std(end);

                % register parc to T1w_MPR_vNAV_*_orient-std (orient-rpi)
                pwd0 = pushd(schaef_dir);
                t1_on_t1w = fullfile(schaef_dir, "T1_on_T1w.nii.gz");
                flirt = mlfsl.Flirt( ...
                    'in', mybasename(T.T1_PATH{sidx}, withext=true, withpath=false), ...
                    'ref', t1w_orient_std, ...
                    'out', t1_on_t1w, ...
                    'bins', 1024, ...
                    'cost', 'corratio', ...
                    'dof', 6, ...
                    'interp', 'spline', ...
                    'noclobber', false);
                flirt.flirt();
                assert(isfile(t1_on_t1w))
                parc = fullfile(schaef_dir, parc_fp + ".nii.gz");
                parc_out = fullfile(schaef_dir, parc_fp + "_on_T1w.nii.gz");
                flirt.in = parc;
                flirt.out = parc_out;
                flirt.ref = t1w_orient_std;
                flirt.interp = "nearestneighbour";
                flirt.applyXfm();
                assert(isfile(parc_out))
                popd(pwd0);
            end
        end

        function build_bmc_nmaf(this, opts)
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
            %% original logic for building sourcedata/sub-*/ses-*

            pwd0 = pushd(this.raw_dcm_path);

            % ensure session folders
            ensuredir(this.source_sub_path);
            dts = this.find_dcm_dates();
            for dtidx = 1:length(dts)
                this.sessions(dtidx) = sprintf("ses-%s", string(datetime(dts(dtidx), Format="yyyyMMdd")));
                ensuredir(fullfile(this.source_sub_path, this.sessions(dtidx) ));
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

            popd(pwd0)
            return

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

        end

        function build_sourcedata_dcm_2(this)
            %% logic for building sourcedata/sub-*/ses-*/{pet,anat} for schemas of 20250814

            pwd0 = pushd(this.raw_dcm_pet_path);

            % ensure sourcedata/sub-*/ses-* folders
            ensuredir(fullfile(this.sourcedata, this.sub));
            dts = this.find_dcm_dates();
            for dtidx = 1:length(dts)
                sessions_(dtidx) = sprintf("ses-%s", string(datetime(dts(dtidx), Format="yyyyMMdd"))); %#ok<AGROW>
                ensuredir(fullfile(this.sourcedata, this.sub, sessions_(dtidx)));
            end

            % populate pet
            for ses = asrow(sessions_)
                sourcedata_pet_pth = fullfile(this.sourcedata, this.sub, ses, "pet");
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
                    "sub-*_"+ses+"*Phantom*.*", ...                    
                    "sub-*_"+ses+"*AC*.*", ...   
                    "sub-*_"+ses+"*NAC*.*"]);
                if ~isemptytext(g)
                    ensuredir(sourcedata_pet_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, sourcedata_pet_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            popd(pwd0)

            if ~isfolder(this.raw_dcm_mri_path)
                return
            end

            pwd0 = pushd(this.raw_dcm_mri_path);

            % ensure sourcedata/sub-*/ses-* folders
            ensuredir(fullfile(this.sourcedata, this.sub));
            dts = this.find_dcm_dates();
            for dtidx = 1:length(dts)
                sessions_(dtidx) = sprintf("ses-%s", string(datetime(dts(dtidx), Format="yyyyMMdd")));
                ensuredir(fullfile(this.sourcedata, this.sub, sessions_(dtidx)));
            end

            % populate anat
            for ses = asrow(sessions_)
                sourcedata_anat_pth = fullfile(this.sourcedata, this.sub, ses, "anat");
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
                    ensuredir(sourcedata_anat_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, sourcedata_anat_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            popd(pwd0)
        end

        function build_sourcedata_dcm_3(this)
            %% logic for building sourcedata/sub-*/ses-*/anat for schemas of 20250814

            pwd0 = pushd(this.raw_dcm_mri_path);

            % ensure sourcedata/sub-*/ses-* folders
            ensuredir(fullfile(this.sourcedata, this.sub));
            dts = this.find_dcm_dates();
            for dtidx = 1:length(dts)
                sessions_(dtidx) = sprintf("ses-%s", string(datetime(dts(dtidx), Format="yyyyMMdd"))); %#ok<AGROW>
                ensuredir(fullfile(this.sourcedata, this.sub, sessions_(dtidx)));
            end

            % populate anat
            for ses = asrow(sessions_)
                sourcedata_anat_pth = fullfile(this.sourcedata, this.sub, ses, "anat");
                g = mglob([ ...
                    "sub-*_"+ses+"*FLAIR*.*", ...        
                    "sub-*_"+ses+"*tof*.*", ...                
                    "sub-*_"+ses+"*_T1-*.*", ...                
                    "sub-*_"+ses+"*_T1w*vNav*.*", ...              
                    "sub-*_"+ses+"*_T2w*vNav*.*"]);
                if ~isemptytext(g)
                    ensuredir(sourcedata_anat_pth);
                    for g1 = asrow(g)
                        try
                            movefile(g1, sourcedata_anat_pth);
                        catch %#ok<CTCH>
                        end
                    end
                end
            end

            popd(pwd0)
        end

        function build_sourcedata_dcm_by_lm(this, map, opts)
            %% copies niftis in raw_dcm_pet_path into sourcedata/sub-*/ses-<yyyyMMddHHmmss>/pet,
            %  where ses-<yyyyMMddHHmmss> names the listmode each nifti belongs to.  Unlike
            %  build_sourcedata_dcm_2(), separate scans on one day (e.g., a subject's scans followed by
            %  a calibration phantom) never share, nor overwrite, a ses-<yyyyMMdd> folder.
            %
            %  Assignment by json Modality and AcquisitionTime, within opts.slack:
            %      CT:  the earliest listmode starting at or after the CT, i.e., the scan it attenuates;
            %      PT:  the latest listmode starting at or before the reconstruction, whose frames may
            %           begin minutes into the listmode (e.g., 17:13:25 static of a 17:08:22 listmode).
            %  Niftis lacking Modality or AcquisitionTime, or without a qualifying listmode, are
            %  reported and skipped.

            arguments
                this mlsiemens.BrainMoCoBuilder
                map containers.Map
                opts.slack duration = seconds(60)
            end
            if map.Count == 0
                error("mlsiemens:ValueError", "%s: map of listmode is empty", stackstr())
            end

            % listmode datetimes, ascending
            vals = map.values;
            lm_dt = NaT(1, numel(vals), TimeZone=vals{1}.datetime.TimeZone);
            lm_ses = strings(1, numel(vals));
            for vi = 1:numel(vals)
                lm_dt(vi) = vals{vi}.datetime;
                lm_ses(vi) = "ses-" + string(vals{vi}.datetimestr);
            end
            [lm_dt, order] = sort(lm_dt);
            lm_ses = lm_ses(order);

            niis = mglob(fullfile(this.raw_dcm_pet_path, "*.nii.gz"));
            for nii = asrow(niis)
                fp = extractBefore(nii, ".nii.gz");
                [acq_dt, modality] = this.nifti_acquisition_datetime(fp, lm_dt(1).TimeZone);
                if isnat(acq_dt) || isemptytext(modality)
                    fprintf(2, "%s: skipping %s, which lacks AcquisitionTime or Modality\n", ...
                        stackstr(), mybasename(fp));
                    continue
                end
                switch upper(modality)
                    case "CT"
                        idx = find(lm_dt >= acq_dt - opts.slack, 1, "first");
                    case "PT"
                        idx = find(lm_dt <= acq_dt + opts.slack, 1, "last");
                    otherwise
                        idx = [];
                end
                if isempty(idx)
                    fprintf(2, "%s: skipping %s (%s at %s), which matches no listmode\n", ...
                        stackstr(), mybasename(fp), modality, string(acq_dt));
                    continue
                end
                dest = fullfile(this.sourcedata, this.sub, lm_ses(idx), "pet");
                ensuredir(dest);
                copyfile(fp + ".*", dest);
                fprintf("%s: %s -> %s\n", stackstr(), mybasename(fp), dest);
            end
        end

        function build_sourcedata_lm(this, s, opts)
            %% migrates to sourcedata; use rsync -aL to rsync listmode to Windows/e7
            %  opts.do_symlink:  symlink CT folder, norm and listmode rather than copying them.

            arguments
                this mlsiemens.BrainMoCoBuilder
                s struct
                opts.do_symlink logical = false
            end

            lm_path = fullfile(this.sourcedata, this.sub, "ses-"+string(s.datetimestr), "lm");
            if opts.do_symlink
                % one shell call; single quotes because export paths contain spaces and parens
                [st, r] = mysystem(sprintf( ...
                    "mkdir -p '%s' && ln -sfn '%s' '%s/CT' && ln -sf '%s' '%s/' && ln -sf '%s' '%s/'", ...
                    lm_path, s.ct, lm_path, s.norm, lm_path, s.ptd, lm_path));
                if st ~= 0
                    error("mlsiemens:StagingError", "%s: ln staging rc=%d: %s", stackstr(), st, r);
                end
                return
            end

            pwd0 = pushd(this.raw_lm_path);
            ensuredir(lm_path);
            copyfile(s.ct, fullfile(lm_path, "CT"));
            copyfile(s.norm, lm_path);
            try
                copyfile(s.ptd, lm_path);
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

            %  this.lm_pattern selects listmode by filename; this.lm_select == "last" then keeps only
            %  the latest acquisition, e.g., a phantom scanned after a subject on the same day.

            pwd0 = pushd(this.raw_lm_path);
            m = containers.Map;

            g = mglob(fullfile(this.raw_lm_path, this.lm_pattern));
            if isempty(g)
                popd(pwd0);
                error("mlsiemens:FileNotFoundError", "%s: no listmode matches %s", ...
                    stackstr(), fullfile(this.raw_lm_path, this.lm_pattern))
            end
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

            if this.lm_select == "last" && m.Count > 1
                ks = m.keys;
                dts = cellfun(@(k) posixtime(m(k).datetime), ks);
                [~, ilast] = max(dts);
                m = containers.Map(ks(ilast), {m(ks{ilast})});
            end
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
        
        function build_raw_dcm(this, opts)
            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.series_pet {mustBeText} = ""  % string(3:21)
                opts.series_mri {mustBeText} = ""  % at least [9,16], possibly more
                opts.do_pet logical = true
                opts.do_mri logical = true
            end

            % sub-*/dcm/pet/
            if opts.do_pet
                pwd0 = pushd(this.raw_dcm_pet_path);
                if isemptytext(opts.series_pet)
                    try
                        this.dcm2niix();
                    catch ME
                        fprintf("%s: %s\n", stackstr(), ME.message)
                    end
                else
                    for s = asrow(opts.series_pet)
                        try
                            [~,r] = this.dcm2niix(series=s);  % CO static
                        catch ME
                            disp(r)
                            fprintf("%s: %s\n", stackstr(), ME.message)
                        end
                    end
                end
                popd(pwd0);
            end

            % sub-*/dcm/mri/
            if opts.do_mri
                pwd0 = pushd(this.raw_dcm_mri_path);
                if isemptytext(opts.series_mri)
                    try
                        [~,r] = this.dcm2niix();  % MPR vNav
                        %disp(r)
                    catch ME
                        fprintf("%s: %s\n", stackstr(), ME.message)
                    end
                else
                    for s = asrow(opts.series_mri)
                        try
                            [~,r] = this.dcm2niix(series=s);  % MPR vNav
                            %disp(r)
                        catch ME
                            fprintf("%s: %s\n", stackstr(), ME.message)
                        end
                    end
                end
                popd(pwd0);
            end
        end
        
        function build_raw_lm(this)
            pwd0 = pushd(this.raw_lm_path);
            g = mglob(fullfile("**", "*.ptd"));
            for gi = 1:length(g)
                try
                    [~,r] = mysystem(sprintf('ln -s "%s"', g(gi)));
                catch ME
                    if ~contains(r, "File exists")
                        handwarning(ME)
                    end
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
            %  opts.ct_series:  if nonempty, accept only these series numbers.  Recommended whenever
            %      one day has several CTs:  dcm2niix names files by study time, not acquisition time,
            %      so every CT of a study ties on datetime and the default choice is arbitrary.

            arguments
                this mlsiemens.BrainMoCoBuilder
                opts.dt datetime = NaT % datetimes of listmode to match
                opts.ct_series double = this.ct_series
            end

            pwd0 = pushd(this.raw_dcm_pet_path);
            
            % glob CTs
            g = glob(fullfile(this.raw_dcm_pet_path, '*_CT_*.nii.gz')); 
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
            if ~isempty(opts.ct_series)
                T = T(ismember(T.series, opts.ct_series), :);
            end
            if isempty(T)
                popd(pwd0);
                error("mlsiemens:FileNotFoundError", ...
                    "%s: no CT series %s precedes listmode at %s in %s", ...
                    stackstr(), mat2str(opts.ct_series), string(opts.dt), this.raw_dcm_pet_path)
            end
            nii_fqfn = T.fqfn{1};
            j_fqfn = strrep(nii_fqfn, ".nii.gz", ".json");
            j = readstruct(j_fqfn);
            if isfield(j, "dicom_folder")
                folder = j.dicom_folder;
            else
                folder = fileparts(j_fqfn);
            end

            popd(pwd0);
        end
        
        function dts = find_dcm_dates(this)
            %% unique session dates in this.raw_dcm_path

            % pwd0 = pushd(this.raw_dcm_pet_path);
            g = mglob("sub-*_ses-*_*.nii.gz");
            dts = NaT(size(g));
            for idx = 1:length(g)
                re = regexp(g(idx), "sub-\S+_ses-(?<dt>\d{8})\d*\S+.nii.gz", "names");
                dts(idx) = datetime(re.dt, InputFormat="yyyyMMdd");
            end
            dts = unique(dts);
            % popd(pwd0);
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
        function construct_bmcbuilder(sub_nums, info_table, opts)
            %% constructs /vgpool02/data2/jjlee/bmcbuilder for use by e7, then calls build_rawdata() as requested

            arguments
                sub_nums string  % set to [] | "" to use subs_pet from 1-row info_table
                info_table table
                opts.do_build_rawdata logical = true
            end
            if isemptytext(sub_nums) && 1 == size(info_table, 1)
                sub_nums = info_table.subs_pet;
            end
            sub_nums = sort(sub_nums);

            % init
            T = info_table(contains(info_table.PET_ID, sub_nums), :);  % select sub_nums
            T = sortrows(T, "PET_ID");

            % prefer working in vglab2:/vgpool02/data2/jjlee/bmcbuilder
            visionlmdir = "/vgpool02/data2/listmode/vision";
            petdcmdir = "/data/nil-bluearc/vlassenko/RAW_IMAGES/PET";
            mridcmdir = "/data/nil-bluearc/vlassenko/RAW_IMAGES/MRI";
            workdir = "/vgpool02/data2/jjlee/bmcbuilder";
            ensuredir(workdir);
            cd(workdir)

            for sidx = 1:length(sub_nums)
                
                % init identifiers
                sub_num = sub_nums(sidx);
                sub = "sub-" + sub_num;
                bmcblmdir = fullfile(workdir, sub, "lm");
                bmcbdcmdir = fullfile(workdir, sub, "dcm");

                try
                    % populate lm/
                    ensuredir(bmcblmdir);
                    pwd0 = pushd(bmcblmdir);
                    listmode_folders = mglob(fullfile(visionlmdir, sub_num + "*"));
                    for lmf = listmode_folders
                        if ~isfolder(mybasename(lmf))
                            mysystem(sprintf("ln -s %s", lmf));
                        end
                    end
                    popd(pwd0);

                    % populate dcm/pet/
                    ensuredir(fullfile(bmcbdcmdir, "pet"))
                    pwd0 = pushd(fullfile(bmcbdcmdir, "pet"));
                    fold = extractAfter(T.PET_ID{sidx}, "_");
                    pet_folders = mglob(fullfile(petdcmdir, sub_num, fold + "*"));
                    pet_folders = pet_folders(~endsWith(pet_folders, ".zip"));
                    for pf = pet_folders
                        raw_images_fold = sub_num + "_" + mybasename(pf);
                        if ~isfolder(raw_images_fold)
                            mysystem(sprintf("ln -s %s %s", pf, raw_images_fold));
                        end
                    end
                    popd(pwd0);

                    % populate dcm/mri/
                    ensuredir(fullfile(bmcbdcmdir, "mri"))
                    pwd0 = pushd(fullfile(bmcbdcmdir, "mri"));
                    fold = extractAfter(T.MRI_ID{sidx}, "_");
                    mri_folders = mglob(fullfile(mridcmdir, sub_num, fold + "*"));
                    mri_folders = mri_folders(~endsWith(mri_folders, ".zip"));
                    for mf = mri_folders
                        raw_images_fold = sub_num + "_" + mybasename(mf);
                        if ~isfolder(raw_images_fold)
                            mysystem(sprintf("ln -s %s %s", mf, raw_images_fold));
                        end
                    end
                    popd(pwd0);

                    if opts.do_build_rawdata
                        bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=bmcblmdir);  % assumes swappable ["lm/", "dcm/"]
                        bmcb.build_rawdata();
                    end
                catch ME
                    fprintf("%s: while working in:\n", stackstr());
                    fprintf("\t%s\n", bmcblmdir);
                    fprintf("\t%s\n", bmcbdcmdir);
                    handwarning(ME)
                end
            end            
        end

        function construct_bmcbuilder_more_t1w(sub_nums, info_table)
            %% calls build_rawdata() as requested

            arguments
                sub_nums string
                info_table table
            end
            sub_nums = sort(sub_nums);

            % init
            T = info_table(contains(info_table.PET_ID, sub_nums), :);  % select sub_nums
            T = sortrows(T, "PET_ID");

            % prefer working in vglab2:/vgpool02/data2/jjlee/bmcbuilder
            mridcmdir = "/data/nil-bluearc/vlassenko/RAW_IMAGES/MRI";
            workdir = "/vgpool02/data2/jjlee/bmcbuilder";
            ensuredir(workdir);
            cd(workdir)

            for sidx = 1:length(sub_nums)
                
                % init identifiers
                sub_num = sub_nums(sidx);
                sub = "sub-" + sub_num;
                bmcblmdir = fullfile(workdir, sub, "lm");
                bmcbdcmdir = fullfile(workdir, sub, "dcm");

                try
                    % populate dcm/mri/
                    ensuredir(fullfile(bmcbdcmdir, "mri"))
                    pwd0 = pushd(fullfile(bmcbdcmdir, "mri"));
                    fold = extractAfter(T.MRI_ID{sidx}, "_");
                    mri_folders = mglob(fullfile(mridcmdir, sub_num, fold + "*"));
                    mri_folders = mri_folders(~endsWith(mri_folders, ".zip"));
                    for mf = mri_folders
                        raw_images_fold = sub_num + "_" + mybasename(mf);
                        if ~isfolder(raw_images_fold)
                            mysystem(sprintf("ln -s %s %s", mf, raw_images_fold));
                        end
                    end
                    popd(pwd0);

                    bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=bmcblmdir);  % assumes swappable ["lm/", "dcm/"]
                    bmcb.build_raw_dcm(do_pet=false, do_mri=true)
                    bmcb.build_sourcedata_dcm_3()
                catch ME
                    fprintf("%s: while working in:\n", stackstr());
                    fprintf("\t%s\n", bmcblmdir);
                    fprintf("\t%s\n", bmcbdcmdir);
                    handwarning(ME)
                end
            end    
        end

        function bmcb = construct_bmcbuilder_phantom(sub_num, opts)
            %% stages rawdata and sourcedata for a phantom, e.g., a cross-calibration bottle of
            %  [18F]FDG in tap water scanned at the end of a subject's Vision session.  Listmode is
            %  chosen by filename (and optionally by being the day's last), the CT by explicit series,
            %  and sourcedata sessions are ses-yyyyMMddHHmmss, so the subject's own sessions of that
            %  day are neither restaged nor overwritten.  Generalizes the loop formerly inline in
            %  Test_JSReconBuilder_Win.test_BMCBuilder_build_all_phantoms.
            %
            %  Run on vglab2 with SINGULARITY_HOME and PROJECT_FOLDER set (see get.sourcedata).
            %
            %  Args:
            %      sub_num (text):  e.g., "108293"
            %      opts.lm_folder (text):  glob of listmode export folder(s), relative to opts.visionlmdir
            %      opts.dcm_folder (text):  glob of DICOM folder(s), relative to opts.petdcmdir, or an
            %          absolute path, e.g., CT fetched from CNDA with the global cnda skill
            %      opts.lm_pattern (text):  glob of listmode within the export, e.g., an exact .ptd name
            %      opts.lm_select (text):  "all" | "last"; "last" keeps only the day's latest listmode
            %      opts.ct_series (double):  CT series in H.U. for attenuation; strongly recommended
            %      opts.series_pet (text):  DICOM series to convert; ct_series is always included
            %      opts.link_prefix (text):  prefix for symlink names in rawdata lm/ and dcm/pet/
            %      opts.do_symlink (logical):  stage sourcedata lm/ as symlinks (rsync -aL to e7)
            %      opts.do_build_rawdata (logical):  false only populates symlinks
            %  Returns:
            %      bmcb:  mlsiemens.BrainMoCoBuilder; its raw_lm_path holds map.mat

            arguments
                sub_num {mustBeTextScalar}
                opts.lm_folder {mustBeTextScalar}
                opts.dcm_folder {mustBeTextScalar}
                opts.lm_pattern {mustBeTextScalar} = "*LISTMODE*.ptd"
                opts.lm_select {mustBeMember(opts.lm_select, ["all", "last"])} = "all"
                opts.ct_series double = []
                opts.series_pet {mustBeText} = ""
                opts.visionlmdir {mustBeTextScalar} = "/vgpool02/data2/listmode/vision"
                opts.petdcmdir {mustBeTextScalar} = "/data/nil-bluearc/vlassenko/RAW_IMAGES/PET"
                opts.workdir {mustBeTextScalar} = "/vgpool02/data2/jjlee/bmcbuilder"
                opts.link_prefix {mustBeTextScalar} = ""
                opts.do_symlink logical = true
                opts.do_build_rawdata logical = true
            end
            sub_num = string(sub_num);
            series_pet = string(opts.series_pet);
            if ~isempty(opts.ct_series) && any(strlength(series_pet) > 0)
                series_pet = unique([series_pet, string(opts.ct_series)], "stable");
            end
            if isempty(opts.ct_series)
                warning("mlsiemens:RuntimeWarning", ...
                    "%s: ct_series is empty; find_ct() will guess among the day's CTs", stackstr())
            end

            % resolve the listmode within the phantom's own export:  exactly one file, so that links
            % left in a shared workdir by other staging (e.g., the subject's own scans) never match
            lm_src = mglob(fullfile(opts.visionlmdir, opts.lm_folder, "**", opts.lm_pattern));
            if isempty(lm_src)
                error("mlsiemens:FileNotFoundError", "%s: no %s in %s", stackstr(), ...
                    opts.lm_pattern, fullfile(opts.visionlmdir, opts.lm_folder))
            end
            if numel(lm_src) > 1 && opts.lm_select ~= "last"
                error("mlsiemens:ValueError", "%s: %s matches %i listmode files in %s; name one:\n%s", ...
                    stackstr(), opts.lm_pattern, numel(lm_src), opts.lm_folder, join(lm_src, newline))
            end
            lm_pattern = opts.lm_pattern;
            if isscalar(lm_src)
                [~, f, x] = fileparts(lm_src);
                lm_pattern = string(f) + string(x);
            end

            bmcblmdir = fullfile(opts.workdir, "sub-" + sub_num, "lm");
            bmcbdcmpetdir = fullfile(opts.workdir, "sub-" + sub_num, "dcm", "pet");
            link_into(bmcblmdir, fullfile(opts.visionlmdir, opts.lm_folder));
            dcm_src = opts.dcm_folder;
            if ~startsWith(dcm_src, "/")
                dcm_src = fullfile(opts.petdcmdir, dcm_src);
            end
            link_into(bmcbdcmpetdir, dcm_src);

            bmcb = mlsiemens.BrainMoCoBuilder( ...
                raw_lm_path=bmcblmdir, ...
                ct_series=opts.ct_series, ...
                lm_pattern=lm_pattern, ...
                lm_select=opts.lm_select);
            if opts.do_build_rawdata
                bmcb.build_rawdata( ...
                    do_pet=true, do_mri=false, series_pet=series_pet, ...
                    dcm_sessions="listmode", do_symlink=opts.do_symlink);
            end

            function link_into(dest, source_glob)
                ensuredir(dest);
                sources = mglob(source_glob);
                sources = sources(~endsWith(sources, ".zip"));
                if isempty(sources)
                    error("mlsiemens:FileNotFoundError", "%s: nothing matches %s", stackstr(), source_glob)
                end
                for src = asrow(sources)
                    link = fullfile(dest, opts.link_prefix + mybasename(src));
                    if ~isfolder(link) && ~isfile(link)
                        mysystem(sprintf("ln -s '%s' '%s'", src, link));
                    end
                end
            end
        end

        function T = read_crosscal_manifest(fqfn)
            %% table of cross-calibration phantoms from data/crosscal_phantoms.csv, the single
            %  source of truth for each phantom's listmode, CT series, session and status:
            %  ready | staged | blocked_no_ct | blocked_no_lm.  Text columns are strings;
            %  series_pet is split on ";".

            arguments
                fqfn {mustBeTextScalar} = fullfile( ...
                    fileparts(fileparts(fileparts(mfilename("fullpath")))), "data", "crosscal_phantoms.csv")
            end
            opts = detectImportOptions(fqfn, Delimiter=",", TextType="string");
            opts = setvartype(opts, opts.VariableNames, "string");
            T = readtable(fqfn, opts);
            T.series_pet = arrayfun(@(s) split(s, ";")', T.series_pet, UniformOutput=false);
        end

        function report = stage_crosscal_phantoms(opts)
            %% stages, with construct_bmcbuilder_phantom(), every manifest row whose status is
            %  opts.status (default "ready") and, if given, whose sub is in opts.subs.  Every
            %  selected row gets an outcome: "staged", "failed" (with the error), or "skipped"
            %  with its blocking status, so a skipped phantom never passes for a staged one.
            %  Run on vglab2 with SINGULARITY_HOME and PROJECT_FOLDER set.

            arguments
                opts.manifest {mustBeTextScalar} = ""
                opts.subs string = string.empty
                opts.status string = "ready"
                opts.workdir {mustBeTextScalar} = "/vgpool02/data2/jjlee/bmcbuilder/crosscal"  % apart from subjects' own
            end
            if isemptytext(opts.manifest)
                T = mlsiemens.BrainMoCoBuilder.read_crosscal_manifest();
            else
                T = mlsiemens.BrainMoCoBuilder.read_crosscal_manifest(opts.manifest);
            end
            if ~isempty(opts.subs)
                T = T(ismember(T.sub, opts.subs), :);
            end
            if isempty(T)
                error("mlsiemens:ValueError", "%s: no manifest rows for subs %s", stackstr(), join(opts.subs))
            end

            outcome = strings(height(T), 1);
            detail = strings(height(T), 1);
            for ti = 1:height(T)
                r = T(ti, :);
                if ~ismember(r.status, opts.status)
                    outcome(ti) = "skipped";
                    detail(ti) = r.status;
                    continue
                end
                try
                    mlsiemens.BrainMoCoBuilder.construct_bmcbuilder_phantom( ...
                        r.sub, ...
                        lm_folder=r.lm_folder, ...
                        dcm_folder=r.dcm_folder, ...
                        lm_pattern=r.lm_pattern, ...
                        ct_series=str2double(r.ct_series), ...
                        series_pet=r.series_pet{1}, ...
                        workdir=opts.workdir);
                    ses_path = fullfile(getenv("SINGULARITY_HOME"), getenv("PROJECT_FOLDER"), ...
                        "sourcedata", "sub-" + r.sub, "ses-" + r.ses);
                    if ~isfolder(fullfile(ses_path, "lm"))
                        error("mlsiemens:FileNotFoundError", "expected %s/lm after staging", ses_path)
                    end
                    outcome(ti) = "staged";
                    detail(ti) = ses_path;
                catch ME
                    outcome(ti) = "failed";
                    detail(ti) = string(ME.identifier) + ": " + string(ME.message);
                end
            end
            report = table(T.sub, T.status, outcome, detail, ...
                VariableNames=["sub", "status", "outcome", "detail"]);
            disp(report)
        end

        function [dt, modality] = nifti_acquisition_datetime(fp, time_zone)
            %% datetime of a dcm2niix nifti from its json AcquisitionTime and the date of its ses-<14>
            %  filename tag, and its json Modality; NaT and "" if missing.  dcm2niix names files by
            %  study time, so the filename alone cannot tell apart series acquired hours apart.

            arguments
                fp {mustBeTextScalar}  % fileprefix, e.g., sub-108293_ses-20210421134537_CT_Brain-16
                time_zone {mustBeTextScalar} = "local"
            end
            dt = NaT(TimeZone=time_zone);
            modality = "";
            re = regexp(mybasename(fp), "_ses-(?<date>\d{8})\d*_", "names", "once");
            if isempty(re) || ~isfile(fp + ".json")
                return
            end
            j = jsondecode(fileread(fp + ".json"));
            if isfield(j, "Modality")
                modality = string(j.Modality);
            end
            if ~isfield(j, "AcquisitionTime")
                return
            end
            tok = regexp(string(j.AcquisitionTime), "^(\d{2}):?(\d{2}):?(\d{2}(?:\.\d+)?)", "tokens", "once");
            if isempty(tok)
                return
            end
            dt = datetime(re.date, InputFormat="yyyyMMdd", TimeZone=time_zone) + ...
                hours(str2double(tok(1))) + minutes(str2double(tok(2))) + seconds(str2double(tok(3)));
        end

        function T = construct_info_table()
            %% Create table with subs_pet related variables
            %  subs_pet: 82 unique 6-digit strings
            %  PET_ID: 82 unique longer strings, each containing one subs_pet element
            %  MRI_ID: 77 unique longer strings, each containing one subs_pet element
            %  ...
            assert(isfile("subs_pet.mat"))
            assert(isfile("PET_ID.mat"))
            assert(isfile("MRI_ID.mat"))
            assert(isfile("T1_PATH.mat"))
            assert(isfile("PARCEL_PATH.mat"))
            assert(isfile("PARCEL_PATH_0.mat"))
            load("subs_pet.mat");
            load("PET_ID.mat");
            load("MRI_ID.mat");
            load("T1_PATH.mat");
            load("PARCEL_PATH.mat");
            load("PARCEL_PATH_0.mat");
            s.PET_ID = PET_ID; % struct enable loopable fields
            s.MRI_ID = MRI_ID;
            s.T1_PATH = T1_PATH;
            s.PARCEL_PATH = PARCEL_PATH;
            s.PARCEL_PATH_0 = PARCEL_PATH_0;
            s_fields = fields(s);

            % Now create the matching logic
            N = length(subs_pet);
            t.PET_ID = strings(N, 1); % Initialize with empty strings
            t.MRI_ID = strings(N, 1);
            t.T1_PATH = strings(N, 1);
            t.PARCEL_PATH = strings(N, 1);
            t.PARCEL_PATH_0 = strings(N, 1);
            t_fields = fields(t);
            assert(length(t_fields) == length(s_fields))

            % For each subs_pet value, find if it exists in any VARIABLE_ string
            for isub = 1:length(subs_pet)

                for ifield = 1:length(s_fields)

                    s_field = s_fields{ifield};
                    t_field = t_fields{ifield};

                    % Check which .VARIABLE_ strings contain the current subs_pet value
                    contains_current = contains(s.(s_field), subs_pet(isub));

                    if any(contains_current)
                        % Find the first s.VARIABLE_ that contains this subs_pet value
                        found = find(contains_current, 1);
                        t.(t_field)(isub) = s.(s_field)(found);
                    else
                        % If no s.VARIABLE_ contains this subs_pet, leave as empty string
                        t.(t_field)(isub) = "";
                    end
                end
            end

            % Create the table
            T = table(subs_pet, t.PET_ID, t.MRI_ID, t.T1_PATH, t.PARCEL_PATH, t.PARCEL_PATH_0, ...
                VariableNames = ["subs_pet", "PET_ID", "MRI_ID", "T1_PATH", "PARCEL_PATH", "PARCEL_PATH_0"]);

            % Display first few rows to verify
            disp('First 10 rows of the table:');
            disp(T(1:10, :));

            % Display summary statistics
            fprintf('\nTable summary:\n');
            fprintf('Total rows: %d\n', height(T));
            for ifield = 1:length(t_fields)
                field = t_fields{ifield};
                fprintf('Non-empty, empty %s entries: %d, %d\n', ...
                    field, sum(t.(field) ~= ""), sum(t.(field) == ""));
            end

            % Verify that each MRI_ID contains its corresponding subs_pet
            fprintf('\nVerification:\n');
            for ifield = 1:length(t_fields)
                field = t_fields{ifield};
                for isub = 1:height(T)
                    if T.(field)(isub) ~= ""
                        if ~contains(T.(field)(isub), T.subs_pet(isub))
                            fprintf('Error: %s(%d) does not contain subs_pet\n', isub, field);
                        end
                    end
                end
            end
            fprintf('Verification complete.\n');
        end
        
        function [s,r,fn] = dcm2niix(folder, opts)
            %% https://github.com/rordenlab/dcm2niix
            %  e.g., $ dcm2niix -f sub-%n_ses-%t_%d-%s -i 'n' -o $(pwd) -d 8 -v 0 -w 2 -z y $(pwd)
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
                opts.d {mustBeInteger} = 8
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
                opts.series {mustBeTextScalar} = "**"
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
            folders = find_dcm_folders(folder, opts.series);
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
            function folds = find_dcm_folders(fold0, series)
                %% find all unique folders contain dicoms within fold0
                %  e.g., /vgpool02/data2/jjlee/bmcbuilder/sub-108030/dcm/pet/108030_WMH_PET_20250915/108030_WMH_PET_20250915/scans/10-Oxygen1_Dynamic/resources/DICOM/files:

                series = convertStringsToChars(series);
                dcms = glob(fullfile(fold0, '**', 'DICOM*', series, 'DICOM', '*.dcm'));
                if isempty(dcms)
                    dcms = glob(fullfile(fold0, '**', series, 'DICOM*', 'files', '*.dcm'));
                end
                folds = unique(cellfun(@fileparts, dcms, UniformOutput=false));
            end
        end
        
        function dates = extract_trailing_dates(strings)
            %% Extract 8-digit dates that appear after the last underscore
            %  strings ~ cell-array of char
            %  dates ~ cell-array of char

            % Using regular expressions
            pattern = '[_-](\d{8})$';  % Match underscore followed by exactly 8 digits at end
            dates = regexp(strings, pattern, 'tokens', 'once');

            % Convert cell array of cells to cell array of strings
            if iscell(dates)
                dates = cellfun(@(x) x{1}, dates, 'UniformOutput', false);
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
