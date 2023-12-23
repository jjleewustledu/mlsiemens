classdef BoxcarModel < handle & mlaif.ArteryLee2021Model
    %% Intended for use with mlkinetics.{Idif,MipIdif}.
    %  
    %  Created 01-Dec-2023 19:50:42 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 23.2.0.2428915 (R2023b) Update 4 for MACA64.  Copyright 2023 John J. Lee.
    
    methods    
        function soln = build_solution(this)
            %% MAKE_SOLUTION
            %  @return ks_ in R^1 as mlfourd.ImagingContext2, without saving to filesystems.   
            %  @return this.artery, which is deconvolved.

            % this.Data is assigned in create(), since build_solution() requires no adjustments of this.Data

            % solve artery model and insert solutions into ks
            this.build_model(measurement=this.measurement_); % model assigns this.measurement_

            solved = cell(this.Nensemble, 1);
            losses = NaN(this.Nensemble, 1);
            for idx = 1:this.Nensemble
                tic

                % find lowest loss in the ensemble
                solved{idx} = this.solver_.solve(@mlsiemens.BoxcarModel.loss_function);
                losses(idx) = solved{idx}.product.loss;

                toc
            end

            % find best loss in solved
            T = table(solved, losses);
            T = sortrows(T, "losses", "ascend");
            solved_star = T{1, "solved"}{1};

            % update idealized artery
            pr_ = solved_star.product;
            [~,A,ideal] = this.sampled(pr_.ks, this.Data, [], solved_star.TimesSampled);
            img_new_ = solved_star.rescaleModelEstimate(A*ideal);
            ai_new_ = this.artery.selectImagingTool(img=img_new_); % ref to be immediately updated
            ai_new_.fileprefix = strrep(this.artery.fileprefix, "_pet", "_boxcar");
            this.artery_ = ai_new_;
            solved_star.ArteryInterpolated = this.interp1_artery(img=img_new_);
            this.solver_ = solved_star;

            % product_ := ks
            ks_mat_= [asrow(pr_.ks), pr_.loss];
            ks_mat_ = single(ks_mat_);
            soln = this.artery.selectImagingTool(img=ks_mat_);
            soln.fileprefix = strrep(this.artery.fileprefix, "_pet", "_boxcarks");
            soln.fileprefix = strrep(this.artery.fileprefix, "_idif", "_boxcarks");
            soln.save();
            this.product_ = soln;

            % plot idealized artery
            h = solved_star.plot( ...
                tag=this.artery.fileprefix, ...
                xlim=[-10, this.times_sampled(end)+10], ...
                zoomMeas=1, ...
                zoomModel=1);
            saveFigure2(h, ...
                this.artery.fqfp + "_" + stackstr(), ...
                closeFigure=this.closeFigures);
        end
    end

    methods (Static)
        function this = create(opts)
            arguments
                opts.artery mlfourd.ImagingContext2
                opts.model_kind {mustBeTextScalar} = "3bolus"
                opts.t0_forced {mustBeNumeric} = []
                opts.tracer {mustBeTextScalar} = "Unknown"
                opts.closeFigures logical = false
                opts.Nensemble double = 10
            end

            this = mlsiemens.BoxcarModel();

            this.artery_= mlpipeline.ImagingMediator.ensureFiniteImagingContext(opts.artery);
            ifc = this.artery_.imagingFormat;
            this.measurement_ = asrow(ifc.img);
            this.times_sampled_ = asrow(ifc.json_metadata.timesMid);
            this.Data.timesMid = this.times_sampled_;
            this.Data.taus = asrow(ifc.json_metadata.taus);
            this.Data.model_kind = opts.model_kind;
            this.Data.N = round(this.times_sampled(end)) + 1;
            if ~isempty(opts.t0_forced)
                this.Data.t0_forced = opts.t0_forced;
            end
            this.Data.tracer = opts.tracer;
            this.closeFigures = opts.closeFigures;
            this.Nensemble = opts.Nensemble;

            this.LENK = 12;
        end

        function vec = apply_boxcar(vec, Data)
            %% Args:            
            %      vec double, has 1 Hz sampling
            %      Data struct
            %  Returns:
            %      vec double, sampled at opts.Data.timesMid

            arguments
                vec double 
                Data struct = []
            end      
            if isempty(Data)
                return
            end
            timesMid = Data.timesMid;
            taus = Data.taus;
            times0 = timesMid - taus/2;
            timesF = timesMid + taus/2;

            vec_sampled = NaN(1, length(timesMid));
            for vi = 1:length(timesMid)
                s = times0(vi) + 1;
                s1 = min(timesF(vi), length(vec));
                vec_sampled(vi) = mean(vec(s:s1));
            end
            vec = vec_sampled;
        end
        function loss = loss_function(ks, Data, ~, times_sampled, measurement)
            import mlsiemens.BoxcarModel.sampled
            
            estimation = sampled(ks, Data, [], times_sampled); 
            measurement_norm = measurement/max(measurement); % \in [0 1] 
            denergy = abs(estimation - measurement_norm);
            kT = 0.5*mean(estimation) + 0.5*mean(measurement_norm);
            loss = mean(denergy)/kT;            
            %positive = measurement_norm > 0.01;
            %eoverm = estimation(positive)./measurement_norm(positive);            
            %loss = mean(abs(1 - eoverm));
        end
        function [qs,A_qs,qs_] = sampled(ks, Data, artery_interpolated, times_sampled)
            %% Returns:
            %      qs, the Bayesian estimate of the measured boxcar AIF, including baseline.
            %      qs_, the Bayesian estimate of the idealized AIF, scaled to unity.
            %      A_qs, providing the scaling factor lost to the boxcar.
            
            arguments
                ks {mustBeNumeric}
                Data struct
                artery_interpolated {mustBeNumeric} = []
                times_sampled {mustBeNumeric} = []
            end            
            
            amplitude = ks(11);
            qs_ = amplitude*mlsiemens.BoxcarModel.solution(ks, Data); % \in [0 1]
            qs = mlsiemens.BoxcarModel.apply_boxcar(qs_, Data); % 1 Hz sampling -> sampling of times_sampled
            A_qs = 1/max(qs); % amplitude lost to boxcar > 1

            if ~isempty(times_sampled)
                idx_sampled = round(Data.timesMid) + 1;
                qs_ = qs_(idx_sampled);
                return % using Data.timesMid
            else
                qs = interp1([0, Data.timesMid], [0, qs], 0:Data.timesMid(end));
            end
        end

        function qs = solution(ks, Data)
            %% @return the idealized true AIF without baseline, scaled to unity.
            
            N = Data.N;
            model_kind = Data.model_kind;
            import mlsiemens.BoxcarModel
            switch model_kind
                case '1bolus'
                    qs = BoxcarModel.solution_1bolus(ks, N, [], ks(3));
                case '2bolus'
                    qs = BoxcarModel.solution_2bolus(ks, N, [], ks(3));
                case '3bolus'
                    qs = BoxcarModel.solution_3bolus(ks, N, []);
                case '4bolus'
                    qs = BoxcarModel.solution_4bolus(ks, N, []);
                otherwise
                    error('mlaif:ValueError', ...
                        'BoxcarModel.solution.model_kind = %s', model_kind)
            end
        end
    end

    %% PROTECTED

    properties (Access = protected)
    end

    methods (Access = protected)
        function this = BoxcarModel(varargin)
            this = this@mlaif.ArteryLee2021Model(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
