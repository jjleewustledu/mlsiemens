classdef XlsxObjScanData < mlio.AbstractXlsxIO & mldata.IManualMeasurements
	%% XLSXOBJSCANDATA  

	%  $Revision$
 	%  was created 11-Jun-2017 15:36:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
    
	properties (Dependent)
        capracHeader
        % this.capracHeader -> 4×4 table
        %     Var1             Var2                   Var3                   Var4    
        % _____________    _____________    _________________________    ____________
        % 'DATE:'          '09-Sep-2016'    'PROJECT ID:'                'CCIR_00754'
        % 'SUBJECT ID:'    'HYGLY28'        'PRINCIPLE INVESTIGATOR:'    'Arbelaez'  
        % 'ISOTOPES:'      ''               'DOSES DELIVERED / mCi:'     '115.9'     
        % ''               ''               'OPERATOR:'                  'JJL'   
        
        fdg
        % this.fdg -> 38×17 table
        % TUBE       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER       TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G      MASSSAMPLE_G       apertureCorrGe_68_Kdpm_G    TRUEDECAY_APERTURECORRGe_68_Kdpm_G          COMMENTS      
        % ____    ____________________    __________    ______________    _______    _________    ____________________    ____________________    _________    _______    __________    _________    _________    _________________    ________________________    __________________________________    ____________________
        % 26      09-Sep-2016 11:37:00    '813'         NaN               false      '[18F]DG'    09-Sep-2016 12:01:02    09-Sep-2016 12:09:18      NaN          NaN           0        3.7736       4.3328                  0.5592                    0                           0                     ''                  
        % ...
        
        oo
        % this.oo -> 4×17 table
        % TUBE       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER      TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G    MassSample_G    apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    COMMENTS
        % ____    ____________________    __________    ______________    _______    ________    ____________________    ____________________    _________    _______    __________    _________    _________    ____________    ________________________    ______________________________    ________
        % '1'     09-Sep-2016 09:12:00    189           NaN               true       'O[15O]'    09-Sep-2016 10:23:08    09-Sep-2016 10:29:57    NaN          NaN        442.8         3.7859       5.5693       1.7834          307.050645885317            1589.89417549421                  ''      
        % 'P1'    09-Sep-2016 10:14:00    210           NaN               true       'O[15O]'    09-Sep-2016 10:23:08    09-Sep-2016 10:34:37    NaN          NaN        21.07         3.8478       4.5595       0.7117          29.5276730836604            748.030808434861                  'Plasma'
        % '2'     09-Sep-2016 10:44:00    224           NaN               true       'O[15O]'    09-Sep-2016 11:23:45    09-Sep-2016 11:32:10    NaN          NaN        126.3         3.8263       5.3021       1.4758          97.5833310265788            734.626175043027                  ''      
        % 'P2'    NaT                     NaN           NaN               false      'O[15O]'    09-Sep-2016 11:23:45    09-Sep-2016 11:34:52    NaN          NaN        21.98         3.7965       4.4618       0.6653            32.81426432084             619.00902301696                  'Plasma'
        
        tracerAdmin       
        % this.tracerAdmin -> 7×4 table
        %              ADMINistrationTime_Hh_mm_ss    TrueAdmin_Time_Hh_mm_ss    dose_MCi    COMMENTS
        %              ___________________________    _______________________    ________    ________
        % C[15O]       09-Sep-2016 10:11:36           09-Sep-2016 10:09:19         21        NaN     
        % O[15O]       09-Sep-2016 10:27:24           09-Sep-2016 10:25:07         18        NaN     
        % H2[15O]      09-Sep-2016 10:43:04           09-Sep-2016 10:40:47       20.7        NaN     
        % C[15O]_1     09-Sep-2016 10:59:56           09-Sep-2016 10:57:39         15        NaN     
        % O[15O]_1     09-Sep-2016 11:28:31           09-Sep-2016 11:26:14         16        NaN     
        % H2[15O]_1    09-Sep-2016 11:43:35           09-Sep-2016 11:41:18       20.3        NaN     
        % [18F]DG      09-Sep-2016 12:03:00           09-Sep-2016 12:00:43        4.9        NaN      
        
        clocks        
        % this.clocks -> 6×1 table
        %                     TimeOffsetWrtNTS____s
        %                     _____________________
        % mMR console            7                 
        % PMOD workstation       0                 
        % mMR PEVCO lab       -118                 
        % CT radiation lab       0                 
        % hand timers          137                 
        % 2nd PEVCO lab          0  
        
        cyclotron
        % this.cyclotron -> 3×8 table
        %                           time_Hh_mm_ss             dose_MCi        CYCLOTRONLOTID       CYCLOTRONTIME        CyclotronActivity_MCi_ML    CyclotronVolume_ML    ExpectedDose_MCi            COMMENTS        
        %                       ______________________    ________________    ______________    ____________________    ________________________    __________________    ________________    ________________________
        % syringe + cap dose    '09-Sep-2016 12:33:30'                3.02    'F1-090916'       09-Sep-2016 06:12:00    69.2                        0.4                   2.51974444007394    ''                      
        % residual dose         '09-Sep-2016 12:33:30'                 0.5    ''                NaT                      NaN                        NaN                                NaN    'guessing residual dose'
        % net dose              ''                        2.48889898928836    ''                NaT                      NaN                        NaN                                NaN    ''                      

        phantom
        % this.phantom -> 1×5 table
        % PHANTOM    OriginalVolume_ML    NetVolume_phantom_Dose__ML    DECAYCorrSpecificActivity_KBq_mL    COMMENTS
        % _______    _________________    __________________________    ________________________________    ________
        % NaN        500                  500                           136.810825779928                    NaN     
        
        capracCalibration
        % this.capracCalibration -> 3×19 table
        % WELLCOUNTER       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER       TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G    MassSample_G    apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_        COMMENTS    
        % ___________    ____________________    __________    ______________    _______    _________    ____________________    ____________________    _________    _______    __________    _________    _________    ____________    ________________________    ______________________________    ________________________________    _____________________    ________________
        % NaN            09-Sep-2016 12:45:45    266           NaN               true       '[18F]DG'    09-Sep-2016 12:31:13    09-Sep-2016 12:43:09    NaN          NaN        2977          3.8113       5.8967       2.0854          1928.97650059354            1504.106976004                    25.0684496000667                    0.183234400181105        'failed mixing?'
        % NaN            NaT                     NaN           NaN               false      '[18F]DG'    NaT                     NaT                     NaN          NaN         NaN             NaN          NaN            0                       NaN                       NaN                                 NaN                                  NaN        ''              
        % NaN            NaT                     NaN           NaN               false      '[18F]DG'    NaT                     NaT                     NaN          NaN         NaN             NaN          NaN            0                       NaN                       NaN                                 NaN                                  NaN        ''              
        
        twilite
        % this.twilite -> 3×11 table
        %                            TWILITE                               CathPlace_mentTime_Hh_mm_ss    EnclosedCatheterLength_Cm    VISIBLEVolume_ML     TwiliteBaseline_CoincidentCps    TwiliteLoaded_CoincidentCps    SpecificCountRate_Kcps_mL    SpecificACtivity_KBq_mL    DECAYCORRSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_    COMMENTS
        % _____________________________________________________________    ___________________________    _________________________    _________________    _____________________________    ___________________________    _________________________    _______________________    ________________________________    _____________________    ________
        % 'Medex REF 536035, 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL'    08-Sep-2012 13:22:33           20                           0.144356955380577    91.3                             148.3                          0.394854545454546            116.60378508               116.60378508                        0.852299402589435        NaN     
        % 'Medex'                                                          08-Sep-2012 13:22:33           20                           0.144356955380577     NaN                               NaN                                          0                       0                        NaN                                      NaN        NaN     
        % 'Medex'                                                          08-Sep-2012 13:22:33           20                           0.144356955380577     NaN                               NaN                                          0                       0                        NaN                                      NaN        NaN     

        mMR
        % this.mMR -> 3×9 table
        %         scanStartTime_Hh_mm_ss    ROIMean_KBq_mL    ROIS_d__KBq_mL    ROIVol_Cm3    ROIPIXELS    ROIMin_KBq_mL    ROIMax_KBq_mL    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_
        %         ______________________    ______________    ______________    __________    _________    _____________    _____________    ________________________________    _____________________
        % ROI1    09-Sep-2016 13:22:40      103.61            22.81             518           129746       41.14            134.8            103.533699821761                    0.756765403845334    
        % ROI2    NaT                          NaN              NaN             NaN              NaN         NaN              NaN                           0                                    0    
        % ROI3    NaT                          NaN              NaN             NaN              NaN         NaN              NaN                           0                                    0    

        preferredTimeZone
        referenceDate
        sessionData
        timingData
    end    
    
    methods (Static)
        function tc = tracerCode(tr, snumber)
            assert(ischar(tr));
            assert(isnumeric(snumber));
            if (lstrfind(upper(tr), 'FDG') || ...
                strcmp(tr(1:2), '18') || ...
                strcmp(tr(1), '['))
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
        function g = get.mMR(this)
            g = this.mMR_;
        end
        
        function g = get.preferredTimeZone(~)
            g = mlpipeline.ResourcesRegistry.instance.preferredTimeZone;
        end
        function g = get.referenceDate(this)
            %% from fileprefix
            
            re = regexp(this.fileprefix, '^\w+ (?<dt>\d\d\d\d[a-zA-Z]+\d+)$', 'names');
            g = datetime(re.dt, 'InputFormat', 'yyyMMMd', 'TimeZone', this.preferredTimeZone);
            assert(isdatetime(g))
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        function g = get.timingData(this)
            g = this.timingData_;
        end
        
        %%
        
        function sa   = capracInvEfficiency(this, sa, m)
            % @param sa is specific activity.
            % @param m is sample mass /g.
            
            sa = this.calibrationVisitor_.capracInvEfficiency(sa, m);
        end
        function sa   = capracCalibrationSpecificActivity(this, varargin)
            sa = this.calibrationVisitor_.capracCalibrationSpecificActivity(varargin{:}); 
            if (~isempty(varargin))
                sa = sa(varargin{:});
            end
        end
        function dt_  = capracCalibrationTimesCounted(this, varargin)
            dt_ = this.calibrationVisitor_.capracCalibrationTimesCounted;
            if (~isempty(varargin))
                dt_ = dt_(varargin{:});
            end
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
        function sa   = mMRSpecificActivity(this)
            sa = 1000 * this.mMR_.ROIMean_KBq_mL('ROI1');
        end
        function dt_  = mMRDatetime(this)
            try
                dt_ = this.mMR_.scanStartTime_Hh_mm_ss('ROI1') - ...
                      seconds(this.clocks.TimeOffsetWrtNTS____s('mMR console'));
            catch ME
                dispwarning(ME);
            end
        end
        function sa   = phantomSpecificActivity(this)
            %% PHANTOMSPECIFICACTIVITY returns Bq/mL
            
            sa = 1000 * this.phantom_.DECAYCorrSpecificActivity_KBq_mL;
        end
        function dt_  = phantomDatetime(this)
            try
                ct_ = this.cyclotron_.time_Hh_mm_ss('residual dose');
                ct_ = datetime(ct_{1});
                dt_ =  ct_ - seconds(this.clocks.TimeOffsetWrtNTS____s('mMR PEVCO lab'));
                dt_.TimeZone = mldata.Xlsx.preferredTimeZone;
            catch ME
                dispwarning(ME);
            end
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            warning('off', 'MATLAB:table:ModifiedDimnames');
            
            try
                this.capracHeader_ = ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Radiation Counts Log - Table 1', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', false, 'ReadRowNames', false);
            catch ME
                dispwarning(ME);
            end
            try
                this.clocks_ = this.convertClocks2sec( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true));
            catch ME
                dispwarning(ME);
            end
            try
                this.fdg_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Radiation Counts Log - Runs', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false)); %, 'DatetimeType', 'exceldatenum'));
            catch ME
                dispwarning(ME);
            end
            try
                this.oo_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Radiation Counts Log - Runs-1', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false)); %, 'DatetimeType', 'exceldatenum'));
            catch ME
                dispwarning(ME);
            end
            try
                this.tracerAdmin_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Radiation Counts Log - Runs-2', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true)); %, 'DatetimeType', 'exceldatenum'));
            catch ME
                dispwarning(ME);
            end
            try
                this.cyclotron_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs-2', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true), ...
                    'mMR PEVCO lab');
            catch ME
                dispwarning(ME);
            end
            try
                this.phantom_ = ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs-2-1', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            catch ME
                dispwarning(ME);
            end
            try
                this.capracCalibration_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs-2-2', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false)); %, 'DatetimeType', 'exceldatenum'));
            catch ME
                dispwarning(ME);
            end
            try
                this.twilite_ = ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs-2-1-', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            catch ME
                dispwarning(ME);
            end
            try
                this.mMR_ = this.correctDates2( ...
                    readtable(ip.Results.fqfnXlsx, ...
                    'Sheet', 'Twilite Calibration - Runs-2-11', ...
                    'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true)); %, 'DatetimeType', 'exceldatenum'));
            catch ME
                dispwarning(ME);
            end
            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames'); 
            warning('on', 'MATLAB:table:ModifiedDimnames');  
            
            % only the dates in tradmin are assumed correct;
            % spreadsheets auto-fill datetime cells with the date of data entry
            % which is typically not the date of measurement
            
            this.timingData_.datetimeMeasured = this.referenceDatetime;
            this = this.updateTimingData;
        end
        function dt_  = referenceDatetime(this, varargin)
            %% for tracer
            %  @param tracer
            %  @param snumber
            
            if isempty(this.sessionData_)
                dt_ = this.mMR.scanStartTime_Hh_mm_ss(1);
                assert(isdatetime(dt_));
                return
            end
            
            ip = inputParser;
            addParameter(ip, 'tracer',  this.sessionData.tracer, @ischar);
            addParameter(ip, 'snumber', this.sessionData.snumber, @isnumeric);
            parse(ip, varargin{:});
            
            dt_ = this.tracerAdmin_.TrueAdmin_Time_Hh_mm_ss( ...
                this.tracerCode(ip.Results.tracer, ip.Results.snumber));
            dt_.TimeZone = this.preferredTimeZone;
        end
        
 		function this = XlsxObjScanData(varargin)
 			%% XLSXOBJSCANDATA
            %  @param fqfilename of xlsx.
            %  @param sessionData is an mlpipeline.ISessionsData and provides a default fqfilename.

 			ip = inputParser;
            addParameter(ip, 'fqfilename', '', @ischar);
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'timingData', mldata.TimingData, @(x) isa(x, 'mldata.TimingData'));
            addParameter(ip, 'forceDateToReferenceDate', true, @islogical);
            parse(ip, varargin{:});            
            ipr = ip.Results;
            
            this.sessionData_              = ipr.sessionData;
            this.fqfilename                = ipr.fqfilename;
            if isempty(this.fqfilename)
                this.fqfilename            = this.sessionData_.CCIRRadMeasurements; 
            end
            if ~lexist(this.fqfilename, 'file')
                error('mlsiemens:fileNotFound', 'XlsxObjScanData.ctor');
            end
            this.timingData_               = ipr.timingData;
            this.forceDateToReferenceDate_ = ipr.forceDateToReferenceDate;
 			this = this.readtable;        
            this.calibrationVisitor_       = mlsiemens.CalibrationVisitor(this);
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)        
        function tbl  = correctDates2(this, tbl, varargin)
            %% CORRECTDATES2 overrides mlio.AbstractXlsxIO
            
            vars = tbl.Properties.VariableNames;
            for v = 1:length(vars)
                col = tbl.(vars{v});
                if (this.hasTimings(vars{v}))
                    if (any(isnumeric(col)))                        
                        lrows = logical(~isnan(col) & ~isempty(col));
                        xlsx = mldata.Xlsx;
                        dt_   = xlsx.datetimeConvertFromExcel(tbl{lrows,v});
                        col   = NaT(size(col));
                        col.TimeZone = dt_.TimeZone;
                        col(lrows) = dt_;
                        if (~this.isTrueTiming(vars{v}))
                            col(lrows) = col(lrows) - this.adjustClock4(vars{v}, varargin{:});
                        end
                    end
                    if (any(isdatetime(col)))
                        col.TimeZone = this.preferredTimeZone;
                        lrows = logical(~isnat(col));
                        col(lrows) = this.correctDateToReferenceDate(col(lrows));
                        if (~this.isTrueTiming(vars{v}))
                            col(lrows) = col(lrows) - this.adjustClock4(vars{v}, varargin{:});
                        end
                    end
                end
                tbl.(vars{v}) = col;
            end
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)        
        calibrationVisitor_
        capracCalibration_
        capracHeader_
        clocks_
        cyclotron_
        fdg_
        forceDateToReferenceDate_
        mMR_
        oo_
        phantom_
        sessionData_
        timingData_  
        tracerAdmin_
        twilite_      
    end
    
    methods (Access = private)
        function c    = convertClocks2sec(this, c)
            try
                for ic = 1:length(c.TimeOffsetWrtNTS____s)
                    c.TimeOffsetWrtNTS____s(ic) = this.excelNum2sec(c.TimeOffsetWrtNTS____s(ic));
                end
            catch ME
                %dispwarning(ME);
                for ic = 1:length(c.TIMEOFFSETWRTNTS____S)
                    c.TIMEOFFSETWRTNTS____S(ic) = this.excelNum2sec(c.TIMEOFFSETWRTNTS____S(ic));
                end
            end
            % TIMEOFFSETWRTNTS____S
        end
        function dur  = adjustClock4(this, varargin)
            ip = inputParser;
            addRequired(ip, 'varName', @ischar);
            addOptional(ip, 'wallClockName', '', @ischar);
            parse(ip, varargin{:});            
            vN = lower(ip.Results.varName);
            wCN = ip.Results.wallClockName;
            
            try
                if (~isempty(wCN))
                    dur = seconds(this.clocks.TimeOffsetWrtNTS____s(wCN));
                    return
                end
                if (lstrfind(vN, 'drawn'))
                    dur = seconds(this.clocks.TimeOffsetWrtNTS____s('hand timers')); 
                    return
                end
            catch ME
                if (~isempty(wCN))
                    dur = seconds(this.clocks.TIMEOFFSETWRTNTS____S(wCN));
                    return
                end
                if (lstrfind(vN, 'drawn'))
                    dur = seconds(this.clocks.TIMEOFFSETWRTNTS____S('hand timers')); 
                    return
                end

            end
            
            %TIMEOFFSETWRTNTS____S
            
%             if (lstrfind(vN, 'counted'))
%                 dur = seconds(this.clocks.TimeOffsetWrtNTS____s('CT radiation lab'));
%                 return
%             end
            dur = seconds(0);
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
            dtRef        = this.referenceDate;
            dt_.Year     = dtRef.Year;
            dt_.Month    = dtRef.Month;
            dt_.Day      = dtRef.Day;
            dt_.TimeZone = dtRef.TimeZone;
        end
        function this = updateTimingData(this)
            if isempty(this.sessionData_) || ...
                    ~lstrcmp(upper(this.sessionData.tracer), 'FDG')
                return
            end            
            td       = this.timingData_;
            t        = this.measurementsTable2timesDrawn;
            td.times = double(t - t(1));      
            this.timingData_ = td;
        end
        function t    = measurementsTable2timesDrawn(this)
            timedrawn = ensureDatetime(this.fdg.TIMEDRAWN_Hh_mm_ss);
            t = seconds(timedrawn - timedrawn(1));
            t = ensureRowVector(t);
        end
    end
    
    %% HIDDEN, DEPRECATED
    
    methods (Hidden)
        function fn = crv(this)
            tbl = readtable(fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Twilite census.xlsx'), ...
                'Sheet', 'Sheet 1 - DateTable', ...
                'filetype', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false, 'DatetimeType', 'exceldatenum');            
            
            for id = 1:length(tbl.Date)                
                date_ = this.sessionData.datetime;
                date_.Hour = 0;
                date_.Minute = 0;
                date_.Second = 0;
                xlsx = mldata.Xlsx;
                if (date_ == xlsx.datetimeConvertFromExcel(tbl.Date(id)) && ...
                    1 == tbl.Human(id))
                    fn = tbl.Filename(id);
                    if (iscell(fn))
                        fn = fn{1};
                    end
                    return
                end
            end
            error('mlsiemens:soughtDataNotFound', 'XlsxObjScanData.crv');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

