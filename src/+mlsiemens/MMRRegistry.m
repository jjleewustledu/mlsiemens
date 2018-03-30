classdef MMRRegistry < mlpatterns.Singleton
	%% MMRREGISTRY  

	%  $Revision$
 	%  was created 16-Oct-2015 10:49:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
    
    
	properties (Constant)
        DISPERSION_LIST  = { 'fwhh' 'sigma' };
    end
    
    methods
        function g = testStudyData(~, reg)
            assert(ischar(reg));
            g = mlpipeline.StudyDataSingletons.instance(reg);
        end
        function g = testSessionData(this, reg)
            assert(ischar(reg));
            studyData = this.testStudyData(reg);
            iter = studyData.createIteratorForSessionData;
            g = iter.next;
        end
    end
    
    methods (Static)
        function this = instance(qualifier)
            %% INSTANCE uses string qualifiers to implement registry behavior that
            %  requires access to the persistent uniqueInstance
            persistent uniqueInstance
            
            if (exist('qualifier','var') && ischar(qualifier))
                if (strcmp(qualifier, 'initialize'))
                    uniqueInstance = [];
                end
            end
            
            if (isempty(uniqueInstance))
                this = mlsiemens.MMRRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
    methods
        function ps   = petPointSpread(this, varargin)
            %% PETPOINTSPREAD
            %  The fwhh at 1cm from axis was measured by:
            %  Delso, Fuerst Jackoby, et al.  Performance Measurements of the Siemens mMR Integrated Whole-Body PET/MR
            %  Scanner.  J Nucl Med 2011; 52:1?9.
            %  @param optional dispersion may be "fwhh" (default) or "sigma"
            %  @param optional geometricMean is logical (default is false)
            %  @return a scalar or 3-vector in mm
        
            ip = inputParser;
            addOptional( ip, 'dispersion',   'fwhh', @(s) lstrfind(lower(s), this.DISPERSION_LIST));
            addParameter(ip, 'mean',         true, @islogical);
            addParameter(ip, 'imgblur_4dfp', false, @islogical);
            parse(ip, varargin{:});
            
            ps = [4.3 4.3 4.3];
            if (strcmp(ip.Results.dispersion, 'sigma'))
                ps = fwhh2sigma(ps);
            end
            if (ip.Results.mean)
                ps = mean(ps);
            end
            if (ip.Results.imgblur_4dfp)
                ps = sprintf('_b%i', floor(10*mean(ps)));
            end
        end     
    end
    
	methods (Access = 'private')
 		function this = MMRRegistry(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

