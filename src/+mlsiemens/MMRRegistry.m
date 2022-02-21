classdef MMRRegistry < mlpatterns.Singleton
	%% MMRREGISTRY  

	%  $Revision$
 	%  was created 16-Oct-2015 10:49:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.    
    
	properties (Constant)
        DISPERSION_LIST  = {'fwhh' 'sigma'};
    end
    
    methods (Static)
        function this = instance()
            persistent uniqueInstance
            if (isempty(uniqueInstance))
                this = mlsiemens.MMRRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
    methods
        function ps = petPointSpread(this, varargin)
            %% PETPOINTSPREAD
            %  The fwhh at 1cm from axis was measured by:
            %  Delso, Fuerst Jackoby, et al.  Performance Measurements of the Siemens mMR Integrated Whole-Body PET/MR
            %  Scanner.  J Nucl Med 2011; 52:1?9.
            %
            %  @param optional dispersion may be "fwhh" (default) or "sigma".
            %  @param optional mean is logical (default is true).
            %  @param imgblur_4dfp is logical for returning char suffix (default is false).
            %  @param tag is logical for returning char suffix (default is false).
            %  @return a scalar (mean == true) or 3-vector in mm.
            %  @return char suffix, e.g., '_b43'.
        
            ip = inputParser;
            addOptional( ip, 'dispersion',   'fwhh', @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addParameter(ip, 'mean',         true, @islogical);
            addParameter(ip, 'imgblur_4dfp', false, @islogical);
            addParameter(ip, 'tag',          false, @islogical);
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            ps = [4.3 4.3 4.3];
            if strcmp(ipr.dispersion, 'sigma')
                ps = fwhh2sigma(ps);
            end
            if ipr.mean
                ps = mean(ps);
            end
            if ipr.imgblur_4dfp || ipr.tag
                ps = sprintf('_b%i', floor(10*mean(ps)));
            end
        end     
    end
    
    %% PRIVATE
    
	methods (Access = 'private')
 		function this = MMRRegistry(varargin)
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

