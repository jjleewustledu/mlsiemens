classdef CalibrationContext 
	%% CALIBRATIONCONTEXT  

	%  $Revision$
 	%  was created 30-May-2018 15:55:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		invEffTwilite
        invEffMMR
 	end

	methods 
        
        %% GET/SET
        
        function g = get.invEffTwilite(this)
            g = [];
        end
        function g = get.invEffMMR(~)
            g = 1.1551;
        end
        
        %%
		  
 		function this = CalibrationContext(varargin)
 			%% CALIBRATIONCONTEXT
 			%  @param named sessionContext.
 			
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracerContext', [], @(x) isa(x, 'mlpet.TracerContext'));
            parse(ip, varargin{:});            
            this.tracerContext_ = ip.Results.tracerContext; 		
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        tracerContext_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

