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

            parpool(mlsiemens.BrainMoCo2.N_PROC)

            % calib. phantom
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421171325\lm");
            tic
            mlsiemens.BrainMoCo2.create_fdg_phantom(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 3148.839220 seconds for 54 cumulative, N_PROC == 5, parpool(5).
        end
        function test_BMC_create_oo(this)

            parpool(mlsiemens.BrainMoCo2.N_PROC)

            % oo
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421150523\lm");
            tic
            mlsiemens.BrainMoCo2.create_oo(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 6974.721815 seconds for moving-average (with drop-outs).
            % Elapsed time is 1389.936770 seconds for 2 cumulative, N_PROC == 5
            % Elapsed time is 2662.566290 seconds for 5 cumulative, N_PROC == 5
            % Elapsed time is 4482.024104 seconds for 10 moving-average, N_PROC == 5, parpool(5)
        end
        function test_BMC_create_for_agi(this)
            
            parpool(mlsiemens.BrainMoCo2.N_PROC)

            % co
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421144815\lm");
            tic
            mlsiemens.BrainMoCo2.create_co(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 10988.011654 seconds.

            % oo
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421150523\lm");
            tic
            mlsiemens.BrainMoCo2.create_oo(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 29512.260563 seconds.

            % ho
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421152358\lm");
            tic
            mlsiemens.BrainMoCo2.create_ho(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 7146.333194 seconds.

            % oo
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421154248\lm");
            tic
            mlsiemens.BrainMoCo2.create_oo(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 11010.605297 seconds.

            % fdg
            pwd0 = pushd("D:\CCIR_01211\sourcedata\sub-108293\ses-20210421155709\lm");
            tic
            mlsiemens.BrainMoCo2.create_fdg(pwd);
            toc
            popd(pwd0);
            % Elapsed time is 40264.135840 seconds.
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
