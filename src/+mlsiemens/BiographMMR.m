classdef BiographMMR < mlpet.AbstractScannerData
	%% BiographMMR enables polymorphism of NIfTId for PET data.  It is also a NIfTIdecorator.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    properties (Constant)
        READTABLE_HEADERLINES = 0
    end
    
    properties (Dependent)
        activity % in Bq := specificActivity*voxelVolume
        counts   % in Bq/mL := specificActivity without efficiency adjustments; native to scanner     
        decays   % in Bq*s := specificActivity*voxelVolume*tau
        invEfficiency
        specificActivity % activity/volume in Bq/mL
        specificDecays   % decays/volume in Bq*s/mL := specificActivity*tau            
    end    

    methods (Static) 
        function this = load(varargin)
            this = mlsiemens.BiographMMR(mlfourd.NIfTId.load(varargin{:}));
        end
        function this = loadSession(sessd, varargin)
            assert(isa(sessd, 'mlpipeline.ISessionData'))      
            this = mlsiemens.BiographMMR(mlfourd.NIfTId.load(varargin{:}), 'sessionData', sessd);
        end
        function fwhh = petPointSpread
            fwhh = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
    end
    
    methods 
        
        %% GET, SET
        
        function g    = get.activity(this)
            g = this.specificActivity*this.voxelVolume;
        end
        function g    = get.counts(this)
            g = this.img;
        end
        function g    = get.decays(this)
            g = this.specificActivity.*this.taus*this.voxelVolume;
        end
        function g    = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function this = set.invEfficiency(this, s)
            assert(isnumeric(s));
            this.invEfficiency_ = s;
        end  
        function g    = get.specificActivity(this)
            g = double(this.invEfficiency*this.img);
        end
        function g    = get.specificDecays(this)
            g = this.specificActivity;
            for t = 1:length(this.taus)
                g(:,:,:,t) = g(:,:,:,t)*this.taus(t);
            end
        end
        
        %%
        
        function ai   = activityInterpolants(this, varargin)
            ai = this.interpolateMetric(this.activity, varargin{:});
        end  
        function this = buildCalibrated(this)
            this.invEfficiency_ = this.invEfficiency_;
        end
        function ci   = countInterpolants(this, varargin)
            ci = this.interpolateMetric(this.counts, varargin{:});
        end
        function di   = decayInterpolants(this, varargin)
            di = this.interpolateMetric(this.decays, varargin{:});
        end
        function info = dicominfo(this)
            pwd0 = pushd(this.sessionData.tracerRawdataLocation);
            dtool = mlsystem.DirTool('*.dcm');
            info = struct([]);
            for idt = 1:length(dtool.fns)
                info__ = dicominfo(dtool.fns{idt});
                assert(info__.InstanceNumber <= length(dtool.fns));
                info(info__.InstanceNumber) = info__;
            end
            popd(pwd0);
        end
        function this = petobs(this, varargin)
            ip = inputParser;
            addOptional(ip, 'idx0', this.index0, @isnumeric);
            addOptional(ip, 'idxF', this.indexF, @isnumeric);            
            parse(ip, varargin{:});
            idx0 = ip.Results.idx0;
            idxF = ip.Results.idxF;
            
            this.fileprefix = [this.fileprefix '_obs'];
            if (idx0 == idxF)
                this.img = squeeze(this.img);
                return
            end
            this.img = trapz(this.times(idx0:idxF), this.img(:,:,:,idx0:idxF), 4);
        end    
        function sai  = specificActivityInterpolants(this, varargin)
            sai = this.interpolateMetric(this.specificActivity);
        end
        function sdi  = specificDecayInterpolants(this, varargin)
            sdi = this.interpolateMetric(this.specificDecays);
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function v    = voxelVolume(this)
            %  @param this.img is at least 3D
            %  @return voxel volume in mL
            
            assert(length(size(this)) >= 3);
            v = prod(this.mmppix/10);
        end
        
 		function this = BiographMMR(cmp, varargin)
            this = this@mlpet.AbstractScannerData(cmp, varargin{:});
            
            % avoid decorator redundancy
            if (nargin == 1 && isa(cmp, 'mlsiemens.BiographMMR'))
                this = this.component;
                return
            end
                
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'invEfficiency', 1.155, @isnumeric); % from HYGLY28/V2
            parse(ip, varargin{:});    
            this.invEfficiency_ = ip.Results.invEfficiency; 
            this.isDecayCorrected_ = true;     
            this = this.append_descrip('decorated by BiographMMR');
        end        
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
    end
    
    methods (Access = protected)
        function this = createTimingData(this)
            this.timingData_ = mldata.TimingData( ...
                'times',     this.sessionData.times, ...
                'datetimeMeasured', this.sessionData.readDatetime0 - this.manualDataClocksTimeOffsetMMRConsole);
            if (length(size(this)) < 4)
                return
            end
            if (size(this, 4) == length(this.times))
                return
            end
            if (size(this, 4) < length(this.times)) % trim this.times
                this.times = this.times(1:size(this, 4));
            end
            if (length(this.times) < size(this, 4)) % trim this.img
                this.img = this.img(:,:,:,1:length(this.times));
            end
            warning('mlpet:unexpectedNumel', ...
                'AbstractScannerData.createTiminData:  this.times->%i but size(this,4)->%i', ...
                length(this.times), size(this, 4));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

