classdef (Sealed) BiographVisionKit2 < handle & mlkinetics.ScannerKit
    %% is an extensible factory making using of the factory method pattern (cf. GoF pp. 90-91, 107). 
    %  
    %  Created 09-Jun-2022 13:53:36 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if isempty(uniqueInstance)
                this = mlsiemens.BiographVisionKit2();
                this.install_scanner(varargin{:});
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.install_scanner(varargin{:});
            end
        end
    end 

    methods
        function d = do_make_device(this)
            this.device_ = mlsiemens.BiographVisionDevice.create( ...
                bids_kit=this.bids_kit_, ...
                tracer_kit=this.tracer_kit_);
            d = this.device_;
        end
    end

    %% PROTECTED

    methods (Access = protected)
        function install_scanner(this, varargin)
            install_scanner@mlkinetics.ScannerKit(this, varargin{:});
        end
    end

    %% PRIVATE

    properties (Access = private)
    end

    methods (Access = private)
        function this = BiographVisionKit2()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
