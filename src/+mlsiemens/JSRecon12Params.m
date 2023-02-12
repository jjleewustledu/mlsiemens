classdef JSRecon12Params
    %% line1
    %  line2
    %  
    %  Created 23-Aug-2022 23:16:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.2009381 (R2022a) Update 4 for MACI64.  Copyright 2022 John J. Lee.

    properties    
        % NOTE: keywords are NOT case-sensitive

        %------------------------------------------------------
        % umapfilter: GAUSS and 4.0 are our standard and should
        % not ordinarily be changed
        umapfiltertype  =   'GAUSS'
        umapfilterxy    =     4.0
        umapfilterz     =     4.0

        %------------------------------------------------------
        % Image zoom (default is 1; many cardiac sites like 2)
        zoom           =   2

        %------------------------------------------------------
        % Postfiltering (all recon methods)
        % To select "no filtering" set postfilterxy AND postfilterz to 0
        postfiltertype  =   'GAUSS'
        postfilterxy    =     0
        postfilterz     =     0

        %------------------------------------------------------
        % matchctslice, 0 = off, 1 = on
        % altctargs, 0 = --ctm UMapPETLo,UMapPETHi,UMapSpacing,UMapThickness

        matchctslice    =       0

        %------------------------------------------------------
        % Set if call to e7_sino should contain "-d ." flag

        Debug           =       0

        %------------------------------------------------------
        % Set to reconstruct without attenuation correction
        % If this flag is set, then all batch files are NAC
        % and the MakeNACBats flag below is ignored

        NACFlag         =       0

        %------------------------------------------------------
        % Set to create NAC batch files in parallel with AC
        % This flag only works if NACFlag above is 0

        MakeNACBats     =       0

        %---------------------------------------------
        % Set to enable absolute scatter
        % Works for mCT VG50 & above, mMR VA20 & above

        AbsFlag         =       0

        %---------------------------------------------
        % Set to disable scatter completely
        % (sets the --nosc flag in e7_recon)

        NoScatter       =       0

        %---------------------------------------------
        % Set to assume "LargeListmode" in software versions VG70+
        %
        % If the flag is set, JSRecon12 converts PTD listmode files
        % to DCM/BF format. If the flag is clear, JSRecon12 converts
        % DCM/BF listmode files to PTD format. This flag is always set
        % for version VR10.

        LargeListmode   =		 0

        %------------------------------------------------------
        % Dynamic Framing
        %
        % Default framing parameters for listmode files.
        % Syntax is S:L,L,L,L,L, ... where S=StartTime
        % and L=FrameLength. Times in seconds. If you
        % say "all", the whole LM file will be used.
        %
        % NOTE: You cannot do gating (above) and dynamic at the same time.
        % If you're doing gating, select "LMFrames = all"

        %LMFrames       = 0:15,15,15,15,15,15,15,15,60,60,60,120,120,120,120,120
        %LMFrames       = 0:300,300,300,300
        %LMFrames        = all
        LMFrames        = 'all'

        %------------------------------------------------------
        % Set to use the GPU for reconstruction
        % Values are equivalent to the possible parameters given
        % in the e7_recon help file. -1 means do not use the GPU
        % This is the safest option. (JSRecon12 does not support GPUs.)

        usegpu          = -1

        %------------------------------------------------------
        % Various mappings & other flags
        %
        % ForceForce:  if set, e7_recon batch files always include the --force flag

        ForceForce      =       0

        %------------------------------------------------------
        % Only valid for mMR data!
        %
        % LMOrderFlag: For -WB- reconstruction. 0 = order by acquisition time (usual choice). 1 = reverse order.
        % usemlaa: set to use MLAA to generate an extended umap (1==true, any other value==false)
        % for mlaaparams, -e, -u, --ou, --gpu, --ext and --force must not be set as those are added programatically
        % TrustedFOV:  if set, TrustedFOV is enabled for mMR VB20P (but not VB18P).

        LMOrderFlag     =       0
        usemlaa         =       0
        TrustedFOV      =       0

        % The following parameters are used in e7_mlaa for V18 and V20
        mlaaparams      = '--is 3,21 --isaa 20,9 --gf -R 2,4 -w 344 --pthr 0.2,0.2 --fov 0.094681,0.933983,0.252103,220,220,190 --beta 0.1,0.001,0.1 --gamma 0.001,0.001 --msw 0,1,1,0.0885,1,1,0.113,1,1,0.0277,1,1 --prior GEMAN_3D'
        % The following parameters are used in e7_mlaa for VE11P
        mlaaVE11P       = '--is 1,1  --isaa 20,9 --gf -R 2,4 -w 344 --pthr 0.2,0.2 --fov 0,0,0,215,230,272'
    end

    properties (Dependent)
        %------------------------------------------------------
        % These flags control which batch files are called in the
        % "Run-99-All" batch files. Clear all flags except the
        % ones you want to run.
        doIF2Dicom
        doIF2MIP

        %------------------------------------------------------
        % These flags control which batch files are called in the
        % "Run-99-All" batch files. Clear all flags except the
        % ones you want to run.
        doAWRecon
        doAWTOFRecon
        doFBPRecon
        doFBPTOFRecon
        doOPRecon
        doOPTOFRecon
        doPSFRecon
        doPSFTOFRecon

        %------------------------------------------------------
        % Default iterations & subsets for TOF recons
        % NOTE: These are not in any sense "recommended".
        %       I picked these numbers rather arbitrarily.
        % For Horizon 111*, TOF subsets = 20. Cannot be changed.
        % For Vision  12**, TOF subsets = 5. Cannot be changed.
        TOFawiter
        TOFawsubsets
        TOFopiter
        TOFopsubsets
        TOFpsfiter
        TOFpsfsubsets

        %------------------------------------------------------
        % Default output image resolution (outimagesize)
        % If this keyword is omitted, the default will be
        % 200 for mCT models 1103 & 1104,
        % 180 for Horizon models 1113 & 1114,
        % 220 for Vision models 12xx
        % 344 for mMR model 2008, and
        % 168 for all others (1080/1093/1094).
        %
        % -- use for 1080/1093/1094 --
        % outimagesize  =     168
        % outimagesize  =     336
        % -- use for 1103/1104 --
        % outimagesize  =     200
        % outimagesize  =     400
        % -- use for 1113/1114 --
        % outimagesize  =     180
        % outimagesize  =     360
        % -- use for 12xx --
        % outimagesize  =     220
        % outimagesize  =     440
        % -- use for mMR 2008 --
        % outimagesize  =     172
        % outimagesize  =     344
        outimagesize        
    end

    methods

        %% GET

        function g = get.doIF2Dicom(~)
            g =       1;
        end
        function g = get.doIF2MIP(~)
            g =       1;
        end

        function g = get.doAWRecon(~)
            g =       0;
        end
        function g = get.doAWTOFRecon(~)
            g =       1;
        end
        function g = get.doFBPRecon(~)
            g =       0;
        end
        function g = get.doFBPTOFRecon(~)
            g =       0;
        end
        function g = get.doOPRecon(this)
            g = ~strcmp(this.model_, "Vision");
        end
        function g = get.doOPTOFRecon(this)
            g = strcmp(this.model_, "Vision");
        end
        function g = get.doPSFRecon(~)
            g =       0;
        end
        function g = get.doPSFTOFRecon(~)
            g =       0;
        end

        function g = get.TOFawiter(this)
            if strcmp(this.model_, "Vision") %#ok<*IFBDUP> 
                g = 3;
            else
                g = 3;
            end
        end
        function g = get.TOFawsubsets(this)
            if strcmp(this.model_, "Vision")
                g = 5;
            else
                g = 21;
            end
        end
        function g = get.TOFopiter(this)
            if strcmp(this.model_, "Vision")
                g = 3;
            else
                g = 3;
            end
        end
        function g = get.TOFopsubsets(this)
            if strcmp(this.model_, "Vision")
                g = 5;
            else
                g = 21;
            end
        end
        function g = get.TOFpsfiter(this)
            if strcmp(this.model_, "Vision")
                g = 3;
            else
                g = 3;
            end          
        end
        function g = get.TOFpsfsubsets(this)
            if strcmp(this.model_, "Vision")
                g = 5;
            else
                g = 21;
            end
        end

        function g = get.outimagesize(this)
            switch this.model_
                case "Vision"
                    g = 400;
                case "mMR"
                    g = 344;
                case "mCT"
                    g = 400;
                otherwise
                    error('mlsiemens:ValueError', ...
                        'JSRecon12Params.get.outimagesize.this.model_ -> %s', this.model_);
            end
        end

        %%

        function this = JSRecon12Params(varargin)
            %% JSRECON12PARAMS 
            %  Args:
            %      model (text): Description of scanner model
            
            ip = inputParser;
            addParameter(ip, "model", "Vision", @(x) matches(x, ["Vision", "mMR", "mCT"]))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.model_ = ipr.model;
        end
    end

    properties (Access = private)
        model_
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
