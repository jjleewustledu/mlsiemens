classdef CalibrationVisitor 
	%% CALIBRATIONVISITOR uses calibration measurements from 
    %  {CCIRRadMeasurements 2017dec6, aperture data from 2017dec6}.numbers, stored as constant private properties below.

	%  $Revision$
 	%  was created 31-Jan-2018 20:02:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        aperture_mass_ = [2.2824 1.7717 1.5618 1.5226 1.5079 1.4905 1.4612 1.3291 1.3243 1.0908 0.9382 0.8421 0.6768 ...
                          0.4998 0.4298 0.4049 0.3851 0.3531 0.2766 0.2469 0.1656 0.0750999999999999 0.0476000000000001]
        % specific activities, kdpm / mL
        aperture_meas_ = [1303.45250613389 1466.95264435288 1539.24958381355 1518.45527387364 1506.73121559785 ...
                          1497.48406574975 1471.39337530797 1479.94883755925 1458.1288227743  1496.1496149615  ...
                          1502.87785120443 1459.44662154138 1483.45153664303 1482.7931172469  1470.21870637506 ...
                          1473.20326006421 1435.7309789665  1403.00198244123 1404.19378163413 1402.59214256784 ...
                          1326.08695652174 1471.37150466045 1554.62184873949]
        aperture_pred_ = [1960.67751013444 1892.55740383939 1855.48050008736 1821.04544826672 1786.30924751463 ...
                          1751.31384081938 1708.35231721859 1675.94209189558 1642.59019078875 1614.31316639972 ...
                          1565.62388408917 1518.4031187066  1482.24668569287 1450             1428.94302752979 ...
                          1406.26656536058 1385.84469201397 1360.12540594084 1335.16443190458 1309.69634719103 ...
                          1287.28552507606 1270.72942932876 1242.56117528013]
    end

	methods
        function a    = capracInvEfficiency1(this, a, m)
            %% CAPRACINVEFFICIENCY1 is a spline extrapolation of calibration syringe with homogeneous tracer;
            %  it includes filling factor effects.
            %  incrementally ejected from the syringe.
            %  @param a is activity.
            %  @param m is sample mass /g; m < 3 g.
            
            assert(all(m < 3));
            a = a .* ppval(this.aperture_spline_, m);
        end
        function a    = capracInvEfficiency(~, a, m)
            %% CORRECTFILLINGFACTOR is a polynomial regression on prefilled, separately weighed calibration samples;
            %  it includes filling factor effects.
            %  @param a is activity.
            %  @param m is sample mass /g; m < 3 g.
            
            assert(all(m < 2.5));
            %a = 1592.7*a ./ (53.495*m.^3 - 298.43*m.^2 + 191.17*m + 1592.7); % from CCIRRadMeasurements.numbers
            % from polyfitting this.aperture_mass -> this.aperture_pred_ ./ this.aperture_meas_
            
            a = a.*(0.11429*m.^5 - 0.74109*m.^4 + 1.7927*m.^3 - 1.8759*m.^2 + 0.96511*m + 0.7927); 
        end
        function sa   = capracCalibrationSpecificActivity(this, varargin)
            %  @param optional array indices.
            %  @return specific activity(array indices) excluding NaN.
            
            m = this.manMeasures_.capracCalibration.MassSample_G;
            m = m(~isnan(m));
            g = this.manMeasures_.capracCalibration.Ge_68_Kdpm;
            g = g(~isnan(g));
            sa = this.capracInvEfficiency(g, m)./m;
            if (~isempty(varargin))
                sa = sa(varargin{:});
            end
        end
        function dt_  = capracCalibrationTimesCounted(this, varargin)
            %  @param optional array indices.
            %  @return datetime(array indices) excluding NaT.
            
            dt_ = this.manMeasures_.capracCalibration.TIMECOUNTED_Hh_mm_ss;
            dt_ = dt_(~isnat(dt_));
            if (~isempty(varargin))
                dt_ = dt_(varargin{:});
            end
        end
        
 		function this = CalibrationVisitor(manMeasures)
 			%% CALIBRATIONVISITOR
 			%  @param required manMeasures is an mldata.IManualMeasurements

            assert(isa(manMeasures, 'mldata.IManualMeasurements'));
            this.manMeasures_ = manMeasures;
            this.aperture_spline_ = ...
                spline(this.aperture_mass_, this.aperture_pred_ ./ this.aperture_meas_);      
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        aperture_spline_ % 1/efficiency of Caprac   
        manMeasures_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

