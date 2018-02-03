classdef CalibrationBuilder < mlpet.ICalibrationBuilder
	%% CALIBRATIONBUILDER  

	%  $Revision$
 	%  was created 09-Jan-2018 16:43:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties 		
        consoleClockOffset
        doseAdminDatetime
        invEfficiency
    end
    
    properties (Dependent)
        product
    end

	methods 
        function this = buildCounts(this)
        end
        function this = buildSpecificActivity(this)
            import mlswisstrace.*;
            twil = Twilite( ...
                'fqfilename', '', ...
                'sessionData', this.sessionData_, ...
                'scannerData', this.scannerData_, ...
                'doseAdminDatetime', this.doseAdminDatetime_);
            twilCal = TwiliteCalibration( ...
                'fqfilename', '', ...
                'sessionData', this.sessionData_, ...
                'scannerData', this.scannerData_, ...
                'doseAdminDatetime', this.doseAdminDatetime_);
            specEff = this.manMeasures_.phantomSpecificActivity / ...
                      twilCal.coincidenceAtDatetime(this.manMeasures_.phantomDatetime);
            this.product_ = twil.coincidence * specEff;
        end
		  
 		function this = CalibrationBuilder(varargin)
 			%% CALIBRATIONBUILDER
            %  @param named manMeasures is an mldata.IManualMeasurements.
            
            
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        doseAdminDatetime_
        manMeasures_
        product_
        scannerData_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

