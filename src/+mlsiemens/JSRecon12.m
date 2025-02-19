classdef JSRecon12 < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 17-Aug-2022 14:00:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.2009381 (R2022a) Update 4 for MACI64.  Copyright 2022 Judson Jones, John J. Lee.
    
    properties
        ListmodeFolder
        ParamsFile
        ParentFolder
        UmapFolder
        
        bin_version_folder = 'bin.win64-VG80'
        discontinuities % last time prior to discontinuity, in sec
        dt % sec
        jsrecon12_js
        scanner
        tracer
        window % sec
    end

    properties (Dependent)
        DataFolder
    end

    methods %% GET
        function g = get.DataFolder(this)
            g = fullfile(this.ParentFolder, this.tracer);
        end
    end

    methods
        function call(this, varargin)
            %% CALL:  generic call for running JSRecon
            %
            %  makes use of JSRecon structure 
            %  and the looping thru each PET Raw Data 
            %  with the same variables defined for each
            %  like: ParentFolder and DataFolder
            %
            %  write other scripts that use these variables
            %  and do your customized processing
            %
            %  9.15.16 - orginal, runs JSRecon batch files, ch
            %  3.7.17 - make generic, ch
            %  6.30.17 - make more generic for Judson to distribute, ch
            %
            %  Args:
            %      ParentFolder (folder): contains folders of listmode & umap, e.g., 'PET_Raw_Data_0602'
            %      ForceJSRecon (logical): force redo of JSRecon, even if already done
            %      ParamsFile (file): supercedes C:\\JSRecon12\JSRecon_params.txt
                        
            ip = inputParser;
            addParameter(ip, 'ParentFolder', this.ParentFolder, @isfolder);
            addParameter(ip, 'ForceJSRecon', false, @islogical);
            addParameter(ip, 'ParamsFile', this.ParamsFile, @isfile);
            parse(ip, varargin{:});
            ipr = ip.Results;
            this.ParentFolder = ipr.ParentFolder;

            %% folder of patient data folders
            
            % each folder in parent folder 
            % has one set of JSRecon data in the expected format
            cd(this.ParentFolder);
            fprintf('moved to patient scans folder: %s\n',pwd);
            
            %% capture all patient scan folders that can be processed
            
            folders = dir('*');
            ndx2 = 0;
            for ScanIndex=3:length(folders)  % skip . and .. folders
                fn = folders(ScanIndex).name;
                % JSRecon makes files '*-Converted', don't count those
                if ~contains(fn, 'Converted') && folders(ScanIndex).isdir
                    ndx2 = ndx2+1;
                    folder{ndx2} = fn; %#ok<AGROW> 
                end
            end
            fprintf('found %d JSRecon folders\n',length(folder));
            for ScanIndex=1:length(folder)  
                DataFolder = folder{ScanIndex};
                fprintf('[%2d]: %s\n',ScanIndex,DataFolder);
            end
            
            %% select which cardiac scans to process
            
            % array of which scans to run, 0 = all
            Scans2Process = 4; 
            %clc
            
            if Scans2Process==0
                Scans2Process = 1:length(folder);
            end
            fprintf('process these folders:\n');
            for ScanIndex=Scans2Process  
                DataFolder = folder{ScanIndex};
                fprintf('[%2d]: %s\n',ScanIndex,DataFolder);
            end
            
            %% JSRecon processing
            clc
            
            for ScanIndex=Scans2Process
                
                cd(this.ParentFolder);
                DataFolder = folder{ScanIndex};
                fprintf('[%2d]: %s\n',ScanIndex,DataFolder);
               
                % run JSRecon unless already run
                fdrconv = sprintf('%s-Converted',DataFolder);
                files = dir(fdrconv);
                if isempty(files) || ipr.ForceJSRecon
                    mlsiemens.JSRecon12.cscript_jsrecon12(DataFolder, ipr.ParamsFile);
                else
                    fprintf('JSRecon already done...\n');
                end
                
            end
            
            %% generic processing
            
            COMPLETED = zeros(size(Scans2Process));
            for ScanIndex=Scans2Process
                   
                % move to listmode folder for processing
                cd(this.ParentFolder);
                DataFolder = folder{ScanIndex};
                fprintf('[%2d]: %s\n',ScanIndex,DataFolder);    
                fdrconv = sprintf('%s\\%s-Converted',this.ParentFolder,DataFolder);
                fdrlist = sprintf('%s\\%s-LM-00',fdrconv,DataFolder);
                %fdrumap = sprintf('%s\\UMapSeries',fdrconv);
                %fdrraw = sprintf('%s\\%s',this.ParentFolder,DataFolder);
                try
                    % move to the desired folder, ie the listmode folder
                    cd(fdrlist);
                catch
                    fprintf('no listmode folder for %s\n',DataFolder);
                    continue;
                end
                    
                %% skip so can select processing
                
                %fprintf('skip processing\n');
                %continue;
                
                %% scripted processing
                
                try       
                    
                    %% histogramming listmode to frames specified in JSRecon
                    
                    file = dir('Run*Histogramming.bat');
                    cmd = sprintf('!%s',file.name);
                    fprintf('%s\n',cmd);
                    tic; eval(cmd); toc
            
                    %% make mumaps from CT
                    
                    file = dir('Run*Makeumap.bat');
                    cmd = sprintf('!%s',file.name);
                    fprintf('%s\n',cmd);
                    tic; eval(cmd); toc
            
                    %% recon processing
                    
                    file = dir('Run*OPTOF.bat');
                    cmd = sprintf('!%s',file.name);
                    fprintf('%s\n',cmd);
                    tic; eval(cmd); toc
                                        
                    %% dicom writing
                    
                    file = dir('Run*IF2Dicom.bat');
                    cmd = sprintf('!%s',file.name);
                    fprintf('%s\n',cmd);
                    tic; eval(cmd); toc

                    %% show as completed
                    
                    %pause;
                    %close all;        
                    COMPLETED(ScanIndex) = 1;
                            
                catch
                    fprintf('failed to complete scan %d\n',ScanIndex);
                    %pause;
                    %close all; 
                end 
                
            end
            
            fprintf('COMPLETED RECON for %d of %d scans\n', ...
                sum(COMPLETED),length(Scans2Process));
            fprintf('JSReconScript.m completed\n');
        end
        function check_env(this)
            assert(strcmpi('PCWIN64', computer), ...
                'mlsiemens.JSRecon12 requires e7 on PC Windows')
            assert(isfolder(fullfile('C:', 'JSRecon12')))
            assert(isfolder(fullfile('C:', 'Service')))
            assert(isfolder(fullfile('C:', 'Siemens', 'PET', this.bin_version_folder)))
        end
        function this = JSRecon12(dtor, opts)
            %% JSRECON12 
            %  Args:
            %  dtor = []
            %  opts.ListmodeFolder {mustBeTextScalar} = ""
            %  opts.ParentFolder {mustBeFolder} = "D:\MyProject\+Input\sub-id\ses-id"
            %  opts.ParamsFile {mustBeFiles} = "C:\JSRecon12\JSRecon_params.txt"
            %  opts.scanner {mustBeTextScalar} = "vision"
            %  opts.tracer {mustBeTextScalar} = "fdg"
            %  opts.UmapFolder {mustBeTextScalar} = ""
            
            arguments
                dtor = []
                opts.ListmodeFolder {mustBeTextScalar} = ""
                opts.ParentFolder {mustBeFolder} = "D:\MyBMCProject\+Input\sub-108293\ses-20210421"
                opts.ParamsFile {mustBeFiles} = "C:\JSRecon12\JSRecon_params.txt"
                opts.scanner {mustBeTextScalar} = "vision"
                opts.tracer {mustBeTextScalar} = "fdg"
                opts.UmapFolder {mustBeTextScalar} = ""
            end
            
            this.director_ = dtor;
            this.jsrecon12_js = "C:\JSRecon12\JSRecon12.js";
            this.ParentFolder = opts.ParentFolder;
            if "" ~= opts.tracer
                this.ParamsFile = fullfile("D:", sprintf("params_%s_%s.txt", opts.scanner, opts.tracer));
            else
                this.ParamsFile = opts.ParamsFile;
            end
            this.scanner = opts.scanner;
            this.tracer = opts.tracer;
        end
    end

    methods (Static)
        function [s,r] = cscript(js, args, opts)
            arguments
                js string {mustBeTextScalar}
                args string {mustBeText}
                opts.do_logging logical = false
                opts.log_file {mustBeTextScalar} = fullfile("D:", stackstr() + ".log")
            end
            suffix = "";
            if opts.do_logging
                suffix = ">> " + opts.log_file;
            end
            switch length(args)
                case 1                    
                    cmd = sprintf("cscript /E:JScript %s %s %s", js, args(1), suffix);
                case 2
                    cmd = sprintf("cscript /E:JScript %s %s %s %s", js, args(1), args(2), suffix);
                otherwise
                    error("mlraut:ValueError", stackstr());
            end
            [s,r] = mysystem(cmd);
        end
        function [s,r] = cscript_jsrecon12(data_folder, params_file)
            arguments
                data_folder {mustBeFolder}
                params_file {mustBeFile}
            end
            js = fullfile("C:", "JSRecon12", "JSRecon12.js");
            [s,r] = mlsiemens.JSRecon12.cscript(js, [data_folder, params_file]);
        end
        function [s,r] = cscript_staticrecon(data_folder)
            arguments
                data_folder {mustBeFolder}
            end
            js = fullfile("C:", "JSRecon12", "StaticRecon", "StaticRecon.js");
            [s,r] = mlsiemens.JSRecon12.cscript(js, data_folder);
        end
    end

    %% PROTECTED

    properties (Access = protected)
        director_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
