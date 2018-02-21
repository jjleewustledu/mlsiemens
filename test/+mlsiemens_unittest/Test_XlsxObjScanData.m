classdef Test_XlsxObjScanData < matlab.unittest.TestCase
	%% TEST_XLSXOBJSCANDATA 

	%  Usage:  >> results = run(mlsiemens_unittest.Test_XlsxObjScanData)
 	%          >> result  = run(mlsiemens_unittest.Test_XlsxObjScanData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Jul-2017 18:09:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/test/+mlsiemens_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        fqfilename = fullfile(getenv('HOME'), 'Documents/private/CCIRRadMeasurements 2016sep9.xlsx')
 		registry
        sessd
        subjectsDir = '/data/nil-bluearc/raichle/PPGdata/jjlee2'
 		testObj
 	end

	methods (Test)
        function test_capracHeader(this)
            this.verifyClass(this.testObj.capracHeader, 'table');
            datecell = this.testObj.capracHeader{1,2};
            [~,d] = version;
            if (datetime(d) >= datetime(2016,9,7))
                this.verifyEqual(datecell{1}, '09-Sep-2016');
                return
            end
            this.verifyEqual(datecell{1}, '41160');
        end
        function test_fdg(this)
            import mldata.TimingData.*;
            this.verifyClass(this.testObj.fdg, 'table');
            this.verifyEqual( ...
                this.testObj.fdg.TIMEDRAWN_Hh_mm_ss(1), setPreferredTimeZone(datetime(2016,9,9,12,01,02)));
            this.verifyEqual( ...
                this.testObj.fdg.Ge_68_Kdpm(1), 0);
        end
        function test_oo(this)
            import mldata.TimingData.*;
            this.verifyClass(this.testObj.oo, 'table');
            this.verifyEqual( ...
                this.testObj.oo.TIMEDRAWN_Hh_mm_ss(1), setPreferredTimeZone(datetime(2016,9,9,10,23,08)));
            this.verifyEqual( ...
                this.testObj.oo.Ge_68_Kdpm(1), 442.8);
        end
        function test_tracerAdmin(this)
            import mldata.TimingData.*;
            this.verifyClass(this.testObj.tracerAdmin, 'table');
            this.verifyEqual( ...
                this.testObj.tracerAdmin.ADMINistrationTime_Hh_mm_ss('C[15O]'), ...
                setPreferredTimeZone(datetime(2016,9,9,10,11,36)));
            this.verifyEqual( ...
                this.testObj.tracerAdmin.TrueAdmin_Time_Hh_mm_ss('C[15O]'), ...
                setPreferredTimeZone(datetime(2016,9,9,10,09,19)));
            this.verifyEqual( ...
                this.testObj.tracerAdmin.dose_MCi('C[15O]'), 21);
        end
        function test_clocks(this)
            this.verifyClass(this.testObj.clocks, 'table');
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('mMR console'), 7);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('PMOD workstation'), 0);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('mMR PEVCO lab'), -118);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('CT radiation lab'), 0);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('hand timers'), 137);
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s('2nd PEVCO lab'), 0);
        end
        function test_referenceDate(this)
            this.verifyEqual(this.testObj.referenceDate, datetime(2016,9,9, 'TimeZone', 'America/Chicago'));
        end
        function test_datetime(this)
        end
        function test_referenceDatetime(this)
            this.verifyEqual(this.testObj.referenceDatetime, setPreferredTimeZone(datetime(2016,9,9,12,00,43)));
        end
        function test_fqfilename(this)
            import mlsiemens.*;
            this.verifyEqual(this.testObj.fqfilename, this.fqfilename)
            obj = XlsxObjScanData('sessionData', this.sessd);
            this.verifyEqual(obj.fqfilename, this.fqfilename);
        end
        function test_fqfilename2(this)
            import mlsiemens.*;
            sessd_ = this.sessd;
            sessd_.sessionDate = datetime(2016, 9, 23);
            obj = XlsxObjScanData('sessionData', sessd_);
            this.verifyEqual(obj.fqfilename, ...
                fullfile(getenv('HOME'), 'Documents/private/CCIRRadMeasurements 2016sep23.xlsx'));
        end
        function test_mMR(this)
            disp(this.testObj.mMR);
        end
        
        function test_capracInvEfficiency(this)
            import mlsiemens.*;
            masses0 = CalibrationVisitor.aperture_mass_;
            masses  = linspace(0.01, 2.5 - 0.01, 100);
            invEff0 = CalibrationVisitor.aperture_pred_ ./ mlsiemens.CalibrationVisitor.aperture_meas_;
            invEff  = this.testObj.capracInvEfficiency(1, masses);
            figure;
            plot(masses0, invEff0, 'o', masses, invEff, '-');
            title(sprintf('%s:  test_capracInvEfficiency', class(this)), 'Interpreter', 'none');
            xlabel('mass / g');
            ylabel('Caprac efficiency^{-1}');
        end
	end

 	methods (TestClassSetup)
		function setupXlsxObjScanData(this)
 			import mlsiemens.* mlraichle.*;
            this.sessd = SessionData( ...
                'studyData', StudyData, ...
                'sessionPath', fullfile(this.subjectsDir, 'HYGLY28', ''), ...
                'sessionDate', datetime('9-Sep-2016'));
 			this.testObj_ = XlsxObjScanData( ...
                'sessionData', this.sessd, ...
                'fqfilename', this.fqfilename);
 		end
	end

 	methods (TestMethodSetup)
		function setupXlsxObjScanDataTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

