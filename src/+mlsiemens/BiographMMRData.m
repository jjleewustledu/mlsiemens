classdef BiographMMRData < handle & mlpet.AbstractTracerData
	%% BIOGRAPHMMRDATA  

	%  $Revision$
 	%  was created 17-Oct-2018 15:57:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = BiographMMRData(varargin)
 			%% BIOGRAPHMMRDATA
 			%  @param .

 			this = this@mlpet.AbstractTracerData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

