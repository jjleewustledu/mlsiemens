classdef BiographVisionData < handle & mlsiemens.BiographData
	%% BIOGRAPHVISIONDATA  

	%  $Revision$
 	%  was created 07-Mar-2020 17:56:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function this = createFromSession(sesd)
            assert(isa(sesd, 'mlpipeline.ISessionData'))
            this = mlsiemens.BiographVisionData( ...
                'isotope', sesd.isotope, ...
                'tracer', sesd.tracer, ...
                'datetimeMeasured', sesd.datetime, ...
                'taus', sesd.taus);
            this = this.read(sesd.tracerResolvedToSubject());
        end
        function fwhh = petPointSpread
            fwhh = mlsiemens.VisionRegistry.instance.petPointSpread;
        end
    end

	methods 
		  
 		function this = BiographVisionData(varargin)
 			%% BIOGRAPHVISIONDATA
            %  @param isotope in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %  @param tracer.
            %  @param datetimeMeasured is the measured datetime for times(1).  MANDATORY.
 			%  @param datetimeForDecayCorrection.
            %  @param dt is numeric and must satisfy Nyquist requirements of the client.
 			%  @param taus  are frame durations.
 			%  @param time0 >= this.times(1).
 			%  @param timeF <= this.times(end).
 			%  @param times are frame starts.

 			this = this@mlsiemens.BiographData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

