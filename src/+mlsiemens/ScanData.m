classdef ScanData < mlpipeline.ScanData
	%% SCANDATA  

	%  $Revision$
 	%  was created 18-Jul-2017 01:32:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods
		  
 		function this = ScanData(varargin)
 			%% SCANDATA requires this.sessionData.{tracerRevision, CCIRRadMeasurements}.

 			this = this@mlpipeline.ScanData(varargin{:});
            
            import mlsiemens.*;
            if (isempty(this.scannerData_))
                this.assertSessionData('tracerRevision');
                this.scannerData_ = BiographMMR.loadSession(this.sessionData, this.sessionData.tracerRevision);
            end
            if (isempty(this.xlsxObj_) && ...
                lexist(this.sessionData.arterialSamplerCrv, 'file'))
                this.aifData_ = mlpet.Twilite('twiliteCrv', this.sessionData.arterialSamplerCrv);
            end
            if (isempty(this.xlsxObj_))
                this.assertSessionData('CCIRRadMeasurements');
                this.xlsxObj_ = XlsxObjScanData('filename', this.sessionData.CCIRRadMeasurements);
            end
 		end
    end 
    
    methods (Access = protected)
        function assertSessionData(this, sessDataLabel)            
            assert(lexist(this.sessionData.(sessDataLabel)), ...
                'mlsiemens:missingData', 'ScanData.sessionData.%s -> %s', ...
                sessDataLabel, this.sessionData.(sessDataLabel));
        end
        function this = propagateMetadata(this)
            this.scannerData_.consoleClockOffset = ;
            this.scannerData_.doseAdminDatetime = ;
            this.scannerData_.time0 = ;
            this.scannerData_.timeDuration = ;
            this.scannerData_.dt = ;
            this.aifData_.efficiencyFactor = ;
            this.aifData_.aifTimeShift = ;
            
                        
            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

