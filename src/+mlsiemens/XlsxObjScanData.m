classdef XlsxObjScanData < mlio.AbstractIO & mlpipeline.IXlsxObjScanData
	%% XLSXOBJSCANDATA  

	%  $Revision$
 	%  was created 11-Jun-2017 15:36:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        capracHeader
        fdg
        oo
        tracerAdmin
        clocks
        cyclotron
        phantom
        capracCalibration
        twilite
        mmr
        pmod
        timingData
        
        referenceDate
        sessionData
    end
    
    methods (Static)
    end
    
	methods 
        
        %% GET
        
        function g = get.capracHeader(this)
            g = this.capracHeader_;
        end
        function g = get.fdg(this)
            g = this.fdg_;
        end
        function g = get.oo(this)
            g = this.oo_;
        end
        function g = get.tracerAdmin(this)
            g = this.tracerAdmin_;
        end
        function g = get.clocks(this)
            g = this.clocks_;
        end
        function g = get.cyclotron(this)
            g = this.cyclotron_;
        end
        function g = get.phantom(this)
            g = this.phantom_;
        end
        function g = get.capracCalibration(this)
            g = this.capracCalibration_;
        end
        function g = get.twilite(this)
            g = this.twilite_;
        end
        function g = get.mmr(this)
            g = this.mmr_;
        end
        function g = get.pmod(this)
            g = this.pmod_;
        end
        function g = get.timingData(this)
            g = this.timingData_;
        end
        
        function g = get.referenceDate(this)
            if (isempty(this.capracHeader))
                error('mlsiemens:variableReferencedBeforeAssigned', 'XlsxObjScanData.get.referenceDate');
            end
            g = datetime(this.capracHeader_.Var2(1));
            %g.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
        
        function [m,s] = calibrationBaseline(~)
            %% CALIBRATIONBASELINE returns specific activity from mMR
            %  @returns m, mean
            %  @returns s, std
            
            m = 0; s = 0;
        end
        function [m,s] = calibrationMeasurement(this)
            %% CALIBRATIONMEASUREMENT returns specific activity without baseline
            %  @returns m, mean
            %  @returns s, std
            
            [m,s] = this.calibrationSample;
             m    = m - this.calibrationBackground;
        end
        function [m,s] = calibrationSample(this)
            %% CALIBRATIONSAMPLE returns specific activity from mMR
            %  @returns m, mean
            %  @returns s, std
            
            m = 1e3*this.xlsxObj_.mmr.ROIMean_KBq_mL;
            m = m(~isnan(m));
            s = 1e3*this.xlsxObj_.mmr.ROIS_d__KBq_mL;
            s = s(~isnan(s));
        end
        function dt = datetime(this, varargin)
            for v = 1:length(varargin)
                if (ischar(varargin{v}))
                    try
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm:ss', 'TimeZone', 'local');
                    catch ME
                        handwarning(ME);
                        varargin{v} = datetime(varargin{v}, 'InputFormat', 'HH:mm', 'TimeZone', 'local');
                    end
                end
                dt = datetime(varargin{v}, 'ConvertFrom', 'excel1904', 'TimeZone', 'local');
                dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
                dt = this.correctDateToReferenceDate(dt);
            end
        end
        function dt = fdgDatetimes(this, varargin)
            dt = this.fdg.TIMEDRAWN_Hh_mm_ss;
            dt = dt(this.fdgValid_);
            dt = dt - this.clocks.TimeOffsetWrtNTS____s('hand timers');
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function dt = ooDatetimes(this, varargin)
            dt = this.oo.TIMEDRAWN_Hh_mm_ss;
            dt = dt(this.ooValid_);
            dt = dt - this.clocks.TimeOffsetWrtNTS____s('hand timers');
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');            
            this.capracHeader_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Table 1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', false, 'ReadRowNames', false);  
            this.fdg_ = this.correctTableToReferenceDate( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false));
            this.oo_ = this.correctTableToReferenceDate( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false)); 
            this.tracerAdmin_ = this.correctTableToReferenceDate( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true)); 
            this.clocks_ = this.convertClocks( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true, 'DatetimeType', 'exceldatenum'));
            this.cyclotron_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.phantom_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            this.capracCalibration_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            this.twilite_ = this.correctTableToReferenceDate( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1-', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false));
            this.mmr_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-11', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            this.pmod_ = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-12', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');   
            
            % only the dates in tradmin are assumed correct;
            % spreadsheets auto-fill datetime cells with the date of data entry
            % which is typically not the date of measurement
            
            this.timingData_.datetime0 = this.referenceDatetime;
            this.fdgValid_ = ~isnat(this.fdg_.TIMEDRAWN_Hh_mm_ss) & strcmp(this.fdg_.TRACER, '[18F]DG');
            this.ooValid_  = ~isnat(this.oo_.TIMEDRAWN_Hh_mm_ss)  & strcmp(this.oo_.TRACER,  'O[15O]');                         
        end
        function dt   = referenceDatetime(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tracer',  this.sessionData.tracer, @ischar);
            addParameter(ip, 'snumber', this.sessionData.snumber, @isnumeric);
            parse(ip, varargin{:});
            
            dt = this.tracerAdmin_.TrueAdmin_Time_Hh_mm_ss(this.tracerCode(ip.Results.tracer, ip.Results.snumber));
            if (isempty(dt) || isnat(dt))
                error('mlsiemens:unexpectedParameterState', 'XlsxObjScanData.referenceDatetime');
            end
        end
        
 		function this = XlsxObjScanData(varargin)
 			%% XLSXOBJSCANDATA
 			%  Usage:  this = XlsxObjScanData()

 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'timingData', mldata.TimingData, @(x) isa(x, 'mldata.TimingData'));
            parse(ip, varargin{:});            
            
            this.sessionData_ = ip.Results.sessionData;
            this.fqfilename   = this.sessionData_.CCIRRadMeasurements;
            this.timingData_  = ip.Results.timingData;
 			this              = this.readtable;
            this              = this.updateTimingData;            
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        capracHeader_
        fdg_
        oo_
        tracerAdmin_
        clocks_
        cyclotron_
        phantom_
        capracCalibration_
        twilite_
        mmr_
        pmod_
        sessionData_
        timingData_
        fdgValid_
        ooValid_
    end
    
    methods (Static, Access = private)
        function s  = clockTimeOffsetToSeconds(excelObj)
            %% CLOCKTIMEOFFSET converts this.clocks.TimeOffsetWrtNTS____s(:) to seconds
            
            pm = sign(excelObj);
            dt = datetime(abs(excelObj), 'ConvertFrom', 'excel');
            %dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            s  = pm*seconds(dt - datetime(dt.Year, dt.Month, dt.Day));
        end
        function tc = tracerCode(tr, s)
            assert(ischar(tr));
            assert(isnumeric(s));
            if (lstrfind(upper(tr), 'FDG'))
                tc = '[18F]DG';
                return
            end
            switch tr(1)
                case 'C'
                    tc = 'C[15O]';
                case 'O'
                    tc = 'O[15O]';
                case 'H'
                    tc = 'H2[15O]';
                otherwise
                    error('mlsiemens:unsupportedSwitchCase', 'XlsxObjScanData.tracerCode');
            end
            if (s > 1)
                tc = sprintf('%s_%i', tc, s-1);
            end
        end
    end
    
    methods (Access = private)
        function c    = convertClocks(this, c)
            for ic = 1:length(c.TimeOffsetWrtNTS____s)
                c.TimeOffsetWrtNTS____s(ic) = this.clockTimeOffsetToSeconds(c.TimeOffsetWrtNTS____s(ic));
            end
        end
        function tbl  = correctTableToReferenceDate(this, tbl)
            vars = tbl.Properties.VariableNames;
            for v = 1:length(vars)          
                col  = tbl{:,v};
                if (any(isdatetime(col)))
                    lrows = logical(~isnat(col));
                    col(lrows) = this.correctDateToReferenceDate(tbl{lrows,v});
                end
                tbl.(vars{v}) = col;
            end
        end
        function dt   = correctDateToReferenceDate(this, dt)
            if (~isa(dt, 'datetime'))
                dt = this.datetime(dt);
                assert(isa(dt, 'datetime'));
            end
            %if (isempty(dt.TimeZone))
            %    dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            %end
            dtRef       = this.referenceDate;
            dt.Year     = dtRef.Year;
            dt.Month    = dtRef.Month;
            dt.Day      = dtRef.Day;
        end
        function d    = extractDateOnly(this, dt)
            if (~isa(dt, 'datetime'))
                dt = this.datetime(dt);
                assert(isa(dt, 'datetime'));
            end
            d.Year  = dt.Year;
            d.Month = dt.Month;
            d.Day   = dt.Day;
        end
        function dt   = replaceDateOnly(this, dt, d)
            if (~isa(dt, 'datetime'))
                dt = this.datetime(dt);
                assert(isa(dt, 'datetime'));
            end
            dt.Year  = d.Year;
            dt.Month = d.Month;
            dt.Day   = d.Day;
            dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
        function t    = tableCaprac2times(this)
            t = seconds(this.fdgDatetimes - this.fdgDatetimes(1));
            t = ensureRowVector(t);
        end
        function this = updateTimingData(this)
            td           = this.timingData_;
            td.times     = this.tableCaprac2times;
            td.dt        = min(td.taus);
            
            this.timingData_ = td;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

