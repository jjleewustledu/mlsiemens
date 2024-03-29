classdef BiographMMRData < handle & mlsiemens.BiographData
	%% BIOGRAPHMMRDATA  

	%  $Revision$
 	%  was created 17-Oct-2018 15:57:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
 		R_NUMBER_FINAL = 2
 	end

    methods (Static)
        function consoleTaus(varargin)
            error('mlan:NotImplementedError', stackstr());
        end
        function this = create(bids_med, opts)
            arguments
                bids_med mlpipeline.ImagingMediator {mustBeNonempty}
                opts.counter = [];
            end

            bids_med.rnumber = mlsiemens.BiographMMRData.R_NUMBER_FINAL;
            this = mlsiemens.BiographMMRData( ...
                'isotope', bids_med.isotope, ...
                'tracer', bids_med.tracer, ...
                'datetimeMeasured', bids_med.datetime, ...
                'times', bids_med.times, ...
                'taus', bids_med.taus, ...
                'radMeasurements', opts.counter);
            this.imagingContext_ = bids_med.imagingContext;
        end
        function this = createFromSession(sesd, varargin)
            sesd.rnumber = mlsiemens.BiographMMRData.R_NUMBER_FINAL;
            this = mlsiemens.BiographMMRData( ...
                'isotope', sesd.isotope, ...
                'tracer', sesd.tracer, ...
                'datetimeMeasured', sesd.datetime, ...
                'taus', sesd.taus, ...
                varargin{:});
            this.read(sesd.tracerOnAtlas());
            this.decayUncorrect(); % ensure decay-uncorrected state for legacy pipelines
        end
        function fwhh = petPointSpread
            fwhh = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
    end
    
	methods 		  
 		function this = BiographMMRData(varargin)
 			%% BIOGRAPHMMRDATA
            %  @param isotope in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %  @param tracer.
            %  @param datetimeMeasured is the measured datetime for times(1).  Ctor corrects clocks.  MANDATORY.
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

