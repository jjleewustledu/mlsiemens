classdef EcatExactHRPlusKit < handle & mlpet.ScannerKit
	%% ECATEXACTHRPLUSKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 16:09:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent) 		
        sessionData
        radMeasurements
    end

    methods (Static)
        function this = createFromSession(varargin)
            this = mlsiemens.EcatExactHRPlusKit('sessionData', varargin{:});            
        end
    end
    
    methods
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.radMeasurements(this)
            g = mlpet.NNICURadMeasurements.createFromSession(this.sessionData);
        end
        
        %% 
        
        function g = buildScannerDevice(this)
            g = mlsiemens.EcatExactHRPlusDevice.createFromSession(this.sessionData);
        end
        function g = buildArterialSamplingDevice(this)
            g = mlpet.BloodSuckerDevice.createFromSession(this.sessionData);
        end
        function g = buildCountingDevice(this)
            g = mlpet.WellCounterDevice.createFromSession(this.sessionData);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
    end
    
	methods (Access = protected)		  
 		function this = EcatExactHRPlusKit(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            this.sessionData_ = ip.Results.sessionData;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

