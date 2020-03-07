classdef EcatExactHRPlusKit < handle & mlpet.ScannerKit
	%% ECATEXACTHRPLUSKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 16:09:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function obj = createReferenceSources() 
            %% reference for the device from calibration phantom
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createRadMeasurements() 
            %% manually curated data spreadsheets
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createDevice() 
            %% scanner
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createDeviceCalibration()
            %% calibration by phantom
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createDeviceData() 
            %% reconstructed, resolved
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createCalibratedDeviceData() 
            %% reconstructed, resolved, calibrated
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
        function obj = createCalibratedAif()
            %% from cross-calibration
            
            error('mlsiemens:NotImplementedError', 'EcatExactHRPlusKit')
        end
    end
    
	methods 
		  
 		function this = EcatExactHRPlusKit(varargin)
 			%% ECATEXACTHRPLUSKIT
 			%  @param .

 			this = this@mlpet.ScannerKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

