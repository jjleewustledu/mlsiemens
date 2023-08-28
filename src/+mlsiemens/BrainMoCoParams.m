classdef BrainMoCoParams
    %% line1
    %  line2
    %  
    %  Created 19-Apr-2023 00:15:19 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiements/src/+mlsiements.
    %  Developed on Matlab 9.14.0.2206163 (R2023a) for MACI64.  Copyright 2023 John J. Lee.
    
    properties
        %---------------------------------------
        % SECTION 1 -- Reconstruction Parameters
        %---------------------------------------

        % These parameters will be used for both the conventional non-motion-corrected
        % reconstruction and the new brain-motion-corrected reconstruction
        %
        % Resolution  -- transaxial resolution of reconstructed images. This is typically
        %                200 or 400 for mCT, 220 or 440 for Vision, 172 or 344 for mMR,
        %                and 180 or 360 for Horizon.
        %                If this is not set to one of these, the selection will be adjusted
        % Gaussian    -- isotropic gaussian postfilter FWHM in mm
        % Hanning     -- isotropic Hanning postfilter FWHM in mm
        % FBP         -- enable FBP reconstruction (OP is the default)
        % PSF         -- 0 = disable PSF. 1 = enable PSF.
        % TOF         -- 0 = disable TOF. 1 = enable TOF.
        % Iterations  -- %iterations in iterative reconstruction
        % Subsets     -- %subsets in iterative reconstruction (Vision always 5)
        % CTMatch     -- Set to enable CT matching
        % Zoom        -- must be 1 or 2. Enforced.
        % NACFlag     -- set for no attenuation correction
        % Skip        -- skip this many seconds at the beginning of the listmode file

        %Resolution            =    400        %for mCT
        Resolution             =    440        %for Vision
        %Resolution            =    344        %for mMR
        %Resolution            =    360        %for Horizon

        Gaussian              =     0          %FWHM in mm for Gaussian postfilter. If both Gaussian
                                               %and Hanning are non-zero, Gaussian is used
        Hanning               =     0          %FWHM in mm for Hanning postfilter
        FBP                   =     0
        PSF                   =     1
        TOF                   =     1          %automatically set to 0 for mMR & Horizon
        Iterations            =     4
        Subsets               =     5          %automatically set to 5 for Vision
        CTMatch               =     0
        Zoom                  =     2
        NACFlag               =     0
        AbsFlag               =     1          %set for absolute scatter
        Skip                  =     0          %skip the first N seconds

        %----------------------------
        % SECTION 2 -- Script Control
        %----------------------------

        %--------------------------------------------------
        % Which kinds of reconstructions do you want to do?
        %--------------------------------------------------

        doConventional        =     0     % conventional recon
        doBMCRecon            =     1     % static BMC recon
        doBMCDynamic          =     1     % dynamic BMC recon
        
        %-----------------------------------
        % How do you want to see the output? (interfile is always enabled)
        %-----------------------------------
        
        doMakeDicom           =     1     % convert conventional recon to Dicom
        doBMCMakeDicom        =     1     % convert static BMC to Dicom
        doDYNMakeDicom        =     1     % convert dynamic BMC to Dicom
        
        %---------------------
        % For Dynamic BMC Only (ignored if doBMCDynamic disabled)
        %---------------------

        % LMFrames    -- framing parameters. Syntax is S:L,L,L,L,L...
        %                where S=StartTime L=FrameLength. Times in seconds.

        LMFrames = []
        
        %-------------------------------------------%
        %-------------------------------------------%
        %              IGNORE THE REST              %
        %-------------------------------------------%
        %-------------------------------------------%
        
        %-------------------------------------------
        % SECTION 3 -- Miscellaneous debugging flags
        %-------------------------------------------

        % These flags are here for debugging.
        % They should always be set.

        % Initialization
        doKickoff             =     1
        % Conventional recon         1
        doJSRecon12           =     1
        doMakeUMap            =     1
        doHistogramming       =     1
        doRecon               =     1
        % BMC recon                  1
        doCopyFolder          =     1
        doBMCJSRecon          =     1
        doBMCMakeUMap         =     1
        doPreliminaries       =     1
        doProcessAll          =     1
        doInkiStep_0          =     1
        doInkiStep_1          =     1
        doInkiStep_2          =     1
        doInkiStep_3          =     1
        doInkiStep_4          =     1
        doInkiStep_5          =     1
        % Collect results            1
        doCollect             =     1
    end

    methods
        function this = BrainMoCoParams(opts)
            %% Args:
            %  opts.model {mustBeTextScalar} = "Vision"
            
            arguments
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "fdg"
            end            
            this.model_ = opts.model;
            this.tracer_ = opts.tracer;
        end
        function writelines(this, opts)
            arguments
                this mlsiemens.BrainMoCoParams
                opts.fname {mustBeTextScalar} = ""
                opts.start_time {mustBeInteger} = 0
                opts.frame_lengths {mustBeNumeric} = 10*ones(1,6)
            end
            if "" == opts.fname
                opts.fname = sprintf("params_%s_%s.txt", lower(this.model_), lower(this.tracer_));
            end

            lines = "";
            p = properties(this);
            for idx = 1:length(p)
                if ~contains(p{idx}, 'LMFrames')
                    line = sprintf("%s\t:=\t%d", p{idx}, this.(p{idx}));
                else
                    c = mat2str(opts.frame_lengths);
                    s = c(2:end-1);
                    frames = strrep(s, " ", ",");
                    line = sprintf("LMFrames\t:=\t%d:%s", opts.start_time, frames);
                end
                lines = [lines; line]; %#ok<AGROW>
            end
            writelines(lines, opts.fname);
        end
    end

    %% PRIVATE
    
    properties (Access = private)
        model_
        tracer_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
