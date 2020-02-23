classdef BiographMMRDevice < handle & mlpet.Device
	%% BIOGRAPHMMRDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end
    
    methods (Static)        
        function checkRangeInvEfficiency(ie)
            %  @param required ie is numeric.
            %  @throws mlsiemens:ValueError.
            
            assert(all(0.95 < ie) && all(ie < 1.05), ...
                'mlsiemens:ValueError', ...
                'BiographMMRDevice.checkRangeInvEfficiency.ie->%s', mat2str(ie));
        end
    end

	methods 
		  
 		function this = BiographMMRDevice(varargin)
 			%% BIOGRAPHMMRDEVICE
 			%  @param .

 			this = this@mlpet.Device(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

