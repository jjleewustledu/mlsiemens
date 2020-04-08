classdef BiographMMRDevice < handle & mlsiemens.BiographDevice
	%% BIOGRAPHMMRDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties 		
 	end
    
    methods (Static)
        function this = createFromSession(varargin)
            this = mlsiemens.BiographMMRDevice( ...
                'calibration', mlsiemens.BiographCalibration.createFromSession(varargin{:}), ...
                'data', mlsiemens.BiographMMRData.createFromSession(varargin{:}));
        end
        function ie = invEfficiencyf(sesd)
            this = mlsiemens.BiographMMRDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end

	methods 		  
 		function this = BiographMMRDevice(varargin)
 			%% BIOGRAPHMMRDEVICE
            
 			this = this@mlsiemens.BiographDevice(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
