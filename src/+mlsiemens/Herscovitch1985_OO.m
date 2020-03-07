classdef Herscovitch1985_OO < mlsiemens.Herscovitch1985_15O
	%% HERSCOVITCH1985_OO  

	%  $Revision$
 	%  was created 16-Jun-2018 15:33:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = Herscovitch1985_OO(varargin)
 			%% HERSCOVITCH1985_OO
 			%  @param .

 			this = this@mlsiemens.Herscovitch1985(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

