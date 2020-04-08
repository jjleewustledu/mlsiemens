classdef EcatExactHRPlusDevice < handle & mlpet.AbstractDevice
	%% ECATEXACTHRPLUSDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		calibrationAvailable
 	end
    
    methods (Static)
        function this = createFromSession(varargin)
        end        
        function ie = invEfficiencyf(sesd)
        end
    end

	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(this)
        end
        
        %%        
        
        function a = activity(this, varargin)
        end        
        function a = activityDensity(this, varargin)
        end
        function c = countRate(this, varargin)
        end        
        function h = plot(this, varargin)
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)		  
 		function this = EcatExactHRPlusDevice(varargin)
 			%% ECATEXACTHRPLUSDEVICE
 			%  @param .

 			this = this@mlpet.AbstractDevice(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

