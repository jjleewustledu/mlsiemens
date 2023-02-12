classdef JSReconBuilder < handle
    %% builds PET imaging with JSRecon12 & e7
    %  
    %  Created 07-Sep-2022 00:28:15 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.2039608 (R2022a) Update 5 for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        umapdir % single directory or cell array of directories
        lmdir % for listmode
    end

    properties (Dependent)
        dicomExt
        director
        hasBf
        hasPtd
        hasPtr
        rawdataDir
        studyFolder
        workdir

        study_builder
    end

    methods

        %% GET

        function g = get.dicomExt(this)
            g = this.study_builder.dicomExt;
        end
        function g = get.director(this)
            g = this.director_;
        end
        function g = get.hasBf(this)
            g = glob(fullfile(this.workdir, '**.bf'));
            g = ~isempty(g);
        end
        function g = get.hasPtd(this)
            g = glob(fullfile(this.workdir, '**.ptd'));
            g = ~isempty(g);
        end
        function g = get.hasPtr(this)
            g = glob(fullfile(this.workdir, '**.ptr'));
            g = ~isempty(g);
        end
        function g = get.rawdataDir(this)
            g = this.study_builder.rawdataDir;
        end
        function g = get.studyFolder(this)
            g = this.study_builder.studyFolder;
        end
        function g = get.workdir(this)
            g = this.workdir_;
        end

        function g = get.study_builder(this)
            g = this.director_.study_builder;
        end

        %% SET

        function set.director(this, s)
            assert(isa(s, 'mlsiemens.JSReconDirector'))
            this.director_ = s;
        end

        %% 

        function check_env(this)
            assert(strcmpi('PCWIN64', computer), ...
                'mlsiemens.JSReconBuilder requires e7 on PC Windows')
            assert(isfolder(fullfile('C:', 'Siemens', 'PET')))
        end
        function this = call(this)

            pwd0 = pushd(this.workdir);
            this.unpack_listmode();
            this.umapdir = this.find_AC_CT();
            this.lmdir = this.find_listmode();
            len_umapdir = length(this.umapdir);
            len_lmdir = length(this.lmdir);
            assert(len_umapdir == len_lmdir, ...
                'mlsiemens.JSReconBuilder:  len_umapdir->%i, len_lmdir->%i', len_umapdir, len_lmdir)
            
            % mv LM/ to rawdata/sub-dir/ses-dir/TRA_DTyyyymmddHHMMSS.000000/

            % cp umap/ to LM/umap/

            % mkdir & populate
            % rawdata/sub-dir/ses-dir/TRA_DTyyyymmddHHMMSS.000000-Converted-NAC/output/PET/single-frame

            % mkdir & populate
            % rawdata/sub-dir/ses-dir/TRA_DTyyyymmddHHMMSS.000000-Converted-AC/output/PET/single-frame

            % mkdir & populate
            % derivatives/sub-dir/resampling_restricted





            popd(pwd0);
        end
        function umapdir = find_AC_CT(this, varargin)
            g = glob(fullfile(this.workdir, ['**' this.dicomExt]))';
            dns = unique(cellfun(@(x) myfileparts(x), g, 'UniformOutput', false));

            % only one AC CT in workdir
            if 1 == length(dns) && this.dicom_is_AC_CT(dns{1})
                umapdir = dns{1};
                return
            end

            % multiple AC CT in workdir
            di = 1;
            for d = dns
                if this.dicom_is_AC_CT(d{1})
                    umapdir{di} = d{1}; %#ok<AGROW> 
                    di = di + 1;
                end
            end
        end              
        function lmdir = find_listmode(this, varargin)
            %  Returns:
            %      lmdir (folder|cell): containing listmode

            if this.hasBf
                g = glob(fullfile(this.workdir, '**.bf'))';                
            end
            if this.hasPtd
                g = glob(fullfile(this.workdir, '**.ptd'))';
            end
            lmdir = unique(cellfun(@(x) myfileparts(x), g, 'UniformOutput', false));
        end        
        function dns = unpack_dcm(this, workdir)
            %% Unpacks DICOMs from pwd, which must be the trunk of a filetree containing packed DICOMs.
            arguments
                this mlsiemens.JSReconBuilder
                workdir {mustBeFolder} = this.workdir
            end

            for z = glob(fullfile(workdir, '**.zip'))'
                outdir = this.unpacking_dir(workdir, mybasename(z{1}));
                ensuredir(outdir);
                pwd0 = pushd(outdir);
                try   
                    if ~contains(z{1}, 'cnda.wustl.edu')
                        continue
                    end
                    fns = unzip(z{1}, outdir);

                    select = contains(fns, '.dcm');
                    fns_dcm = fns(select);
                    dns = cellfun(@myfileparts, fns_dcm, UniformOutput=false);
                    dns = unique(dns);
                    if ~isempty(dns)
                        for d = asrow(dns)
                            mlpipeline.Bids.dcm2niix(d{1});
                        end
                    end   
                catch ME
                    handwarning(ME)
                end
                popd(pwd0);
            end
        end 
        function this = unpack_listmode(this, workdir)
            %% Unpacks listmode from pwd, which must be the trunk of a filetree containing packed listmode.
            %  ptd ~ e.g., 108007.PT.Head_CCIR_1211_FDG_(Adult).602.PET_LISTMODE.2021.02.23.14.04.04.508000.2.0.105550091.ptd
            %        PET_CALIBRATION
            %        PET_COUNTRATE
            %        PET_EM_SINO
            %        PET_LISTMODE
            %        PETCT_SPL
            %  ptr ~ e.g., 108007.CT.Head_CCIR_1211_FDG_(Adult).601.RAW.20210219.161010.182998.2021.02.23.14.04.09.523000.105588078.ptr

            arguments
                this mlsiemens.JSReconBuilder
                workdir {mustBeFolder} = this.workdir
            end

            for z = glob(fullfile(workdir, '**.zip'))'
                outdir = this.unpacking_dir(workdir, mybasename(z{1}));
                ensuredir(outdir);
                pwd0 = pushd(outdir);
                try          
                    if contains(z{1}, 'cnda.wustl.edu')
                        continue
                    end
                    fns = unzip(z{1}, outdir);

                    select_pt = contains(fns, {'.ptr' '.ptd'});
                    fns_pt = fns(select_pt);
                    if ~isempty(fns_pt)
                        movefiles(fns_pt, outdir);
                        dns = cellfun(@myfileparts, fns_pt, UniformOutput=false);
                        dns = this.sort_folders(dns);
                        for d = asrow(dns)
                            %rmdir(d{1}, 's');
                        end
                    end                    

                    select_bf = contains(fns, '.bf');
                    fns_bf = fns(select_bf);
                    if ~isempty(fns_bf)
                        select_bf_dcm = cellfun(@(x) mybasename(x), fns_bf, UniformOutput=false);
                        fns_bf_dcm = contains(fns, select_bf_dcm);

                        movefiles(fns_bf, outdir);
                        movefiles(fns_bf_dcm, outdir);
                        dns = cellfun(@myfileparts, fns_bf, UniformOutput=false);
                        dns = this.sort_folders(dns);
                        for d = asrow(dns)
                            %rmdir(d{1}, 's');
                        end
                    end
                catch ME
                    handwarning(ME)
                end
                popd(pwd0);
            end
        end
        function d = unpacking_dir(this, d0, tag)
            arguments
                this mlsiemens.JSReconBuilder %#ok<INUSA> 
                d0 {mustBeFolder} = pwd
                tag {mustBeTextScalar} = ''
            end

            try
                fold = 'unknown';
                if contains(tag, 'jjlee', IgnoreCase=true)
                    fold = 'cnda.wustl.edu';
                end
                if contains(tag, 'fdg', IgnoreCase=true)
                    fold = 'fdg';
                end
                if contains(tag, {'tp' 'o15' '15o' 'oo' 'co' 'oc'}, IgnoreCase=true)
                    fold = 'o15';
                end
                if contains(tag, 'pib', IgnoreCase=true)
                    fold = 'pib';
                end
                if contains(tag, {'av1451' 'flortaucipir' 'tau'}, IgnoreCase=true)
                    fold = 'av1451';
                end
                if contains(tag, {'av45' 'florbetapir' 'amyloid'}, IgnoreCase=true)
                    fold = 'av45';
                end
                if contains(tag, {'azan' 'asem' 'r01aa'}, IgnoreCase=true)
                    fold = 'aa';
                end
                if contains(tag, {'cal' 'phant'}, IgnoreCase=true)
                    fold = 'cal';
                end
                d = fullfile(d0, fold);
            catch ME
                handwarning(ME)
                d = d0;
            end
        end

        function this = JSReconBuilder(dtor, opts)
            %% JSRECONBUILDER 
            %  Args:
            %      dtor mlsiemens.JSReconDirector = []:  references objects including study_builder, workdir.
            %      opts.workdir {mustBeFolder} = pwd:  trunk of filetree containing packed listmode.
                        
            arguments
                dtor = []
                opts.workdir {mustBeFolder} = pwd
            end            
            this.director_ = dtor;
            this.workdir_ = opts.workdir;
        end
    end

    methods (Static) 
        function dns = sort_folders(dns, opts)
            arguments
                dns cell {mustBeNonempty}
                opts.ComparisonMethod {mustBeTextScalar} = 'depth'
            end
            dns = unique(dns);
            switch opts.ComparisonMethod
                case 'depth'
                    depth = cellfun(@(x) length(regexp(x, filesep)), dns);
                    [~,idx] = sort(depth, 'descend');
                    dns = dns(idx);
                otherwise
                    error('mlsiemens:ValueError', stackstr(2))
            end
        end
    end

    %% PROTECTED

    properties (Access = protected)
        director_
        workdir_
    end

    methods (Access = protected)
        function tf = dicom_is_AC_CT(this, folder_)
            g = glob(fullfile(folder_, ['*' this.dicomExt]))';
            info = dicominfo(g{1});
            tf = contains(info.SeriesDescription, 'AC') && ...
                contains(info.SeriesDescription, 'CT') && ...
                contains(info.ImageType, 'CT') && ...
                contains(info.Modality, 'CT');
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
