classdef CalibrationBuilder < mlpet.ICalibrationBuilder
	%% CALIBRATIONBUILDER  

	%  $Revision$
 	%  was created 09-Jan-2018 16:43:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties 		
        consoleClockOffset
        doseAdminDatetime
        efficiencyFactor
 	end

	methods 
		  
 		function this = CalibrationBuilder(varargin)
 			%% CALIBRATIONBUILDER
 			%  Usage:  this = CalibrationBuilder()

 			this = this@mlpet.ICalibrationBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

