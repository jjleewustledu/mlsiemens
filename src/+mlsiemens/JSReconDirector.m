classdef JSReconDirector < handle
    %% line1
    %  line2
    %  
    %  Created 21-Nov-2022 12:28:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods
        function this = JSReconDirector(study_bldr, jsr_bldr)
            %% JSRECONDIRECTOR 
            %  Args:
            %      study_bldr {mustBeNonMissing}
            %      jsr_bldr mlsiemens.JSReconBuilder = mlsiemens.JSReconBuilder()
            
            arguments
                study_bldr {mustBeNonmissing}
                jsr_bldr mlsiemens.JSReconBuilder = mlsiemens.JSReconBuilder()
            end
            this.study_builder_ = study_bldr;
            this.jsr_builder_ = jsr_bldr;
            this.jsr_builder_.director = this;
        end
    end

    %% PRIVATE

    properties (Access = private)
        jsr_builder_
        study_builder_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end