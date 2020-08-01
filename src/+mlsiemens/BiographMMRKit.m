classdef BiographMMRKit < handle & mlsiemens.BiographKit
	%% BIOGRAPHMMRKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 16:09:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    methods (Static)
        function this = createFromSession(varargin)
            this = mlsiemens.BiographMMRKit('sessionData', varargin{:});            
        end
    end
    
    methods
        function d = buildScannerDevice(this)
            d = mlsiemens.BiographMMRDevice.createFromSession( ...
                this.sessionData, 'radMeasurements', this.radMeasurements);
        end
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = BiographMMRKit(varargin)
            this = this@mlsiemens.BiographKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

