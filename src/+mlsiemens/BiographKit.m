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
            arterialDev = copy(ipr.arterialDev);
            scannerDev = ipr.scannerDev;

            % find Dt of carotid bolus from radial-artery bolus, unresolved frames-of-reference
            unifTimes = 0:max(arterialDev.timeWindow, scannerDev.timesMid(end));
            arterialDevTimes = arterialDev.times(arterialDev.index0:arterialDev.indexF) - arterialDev.time0;
            arterialAct = makima(arterialDevTimes, ...
                                 arterialDev.activityDensity(), ...
                                 unifTimes);
            scannerAct = makima(scannerDev.timesMid, ...
                                scannerDev.activityDensity('volumeAveraged', true), ...
                                unifTimes);
            dscannerAct = diff(scannerAct);
            top = arterialDev.threshOfPeak;
            [~,idxArterial] = max(arterialAct > top*max(arterialAct));
            [~,idxScanner] = max(dscannerAct > top*max(dscannerAct));
            tArterial = seconds(unifTimes(idxArterial));
            tScanner = seconds(unifTimes(idxScanner));
            
            % manage failures of makima()
            if tArterial > seconds(0.5*arterialDev.timeWindow)
                warning('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.tArterial was %g but arterialDev.timeWindow was %g.\n', ...
                    seconds(tArterial), arterialDev.timeWindow)
                [~,idxArterial] = max(arterialDev.activityDensity() > top*max(arterialDev.activityDensity()));
                tArterial = seconds(arterialDevTimes(idxArterial));
                fprintf('tArterial forced-> %g\n', seconds(tArterial))
            end            
            if tArterial > seconds(0.5*arterialDev.timeWindow) %%% UNRECOVERABLE
                error('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.tArterial was %g but arterialDev.timeWindow was %g.', ...
                    seconds(tArterial), arterialDev.timeWindow)
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow)
                warning('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.tScanner was %g but scannerDev.timeWindow was %g.\n', ...
                    seconds(tScanner), scannerDev.timeWindow)
                scannerDevAD = scannerDev.activityDensity('volumeAveraged', true, 'diff', true);
                [~,idxScanner] = max(scannerDevAD > top*max(scannerDevAD));
                tScanner = seconds(scannerDev.timesMid(idxScanner));
                fprintf('tScanner forced -> %g\n', seconds(tScanner))
            end
            if tScanner > seconds(0.75*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.tScanner was %g but scannerDev.timeWindow was %g.', ...
                    seconds(tScanner), scannerDev.timeWindow)
            end
            
            % resolve frames-of-reference, ignoring delay of radial artery from carotid
            Dbolus = scannerDev.datetime0 + tScanner - (arterialDev.datetime0 + tArterial);
            arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                            tScanner - ...
                                            tArterial - ...
                                            Dbolus;
                                        
            % manage failures of Dbolus
            if Dbolus > seconds(15)
                warning('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.Dbolus was %g.\n', seconds(Dbolus))
                fprintf('scannerDev.datetime0 was %s.\n', datestr(scannerDev.datetime0))
                fprintf('tScanner was %g.\n', seconds(tScanner))
                fprintf('arterialDev.datetime0 was %s.\n', datestr(arterialDev.datetime0))
                fprintf('tArterial was %g.\n', seconds(tArterial))
                Dbolus = seconds(15);
                arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0 + ...
                                                tScanner - ...
                                                tArterial - ...
                                                Dbolus;
                fprintf('Dbolus forced -> %g\n', seconds(Dbolus))
                fprintf('arterialDev.datetimeMeasured forced -> %s\n', ...
                        datestr(arterialDev.datetimeMeasured))
            end
            if abs(Dbolus) > seconds(0.5*scannerDev.timeWindow) %%% UNRECOVERABLE
                error('mlsiemens:ValueError', ...
                    'BiographKit.alignArterialToScanner.Dbolus was %g but scannerDev.timeWindow was %g.', ...
                    seconds(Dbolus), scannerDev.timeWindow)
                %Dbolus = seconds(0);
                %arterialDev.datetimeMeasured = -seconds(arterialDev.time0) + scannerDev.datetime0;
                %warning('mlsiemens:ValueError', ...
                %        'BiographKit.alignArterialToScanner.Dbolus forced -> %g', seconds(Dbolus))
                %warning('mlsiemens:ValueError', ...
                %        'BiographKit.alignArterialToScanner.arterialDev.datetimeMeasured forced -> %s', ...
                %        datestr(arterialDev.datetimeMeasured))
            end
                                        
            % adjust arterialDev worldline to describe carotid bolus
            if ipr.sameWorldline
                arterialDev.datetimeMeasured = arterialDev.datetimeMeasured + Dbolus;
            else
                arterialDev.shiftWorldlines(seconds(Dbolus));
            end
            arterialDev.Dt = seconds(Dbolus);
            arterialDatetimePeak = arterialDev.datetime0 + tArterial;
            
            % tBuffer
            RR.Ddatetime0 = seconds(scannerDev.datetime0 - arterialDev.datetime0);

            % synchronize decay correction times
            arterialDev.datetimeForDecayCorrection = scannerDev.datetimeForDecayCorrection;            
        end
        function twi = extrapolateTwilite(twi, scanner, varargin)
            %% EXTRAPOLATETWILITE
            %  @param optional indexCliff is # time indices from max of countrate at which to start extrapolating
            
            ip = inputParser;
            addRequired(ip, 'twi', @(x) isa(x, 'mlswisstrace.TwiliteDevice'))
            addRequired(ip, 'scanner', @(x) isa(x, 'mlpet.AbstractDevice'))
            addOptional(ip, 'indexCliff', [], @isnumeric)
            parse(ip, twi, scanner, varargin{:})
            ipr = ip.Results;
            
            try
                b = mean(twi.baselineCountRate);
                c = twi.countRate();
                c(c < 0) = 0;
                [~,idxPeak] = max(c);
                lowerbound = 0.05*(c(idxPeak) - b) + b;
                if isempty(ipr.indexCliff)
                    [~,ipr.indexCliff] = max(c(idxPeak:end) < lowerbound);
                end
                tauBeforeCliff = idxPeak + ipr.indexCliff - 10;
                twi.imputeSteadyStateActivityDensity( ...
                    twi.time0 + tauBeforeCliff, ...
                    min(twi.time0 + scanner.timeWindow, max(twi.times)));
            catch ME
                handwarning(ME)
            end
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
            addParameter(ip, 'indexCliff', [], @isnumeric)
            parse(ip, scannerDev, varargin{:})
            ipr = ip.Results;
            
            arterialDev = mlswisstrace.TwiliteDevice.createFromSession(this.sessionData);
            arterialDev.deconvCatheter = ipr.deconvCatheter;
            arterialDev = this.alignArterialToScanner( ...
                arterialDev, scannerDev, 'sameWorldline', ipr.sameWorldline);
            this.extrapolateTwilite(arterialDev, scannerDev, ipr.indexCliff);
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

