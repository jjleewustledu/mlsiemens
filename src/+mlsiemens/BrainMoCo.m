classdef BrainMoCo < handle
    %% builds PET imaging with JSRecon12 & e7 & Inki Hong's BrainMotionCorrection
    %  
    %  Created 03-Jan-2023 01:19:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function check_env(this)
            assert(strcmpi('PCWIN64', computer), ...
                'mlsiemens.BrainMoCo requires e7 on PC Windows')
            assert(isfolder(fullfile('C:', 'JSRecon12', 'BrainMotionCorrection')))
            assert(isfolder(fullfile('C:', 'Inki')))
        end
        function this = call(this)
            
        end
        function this = BrainMoCo(dtor, opts)
            %% BRAINMOCO 
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
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
