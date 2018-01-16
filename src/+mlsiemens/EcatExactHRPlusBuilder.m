classdef EcatExactHRPlusBuilder < mlpet.AbstractScannerBuilder
	%% ECATEXACTHRPLUSBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 16:34:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = EcatExactHRPlusBuilder(varargin)
 			%% ECATEXACTHRPLUSBUILDER
 			%  Usage:  this = EcatExactHRPlusBuilder()

 			this = this@mlpet.AbstractScannerBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

