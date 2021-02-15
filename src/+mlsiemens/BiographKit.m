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
        function [arterialDev,arterialDatetimePeak] = alignArterialToScanner(varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'arterialDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            parse(ip, varargin{:})
            ipr = ip.Results;

            if strcmpi('15o', ipr.arterialDev.isotope)
                if ~ipr.arterialDev.deconvCatheter
                    [arterialDev,arterialDatetimePeak] = ...
                        mlsiemens.BiographKit.alignArterialToScannerCoarsely(varargin{:});                    
                    return
                end
                [arterialDev,arterialDatetimePeak] = ...
                    mlsiemens.BiographKit.alignArterialToScannerPrecisely(varargin{:});
                return
            end
            [arterialDev,arterialDatetimePeak] = ...
                mlsiemens.BiographKit.alignArterialToScannerPrecisely(varargin{:});
        end
        function twi = extrapolateTwilite(twi, scanner)
            c = twi.countRate();
            [~,idxPeak] = max(c);
            [~,indexCliff] = max(c(idxPeak:end) < 0.05*c(idxPeak));
            tauBeforeCliff = idxPeak + indexCliff - 10;
            twi.imputeSteadyStateActivityDensity(twi.time0 + tauBeforeCliff, twi.time0 + scanner.timeWindow);
        end
    end
    
    methods
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.radMeasurements(this)
            if isempty(this.radMeasurements_)
                this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromSession(this.sessionData);
            end
            g = this.radMeasurements_;
        end
        
        %%
        
        function arterialDev = buildArterialSamplingDevice(this, scannerDev, varargin)
            ip = inputParser;
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'deconvCatheter', true, @islogical)
            addParameter(ip, 'sameWorldline', false, @islogical)
            parse(ip, scannerDev, varargin{:})
            ipr = ip.Results;
            
            arterialDev = mlswisstrace.TwiliteDevice.createFromSession(this.sessionData);
            arterialDev.deconvCatheter = ipr.deconvCatheter;
            arterialDev = this.alignArterialToScanner( ...
                arterialDev, scannerDev, 'sameWorldline', ipr.sameWorldline);
            this.extrapolateTwilite(arterialDev, scannerDev);
        end
        function countingDev = buildCountingDevice(this, varargin)
            ip = inputParser;
            addOptional(ip, 'scannerDev', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'sameWorldline', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            countingDev = mlcapintec.CapracDevice.createFromSession(this.sessionData);
            if ~isempty(ipr.scannerDev)
                countingDev = this.alignArterialToScanner( ...
                    countingDev, ipr.scannerDev, 'sameWorldline', ipr.sameWorldline);
            end
        end
        function d = datetime(this)
            d = datetime(this.sessionData);
        end
        function d = datestr(this)
            d = datestr(datetime(this), 'yyyymmddHHMMSS');
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
        radMeasurements_
        sessionData_
    end
    
    methods (Access = protected, Static)        
        function [arterialDev,arterialDatetimePeak] = alignArterialToScannerPrecisely(varargin)
            %% ALIGNARTERIALTOSCANNER
            %  @param required arterialDev is counting device or arterial sampling device, as mlpet.AbstractDevice.
            %  @param required scannerlDev is mlpet.AbstractDevice.
            %  @param sameWorldline is logical.
            %  @return arterialDev, modified if not sameWorldline;
            %  @return arterialDatetimePeak, updated with alignments.
            %  @return arterialDev.Dt, always updated.
            %  @return updates mlraichle.RaichleRegistry.tBuffer.
            
            ip = inputParser;
            addRequired(ip, 'arterialDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'sameWorldline', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            arterialDev = ipr.arterialDev;
            scannerDev = ipr.scannerDev;

            % match radial-artery bolus to carotid bolus using scannerDev.threshOfPeak
            unifTimes = 0:max(arterialDev.timeWindow, scannerDev.timesMid(end));
            arterialDevTimes = arterialDev.times(arterialDev.index0:arterialDev.indexF) - arterialDev.time0;
            arterialAct = makima([-1 arterialDevTimes], ...
                                 [ 0 arterialDev.activityDensity()], ...
                                 unifTimes);
            scannerAct = makima([-1 scannerDev.timesMid], ...
                                [ 0 scannerDev.activityDensity('volumeAveraged', true)], ...
                                unifTimes);
            dscannerAct = diff(scannerAct);
            top = arterialDev.threshOfPeak;
            [~,idxArterial] = max(arterialAct > top*max(arterialAct));
            [~,idxScanner] = max(dscannerAct > top*max(dscannerAct));
            arterialDatetimePeak = arterialDev.datetime0 + seconds(unifTimes(idxArterial));
            scannerDatetimePeak = scannerDev.datetime0 + seconds(unifTimes(idxScanner));                        
            Dt = seconds(scannerDatetimePeak - arterialDatetimePeak);
            
            % adjust arterialDev worldline to describe carotid bolus
            if ipr.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + seconds(Dt);
            else
                arterialDev.shiftWorldlines(Dt);
            end
            arterialDatetimePeak = arterialDatetimePeak + seconds(Dt);
            arterialDev.Dt = Dt;
            
            % tBuffer
            RR = mlraichle.RaichleRegistry.instance();
            RR.Ddatetime0 = seconds(ipr.scannerDev.datetime0 - ipr.arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = scannerDev.datetimeForDecayCorrection;
            
            if abs(Dt) > arterialDev.timeWindow
                error('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScannerPrecisely.Dt was %g but arterialDev.timeWindow was %g.', ...
                    Dt, arterialDev.timeWindow)
            end
        end
        function [arterialDev,arterialDatetimePeak] = alignArterialToScannerCoarsely(varargin)
            %% ALIGNARTERIALTOSCANNER
            %  @param required arterialDev is counting device or arterial sampling device, as mlpet.AbstractDevice.
            %  @param required scannerlDev is mlpet.AbstractDevice.
            %  @param sameWorldline is logical.
            %  @return arterialDev, modified if not sameWorldline;
            %  @return arterialDatetimePeak, updated with alignments.
            %  @return arterialDev.Dt, always updated.
            %  @return updates mlraichle.RaichleRegistry.tBuffer.
            
            ip = inputParser;
            addRequired(ip, 'arterialDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addRequired(ip, 'scannerDev', @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'sameWorldline', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            arterialDev = ipr.arterialDev;
            scannerDev = ipr.scannerDev;

            % match radial-artery bolus to carotid bolus using scannerDev.threshOfPeak
            top = arterialDev.threshOfPeak; 
            arterialAct = arterialDev.activityDensity();
            scannerAct = scannerDev.activityDensity('volumeAveraged', true, 'diff', true);                       
            [~,idxArterial] = max(arterialAct > top*max(arterialAct));
            [~,idxScanner] = max(scannerAct > top*max(scannerAct));
            arterialDatetimePeak = arterialDev.datetime0 + seconds(idxArterial - 1);
            Dt = seconds(scannerDev.datetimes(idxScanner) - arterialDev.datetimes(idxArterial));
            
            % adjust arterialDev worldline to describe carotid bolus
            if ipr.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + seconds(Dt);
            else
                arterialDev.shiftWorldlines(Dt);
            end
            arterialDatetimePeak = arterialDatetimePeak + seconds(Dt);
            arterialDev.Dt = Dt;
            
            % tBuffer
            RR = mlraichle.RaichleRegistry.instance();
            RR.Ddatetime0 = seconds(ipr.scannerDev.datetime0 - ipr.arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = scannerDev.datetimeForDecayCorrection;
            
            if abs(Dt) > arterialDev.timeWindow
                error('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScannerCoarsely.Dt was %g but arterialDev.timeWindow was %g.', ...
                    Dt, arterialDev.timeWindow)
            end
        end
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

