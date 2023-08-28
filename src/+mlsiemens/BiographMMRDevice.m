classdef BiographMMRDevice < handle & mlsiemens.BiographDevice
	%% BIOGRAPHMMRDEVICE represents the Siemens Biograph mMR scanner.

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.

    methods (Static)
        function this = create(opts)
            arguments
                opts.bids_kit mlkinetics.BidsKit {mustBeNonempty}
                opts.tracer_kit mlkinetics.TracerKit {mustBeNonempty}
            end

            import mlsiemens.*;
            bids_med = opts.bids_kit.make_bids_med();
            counter = opts.tracer_kit.make_handleto_counter();
            radionuclide = opts.tracer_kit.make_radionuclides();
            this = BiographMMRDevice( ...
                calibration=BiographCalibration.create(bids_med, counter, radionuclide), ...
                data=BiographMMRData.create(bids_med, counter));
        end
        function this = createFromSession(varargin)
            import mlsiemens.*;
            this = BiographMMRDevice( ...
                calibration=BiographCalibration.createFromSession(varargin{:}), ...
                data=BiographMMRData.create(varargin{:}));
        end
        function ie = invEfficiencyf(sesd)
            try
                this = mlsiemens.BiographMMRDevice.create(sesd);
            catch ME 
                handwarning(ME)
                this = mlsiemens.BiographMMRDevice.createFromSession(sesd);
            end            
            ie = this.invEfficiency_;
        end
    end 	

    %% PRIVATE

	methods (Access = private)
 		function this = BiographMMRDevice(varargin)
 			this = this@mlsiemens.BiographDevice(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
