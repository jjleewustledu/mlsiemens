classdef BiographVisionDevice < handle & mlsiemens.BiographDevice
	%% BIOGRAPHVISIONDEVICE represents the Siemens Biograph 128 Vision 600 Edge scanner.

	%  $Revision$
 	%  was created 18-Mar-2020 15:16:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    methods (Static)
        function this = createFromSession(varargin)
            this = mlsiemens.BiographVisionDevice( ...
                'calibration', mlsiemens.BiographCalibration.createFromSession(varargin{:}), ...
                'data', mlsiemens.BiographVisionData.createFromSession(varargin{:}));
        end
        function ie = invEfficiencyf(sesd)
            this = mlsiemens.BiographVisionDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end
    
	properties (Constant)
        MAX_NORMAL_BACKGROUND = 20 % Bq/mL
 	end

	methods		  
 		function this = BiographVisionDevice(varargin)
 			this = this@mlsiemens.BiographDevice(varargin{:}); 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
