classdef Herscovitch1985_15O < mlsiemens.Herscovitch1985
	%% HERSCOVITCH1985_15O  

	%  $Revision$
 	%  was created 16-Jun-2018 15:34:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = Herscovitch1985_15O(varargin)
 			%% HERSCOVITCH1985_15O
 			%  @param .

 			this = this@mlsiemens.Herscovitch1985(varargin{:});
            
            this = this.deconvolveAif;
            this.aif_ = this.aif_.setTime0ToInflow;
            this.aif_.timeDuration = this.configAifTimeDuration(this.sessionData.tracer);
            this.scanner_ = this.scanner.setTime0ToInflow;
            this.scanner_.timeDuration = this.aif.timeDuration;
            
            this.scanner_.isDecayCorrected = false; % decay-uncorrected with zero-time at bolus inflow
            tzero = seconds(this.scanner_.datetime0 - this.aif_.datetime0); % zero-times in the aif frame
            this.aif_ = this.aif_.shiftWorldlines(tzero, this.aif_.time0); 
            
            % mMR            |   /----------
            %                |  /
            %                | time0
            %     dt00       dt0
            %
            % Twi                        |   |\ deconv
            %                            |  /   \ 
            %                            | time0
            %           dt00             dt0
            %                ^
            %                tzero in Twi frame  
 		end
 	end 

    %% PROTECTED    
    
    methods (Static, Access = protected)
        function [aif,scanner,mask] = configAcquiredData(sessd)
            import mlsiemens.*;             
            assert(strcmpi(sessd.tracer, 'OC') || ...
                   strcmpi(sessd.tracer, 'OO') || ...
                   strcmpi(sessd.tracer, 'HO'), ...
                   'mlsiemens:unexpectedParamValue', 'Herscovitch1985_15O.sessd.tracer->%s', sessd.tracer);
            sessdFdg = sessd;
            sessdFdg.tracer = 'FDG';
            
            mand = XlsxObjScanData('sessionData', sessd);
            COMM = mand.tracerAdmin.COMMENTS(sessd.doseAdminDatetimeTag);
            if (iscell(COMM)) 
                COMM = COMM{1}; 
            end
            if (ischar(COMM))
                COMM = lower(COMM);
                if (~isempty(COMM))
                    if (lstrfind(COMM, 'fail') || lstrfind(COMM, 'missing'))
                        error('mlsiemens:dataAcquisitionFailure', ...
                            'Herscovitch195.configAcquiredData.COMM->%s', COMM);
                    end
                end
            end
            
            aif = mlswisstrace.Twilite( ...
                'scannerData',       [], ...
                'fqfilename',        sessd.studyCensus.arterialSamplingCrv, ...
                'invEfficiency',     sessd.INV_EFF_TWILITE, ...
                'sessionData',       sessd, ...
                'manualData',        mand, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'isotope', '15O');
            mask = sessdFdg.MaskOpFdg;
            if (~lexist(sessd.tracerResolvedFinal, 'file'))
                error('mlsiemens:fileNotFound', 'Herscovitch.configAcquiredData');
            end
            scanner = mlsiemens.BiographMMR( ...
                sessd.tracerResolvedFinal('typ','niftid'), ...
                'sessionData',       sessd, ...
                'doseAdminDatetime', mand.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(sessd.doseAdminDatetimeTag), ...
                'invEfficiency',     sessd.INV_EFF_MMR, ...
                'manualData',        mand, ...
                'mask',              mask);
            scanner.dt = 1;
            [aif,scanner] = Herscovitch1985.adjustClocks(aif, scanner);
            [aif,scanner] = Herscovitch1985.writeAcquisitionDiary(sessd, aif, scanner);
        end       
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

