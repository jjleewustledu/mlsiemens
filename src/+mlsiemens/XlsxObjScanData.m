classdef XlsxObjScanData < mlio.AbstractIO & mldata.IManualMeasurements
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
        
        function sa   = correctFillingFactor(~, sa, m)
            % @param sa is specific activity.
            % @param m is sample mass /g.
            
            sa = 1592.7*sa ./ (53.495*m.^4 - 298.43*m.^3 + 191.17*m.^2 + 1592.7*m);
        end
        function sa   = capracCalibrationSpecificActivity(this)
            sa = this.capracCalibration_.Ge_68_Kdpm;
            sa = dt_(~isnan(sa));
        end
        function dt_  = capracCalibrationDatetime(this)
            dt_ = this.capracCalibration_.TIMEDRAWN_Hh_mm_ss;
            dt_ = dt_(~isnat(dt_));
        end
        function sa   = fdgGe68(this, varargin)
            sa = this.correctFillingFactor(this.fdg_.Ge_68_Kdpm, this.fdg_.MASSSAMPLE_G);
            sa = sa(this.fdgValid_);
            if (~isempty(varargin))
                sa = sa(varargin{:});
            end
        end
        function dt_  = fdgTimesDrawn(this, varargin)
            dt_ = this.fdg.TIMEDRAWN_Hh_mm_ss;
            dt_ = dt_(this.fdgValid_);
            if (~isempty(varargin))
                dt_ = dt_(varargin{:});
            end
        end % DRAWN
        function sa   = ooGe68(this, varargin)
            sa = this.correctFillingFactor(this.oo_.Ge_68_Kdpm, this.oo_.MASSSAMPLE_G);
            sa = sa(this.ooValid_);
            if (~isempty(varargin))
                sa = sa(varargin{:});
            end
        end
        function dt_  = ooTimesDrawn(this, varargin)
            dt_ = this.oo.TIMEDRAWN_Hh_mm_ss;
            dt_ = dt_(this.ooValid_);
            if (~isempty(varargin))
                dt_ = dt_(varargin{:});
            end
        end % DRAWN
        function sa   = phantomSpecificActivity(this)
            sa = this.phantom_.DECAYCorrSpecificActivity_KBq_mL;
        end
        function dt_  = phantomDatetime(this)
            dt_ = this.cyclotron_.time_Hh_mm_ss('residual dose');
            dt_ = dt_{1};
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');  
            warning('off', 'MATLAB:table:ModifiedDimnames');  

            this.capracHeader_ = ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Table 1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', false, 'ReadRowNames', false);
            this.clocks_ = this.convertClocks2sec( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true));
            
            this.fdg_ = this.correctDates2( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false, 'DatetimeType', 'exceldatenum'));
            this.oo_ = this.correctDates2( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false, 'DatetimeType', 'exceldatenum'));
            this.tracerAdmin_ = this.correctDates2( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Radiation Counts Log - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true, 'DatetimeType', 'exceldatenum'));
            this.cyclotron_ = this.correctDates2( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true));
            this.phantom_ = ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            this.capracCalibration_ = this.correctDates2( ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false, 'DatetimeType', 'exceldatenum'));
            this.twilite_ = ...
                readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'Twilite Calibration - Runs-2-1-', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames'); 
            warning('on', 'MATLAB:table:ModifiedDimnames');  
            
            % only the dates in tradmin are assumed correct;
            % spreadsheets auto-fill datetime cells with the date of data entry
            % which is typically not the date of measurement
            
            this.timingData_.datetime0 = this.referenceDatetime;
            this.fdgValid_ = ~isnat(this.fdg_.TIMEDRAWN_Hh_mm_ss) & ~isempty(this.fdg_.Ge_68_Kdpm) & strcmp(this.fdg_.TRACER, '[18F]DG');
            this.ooValid_  = ~isnat(this.oo_.TIMEDRAWN_Hh_mm_ss)  & ~isempty(this.oo_.Ge_68_Kdpm)  & strcmp(this.oo_.TRACER,  'O[15O]'); 
            this = this.updateTimingData;
        end
        function dt_  = referenceDatetime(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tracer',  this.sessionData.tracer, @ischar);
            addParameter(ip, 'snumber', this.sessionData.snumber, @isnumeric);
            parse(ip, varargin{:});
            
            dt_ = this.tracerAdmin_.TrueAdmin_Time_Hh_mm_ss( ...
                this.tracerCode(ip.Results.tracer, ip.Results.snumber));
        end
        function cath = catheterInfo(this)
            switch (this.twilite_{1,1})
                case 'Medex REF 536035, 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL'
                    cath.vendor = 'Medex';
                    cath.ref = '536035';
                    cath.primingVolume = 1.1;
                    cath.enclosedLength = 20;
                    cath.length = 152.4; % trimmed to ~40 cm
                case 'Braun ref V5424, 48 cm len, 0.642 mL priming vol'
                    cath.vendor = 'Braun';
                    cath.ref = 'V5424';
                    cath.primingVolume = 0.642;
                    cath.enclosedLength = 20;
                    cath.length = 48;
                otherwise
                    error('mlsiemens:unsupportedSwitchcase', 'XlsxObjScanData.catheterInfo');
            end
        end
        
 		function this = XlsxObjScanData(varargin)
 			%% XLSXOBJSCANDATA

 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'timingData', mldata.TimingData, @(x) isa(x, 'mldata.TimingData'));
            addParameter(ip, 'fqfilename', '', @ischar);
            addParameter(ip, 'forceDateToReferenceDate', true, @islogical);
            parse(ip, varargin{:});            
            
            this.sessionData_              = ip.Results.sessionData;
            this.fqfilename                = ip.Results.fqfilename;
            if (isempty(this.fqfilename)); this.fqfilename = this.sessionData_.CCIRRadMeasurements; end
            this.timingData_               = ip.Results.timingData;
            this.forceDateToReferenceDate_ = ip.Results.forceDateToReferenceDate;
 			this = this.readtable;        
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        forceDateToReferenceDate_
        capracHeader_
        fdg_
        oo_
        tracerAdmin_
        clocks_
        cyclotron_
        phantom_
        capracCalibration_
        twilite_
        
        sessionData_
        timingData_
        fdgValid_
        ooValid_
    end
    
    methods (Static, Access = private)
        function tc = tracerCode(tr, snumber)
            assert(ischar(tr));
            assert(isnumeric(snumber));
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
            if (snumber > 1)
                tc = sprintf('%s_%i', tc, snumber-1);
            end
        end
    end
    
    methods (Access = private)
        function c    = convertClocks2sec(this, c)
            for ic = 1:length(c.TimeOffsetWrtNTS____s)
                c.TimeOffsetWrtNTS____s(ic) = this.excelNum2sec(c.TimeOffsetWrtNTS____s(ic));
            end
        end
        function s    = excelNum2sec(~, excelnum)
            
            pm  = sign(excelnum);
            dt_ = datetime(abs(excelnum), 'ConvertFrom', 'excel');
            %dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            s   = pm*seconds(dt_ - datetime(dt_.Year, dt_.Month, dt_.Day));
        end
        function tbl  = correctDates2(this, tbl)
            vars = tbl.Properties.VariableNames;
            for v = 1:length(vars)
                col = tbl.(vars{v});
                if (this.hasTimings(vars{v}))
                    if (any(isnumeric(col)))                        
                        lrows = logical(~isnan(col) & ~isempty(col));
                        col = NaT(size(col));
                        if (~this.isTrueTiming(vars{v}))
                            col(lrows) = ...
                                this.datetimeConvertFromExcel2(tbl{lrows,v}) - ...
                                seconds(this.clocks.TimeOffsetWrtNTS____s('hand timers'));
                        else
                            col(lrows) = ...
                                this.datetimeConvertFromExcel2(tbl{lrows,v});
                        end
                    end
                    if (any(isdatetime(col)))
                        lrows = logical(~isnat(col));
                        col(lrows) = this.correctDateToReferenceDate(col(lrows));
                    end
                end
                tbl.(vars{v}) = col;
            end
        end
        function tf   = hasTimings(~, var)
            tf = lstrfind(lower(var), 'time') | lstrfind(lower(var), 'hh_mm_ss');
        end
        function tf   = isTrueTiming(~, var)
            tf = lstrfind(lower(var), 'true');
        end
        function dt_  = correctDateToReferenceDate(this, dt_)
            if (~this.forceDateToReferenceDate_)
                return
            end
            
            if (~isa(dt_, 'datetime'))
                dt_ = this.datetime(dt_);
            end
            dtRef     = this.referenceDate;
            dt_.Year  = dtRef.Year;
            dt_.Month = dtRef.Month;
            dt_.Day   = dtRef.Day;
        end
        function dt_  = datetimeConvertFromExcel2(~, varargin)
            % addresses what may be an artefact of linking cells across sheets in Numbers/Excel on MacOS
            
            dt_ = mldata.TimingData.datetimeConvertFromExcel2(varargin{:});            
        end
        function d    = extractDateOnly(this, dt_)
            if (~isa(dt_, 'datetime'))
                dt_ = this.datetime(dt_);
                assert(isa(dt_, 'datetime'));
            end
            d.Year  = dt_.Year;
            d.Month = dt_.Month;
            d.Day   = dt_.Day;
        end
        function dt_  = replaceDateOnly(this, dt_, d)
            if (~isa(dt_, 'datetime'))
                dt_ = this.datetime(dt_);
                assert(isa(dt_, 'datetime'));
            end
            dt_.Year  = d.Year;
            dt_.Month = d.Month;
            dt_.Day   = d.Day;
            dt_.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
        function this = updateTimingData(this)
            if (~lstrcmp(upper(this.sessionData.tracer), 'FDG'))
                return
            end
            td       = this.timingData_;
            td.times = this.tableCaprac2times;
            td.dt    = min(td.taus)/2;
            
            this.timingData_ = td;
        end
        function t    = tableCaprac2times(this)
            t = seconds(this.fdgTimesDrawn - this.fdgTimesDrawn(1));
            t = ensureRowVector(t);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

