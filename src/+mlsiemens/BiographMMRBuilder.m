classdef BiographMMRBuilder < mlpet.AbstractScannerBuilder
	%% BIOGRAPHMMRBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 16:34:24 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = BiographMMRBuilder(varargin)
 			%% BIOGRAPHMMRBUILDER

 			this = this@mlpet.AbstractScannerBuilder(varargin{:});
            tracer = mlfourd.ImagingContext(this.sessionData.tracerResolvedFinal);
            tracer = tracer.niftid;
            tracer.viewer = 'fsleyes';
            tracer.view;
            
            this.scanner_ = mlsiemens.BiographMMR( ...
                tracer, ...
                'sessionData', this.sessionData_, ...
                'consoleClockOffset', this.calibrationBuilder.consoleClockOffset, ...
                'doseAdminDatetime', this.calibrationBuilder.doseAdminDatetime, ...
                'invEfficiency', this.calibrationBuilder.scannerEfficiencyFactor, ...
                'timingData', this.readTimingData);
            this.scanner_ = this.volumeContracted(this.roisBuilder_.mask) / this.roisBuilder_.mask.count;
 		end
        
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        scanner_
    end
    
    methods (Access = private)
        function td = readTimingData(this)
            td = mldata.TimingData( ...
                'times',         this.timingTable_{:,'Start_msec_'}/1000, ...
                'taus',          this.timingTable_{:,'Length_msec_'}/1000, ...
                'datetime0',     this.calibrationBuilder.datetime0);
        end           
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

