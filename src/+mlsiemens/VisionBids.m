classdef (Abstract) VisionBids < handle & mlpipeline.Bids
	%% VISIONBIDS  

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

    properties (Dependent)
        atlas_ic
        dlicv_ic
        flair_ic
        T1_ic % FreeSurfer
        t1w_ic
        t2w_ic
        tof_ic
        tof_on_t1w_ic
        wmparc_ic % FreeSurfer
    end

	methods

        %% GET

        function g = get.atlas_ic(~)
            g = mlfourd.ImagingContext2( ...
                fullfile(getenv('FSLDIR'), 'data', 'standard', 'MNI_T1_1mm.nii.gz'));
        end
        function g = get.dlicv_ic(this)
            if ~isempty(this.dlicv_ic_)
                g = copy(this.dlicv_ic_);
                return
            end
            this.dlicv_ic_ = mlfourd.ImagingContext2( ...
                sprintf('%s_DLICV.nii.gz', this.t1w_ic.fqfileprefix));
            if ~isfile(this.dlicv_ic_.fqfn)
                try
                    r = '';
                    [~,r] = this.build_dlicv(this.t1w_ic, this.dlicv_ic_);
                    assert(isfile(this.dlicv_ic_))
                catch ME
                    disp(r)
                    handexcept(ME)
                end
            end
            g = copy(this.dlicv_ic_);
        end
        function g = get.flair_ic(this)
            if ~isempty(this.flair_ic_)
                g = copy(this.flair_ic_);
                return
            end
            globbed = globT(this.flair_toglob);
            fn = globbed{end};
            assert(isfile(fn))
            this.flair_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.flair_ic_);
        end
        function g = get.T1_ic(this)
            if ~isempty(this.T1_ic_)
                g = copy(this.T1_ic_);
                return
            end
            fn = fullfile(this.mriPath, 'T1.mgz');
            assert(isfile(fn))
            this.T1_ic_ = mlfourd.ImagingContext2(fn);
            this.T1_ic_.selectNiftiTool();
            this.T1_ic_.filepath = this.anatPath;
            this.T1_ic_.save();
            g = copy(this.T1_ic_);
        end
        function g = get.t1w_ic(this)
            if ~isempty(this.t1w_ic_)
                g = copy(this.t1w_ic_);
                return
            end
            globbed = globT(this.t1w_toglob);
            fn = globbed{end};
            %assert(isfile(fn))
            fn = fullfile(this.anatPath, strcat(mybasename(fn), '_orient-std.nii.gz'));
            if ~isfile(fn)
                this.build_orientstd(this.t1w_toglob);
            end
            this.t1w_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.t1w_ic_);
        end
        function g = get.t2w_ic(this)
            if ~isempty(this.t2w_ic_)
                g = copy(this.t2w_ic_);
                return
            end
            globbed = globT(this.t2w_toglob);
            fn = globbed{end};
            assert(isfile(fn))
            this.t2w_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.t2w_ic_);
        end
        function g = get.tof_ic(this)
            if ~isempty(this.tof_ic_)
                g = copy(this.tof_ic_);
                return
            end
            globbed = globT(this.tof_toglob);
            fn = globbed{end};
            %assert(isfile(fn))
            fn = fullfile(this.anatPath, strcat(mybasename(fn), '_orient-std.nii.gz'));
            if ~isfile(fn)
                this.build_orientstd(this.tof_toglob);
            end
            this.tof_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.tof_ic_);
        end
        function g = get.tof_on_t1w_ic(this)
            if ~isempty(this.tof_on_t1w_ic_)
                g = copy(this.tof_on_t1w_ic_);
                return
            end
            fn = strcat(this.tof_ic.fqfp, '_on_T1w.nii.gz');
            if isfile(fn)
                this.tof_on_t1w_ic_ = mlfourd.ImagingContext2(fn);
                g = copy(this.tof_on_t1w_ic_);
                return
            end
            f = mlfsl.Flirt( ...
                'in', this.tof_ic.fqfn, ...
                'ref', this.t1w_ic.fqfn, ...
                'out', fn, ...
                'noclobber', true);
            f.flirt();
            this.tof_on_t1w_ic_ = mlfourd.ImagingContext2(fn);
            g = copy(this.tof_on_t1w_ic_);
        end
        function g = get.wmparc_ic(this)
            if ~isempty(this.wmparc_ic_)
                g = copy(this.wmparc_ic_);
                return
            end
            fn = fullfile(this.mriPath, 'wmparc.mgz');
            assert(isfile(fn))
            this.wmparc_ic_ = mlfourd.ImagingContext2(fn);
            this.wmparc_ic_.selectNiftiTool();
            this.wmparc_ic_.filepath = this.anatPath;
            this.wmparc_ic_.save();
            g = copy(this.wmparc_ic_);
        end

        %%

        function this = VisionBids(varargin)
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

            ic = [];
            for g = glob(ipr.patt)

                ensuredir(ipr.destination_path);
                ic = mlfourd.ImagingContext2(g{1});
                ic.afni_3dresample(orient_std=true);
                if ~strcmp(ipr.destination_path, ic.filepath)
                    movefile(ic.fqfileprefix + ".*", ipr.destination_path);
                end
            end
            s = [];
            r = "";
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

    %% PRIVATE

    properties (Access = private)
        atlas_ic_
        dlicv_ic_
        flair_ic_
        T1_ic_
        t1w_ic_
        t2w_ic_
        tof_ic_
        tof_on_t1w_ic_
        wmparc_ic_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

