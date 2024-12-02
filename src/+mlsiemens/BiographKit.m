classdef BiographKit < handle & mlpet.ScannerKit
	%% BIOGRAPHKIT is an abstract factory pattern.  It is DEPRECATED.
      
	%  $Revision$
 	%  was created 23-Feb-2020 16:09:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Dependent) 		
        arterialDev
        countingDev
        radMeasurements
        scannerDev
        sessionData
    end
    
    methods (Static)
        function [arterialDev,arterialDatetimePeak] = alignArterialToReference(varargin)
            [arterialDev,arterialDatetimePeak] = ...
                mlpet.InputFuncDevice.alignArterialToReference(varargin{:});   
        end
    end
    
    methods
        
        %% GET
        
        function g = get.arterialDev(this)
            g = this.arterialDev_;
        end
        function g = get.countingDev(this)
            g = this.countingDev_;
        end
        function g = get.radMeasurements(this)
            if isempty(this.radMeasurements_)
                this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromSession(this.sessionData);
            end
            g = this.radMeasurements_;
        end
        function g = get.scannerDev(this)
            g = this.scannerDev_;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function arterialDev = buildArterialSamplingDevice(this, scannerDev, varargin)
            ip = inputParser;
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'deconvCatheter', true, @islogical)
            addParameter(ip, 'sameWorldline', false, @islogical)
            addParameter(ip, 'indexCliff', [], @isnumeric)
            parse(ip, scannerDev, varargin{:})
            ipr = ip.Results;
            
            arterialDev = mlswisstrace.TwiliteDevice.createFromSession(this.sessionData);
            arterialDev.deconvCatheter = ipr.deconvCatheter;
            arterialDev = this.alignArterialToReference( ...
                    arterialDev=arterialDev, ...
                    referenceDev=ipr.scannerDev, ...
                    sameWorldline=ipr.sameWorldline);
            if scannerDev.timeWindow > arterialDev.timeWindow && ...
                    contains(this.sessionData.isotope, '15O')
                warning('mlsiemens:ValueWarning', ...
                    'scannerDev.timeWindow->%g; arterialDev.timeWindow->%g', ...
                    scannerDev.timeWindow, arterialDev.timeWindow)
                %this.inspectTwiliteCliff(arterialDev, scannerDev, ipr.indexCliff);
            end
            this.scannerDev_ = scannerDev;
            this.arterialDev_ = arterialDev;
        end
        function countingDev = buildCountingDevice(this, varargin)
            ip = inputParser;
            addOptional(ip, 'scannerDev', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'sameWorldline', false, @islogical)
            addParameter(ip, 'alignToScanner', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            countingDev = mlcapintec.CapracDevice.createFromSession(this.sessionData);
            if ~isempty(ipr.scannerDev) && ipr.alignToScanner
                countingDev = this.alignArterialToReference( ...
                    arterialDev=countingDev, ...
                    referenceDev=ipr.scannerDev, ...
                    sameWorldline=ipr.sameWorldline);
            end
            this.countingDev_ = countingDev;
        end
        function idif = buildIdif(~, varargin)
            ip = inputParser;
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlsiemens.BiographDevice'))
            addParameter(ip, 'idifMethod', 'idifmask', @istext)
            parse(ip, varargin{:})
            ipr = ip.Results;

            idif = ipr.scannerDev.idif('idifMethod', ipr.idifMethod);
        end
        function d = datetime(this)
            d = datetime(this.sessionData);
        end
        function d = datestr(this)
            d = datestr(datetime(this), 'yyyymmddHHMMSS');
        end        
        function decayCorrect(this)
            decayCorrect(this.scannerDev_);
        end
        function decayUncorrect(this)
            decayUncorrect(this.scannerDev_);
        end
        function fn = tracerResolvedOpSubject(this, varargin)
            fn = this.sessionData.tracerResolvedOpSubject(varargin{:});
        end
        function fn = tracerOnAtlas(this, varargin)
            fn = this.sessionData.tracerOnAtlas(varargin{:});
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        arterialDev_
        countingDev_
        radMeasurements_
        sessionData_
        scannerDev_
    end
    
	methods (Access = protected)		  
 		function this = BiographKit(varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', []);
            parse(ip, varargin{:})
            this.sessionData_ = ip.Results.sessionData;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

