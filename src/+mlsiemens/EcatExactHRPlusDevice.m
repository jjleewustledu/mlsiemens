classdef EcatExactHRPlusDevice < handle & mlpet.Instrument
	%% ECATEXACTHRPLUSDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = EcatExactHRPlusDevice(varargin)
 			%% ECATEXACTHRPLUSDEVICE
 			%  @param .

 			this = this@mlpet.Instrument(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

