classdef VisionRegistry < mlpatterns.Singleton
	%% VISIONREGISTRY  

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
                this = mlsiemens.VisionRegistry();
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
            %  Sluis J van, Jong J de, Schaar J, Noordzij W, Snick P van, Dierckx R, Borra R, Willemsen A, Boellaard R. 
            %  Performance Characteristics of the Digital Biograph Vision PET/CT System. 
            %  J Nucl Med. Society of Nuclear Medicine; 2019 Jul 1;60(7):1031–1036. 
            %  Available from: http://jnm.snmjournals.org/content/60/7/1031 PMID: 30630944.
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
            
            ps = [3.6 3.6 3.5];
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
 		function this = VisionRegistry(varargin)
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

