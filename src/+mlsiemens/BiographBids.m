classdef (Abstract) BiographBids < handle & mlpipeline.Bids
	%% BIOGRAPHBIDS  

	%  $Revision$
 	%  was created 13-Nov-2021 14:57:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlvg/src/+mlvg.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.

    properties (Abstract)
        flair_toglob
        pet_dyn_toglob
        pet_static_toglob
        t1w_toglob
        t2w_toglob
        tof_toglob
    end

    %%

    methods
        function this = BiographBids(varargin)
            %  Args:
            %      destinationPath (folder): will receive outputs.  Must specify project ID & subject ID.
            %      projectPath (folder): belongs to a CCIR project.  
            %      subjectFolder (text): is the BIDS-adherent string for subject identity.
            %      sessionFolder (text): is the BIDS-adherent string for session identity.

            this = this@mlpipeline.Bids(varargin{:});
        end
        function [s,r] = build_dlicv(~, t1w, dlicv)
            %% nvidia-docker run -it -v $(pwd):/data --rm jjleewustledu/deepmrseg_image:20220615 --task dlicv --inImg fileprefix.nii.gz --outImg fileprefix_DLICV.nii.gz
            image = 'jjleewustledu/deepmrseg_image:20220615';
            cmd = sprintf('nvidia-docker run -it -v %s:/data --rm %s --task dlicv --inImg %s --outImg %s', ...
                t1w.filepath, image, t1w.fqfn, dlicv.fqfn);
            [s,r] = mlbash(cmd);
        end
        function [s,r] = build_orientstd(this, varargin)
            %  Args:
            %      patt (text): e.g., this.t1w_toglob ~ fullfile(this.sourceAnatPath, 'sub-*_T1w_MPR_vNav_4e_RMS.nii.gz')

            ip = inputParser;
            addOptional(ip, 'patt', this.t1w_toglob, @istext)
            addOptional(ip, 'destination_path', this.anatPath, @isfolder)
            parse(ip, varargin{:});
            ipr = ip.Results;

            for g = glob(ipr.patt)
                [~,fp] = myfileparts(g{end});
                fqfn = fullfile(ipr.destination_path, strcat(fp, '_orient-std.nii.gz'));
                ensuredir(strrep(myfileparts(g{1}), 'sourcedata', 'derivatives'));
                cmd = sprintf('fslreorient2std %s %s', g{1}, fqfn);
                [s,r] = mlbash(cmd);
                ic = mlfourd.ImagingContext2(fqfn);
                ic.selectNiftiTool();
                ic.save();
            end
        end
        function [s,r] = build_robustfov(this, varargin)
            %  Args:
            %      patt (text): e.g., this.t1w_toglob ~ fullfile(this.sourceAnatPath, 'sub-*_T1w_MPR_vNav_4e_RMS.nii.gz')

            ip = inputParser;
            addOptional(ip, 'patt', this.t1w_toglob, @istext)
            addOptional(ip, 'destination_path', this.anatPath, @isfolder)
            parse(ip, varargin{:});
            ipr = ip.Results;

            for g = glob(ipr.patt)
                [~,fp] = myfileparts(g{end});
                fqfp = fullfile(ipr.destination_path, fp);
                cmd = sprintf('robustfov -i %s -r %s_robustfov.nii.gz -m %s_robustfov.mat', g{1}, fqfp, fqfp);
                [s,r] = mlbash(cmd);
            end
        end
        function ic = flirt_dyn_to_t1w(this, dyn, t1w, opts)
            %% FLIRT_DYN_TO_T1W time-averages dyn to static PET (as needed),
            %  saves the static, then forwards the static to flirt_static_to_t1w().
            %  Input:
            %      dyn {mustBeNonempty}  % understood by mlfourd.ImagingContext2
            %      t1w {mustBeNonempty}  % "
            %      opts.taus double = [] % provided to ImagingContext2.timeAveraged(taus=opts.taus)
            %  Output:
            %      ic mlfourd.ImagingContext2

            arguments %(Input)
                this mlsiemens.BiographBids
                dyn {mustBeNonempty}
                t1w {mustBeNonempty}
                opts.taus double = []
            end
            %arguments (Output)
            %     ic mlfourd.ImagingContext2
            %end
            dyn = mlfourd.ImagingContext2(dyn); % ensures copy
            t1w = mlfourd.ImagingContext2(t1w); % "
            assert(isfile(dyn))

            isdyn = 4 == length(size(dyn));
            if isdyn
                if isempty(opts.taus)
                    opts.taus = 1:size(dyn, 4);
                end
                static = dyn.timeAveraged(taus=opts.taus);
            end
            static.save();
            ic = this.flirt_static_to_t1w(static, t1w);
        end
        function ic = flirt_static_to_t1w(this, static, t1w)
            %% FLIRT_STATIC_TO_T1W flirts static PET to t1w, preferably high-quality MPRAGE.
            %  Attempts to update json with flirted cost_final.
            %  Input:
            %      static {mustBeNonempty}  % understood by mlfourd.ImagingContext2
            %      t1w {mustBeNonempty}  % "
            %  Output:
            %      ic mlfourd.ImagingContext2

            arguments % (Input)
                this mlsiemens.BiographBids
                static {mustBeNonempty}
                t1w {mustBeNonempty}
            end
            %arguments (Output)
            %     ic mlfourd.ImagingContext2
            %end
            static = mlfourd.ImagingContext2(static); % ensures copy
            t1w = mlfourd.ImagingContext2(t1w);       % "
            assert(isfile(static))
            assert(isfile(t1w))
            
            ic = mlfourd.ImagingContext2(this.on(static, t1w));
            flirted = mlfsl.Flirt( ...
                'in', static.fqniigz, ...
                'ref', t1w.fqniigz, ...
                'out', ic.fqniigz, ...
                'omat', ic.fqmat, ...
                'bins', 256, ...
                'cost', 'mutualinfo', ...
                'dof', 6, ...
                'searchrx', 180, ...
                'interp', 'trilinear');
            flirted.flirt();

            try
                j0 = fileread(static.fqjson);
                [~,j1] = flirted.cost_final();
                jsonrecode(ic, j0, j1);
            catch
            end
        end
        function f = fqon(~, a, b)
            a = mlfourd.ImagingContext2(a);
            b = mlfourd.ImagingContext2(b);
            if endsWith(b.fileprefix, 't1w', IgnoreCase=true)
                f = strcat(a.fqfp, '_on_T1w', a.filesuffix);
                return
            end
            if endsWith(b.fileprefix, 't2w', IgnoreCase=true)
                f = strcat(a.fqfp, '_on_T2w', a.filesuffix);
                return
            end
            if contains(b.fileprefix, 'flair', IgnoreCase=true)
                f = strcat(a.fqfp, '_on_flair', a.filesuffix);
                return
            end
            if contains(b.fileprefix, 'tof', IgnoreCase=true)
                f = strcat(a.fqfp, '_on_tof', a.filesuffix);
                return
            end

            f = strcat(a.fqfp, '_on_', b.fileprefix, a.filesuffix);
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function that = copyElement(this)
            that = copyElement@matlab.mixin.Copyable(this);
            if ~isempty(this.atlas_ic_)
                that.atlas_ic_ = copy(this.atlas_ic_);
            end
            if ~isempty(this.dlicv_ic_)
                that.dlicv_ic_ = copy(this.dlicv_ic_);
            end
            if ~isempty(this.flair_ic_)
                that.flair_ic_ = copy(this.flair_ic_);
            end
            if ~isempty(this.T1_ic_)
                that.T1_ic_ = copy(this.T1_ic_);
            end
            if ~isempty(this.t1w_ic_)
                that.t1w_ic_ = copy(this.t1w_ic_);
            end
            if ~isempty(this.t2w_ic_)
                that.t2w_ic_ = copy(this.t2w_ic_);
            end
            if ~isempty(this.tof_ic_)
                that.tof_ic_ = copy(this.tof_ic_);
            end
            if ~isempty(this.wmparc_ic_)
                that.wmparc_ic_ = copy(this.wmparc_ic_);
            end
        end
    end

    properties (Access = protected)
        atlas_ic_
        dlicv_ic_
        flair_ic_
        T1_ic_
        T1_on_t1w_ic_
        t1w_ic_
        t2w_ic_
        tof_ic_
        tof_on_t1w_ic_
        wmparc_ic_
        wmparc_on_t1w_ic_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

