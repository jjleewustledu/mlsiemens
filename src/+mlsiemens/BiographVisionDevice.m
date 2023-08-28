classdef BiographVisionDevice < handle & mlsiemens.BiographDevice
	%% BIOGRAPHVISIONDEVICE represents the Siemens Biograph 128 Vision 600 Edge scanner.

	%  $Revision$
 	%  was created 18-Mar-2020 15:16:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
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
            this = BiographVisionDevice( ...
                calibration=BiographCalibration.create(bids_med, counter, radionuclide), ...
                data=BiographVisionData.create(bids_med, counter));
        end
        function this = createFromSession(varargin)
            import mlsiemens.*;
            this = BiographVisionDevice( ...
                calibration=BiographCalibration.createFromSession(varargin{:}), ...
                data=BiographVisionData.create(varargin{:}));
        end
        function ie = invEfficiencyf(sesd)
            try
                this = mlsiemens.BiographVisionDevice.create(sesd);
            catch ME 
                handwarning(ME)
                this = mlsiemens.BiographVisionDevice.createFromSession(sesd);
            end            
            ie = this.invEfficiency_;
        end
    end

    %% PRIVATE

	methods (Access = private)
 		function this = BiographVisionDevice(varargin)
 			this = this@mlsiemens.BiographDevice(varargin{:}); 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end
