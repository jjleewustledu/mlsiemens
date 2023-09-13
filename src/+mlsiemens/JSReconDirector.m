classdef JSReconDirector < handle & mlsystem.IHandle
    %% line1
    %  line2
    %  
    %  Created 21-Nov-2022 12:28:26 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2105380 (R2022b) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties (Dependent)
        mediator
    end

    methods %% GET
        function g = get.mediator(this)
            if isempty(this.mediator_)
                this.mediator_ = this.bids_kit_.make_bids_med();
            end
            g = this.mediator_;
        end
    end

    methods
        function this = JSReconDirector(opts)
            %% JSRECONDIRECTOR 
            %  Args:
            %  opts.bids_kit 
            %  opts.jsr_bldr mlsiemens.JSReconBuilder = mlsiemens.JSReconBuilder()
            
            arguments
                opts.bids_kit = []
                opts.jsr_bldr = []
            end
            this.bids_kit_ = opts.bids_kit;
            this.jsr_builder_ = opts.jsr_bldr;
        end
    end

    %% PRIVATE

    properties (Access = private)
        jsr_builder_
        bids_kit_
        mediator_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
