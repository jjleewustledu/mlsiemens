classdef BiographKit < handle & mlpet.ScannerKit
	%% BIOGRAPHKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 16:09:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent) 		
        sessionData
        radMeasurements
    end
    
    methods (Static)
        function ts = estimateTimeshift(arterialDev, scannerDev)
            %% ESTIMATETIMESHIFT
            %  @param arterialDev is counting device or arterial sampling device, as mlpet.AbstractDevice.
            %  @param scannerlDev is mlpet.AbstractDevice.
            %  @return ts is time, in sec, of peak from diff(scanner) - time of peak from device.
            
            assert(isa(arterialDev, 'mlpet.AbstractDevice'))
            [~,idxDev] = max(arterialDev.activityDensity);
            [~,idxScanner] = max(scannerDev.activityDensity('volumeAveraged', true, 'diff', true));
            ts = seconds(scanner.datetimes(idxScanner) - arterialDev.datetimes(idxDev));            
        end
    end
    
    methods
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.radMeasurements(this)
            g = mlpet.CCIRRadMeasurements.createFromSession(this.sessionData);
        end
        
        %%
        
        function arterialDev = buildArterialSamplingDevice(this, scannerDev)
            assert(isa(scannerDev, 'mlpet.AbstractDevice'))
            arterialDev = mlswisstrace.TwiliteDevice.createFromSession(this.sessionData);
            ts = this.estimateTimeshift(arterialDev, scannerDev);
            arterialDev.shiftWorldlines(ts);
        end
        function d = buildCountingDevice(this)
            d = mlcapintec.CapracDevice.createFromSession(this.sessionData);
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        sessionData_
    end
    
	methods (Access = protected)		  
 		function this = BiographKit(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:})
            this.sessionData_ = ip.Results.sessionData;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

