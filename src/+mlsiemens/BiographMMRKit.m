classdef BiographMMRKit < handle & mlpet.ScannerKit
	%% BIOGRAPHMMRKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 16:09:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
    end
    
    methods (Static)
        function obj = createReferenceSources() 
            %% reference for the device from calibration phantom
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
        function obj = createRadMeasurements(varargin) 
            %% Manually curated data spreadsheets.
            %  See also:  mlpet.CCIRRadMeasurements.createFromSession().
            
            obj = mlpet.CCIRRadMeasurements.createFromSession(varargin{:});
        end
        function obj = createDevice() 
            %% scanner
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
        function obj = createDeviceCalibration()
            %% calibration by phantom
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
        function obj = createDeviceData() 
            %% reconstructed, resolved
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
        function obj = createCalibratedDeviceData() 
            %% reconstructed, resolved, calibrated
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
        function obj = createCalibratedAif()
            %% from cross-calibration
            
            error('mlsiemens:NotImplementedError', 'BiographMMRKit')
        end
    end

	methods 
		  
 		function this = BiographMMRKit(varargin)
 			%% BIOGRAPHMMRKIT
 			%  @param .

 			this = this@mlpet.ScannerKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

