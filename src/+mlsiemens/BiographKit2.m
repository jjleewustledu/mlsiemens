classdef BiographKit2 < handle & mlkinetics.ScannerKit2
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 13:52:44 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    methods

        function dev = make_sampling_device(this)
        end
        function dev = make_counting_device(this)
        end
        function dat = make_rad_measurements(this)
            dat = mlpet.CCIRRadMeasurements.createFromSession(this.session);
        end

        function this = BiographKit2(varargin)
            %% BIOGRAPHKIT2 
            %  Args:
            %      arg1 (its_class): Description of arg1.
            
            this = this@mlkinetics.ScannerKit2(varargin{:})
            
            ip = inputParser;
            addParameter(ip, "arg1", [], @(x) false)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
