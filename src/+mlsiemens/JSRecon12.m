classdef JSRecon12
    %% line1
    %  line2
    %  
    %  Created 17-Aug-2022 14:00:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.2009381 (R2022a) Update 4 for MACI64.  Copyright 2022 Judson Jones, John J. Lee.
    
    properties
        ParamsFile
        ParentFolder

        discontinuities % last time prior to discontinuity, in sec
        dt % sec
        window % sec
    end

    methods
        function call_sliding_dynamic(this, varargin)
            write_params_file(this)

        end
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
                    cmd = sprintf('!cscript C:\\JSRecon12\\JSRecon12.js %s %s', DataFolder, ipr.ParamsFile);
                    eval(cmd);
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

        function this = JSRecon12(varargin)
            %% JSRECON12 
            %  Args:
            %      ParentFolder (folder): contains folders of listmode + umap, e.g., PET_Raw_Data_0602
            %      ParamsFile (file): supercedes C:\\JSRecon12\JSRecon_params.txt
            
            ip = inputParser;
            addParameter(ip, 'ParentFolder', 'D:\\CCIR_01211\\cnda.wustl.edu\\108007', @isfolder);
            addParameter(ip, 'ParamsFile', 'C:\\JSRecon12\\JSRecon_params.txt', @isfile);
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.ParentFolder = ipr.ParentFolder;
            this.ParamsFile = ipr.ParamsFile;
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
