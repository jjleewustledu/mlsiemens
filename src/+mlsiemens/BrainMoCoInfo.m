classdef BrainMoCoInfo < handle & mlsystem.IHandle
    %% prepares info for use by BrainMoCoBuilder.
    %  
    %  Created 11-Oct-2025 14:30:20 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 24.2.0.2923080 (R2024b) Update 6 for MACA64.  Copyright 2025 John J. Lee.
    

    properties
        sub_id
        mri_home
        parc_home
        lm_home
    end

    properties (Dependent)
    end

    methods
        function this = BrainMoCoInfo(opts)
            arguments
                opts.sub_id string {mustBeNonempty}
                opts.mri_home {mustBeFolder} = "/data/nil-bluearc/vlassenko/Pipeline/Projects/MRI/Participants"
                opts.parc_home {mustBeFolder} = "/data/nil-bluearc/vlassenko/Pipeline/Projects/PET/InProcess"
                opts.lm_home {mustBeFolder} = "/vgpool02/data2/listmode/vision"
            end

            this.sub_id = opts.sub_id;
            this.mri_home = opts.mri_home;
            this.parc_home = opts.parc_home;
            this.lm_home = opts.lm_home;
        end

        function T = table(this)
            if ~isempty(this.table_)
                T = this.table_;
                return
            end

            % construct the table
            subs_pet = this.sub_id;
            PET_ID = mglob(fullfile(this.parc_home, sprintf("*%s*/", subs_pet)));
            PET_ID = mybasename(this.latest_folder(PET_ID));
            MRI_ID = mglob(fullfile(this.mri_home, sprintf("*%s*/", subs_pet)));
            MRI_ID = mybasename(this.latest_folder(MRI_ID));
            T1_PATH = mglob(fullfile( ...
                this.mri_home, MRI_ID, "Anatomical", "Volume", "T1", ...
                MRI_ID + "_T1.nii.gz"));
            if isempty(T1_PATH)
                T1_PATH = "";
            end
            if ~isfile(T1_PATH)
                warning("mlsiemens:IOError", "%s: could not find %s", stackstr(), T1_PATH)
            end
            PARCEL_PATH = fullfile( ...
                this.parc_home, PET_ID, "PET", "Parcellations", ...
                "Jeremy_DTI+Schaeffer", "Jeremy_DTI+Schaeffer.nii.gz");
            if isempty(PARCEL_PATH)
                PARCEL_PATH = "";
            end
            if ~isfile(PARCEL_PATH)
                warning("mlsiemens:IOError", "%s: could not find %s", stackstr(), PARCEL_PATH)
            end
            PARCEL_PATH_0 = fullfile( ...
                this.parc_home, PET_ID, "PET", "Parcellations", ...
                "Schaefer2018_200Parcels_7Networks_order", "Schaefer2018_200Parcels_7Networks_order_T1.nii.gz");
            if isempty(PARCEL_PATH_0)
                PARCEL_PATH_0 = "";
            end
            if ~isfile(PARCEL_PATH_0)
                warning("mlsiemens:IOError", "%s: could not find %s", stackstr(), PARCEL_PATH_0)
            end

            T = table(subs_pet, PET_ID, MRI_ID, T1_PATH, PARCEL_PATH, PARCEL_PATH_0);
            this.table_ = T;
        end
    end

    %% PRIVATE

    properties (Access = private)
        table_
    end

    methods (Access = private)
        function latest = latest_file(~, files)
            dts = file_datetime(files);
            [~,ordering] = sort(dts);
            [~,select] = max(ordering);
            latest = files(select);
        end
        function latest = latest_folder(~, folds)
            dts = folder_datetime(folds);
            [~,ordering] = sort(dts);
            [~,select] = max(ordering);
            latest = folds(select);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
