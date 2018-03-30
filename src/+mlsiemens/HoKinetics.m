classdef HoKinetics < mlkinetics.AbstractHoKinetics
	%% HOKINETICS  

	%  $Revision$
 	%  was created 18-Jul-2017 01:17:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = HoKinetics(varargin)
 			%% HOKINETICS
 			%  Usage:  this = HoKinetics()

 			this = this@mlkinetics.AbstractHoKinetics(varargin{:});
            
            this.scanData_ = mlsiemens.ScanData('sessionData', this.sessionData);
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

