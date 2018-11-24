classdef DecayCorrectedEcat < mlsiemens.EcatExactHRPlus 
	%% DECAYCORRECTEDECAT implements mlpet.IScannerData for data from detection array of Ecat Exact HR+ scanners, then
    %  applies decay correction for the half-life of the selected isotope.  Most useful properties will be
    %  times, timeInterpolants, counts, countInterpolants.  It is also a NIfTIdecorator.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    
    methods (Static)
        function this = load(fileLoc)
            this = mlsiemens.DecayCorrectedEcat(mlfourd.NIfTId.load(fileLoc));
        end
    end

	methods 		  
 		function this = DecayCorrectedEcat(cmp, varargin) 
 			%% DECAYCORRECTEDECAT 
 			%  Usage:  this = DecayCorrectedEcat(INIfTI_object) 

 			this = this@mlsiemens.EcatExactHRPlus(cmp, varargin{:}); 
            assert( isa(cmp, 'mlfourd.INIfTI'));
            assert(~isa(cmp, 'mlsiemens.DecayCorrectedEcat'));
            
            this.decayCorrection_ = mlpet.Decay('isotope', '15O', 'activities', this.counts);
            this.counts = this.decayCorrection_.undecayActivities(this.times);
            this = this.updateFileprefix;
        end 
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
        function this = updateFileprefix(this)
            this.component_.fileprefix = [this.component.fileprefix '_decayCorrect'];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

