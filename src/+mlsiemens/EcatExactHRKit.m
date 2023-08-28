classdef (Sealed) EcatExactHRKit < handle & mlkinetics.ScannerKit
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 13:54:58 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods (Static)
        function this = instance(varargin)
            persistent uniqueInstance
            if (isempty(uniqueInstance))
                this = mlsiemens.EcatExactHRKit();
                this.install_scanner(varargin{:});
                uniqueInstance = this;
            else
                this = uniqueInstance;
                this.install_scanner(varargin{:});
            end
        end
    end 

    %% PRIVATE

    methods (Access = private)
        function this = EcatExactHRKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
