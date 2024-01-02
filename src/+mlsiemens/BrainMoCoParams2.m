classdef BrainMoCoParams2
    %% line1
    %  line2
    %  
    %  Created 19-Apr-2023 00:15:19 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiements/src/+mlsiements.
    %  Developed on Matlab 9.14.0.2206163 (R2023a) for MACI64.  Copyright 2023 John J. Lee.

    properties (Dependent)
        %---------------------------------------
        % SECTION 1 -- Reconstruction Parameters
        %---------------------------------------
        % These parameters will be used for both the conventional non-motion-corrected
        % reconstruction and the new brain-motion-corrected reconstruction
        %
        % Resolution -- transaxial resolution of reconstructed images. This is typically
        %               200 or 400 for mCT, 220 or 440 for Vision, 172 or 344 for mMR,
        %               and 180 or 360 for Horizon.
        %               If this is not set to one of these, the selection will be adjusted
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
        
        Resolution
    end

    properties
        Gaussian              =     0          %FWHM in mm for Gaussian postfilter. If both Gaussian
                                               %and Hanning are non-zero, Gaussian is used
        Hanning               =     0          %FWHM in mm for Hanning postfilter
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
        doBMCRecon            =     0     % static BMC recon
        doBMCDynamic          =     1     % dynamic BMC recon      

        %-----------------------------------
        % How do you want to see the output? (interfile is always enabled)
        %-----------------------------------
        
        doMakeDicom           =     0     % convert conventional recon to Dicom
        doBMCMakeDicom        =     0     % convert static BMC to Dicom
        doDYNMakeDicom        =     0     % convert dynamic BMC to Dicom
    end

    properties (Dependent)
        %---------------------
        % For Dynamic BMC Only (ignored if doBMCDynamic disabled) 
        %---------------------
        %
        % LMFrames -- framing parameters. Syntax is S:L,L,L,L,L...
        %             where S=StartTime L=FrameLength. Times in seconds.
        LMFrames
    end

    properties
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

    methods %% GET
        function g = get.LMFrames(this)
            g = this.LMFrames_;
        end
        function g = get.Resolution(this)
            if startsWith(this.tracer_, "oo", IgnoreCase=true)
                switch convertCharsToStrings(lower(this.model_))
                    case "mct"
                        g = 400;
                    case "vision"
                        g = 440;
                    case "mmr"
                        g = 344;
                    case "horizon"
                        g = 360;
                    otherwise
                        error("mlsiemens:ValueError", "%s: this.model->%s", stackstr(), this.model_)
                end
                return
            end
            switch convertCharsToStrings(lower(this.model_))
                case "mct"
                    g = 400;
                case "vision"
                    g = 440;
                case "mmr"
                    g = 344;
                case "horizon"
                    g = 360;
                otherwise
                    error("mlsiemens:ValueError", "%s: this.model->%s", stackstr(), this.model_)
            end
        end
    end

    methods
        function this = BrainMoCoParams2(opts)
            %% Args:
            %  opts.LMFrames {mustBeTextScalar} = "0:10,10,10,..." using "start:len,len,len,..." in sec
            %  opts.model {mustBeTextScalar} = "Vision"
            %  opts.tracer {mustBeTextScalar} = "fdg" or otherwise recognized by mlpet.Radionuclides
            %  opts.filepath {mustBeFolder} = pwd
            
            arguments
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:120"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "unknown"
                opts.filepath {mustBeFolder} = pwd
                opts.tag {mustBeTextScalar} = "-start"
                opts.tag0 {mustBeTextScalar} = "-start0"
                opts.starts double {mustBeScalarOrEmpty} = 0
                opts.is_dyn logical = true
                opts.doIF2Dicom logical = false
                opts.clean_up logical = false
                opts.do_jsr logical = false
                opts.do_bmc logical = true
            end
            this.Skip = opts.Skip;
            this.LMFrames_ = convertCharsToStrings(opts.LMFrames);
            this.model_ = convertCharsToStrings(opts.model);
            this.tracer_ = convertCharsToStrings(opts.tracer);
            this.filepath_ = convertCharsToStrings(opts.filepath);

            this.doBMCDynamic = double(opts.is_dyn); % dynamic BMC recon

            if startsWith(opts.tracer, "oo", IgnoreCase=true)
            end
        end
        function fn = fqfilename(this)
            ss = strsplit(this.LMFrames_, ":");
            start_time_ = str2double(ss(1));
            frame_lengths_ = str2num(ss(2)); %#ok<ST2NM>
            fn = fullfile( ...
                this.filepath_, ...
                sprintf("params_%s_%s_start%is_tau%is_nframes%i.txt", ...
                    lower(this.model_), lower(this.tracer_), ...
                    start_time_, frame_lengths_(1), length(frame_lengths_)));
        end
        function s = LMFramesStart(this)
            ss = strip(this.LMFrames, ":");
            s = str2double(ss(1));
        end
        function writelines(this, fqfn)
            arguments
                this mlsiemens.BrainMoCoParams2
                fqfn {mustBeTextScalar} = this.fqfilename()
            end

            lines = ...
                ["#-------------------------------------------#"; ...
                 "#        Parameter file for BMC.js          #"; ...
                 "#-------------------------------------------#"];
            p = properties(this);
            for idx = 1:length(p)
                if istext(this.(p{idx}))
                    line = sprintf("%s\t:=\t%s", p{idx}, this.(p{idx}));
                elseif isnumeric(this.(p{idx}))
                    line = sprintf("%s\t:=\t%d", p{idx}, this.(p{idx}));
                else
                    error("mlsiemens:TypeError", "%s: class(%s)->%s", stackstr(), p{idx}, class(this.(p{idx})))
                end
                lines = [lines; line]; %#ok<AGROW>
            end
            writelines(lines, fqfn);
        end
    end

    %% PRIVATE
    
    properties (Access = private)
        filepath_
        LMFrames_
        model_
        tracer_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
