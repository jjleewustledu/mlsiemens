classdef VideenAutoradiography < mlsiemens.AutoradiographyBuilder
	%% VIDEENAUTORADIOGRAPHY 
    %  Cf:  Raichle, Martin, Herscovitch, Mintun, Markham, 
    %       Brain Blood Flow Measured with Intravenous H_2[^15O].  II.  Implementation and Valication, 
    %       J Nucl Med 24:790-798, 1983.
    %       Hescovitch, Raichle, Kilbourn, Welch,
    %       Positron Emission Tomographic Measurement of Cerebral Blood Flow and Permeability-Surface Area Product of
    %       Water Using [15O]Water and [11C]Butanol, JCBFM 7:527-541, 1987.
    %  Internal units:   mL, cm, g, s

	%  $Revision$
 	%  was created 25-Jan-2017 16:17:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        A0 = 0.290615
        f  = 0.00987298 % mL/s/mL, [15O]H_2O
        af = 2.035279E-06
        bf = 2.096733E-02
    end

    properties (Dependent)
        baseTitle
        detailedTitle
        map 
        pie
        timeLimits % for scan integration over time, per Videen
    end
    
    methods %% GET/SET 
        function bt = get.baseTitle(this)
            bt = sprintf('Videen Autoradiography %s', this.pnum);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s:\nA0 %g, f %g, af %g, bf %g', ...
                         this.baseTitle, this.A0, this.f, this.af, this.bf);
        end
        function m  = get.map(this)
            m = containers.Map;
            m('A0') = struct('fixed', 0, 'min', 0.3,    'mean', this.A0, 'max', 0.5);
            m('af') = struct('fixed', 1, 'min', 1e-7,   'mean', this.af, 'max', 1e-5); 
            m('bf') = struct('fixed', 1, 'min', 1e-3,   'mean', this.bf, 'max', 1e-1);
            m('f')  = struct('fixed', 0, 'min', 0.0053, 'mean', this.f,  'max', 0.012467); 
        end
        function p  = get.pie(this)
            assert(isnumeric(this.pie_) && isscalar(this.pie_));
            p = this.pie_;
        end
        function tl = get.timeLimits(this)
            assert(isnumeric(this.timeLimits_) && length(this.timeLimits_) == 2);
            tl = this.timeLimits_;
        end
    end

    methods (Static)
        function this = load(maskFn, aifFn, ecatFn, varargin)
            
            p = inputParser;
            addRequired(p, 'maskFn', @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',  @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn', @(x) lexist(x, 'file'));
            addOptional(p, 'aifShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask = VideenAutoradiography.loadMask(p.Results.maskFn); 
            aif  = VideenAutoradiography.loadAif(p.Results.aifFn); 
            ecat = VideenAutoradiography.loadEcat(p.Results.ecatFn);
            args = VideenAutoradiography.interpolateData(mask, aif, ecat, p.Results.aifShift, p.Results.ecatShift); 
            this = VideenAutoradiography(args{:});
            %this.frame0 = this.frame0 - p.Results.ecatShift;
            %this.frameF = this.frameF - p.Results.ecatShift;
        end
        function aif  = loadAif(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',      [], @(x) lexist(x, 'file'));
            addOptional(p, 'iwelldata', [], @(x) isa(x, 'mlpet.IWellData'));
            parse(p, varargin{:});
            
            import mlpet.*;
            if (~isempty(p.Results.fqfn))
                aif = UncorrectedDCV.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iwelldata))
                aif = p.Results.iwelldata;
                return
            end
            error('mlpet:requiredObjectNotFound', 'VideenAutoradiography.loadMask');
        end
        function this = simulateMcmc(A0, af, bf, f, t, conc_a, map, pie, timeLimits, mask, aif, ecat)
            import mlpet.*;       
            conc_i = VideenAutoradiography.estimatedData(A0, af, bf, f, t, conc_a, pie, timeLimits); % simulated
            this   = VideenAutoradiography(conc_a, t, conc_i, mask, aif, ecat);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function ci   = estimatedData(A0, af, bf, f, t, conc_a, pie, timeLimits)
            import mlpet.*;
            petti    = VideenAutoradiography.pett_i(f, t, conc_a);
            sumPetti = sum(petti(timeLimits(1):timeLimits(2))) * (t(2) - t(1)); % well-counts     
            ci       = A0 * petti * VideenAutoradiography.sumPettExpect(af, bf, f, pie) / sumPetti;
        end
        function spe  = sumPettExpect(af, bf, f, pie)
            %% SUMPETTEXPECT
            %  from CBF = af * P^2 + bf * P, P <- \int dt c_i; returning units of well-counts
            
            import mlpet.*;
            CBF = 6000 * f / VideenAutoradiography.BRAIN_DENSITY; 
            spe = (-bf + sqrt(bf^2 + 4 * af * CBF)) / (2 * af);             
            spe = pie * spe; % possibly in error by factor of 60 sec/min
        end
        function ci   = pett_i(f, t, conc_a)
            import mlpet.*;
            lambda = VideenAutoradiography.LAMBDA;
            lambda_decay = VideenAutoradiography.LAMBDA_DECAY;
            ci     = f * conv(conc_a, exp(-(f/lambda + lambda_decay) * t));
            ci     = ci(1:length(t));
        end
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecat = ecat.volumeSummed;   
            import mlpet.*;
            [t_a,c_a] = VideenAutoradiography.shiftData( aif.times,  aif.wellCounts,               aifShift);
            [t_i,c_i] = VideenAutoradiography.shiftData(ecat.times, ecat.becquerels/ecat.nPixels, ecatShift); % well-counts/cc/s     
            dt  = min(min(aif.taus), min(ecat.taus));
            t   = min(t_a(1), t_i(1)):dt:min(t_a(end), t_i(end));
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function tl   = getTimeLimits
            dt = mlsystem.DirTool('p*ho*_f*.nii.gz');
            assert(1 == dt.length);            
            names = regexp(dt.fns{1}, 'p\d+ho\d_f(?<t0>\d+)to(?<tf>\d+).nii.gz', 'names'); % _161616fwhh
            tl(1) = str2double(names.t0);
            tl(2) = str2double(names.tf);
        end
    end
    
	methods
 		function this = VideenAutoradiography(varargin) 
            %% VideenAutoradiography 
            % previously (conc_a, times_i, conc_i, mask, aif, ecat)
 			
            this = this@mlsiemens.AutoradiographyBuilder(conc_a, times_i, conc_i, mask, aif, ecat); 
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'concAShift', 0, @isnumeric);
            addParameter(ip, 'concObsShift', 0, @isnumeric);
            parse(varargin{:});
            
            this.pie_                   = this.ecat_.pie; % caching
            this.timeLimits_            = this.getTimeLimits;
            this.expectedBestFitParams_ = [this.A0 this.af this.bf this.f]'; % initial expected values from properties
        end
        
        function this = buildPetObs(this)
        end
        
        function this = simulateItsMcmc(this, conc_a)
            this = mlpet.VideenAutoradiography.simulateMcmc( ...
                   this.A0, this.af, this.bf, this.f, this.times, conc_a, this.map, this.pie, this.timeLimits, ...
                   this.mask, this.aif, this.ecat);
        end
        function ci   = itsEstimatedData(this)
            ci = mlpet.VideenAutoradiography.estimatedData( ...
                this.A0, this.af, this.bf, this.f, this.times, this.concentration_a, this.pie, this.timeLimits);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'A0' 'af' 'bf' 'f'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.af = this.finalParams('af');
            this.bf = this.finalParams('bf');
            this.f  = this.finalParams('f');
        end
        function ed   = estimateData(this)
            keys = this.paramsManager.paramsMap.keys;
            ed = this.estimateDataFast( ...
                this.finalParams(keys{1}), ...
                this.finalParams(keys{2}), ...
                this.finalParams(keys{3}), ...
                this.finalParams(keys{4}));
        end
        function ed   = estimateDataFast(this, A0, af, bf, f)
            ed = mlpet.VideenAutoradiography.estimatedData( ...
                       A0, af, bf, f, this.times, this.concentration_a, this.pie, this.timeLimits);
        end
        function x    = priorLow(~, x)
            x = 0.01*x;
        end
        function x    = priorHigh(~, x)
            x = 100*x;
        end
        function        plotInitialData(this)
            figure;
            semilogy(this.times, this.concentration_a, ...
                     this.times, this.concentration_obs);
            title(sprintf('AutoradiographyDirector.plotInitialData:  %s', this.ecat.fileprefix), 'Interpreter', 'none');
            legend('aif', 'ecat');
            xlabel('time/s');
            ylabel('well-counts/mL/s');
        end
        function        plotProduct(this)
            figure;
            plot(this.times, this.estimateData, this.times, this.dependentData, 'o');
            legend('Bayesian estimatedData', 'concentration_obj from data');
            title(sprintf('VideenAutoradiography.plotProduct:  A0 %g, af %g, bf %g, f %g', this.A0, this.af, this.bf, this.f), 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end   
        function this = save(this)
            this = this.saveas('VideenAutoradiography.save.mat');
        end
        function this = saveas(this, fn)
            videenAutoradiography = this; %#ok<NASGU>
            save(fn, 'videenAutoradiography');         
        end     
 	end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        timeLimits_
        pie_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

