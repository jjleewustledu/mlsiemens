classdef Test_JSReconBuilder_Win < matlab.unittest.TestCase
    %% Demonstrates rawdata management with BrainMoCoBuilder, reconstructions with BrainMoCo2.
    %  
    %  Created 04-Sep-2023 11:58:00 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        testObj
        bar_alpha_smaller_fqfn
    end
    
    methods (Test)
        function test_afun(this)
            import mlsiemens.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        
        %% examples of using BrainMoCoBuilder to manage LM and DICOM

        function test_construct_bmcbuilder(this)
            cd("/home/usr/jjlee/mnt/CHPC_scratch/Singularity/CCIR_01211");
            ld = load('info_20250905234200.mat');
            info13 = ld.info(end-12:end, :);
            
            mlsiemens.BrainMoCoBuilder.construct_bmcbuilder(info13.subs_pet', info13)
        end

        function test_construct_bmcbuilder_more_t1w(this)
            cd("/home/usr/jjlee/mnt/CHPC_scratch/Singularity/CCIR_01211");
            ld = load('info_20250905234200.mat');
            info = [ld.info(ascol([60,67,69,72:74,77:82]), :)];  % 31
            
            mlsiemens.BrainMoCoBuilder.construct_bmcbuilder_more_t1w(info.subs_pet', info)
        end

        function test_BMCBuilder_build_all_jeremydti(this)

            % specify subjects and their info
            % problems:  108087,             108301 may be missing ct for FDG
            % complete:  108197, 108219,     108240, 108313, 108314
            sub_nums = [ ...
                108237, 108246, 108250, 108254, 108303, 108324, 108325, 108326];
            sub_nums = string(sub_nums);
            sub_nums = sort(sub_nums);
            ld = load("~/mnt/CHPC_scratch/Singularity/CCIR_01211/JeremyDTI+Schaeffer_info.mat");
            T_ori = ld.jeremy_dti_schaeffer_info;
            PET_ID = {'108240_20230821'; '108301_WMH_PET_20230828'};
            MRI_ID = {'108240_MR2_20220812'; '108301_MR20210323143736'};
            T1_PATH = { ...
                '/data/nil-bluearc/vlassenko/Pipeline/Projects/MRI/Reprocess/108240_MR2_20220812/Anatomical/Volume/T1/108240_MR2_20220812_T1.nii.gz'; ...
                '/data/nil-bluearc/vlassenko/Pipeline/Projects/MRI/Reprocess/108301_MR20210323143736/Anatomical/Volume/T1/108301_MR20210323143736_T1.nii.gz'};
            PARCEL_PATH = { ...
                ''; ...
                ''};
            T_adhoc = table(PET_ID, MRI_ID, T1_PATH, PARCEL_PATH);
            T_ori = [T_adhoc; T_ori];
            T = T_ori(contains(T_ori.PET_ID, sub_nums), :);  % select sub_nums
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

                bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=bmcblmdir);  % assumes swappable ["lm/", "dcm/"]
                bmcb.build_all();
            end
        end

        %% examples of using BrainMoco2 to reconstruct

        function test_BMC_build_eva109(this)

            setenv("PROJECT_FOLDER", "CCIR_01483")

            path = fullfile("D:", "CCIR_01483", "sourcedata", "sub-eva109", "ses-20241122", "lm");
            tracer = "fdg";
            taus = [15*ones(1,4) 30*ones(1,8) 60*ones(1,5) 120*ones(1,55)];
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                path, tracer=tracer, starts = 0, taus=taus, expand_starts=false);
            toc
            % Elapsed time is ~64 min.
        end
        function test_BMC_build_laforest(this)

            setenv("PROJECT_FOLDER", "Laforest")

            path = fullfile("D:", "Laforest", "sourcedata", "sub-002", "ses-20230123161457", "lm");
            tracer = "fdg";
            taus = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4) 300*ones(1,11)];
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                path, tracer=tracer, starts = 0, taus=taus, expand_starts=false);
            toc
            % Elapsed time is 4629.934149 seconds.
        end
        function test_BMC_build_vatdys(this)

            setenv("PROJECT_FOLDER", "VATDYS")

            path = fullfile("D:", "VATDYS", "sourcedata", "sub-046", "ses-20240521151158", "lm");
            tracer = "fdg";
            taus = [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4) 300*ones(1,11)];
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                path, tracer=tracer, starts = 0, taus=taus, expand_starts=false);
            toc
            % Elapsed time is 4629.934149 seconds.
        end
        function test_BMC_build_co(this)

            setenv("PROJECT_FOLDER", "CCIR_01211")

            path = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108334", "ses-20241216102236", "lm");
            tracer = "co";
            taus = [3*ones(1,20) 5*ones(1,48)];
            tic
            mlsiemens.BrainMoCo2.create_simple( ...
                path, tracer=tracer, starts=0, taus=taus, expand_starts=false);
            toc
            % Elapsed time is ___ seconds.
        end
        function test_BMC_build_co_robust(this)
            %% Addressing failed recons with brain moco making frame alignments worse.
            %
            % "sourcedata/sub-108032/ses-20221003135003/pet/sub-108032_ses-20221003135003_trc-co_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"
            % "sourcedata/sub-108183/ses-20220801102035/pet/sub-108183_ses-20220801102035_trc-co_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"
            % "sourcedata/sub-108319/ses-20240930092620/pet/sub-108319_ses-20240930092620_trc-co_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"
            % "sourcedata/sub-108333/ses-20240930092620/pet/sub-108333_ses-20241202091547_trc-co_proc-delay0-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz"

            setenv("PROJECT_FOLDER", "CCIR_01211")

            subs_sess = [ ...
                "sub-108032/ses-20221003135003", ...
                "sub-108034/ses-20230717131839", ...
                "sub-108121/ses-20231030133024", ...
                "sub-108193/ses-20221123091954", ...
                "sub-108239/ses-20220926131717"];

            for sidx = 1:length(subs_sess)
                sub_ses = subs_sess(sidx);
                lmpath = fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm");
                tracer = "co";
                taus = 60*ones(1,5);
                time_delay = 0;
                dt = 60;

                tic
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    lmpath, tracer=tracer, taus=taus, time_delay=time_delay, dt=dt);
                toc
            end
        end
        function test_BMC_build_sub_oo(this)
            if isempty(gcp('nocreate'))
                parpool(8)
            end

            % all oxygens in pos 2 & 3
            subs = ["sub-108237", "sub-108250", "sub-108254"];
            sess = ["ses-20221031102320", "ses-20221207095507", "ses-20221116100858"]; % first oo
            for si = 1:length(subs)
                tic
                pwd0 = pushd(fullfile("D:\CCIR_01211\sourcedata", subs(si), sess(si), "lm"));
                bmc = mlsiemens.BrainMoCo2(source_lm_path=pwd);
                bmc.build_sub();
                clear bmc
                ls(fullfile("S:\Singularity\CCIR_01211\sourcedata", subs(si)))
                popd(pwd0);
                toc
            end
        end
        function test_BMC_build_all(this)

            setenv("PROJECT_FOLDER", "CCIR_01211")

            src_dir = fullfile("D:", "CCIR_01211", "sourcedata");
            cd(src_dir);

            mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-1082*"));
            %mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-108329"));  % test single sub
            %mglobbed_sub_dir = fullfile(src_dir, "sub-108" + [320, 321, 322]);
            for sub_dir = mglobbed_sub_dir
                try
                    lm_dirs = mglob(fullfile(sub_dir, "ses-*", "lm"));
                    if isempty(lm_dirs); continue; end
                    lm_dir = lm_dirs(1);
                    tic
                    bmc = mlsiemens.BrainMoCo2(source_lm_path=lm_dir);
                    bmc.build_sub(tracers=["co", "oc", "oo", "ho", "fdg"], clean_up=true);
                    toc
                catch ME
                    handwarning(ME)
                end
            end
        end
        function test_BMC_build_all_fdg(this)

            src_dir = fullfile("D:", "CCIR_01211", "sourcedata");
            cd(src_dir);

            mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-1082*"));
            %mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-108329"));  % test single sub
            %mglobbed_sub_dir = fullfile(src_dir, "sub-108" + [320, 321, 322]);
            for sub_dir = mglobbed_sub_dir
                try
                    lm_dirs = mglob(fullfile(sub_dir, "ses-*", "lm"));
                    if isempty(lm_dirs); continue; end
                    lm_dir = lm_dirs(1);
                    tic
                    bmc = mlsiemens.BrainMoCo2(source_lm_path=lm_dir);
                    bmc.build_sub(tracers="fdg", clean_up=true);
                    toc
                catch ME
                    handwarning(ME)
                end
            end
        end
        function test_BMC_build_fdg_stragglers(this)

            setenv("PROJECT_FOLDER", "CCIR_01211");

            % from 0 & 300 sec:
            % sub-108034/ses-20230717142218, sub-108044/ses-20220926103105, sub-108049/ses-20230717110531[*], sub-108090/ses-20231002101811, sub-108098/ses-20230329100559, 
            % from 300 sec:  
            % sub-108240/ses-20230821091100, sub-108259/ses-20231016101150[*], sub-108301/ses-20230828134623[*],
            % sub-108322/ses-20240701111445[*]
            %
            % * are under repair

            subs_sess = [ ...
                "sub-108034/ses-20230717142218", "sub-108044/ses-20220926103105", "sub-108049/ses-20230717110531", ...
                "sub-108090/ses-20231002101811", "sub-108098/ses-20230329100559", ...
                "sub-108240/ses-20230619101812", "sub-108259/ses-20230731151827", ...
                "sub-108322/ses-20240422105849"];
            tis = {1:2, 1:2, 1:2, 1:2, 1:2, 1:2, 1:2, 1:2};

            for sidx = 1:length(subs_sess)
                sub_ses = subs_sess(sidx);
                paths = [ ...
                    fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm"), ...
                    fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm")];
                tracers = ["fdg", "fdg"];
                taus = {10*ones(1,30), 300*ones(1,11)};
                time_delay = [0, 300];
                dt = [1, 300];
                for ti = tis{sidx}  % 1:2
                    pwd0 = pushd(paths(ti));
                    tic
                    mlsiemens.BrainMoCo2.create_moving_average( ...
                        paths(ti), tracer=tracers(ti), taus=taus{ti}, time_delay=time_delay(ti), dt=dt(ti));
                    toc
                    popd(pwd0);
                end
            end
        end
        function test_BMC_build_fdg_108303_delay300(this)

            setenv("PROJECT_FOLDER", "CCIR_01211");

            sub_ses = "sub-108303/ses-20240729114354";
            paths = fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm");
            tracers = "fdg";
            taus = 300*ones(1,9);  % only 3110 sec of LM available
            time_delay = 300;
            dt = 60;

            pwd0 = pushd(paths);
            tic
            mlsiemens.BrainMoCo2.create_moving_average( ...
                paths, tracer=tracers, taus=taus, time_delay=time_delay, dt=dt);
            toc
            popd(pwd0);
        end
        function test_BMC_build_fdg_108007_delay30(this)

            setenv("PROJECT_FOLDER", "CCIR_01211");

            sub_ses = "sub-108007/ses-20210219143132";
            paths = fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm");
            tracers = "oo";
            taus = 20*ones(1,4);
            time_delay = 30;
            dt = 20;

            pwd0 = pushd(paths);
            tic
            mlsiemens.BrainMoCo2.create_moving_average( ...
                paths, tracer=tracers, taus=taus, time_delay=time_delay, dt=dt);
            toc
            popd(pwd0);
        end
        function test_BMC_build_ho_108021(this)
            
            setenv("PROJECT_FOLDER", "CCIR_01211");

            sub_ses = "sub-108021/ses-20230320142013";
            paths = fullfile("D:", "CCIR_01211", "sourcedata", sub_ses, "lm");
            tracers = "ho";
            taus = 10*ones(1,11);
            time_delay = 0;
            dt = 1;

            pwd0 = pushd(paths);
            tic
            mlsiemens.BrainMoCo2.create_moving_average( ...
                paths, tracer=tracers, taus=taus, time_delay=time_delay, dt=dt);
            toc
            popd(pwd0);
        end
        function test_BMC_build_niftis(this)

            setenv("PROJECT_FOLDER", "CCIR_01211")

            src_dir = fullfile("D:", "CCIR_01211", "sourcedata");
            cd(src_dir);

            %mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-1083*"));
            mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-108140"));  % test single sub
            for sub_dir = mglobbed_sub_dir
                try
                    lm_dirs = mglob(fullfile(sub_dir, "ses-*", "lm"));
                    if isempty(lm_dirs); continue; end
                    lm_dir = lm_dirs(1);
                    tic
                    bmc = mlsiemens.BrainMoCo2(source_lm_path=lm_dir);
                    bmc.build_sub( ...
                        tracers=["co", "oc", "oo", "ho"], ...
                        clean_up=false, ...
                        nifti_only=true, ...
                        reuse_source_sub_table=true);
                    toc
                catch ME
                    handwarning(ME)
                end
            end
        end
        function test_BMC_build_clean(this)

            setenv("PROJECT_FOLDER", "CCIR_01211")

            src_dir = fullfile("D:", "CCIR_01211", "sourcedata");
            cd(src_dir);

            %mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-1083*"));
            mglobbed_sub_dir = mglob(fullfile(src_dir, "sub-108140"));  % test single sub
            for sub_dir = mglobbed_sub_dir
                lm_dir = mglob(fullfile(sub_dir, "ses-*", "lm*"));  % single lm dir needed by ctor
                assert(isfolder(lm_dir(1)))
                bmc = mlsiemens.BrainMoCo2(source_lm_path=lm_dir(1));
                bmc.build_clean(tag="-start", starts=0, deep=false);
            end
        end
        function test_BMC_build_sub(this)
            % single subject

            setenv("PROJECT_FOLDER", "CCIR_01211")

            tic
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108007");
            for mg = mglob(fullfile("ses-*", "lm"))
                bmc = mlsiemens.BrainMoCo2(source_lm_path=fullfile(pwd, mg));
                bmc.build_sub();
            end
            ls("V:\jjlee\Singularity\CCIR_01211\sourcedata\sub-108007")
            popd(pwd0);
            toc
        end
        function test_BMC_build_sub_single_lm(this)
            % single subject

            setenv("PROJECT_FOLDER", "CCIR_01211")

            tic
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108284\ses-20230220095210\lm");
            bmc = mlsiemens.BrainMoCo2(source_lm_path=pwd);
            bmc.build_sub(ses0=2, sesF=3);
            ls("S:\Singularity\CCIR_01211\sourcedata\sub-108284")
            popd(pwd0);
            toc
        end
        function test_BMC_create_moving_average_single_start(this)
            % single subject

            error("mlsiemens:NotImplementedError", stackstr())

            setenv("PROJECT_FOLDER", "CCIR_01211")

            source_ses_path = "D:\CCIR_01211\sourcedata\sub-108032\ses-20221003140439";
            source_lm_path = fullfile(source_ses_path, "lm-oo1");
            cd(source_lm_path);
            
            opts.starts = {[0 1 2 3 4 5 6 7 8 9], 0};
            opts.taus = {[10 10 10], [20 20 20 20]};
            opts.time_delay = 0;
            opts.tracer = "oo";
            opts.tag = "-start";
            opts.tag0 = "-start0";

            for parti = 1:length(opts.taus)
                try
                    [starts,taus] = mlsiemens.BrainMoCo2.expand_starts( ...
                        opts.starts{parti}, opts.taus{parti}, time_delay=opts.time_delay, dt=1);

                    % mlsiemens.BrainMoCo2.create_v_moving_average( ...
                    %     source_lm_path, ...
                    %     tag="-start", ...
                    %     taus=taus, ...
                    %     starts=starts, ...
                    %     coarsening_time=3600, ...
                    %     tracer="oo", ...
                    %     do_jsr=false, ...
                    %     do_bmc=true);
                catch ME
                    disp(ME)
                end


                si = 8;  % start offset
                try
                    obj = mlsiemens.BrainMoCo2.create_tagged(source_lm_path, tag=opts.tag, starts=starts(si));
                    [lmframes,skip] = mlsiemens.BrainMoCo2.mat2lmframes(taus, start=starts(si));
                    obj.build_scan( ...
                        LMFrames=lmframes, Skip=skip, tracer=opts.tracer, tag=opts.tag, tag0=opts.tag0, starts=starts(si), ...
                        do_jsr=false, do_bmc=true);
                catch ME
                    handwarning(ME)
                end
            end
        end
        function test_BMC_create_fdg_phantom(this)

            setenv("PROJECT_FOLDER", "CCIR_01211")

            if isempty(gcp('nocreate'))
                parpool(2)
            end

            % calib. phantom
            % pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421171325\lm");
            % tic
            % mlsiemens.BrainMoCo2.create_fdg_phantom(pwd);
            % toc
            % popd(pwd0);
            % Elapsed time is 3148.839220 seconds for 54 cumulative, N_PROC == 5, parpool(5).
            % Elapsed time is ~ 2580 seconds for 5*29 moving average frames, N_PROC == 5, parpool(5).

            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108250", "ses-20221207120651", "lm-fdg"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108254", "ses-20221116130516", "lm-fdg"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108284", "ses-20230220122457", "lm-fdg"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108306", "ses-20230227132837", "lm-fdg")];
            for idx = 1:length(paths)
                apath = paths(idx);
                pwd0 = pushd(apath);
                tic                 
                mlsiemens.BrainMoCo2.create_fdg_phantom(apath);  
                toc
                popd(pwd0);
            end
        end

        function test_BMC_build_clean_co(this)
            pth = fullfile("D:", "CCIR_01211", "sourcedata", "sub-1089300", "ses-20210517103643", "lm-co");
            pwd0 = pushd(pth);
            bmc = mlsiemens.BrainMoCo2(source_lm_path=pth);
            bmc.build_clean(deep=true);
            popd(pwd0);
        end
        function test_BMC_build_clean_oo2(this)
            pth = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2");
            pwd0 = pushd(pth);
            bmc = mlsiemens.BrainMoCo2(source_lm_path=pth);
            for idx = [0:9,30:49]
                bmc.build_clean(starts=idx);
            end
            popd(pwd0);
        end
        function test_BMC_create_sub_table(this)
            pth = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108306", "ses-20230227115809", "lm");
            bmc2 = mlsiemens.BrainMoCo2(source_lm_path=pth);
            bmc2.build_sub_table()
        end
        function test_BMC_create_co_108300(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108300", "ses-20210517103643", "lm-co");
            tracers = "co";
            taus = {10*ones(1,29)};
            pwd0 = pushd(paths);
            tic                 
            mlsiemens.BrainMoCo2.create_moving_average(paths, tracer=tracers, taus=taus{1}, nifti_only=true);
            toc
            popd(pwd0);
        end
        function test_BMC_create_fdg_108300(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108300", "ses-20210517114419", "lm-fdg");
            tracers = "fdg";
            taus = {10*ones(1,329)};
            pwd0 = pushd(paths);
            tic                 
            mlsiemens.BrainMoCo2.create_moving_average(paths, tracer=tracers, taus=taus{1}, nifti_only=true);
            toc
            popd(pwd0);
        end
        function test_BMC_create_fdg_108306(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108306", "ses-20230227115809", "lm-fdg");
            tracers = "fdg";
            taus = 20*ones(1, 165);
            time_delay = 300;
            starts = 0;

            pwd0 = pushd(paths);
            tic                 
            mlsiemens.BrainMoCo2.create_moving_average( ...
                paths, tracer=tracers, taus=taus, time_delay=time_delay, starts=starts);
            toc
            popd(pwd0);
        end
        function test_BMC_create_co(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co");
            tracers = "co";
            taus = {10*ones(1,29)};
            pwd0 = pushd(paths);
            tic                 
            mlsiemens.BrainMoCo2.create_moving_average(paths, tracer=tracers, taus=taus{1});
            toc
            popd(pwd0);
        end
        
        function test_BMC_create_oo(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108034", "ses-20230717131839", "lm");
            tracers = "oo";
            taus = {20*ones(1,4), 10*ones(1,3)};
            time_delay = [30, 0];
            dt = [20, 1];

            for ti = 1:2
                pwd0 = pushd(paths);
                tic
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    paths, tracer=tracers, taus=taus{ti}, time_delay=time_delay(ti), dt=dt(ti));
                toc
                popd(pwd0);
            end
        end

        function test_BMC_create_ho(this)
            paths = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "lm-ho");
            tracers = "ho";
            taus = {10*ones(1,11)};
            pwd0 = pushd(paths);
            tic                 
            mlsiemens.BrainMoCo2.create_moving_average(paths, tracer=tracers, taus=taus{1});
            toc
            popd(pwd0);
        end
        function test_BMC_create_oo2(this)
            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2"), ...                
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2")];                
            tracers = ["oo", "oo"]; 
            taus = {20*ones(1,4), 10*ones(1,3)}; %10*ones(1,359)};
            time_delay = [30, 0];
            for ti = 1:length(paths)
                pwd0 = pushd(paths(ti));
                tic                 
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    paths(ti), tracer=tracers(ti), taus=taus{ti}, time_delay=time_delay(ti));
                toc
                popd(pwd0);
            end
         
            %mlsiemens.BrainMoCo2.create_simple( ...
            %    pwd, tracer="oo", taus=[3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)]);

            % Elapsed time is 6974.721815 seconds for moving-average (with drop-outs).
            % Elapsed time is 1389.936770 seconds for 2 cumulative, N_PROC == 5
            % Elapsed time is 2662.566290 seconds for 5 cumulative, N_PROC == 5
            % Elapsed time is 4482.024104 seconds for 10 moving-average, N_PROC == 5, parpool(5)
            % Elapsed time is 4289.807903 seconds for 5*29 moving average frames, N_PROC == 5, parpool(5). 
            % Elapsed time is 6856.532406 seconds for moving average frames N_PROC == 10, parpool(10).
        end
        function test_BMC_create_fdg(this)
            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm-fdg"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm-fdg")];
            tracers = ["fdg", "fdg"];
            taus = {10*ones(1,29), 10*ones(1,329)};
            time_delay = [0, 300];
            dt = [1, 10];
            for ti = 2:2 %1:length(paths)
                pwd0 = pushd(paths(ti));
                tic                 
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    paths(ti), tracer=tracers(ti), taus=taus{ti}, time_delay=time_delay(ti), dt=dt(ti));
                toc
                popd(pwd0);
            end
        end
        function test_BMC_create_moving_average_agi(this)
            
            % parpool(mlsiemens.BrainMoCo2.N_PROC)

            % fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co"), ...
            % fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "lm-ho"), ...
            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2"), ...                
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2")];
                %fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm-fdg")];
            tracers = ["oo", "oo"]; % "fdg", "co", "ho", 
            % 10*ones(1,29), ...
            % 10*ones(1,11), ...
            taus = { ...
                20*ones(1,4), 10*ones(1,3)};
                %10*ones(1,359)};
            time_delay = [30, 0];
            for ti = 1:length(paths)
                tic
                mlsiemens.BrainMoCo2.create_moving_average( ...
                    paths(ti), tracer=tracers(ti), taus=taus{ti}, time_delay=time_delay(ti));
                toc
            end
        end
        function test_BMC_create_simple_agi(this)
            
            if isempty(gcp('nocreate'))
                parpool(mlsiemens.BrainMoCo2.N_PROC)
            end

            paths = [ ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm-co"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", "lm-oo1"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "lm-ho"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm-oo2"), ...
                fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm-fdg")];
            tracers = ["co", "oo", "ho", "oo", "fdg"];
            taus = { ...
                [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)], ...
                [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)], ...
                [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)], ...
                [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4)], ...
                [3*ones(1,23) 5*ones(1,6) 10*ones(1,8) 30*ones(1,4) 300*ones(1,11)]};
            tic
            parfor (ti = 1:5, mlsiemens.BrainMoCo2.N_PROC)
                mlsiemens.BrainMoCo2.create_simple( ...
                    paths(ti), tracer=tracers(ti), taus=taus{ti});
            end
            toc
            % Elapsed time is 4629.934149 seconds.

            % co
            % pwd0 = pushd(fullfile( ...
            %     "D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421144815", "lm"));
            % tic
            % mlsiemens.BrainMoCo2.create_co(pwd);
            % toc
            % popd(pwd0);
            % Elapsed time is 10988.011654 seconds for cumul2frames.
            % Elapsed time is 3075.282301 seconds for moving average frames.

            % oo
            % pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421150523\lm");
            % tic
            % mlsiemens.BrainMoCo2.create_simple(pwd, tracer="oo");
            % toc
            % popd(pwd0);
            % Elapsed time is 29512.260563 seconds.

            % ho
            % pwd0 = pushd(fullfile( ...
            %     "D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421152358", "lm"));
            % tic
            % mlsiemens.BrainMoCo2.create_simple(pwd, tracer="ho");
            % toc
            % popd(pwd0);
            % Elapsed time is 7146.333194 seconds.

            % oo
            % pwd0 = pushd(fullfile( ...
            %     "D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421154248", "lm"));
            % tic
            % mlsiemens.BrainMoCo2.create_simple(pwd, tracer="oo");
            % toc
            % popd(pwd0);
            % Elapsed time is 11010.605297 seconds.

            % fdg
            % pwd0 = pushd(fullfile( ...
            %     "D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421155709", "lm"));
            % tic
            % mlsiemens.BrainMoCo2.create_simple(pwd, tracer="fdg", ...
            %     taus=[5*ones(1,24) 20*ones(1,9) 60*ones(1,10) 300*ones(1,9)]);
            % toc
            % popd(pwd0);
            % Elapsed time is 40264.135840 seconds.
        end
        function test_BMC_repair_empty_frames(this)
            nii = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-BrainMoCo2-createNiftiMovingAvgFrames.nii.gz");
            nii1 = fullfile("D:", "CCIR_01211", "sourcedata", "sub-108293", "ses-20210421150523", ...
                "sub-108293_ses-20210421150523_trc-oo_proc-Conventional-createNiftiMovingAvgFrames.nii.gz");
            
            tic
            nii = mlsiemens.BrainMoCo2.repair_empty_frames(nii, nii1);
            toc
            
            nii.view
        end
        function test_build_niftis(this)
            lm_path = "D:\CCIR_01211\sourcedata\sub-108306\ses-20230227134149\lm";
            ses_path = myfileparts(lm_path);
            static_dcm_path = fullfile(ses_path, "lm-StaticBMC", "lm-BMC-LM-00-ac_mc_000_000.v-DICOM");
            dyn_dcm_path = fullfile(ses_path, "lm-DynamicBMC", "lm-BMC-LM-00-dynamic-DICOM");
            pet_path = strrep(lm_path, "lm", "pet");

            s.dt = datetime(2023,2,27,13,41,49); % struct of LM info
            s.ct = fullfile(lm_path, "CT");
            s.norm = fullfile(lm_path, "108306.PT.Head_CCIR_0970_FDG_(Adult).602.PET_CALIBRATION.2023.02.27.13.41.49.321000.2.0.223540099.ptd");
            s.lm = fullfile(lm_path, "108306.PT.Head_CCIR_0970_FDG_(Adult).602.PET_LISTMODE.2023.02.27.13.41.49.321000.2.0.223540115.ptd");
            s.id = "2.0.223540115";

            pwd0 = pushd(pet_path);
            mlsiemens.BrainMoCoBuilder.dcm2niix(static_dcm_path, f="sub-%n_ses-%t_trc-oo_proc-bmc-lm-00-static_pet", w=1); % clobber
            delete(myfileparts(static_dcm_path))
            mlsiemens.BrainMoCoBuilder.dcm2niix(dyn_dcm_path, f="sub-%n_ses-%t_trc-oo_proc-bmc-lm-00-dyn_pet", w=1); % clobber
            delete(myfileparts(dyn_dcm_path))
            popd(pwd0);
        end
        function test_build_static(this)
            pwd0 = pushd("D:\CCIR_01211\rawdata\sub-108306\ses-20230227\lm");

            bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=pwd);
            map = bmcb.build_map_of_lm();
            keys = map.keys;
            for k = asrow(keys) 
                bmcb.build_input_folders(map(k{1}));
                bmc = mlsiemens.BrainMoCo(source_lm_path=bmcb.source_lm_path);
                bmc.build_static();
                %bmcb.build_niftis(map(k{1}), tracer="unknown", is_dyn=false);
                %bmcb.build_output_folders(map(k{1}));
            end

            popd(pwd0);
        end
        function test_createNiftiMovingAvgRepair(this)
            sub = "sub-108293";
            ses = "ses-20210421154248";
            mlsiemens.BrainMoCo2.createNiftiMovingAvgRepair(sub, ses);
        end
        function test_cumul2frames(this)
            a = [0 1e3 1e4 5e4 10e4 7e4 6e4 5e4 4e4 3e4 linspace(20e3, 10e3, 10) linspace(10e3, 5e3, 10)]; % len ~ 30
            a = a + 1e4*rand(1,30);
            a(a<0) = 5e3;
            taus = [ones(1,20) 10*ones(1,10)];
            timesMid = cumsum(taus) - taus/2;
            alpha_bar = zeros(1,30);
            alpha = zeros(1,30);
            for i = 1:30
                T = sum(taus(i:30));
                alpha_bar(i) = sum(taus(i:30).*a(i:30))/T; % time-interval averages
                alpha(i) = sum(taus(i:30).*a(i:30));
            end

            figure;
            plot(timesMid, a)
            legend("a")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")

            figure; 
            plot(timesMid, alpha_bar)
            legend("bar \alpha")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")

            figure; 
            ic_alpha_bar = mlfourd.ImagingContext2(alpha_bar);
            ic_a_hat = mlsiemens.BrainMoCo2.cumul2frames(ic_alpha_bar, taus=taus);
            a_hat = ic_a_hat.imagingFormat.img;
            plot(timesMid, a, timesMid, alpha_bar, timesMid, a_hat);            
            legend(["a", "bar \alpha", "a hat"], Interpreter="tex")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")
        end
        function test_cumul2frames_2D(this)
            a = [0 1e3 1e4 5e4 10e4 7e4 6e4 5e4 4e4 3e4 linspace(20e3, 10e3, 10) linspace(10e3, 5e3, 10)]; % len ~ 30
            %a = [a; a; a; a];
            a = a + 1e4*rand(4,30);
            a(a<0) = 5e3;
            taus = [ones(1,20) 10*ones(1,10)];
            timesMid = cumsum(taus, 2) - taus/2;
            alpha_bar = zeros(4,30);
            alpha = zeros(4,30);
            for i = 1:30
                T = sum(taus(i:30), 2);
                alpha_bar(:, i) = sum(taus(i:30).*(a(:, i:30)./T), 2); % time-interval averages
                alpha(:, i) = sum(taus(i:30).*a(:, i:30), 2);
            end
            
            figure; 
            hold on
            for i = 1:4
                plot(timesMid, a(i,:))
            end
            hold off
            legend(["a", "a", "a", "a"])
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")

            figure; 
            hold on
            for i = 1:4
                plot(timesMid, alpha_bar(i,:))
            end
            hold off
            legend(["bar \alpha", "bar \alpha", "bar \alpha", "bar \alpha"])
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")

            figure; 
            ic_alpha_bar = mlfourd.ImagingContext2(alpha_bar);
            ic_a_hat = mlsiemens.BrainMoCo2.cumul2frames(ic_alpha_bar, taus=taus);
            a_hat = ic_a_hat.imagingFormat.img;
            hold on
            for i = 1:4
                plot(timesMid, a(i,:), timesMid, alpha_bar(i,:), timesMid, a_hat(i,:));
            end
            hold off
            legend(["a", "bar \alpha", "a hat", "a", "bar \alpha", "a hat", "a", "bar \alpha", "a hat", "a", "bar \alpha", "a hat"], Interpreter="tex")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")
        end
        function test_cumul2frames_4D(this)
            ic = mlfourd.ImagingContext2(this.bar_alpha_smaller_fqfn);
            ic = mlsiemens.BrainMoCo2.cumul2frames4d(ic);
            ic.view()
        end
        function test_diff_cumul(this)
            a = [0 1e3 1e4 5e4 10e4 7e4 6e4 5e4 4e4 3e4 linspace(20e3, 10e3, 10) linspace(10e3, 5e3, 10)]; % len ~ 30
            a = a + 1e4*rand(1,30);
            a(a<0) = 5e3;
            taus = [ones(1,20) 10*ones(1,10)];
            timesMid = cumsum(taus) - taus/2;
            alpha_bar = zeros(1,30);
            alpha = zeros(1,30);
            for i = 1:30
                T = sum(taus(1:i));
                alpha_bar(i) = sum(taus(1:i).*a(1:i))/T; % time-interval averages
                alpha(i) = sum(taus(1:i).*a(1:i));
            end

            figure;
            plot(timesMid, a)

            figure; 
            ic_alpha = mlfourd.ImagingContext2(alpha);
            ic_a_hat = mlsiemens.BrainMoCo2.diff_cumul(ic_alpha, taus=taus);     
            timesMid_ = timesMid(1:end-1);  
            timesMid__ = timesMid(2:end);
            a_hat = ic_a_hat.imagingFormat.img;
            plot(timesMid, a, timesMid, alpha_bar, timesMid, alpha, timesMid_, a_hat, timesMid__, a_hat);            
            legend(["a", "\alpha bar", "\alpha", "a hat", "a(t++) hat"], Interpreter="tex")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")
        end
        function test_diff_cumul_time_rev(this)
            a = [0 1e3 1e4 5e4 10e4 7e4 6e4 5e4 4e4 3e4 linspace(20e3, 10e3, 10) linspace(10e3, 5e3, 10)]; % len ~ 30
            a = a + 1e4*rand(1,30);
            a(a<0) = 5e3;
            a__ = flip(a);
            taus = [ones(1,20) 10*ones(1,10)];
            taus__ = flip(taus);
            timesMid = cumsum(taus) - taus/2;
            alpha_bar = zeros(1,30);
            alpha = zeros(1,30);
            for i = 1:30
                T = sum(taus__(1:i));
                alpha_bar(i) = sum(taus__(1:i).*a__(1:i))/T; % time-interval averages
                alpha(i) = sum(taus__(1:i).*a__(1:i));
            end

            figure;
            plot(timesMid, a)

            figure; 
            ic_alpha = mlfourd.ImagingContext2(alpha);
            ic_a_hat = mlsiemens.BrainMoCo2.diff_cumul(ic_alpha, taus=flip(taus));   
            ic_a_hat = flip(ic_a_hat, 2);
            timesMid_ = timesMid(1:end-1);  
            a_hat = ic_a_hat.imagingFormat.img;
            plot(timesMid, a, timesMid, flip(alpha_bar), timesMid, flip(alpha), timesMid_, a_hat);            
            legend(["a", "\alpha bar", "\alpha", "a hat"], Interpreter="tex")
            xlabel("times (s)")
            ylabel("activity density (Bq/mL)")
        end
    end
    
    methods (TestClassSetup)
        function setupJSReconBuilder_Win(this)
            import mlsiemens.*
            %this.testObj_ = BrainMoCoBuilder();
            this.bar_alpha_smaller_fqfn = ...
                fullfile(getenv("SINGULARITY_HOME"), "CCIR_01211", "bar_alpha_smaller.nii.gz");

            setenv("PROJECT_FOLDER", "CCIR_01211")
            
        end
    end
    
    methods (TestMethodSetup)
        function setupJSReconBuilder_WinTest(this)
            this.testObj = this.testObj_;
            this.addTeardown(@this.cleanTestMethod)
            
            assert(~isemptytext(getenv("PROJECT_FOLDER")))
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
