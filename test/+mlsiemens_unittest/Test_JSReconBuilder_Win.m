classdef Test_JSReconBuilder_Win < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 04-Sep-2023 11:58:00 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/test/+mlsiemens_unittest.
    %  Developed on Matlab 9.14.0.2337262 (R2023a) Update 5 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        testObj
    end
    
    methods (Test)
        function test_afun(this)
            import mlsiemens.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_BMC_call(this)
            % calib. phantom
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108306\ses-20230227134149\lm");
            bmc = mlsiemens.BrainMoCo(source_lm_path=pwd);
            bmc.call(Skip=0, LMFrames="0:10,10,10", tracer="fdg");
            this.verifyEqual(1,1);            
            popd(pwd0);
        end
        function test_BMC_create_fdg_phantom(this)
            % calib. phantom
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421171325\lm");
            tic
            mlsiemens.BrainMoCo.create_fdg_phantom(pwd);
            toc
            this.verifyEqual(1,1);            
            popd(pwd0);
        end
        function test_BMC_create_oo(this)
            % oo
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421150523\lm");
            tic
            mlsiemens.BrainMoCo2.create_oo(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 6974.721815 seconds for interleaved (with drop-outs).
            % Elapsed time 
        end
        function test_BMC_create_for_agi(this)
            % co
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421144815\lm");
            tic
            mlsiemens.BrainMoCo.create_co(pwd);
            toc
            popd(pwd0);

            % oo
            % pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421150523\lm");
            % tic
            % mlsiemens.BrainMoCo.create_oo(pwd);
            % toc
            % popd(pwd0);

            % ho
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421152358\lm");
            tic
            mlsiemens.BrainMoCo.create_ho(pwd);
            toc
            popd(pwd0);

            % oo
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421154248\lm");
            tic
            mlsiemens.BrainMoCo.create_oo(pwd);
            toc
            popd(pwd0);

            % fdg
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421155709\lm");
            tic
            mlsiemens.BrainMoCo.create_fdg(pwd);
            toc
            popd(pwd0);
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
        function test_call_static(this)
            pwd0 = pushd("D:\CCIR_01211\rawdata\sub-108306\ses-20230227\lm");

            bmcb = mlsiemens.BrainMoCoBuilder(raw_lm_path=pwd);
            map = bmcb.build_map_of_lm();
            keys = map.keys;
            for k = asrow(keys) 
                bmcb.build_input_folders(map(k{1}));
                bmc = mlsiemens.BrainMoCo(source_lm_path=bmcb.source_lm_path);
                bmc.call_static();
                %bmcb.build_niftis(map(k{1}), tracer="unknown", is_dyn=false);
                %bmcb.build_output_folders(map(k{1}));
            end

            popd(pwd0);
        end
    end
    
    methods (TestClassSetup)
        function setupJSReconBuilder_Win(this)
            import mlsiemens.*
            %this.testObj_ = BrainMoCoBuilder();
        end
    end
    
    methods (TestMethodSetup)
        function setupJSReconBuilder_WinTest(this)
            this.testObj = this.testObj_;
            this.addTeardown(@this.cleanTestMethod)
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
