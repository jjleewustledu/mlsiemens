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
 		function this = DecayCorrectedEcat(cmp) 
 			%% DECAYCORRECTEDECAT 
 			%  Usage:  this = DecayCorrectedEcat(INIfTI_object) 

 			this = this@mlsiemens.EcatExactHRPlus(cmp); 
            assert( isa(cmp, 'mlfourd.INIfTI'));
            assert(~isa(cmp, 'mlsiemens.DecayCorrectedEcat'));
            
            this.decayCorrection_ = mlpet.DecayCorrection(this);
            this.counts = this.decayCorrection_.correctedCounts(this.counts, this.times(1));
            this = this.updateFileprefix;
            this = this.setTimeMidpoints_dc;
        end 
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        decayCorrection_
    end
    
    methods (Access = 'protected')
        function this = updateFileprefix(this)
            this.component.fileprefix = [this.component.fileprefix '_decayCorrect'];
        end
        function this = setTimeMidpoints_dc(this)
            k_decay = log(2) / this.decayCorrection_.halfLife;
            this.timeMidpoints_ = this.times;
            for t = 2:this.length
                this.timeMidpoints_(t) = this.times(t-1) - (1/k_decay) * log(0.5*(exp(-k_decay*this.taus(t)) + 1));
            end            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

