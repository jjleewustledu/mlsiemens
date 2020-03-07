classdef ECATRegistry < mlpatterns.Singleton2
	%% ECATREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 14:58:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties (Constant)
        DISPERSION_LIST  = {'fwhh' 'sigma'};
        ORIENTATION_LIST = {'radial' 'tangential' 'tan' 'in-plane' 'axial' '3d'};
    end
    
    methods (Static)
        function this = instance(varargin)
            %% INSTANCE 
            %  @param optional qualifier is char \in {'initialize' ''}
            
            ip = inputParser;
            addOptional(ip, 'qualifier', '', @ischar)
            parse(ip, varargin{:})

            persistent uniqueInstance            
            if (strcmp(ip.Results.qualifier, 'initialize'))
                uniqueInstance = [];
            end
            if (isempty(uniqueInstance))
                this = mlsiemens.ECATRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end
    
	methods 
        function ps = petPointSpread(this, varargin)
            %% PETPOINTSPREAD 
            %  @param radialPosition in cm.
            %  @param dispersion \in DISPERSION_LIST.
            %  @param orientation \in ORIENTATION_LIST.
            %  @param imgblur_4dfp is logical for returning char suffix (default is false).
            %  @returns a 3-vector (in-plane, 3d) in mm or scalar (radial, tan, axial) in mm.
            %
            %  FWHH of tangential & radial resolution of ECAT EXACT HR+ 2D mode; cf.
            %  N. Karakatsanis, et al., Nuclear Instr. & Methods in Physics Research A, 569 (2006) 368--372
            %
            %  Table 1. Spatial resolution for two different radial positions (1 and 10 cm from the center of FOV), 
            %  calculated in accordance with the NEMA NU2-2001 protocol
            %
            %  Experimental results 
            %  Radial position (cm)       1     10     ~5
            %
            %  Orientation FWHH
            %  Radial resolution (mm)     4.82   5.65   5.19
            %  Tangential resolution (mm) 4.39   4.64   4.50
            %  In-plane resolution* (mm)  6.52   7.31   6.87
            %  Axial resolution (mm)      5.10   5.33   5.20
            %
            %  Orientation Sigma
            %  Radial resolution (mm)     2.0469 2.3993 2.2035
            %  Tangential resolution (mm) 1.8643 1.9704 1.9114
            %  In-plane resolution* (mm)  2.7688 3.1043 2.9180
            %  Axial resolution (mm)      2.1658 2.2634 2.2092
            %
            %  * by 2-norm
        
            ip = inputParser;
            addParameter(ip, 'radialPosition', 10, @isnumeric);
            addParameter(ip, 'dispersion', 'fwhh', @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addParameter(ip, 'orientation', 'in-plane', @(s) lstrfind(lower(s), this.ORIENTATION_LIST));
            addParameter(ip, 'imgblur_4dfp', false, @islogical);
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            r = abs(ipr.radialPosition);
            switch lower(ipr.orientation)
                case 'radial'
                    ps = radialFit(r);
                case {'tangential' 'tan'}
                    ps = tanFit(r);
                case 'in-plane'
                    r2  = inPlaneFit(r);
                    ps = [r2 r2 axialFit(r)];
                case 'axial'
                    ps = axialFit(r);
                case '3d'
                    r2  = norm([tanFit(r), radialFit(r), axialFit(r)]);
                    ps = [r2 r2 r2];
                otherwise
                    error('mlsiemens:RuntimeError', ...
                          'ECATRegistry.petPointSpread.orientation->%s', ipr.orientation);
            end
            if strcmp(ipr.dispersion, 'sigma')
                ps = fwhh2sigma(ps);
            end
            if ipr.imgblur_4dfp
                ps = sprintf('_b%i', floor(10*mean(ps)));
            end
            
            %% inner methods
            
            function y = radialFit(x)
                r1  = 4.82;
                r10 = 5.65;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = tanFit(x)
                r1  = 4.39;
                r10 = 4.64;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = inPlaneFit(x)
                r1  = norm([4.82 4.39]);
                r10 = norm([5.65 4.64]);
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
            function y = axialFit(x)
                r1  = 5.10;
                r10 = 5.33;
                y   = (r10 - r1)*(x - 10)/9 + r10;
            end
        end  
    end
    
    %% PRIVATE
    
    methods (Access = private)		  
 		function this = ECATRegistry(varargin)
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

