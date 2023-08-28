classdef BrainMoCo < handle & mlsiemens.JSRecon12
    %% builds PET imaging with JSRecon12 & e7 & Inki Hong's BrainMotionCorrection
    %  
    %  Created 03-Jan-2023 01:19:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    properties
    end

    methods
        function this = BrainMoCo(dtor, opts)
            %% BRAINMOCO 
            %  Args:
            %  dtor mlsiemens.JSReconDirector = []:  references objects including study_builder, workdir.
            %  opts.workdir {mustBeFolder} = pwd:  trunk of filetree containing packed listmode.
            
            this = this@mlsiemens.JSRecon12(dtor, opts);
            if contains(this.ParentFolder, 'MyProject')
                this.ParentFolder = strrep(this.ParentFolder, 'MyProject', 'MyBMCProject');
            end
            this.jsrecon12_js = "C:\JSRecon12\BrainMotionCorrection\BMC.js";
        end
        function this = call(this)
        end
        function check_env(this)
            this.check_env@mlsiemens.JSRecon12();
            assert(isfolder(fullfile('C:', 'JSRecon12', 'BrainMotionCorrection')))
            assert(isfile(fullfile('C:', 'JSRecon12', 'BrainMotionCorrection', 'BMC.js')))
            assert(isfolder(fullfile('C:', 'Inki')))
            assert(isfile(fullfile('C:', 'Inki', 'coregister.exe')))
        end
    end

    methods (Static)
        function [ic_dyn,ic_static] = assemble_nifti(sub, ses, trc)
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
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
