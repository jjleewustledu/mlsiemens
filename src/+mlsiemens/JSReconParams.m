classdef JSReconParams
    %% line1
    %  line2
    %  
    %  Created 23-Aug-2022 23:16:45 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.12.0.2009381 (R2022a) Update 4 for MACI64.  Copyright 2022 John J. Lee.

    properties    
        %------------------------------------------------------#
        %              JSRecon12 parameters                    #
        %                  03-May-2023                         #
        %------------------------------------------------------#
        % Notes:
        % + Keywords are NOT case-sensitive
        % + You can override any of these
        %    parameters on the command line, like this:
        %      cscript C:\JSRecon12\JSRecon12.js MyParameters.txt

        %------------------------------------------------------
        % Postfiltering (all recon methods)
        % To select "no filtering" set postfilterxy AND postfilterz to 0
        postfiltertype  =   "GAUSS"
        postfilterxy    =     0
        postfilterz     =     0

        %------------------------------------------------------
        % Image zoom (default is 1; many cardiac sites like 2)
        zoom           =   2

        % ------------------------------------------------------
        %  matchctslice, 0 = off, 1 = on
        %  altctargs, 0 = --ctm UMapPETLo,UMapPETHi,UMapSpacing,UMapThickness
        %  altctargs, 1 = --ctm UMapPETLo,UMapPETHi,UMapThickness,UMapThickness
        matchctslice    =       0
        altctargs       =       0

        %------------------------------------------------------
        % Set to reconstruct without attenuation correction
        % If this flag is set, then all batch files are NAC
        % and the MakeNACBats flag below is ignored
        NACFlag         =       0

        %------------------------------------------------------
        % Set to create NAC batch files in parallel with AC
        % This flag only works if NACFlag above is 0
        MakeNACBats     =       0

        %---------------------------------------------------------------------
        % Regarding the following two sections, on iterations and subsets 
        % -----                                                         ----- 
        % ALERT    These defaults are not in any sense "recommended"    ALERT 
        % -----        I picked these numbers rather arbitrarily        ----- 
        %                                                                      
        % It is up to you to choose suitable parameters for your application. 
        % For example, if you're doing wholebody oncology, you may prefer     
        % PSFTOF with one set of parameters, but for brain imaging,           
        % you may prefer OPTOF with a different set of parameters.            
        %---------------------------------------------------------------------
        %
        %------------------------------------------------------
        % Default iterations & subsets for non-TOF recons
        % NOTE: These are not in any sense "recommended".
        %       I picked these numbers rather arbitrarily.
        % For Horizon 111*, non-TOF subsets = 20. Cannot be changed.
        % For Vision  12**, non-TOF subsets = 5. Cannot be changed.
        NONawiter       =       2
        NONawsubsets    =       5
        NONopiter       =       2
        NONopsubsets    =       5
        NONpsfiter      =       2
        NONpsfsubsets   =       5

        % ------------------------------------------------------
        %  Default iterations & subsets for TOF recons
        %  NOTE: These are not in any sense "recommended".
        %        I picked these numbers rather arbitrarily.
        %  For Horizon 111*, TOF subsets = 20. Cannot be changed.
        %  For Vision  12**, TOF subsets = 5. Cannot be changed.
        TOFawiter       =       2
        TOFawsubsets    =       5
        TOFopiter       =       2
        TOFopsubsets    =       5
        TOFpsfiter      =       2
        TOFpsfsubsets   =       5

        % ------------------------------------------------------
        %  Metal Artifact Reduction for umaps (cardiac only)
        %  MARFlag = 0 disable --mar switch
        %  MARFlag = 1 enable --mar switch
        %  Default is disabled (0)        
        MARFlag        =       0
        
        % ------------------------------------------------------
        %  MashFlag = 0 disable --mash4 switch in TOF recons
        %  MashFlag = 1 enable  --mash4 switch in TOF recons
        %  (--mash4 is always enabled in the clinical product)
        %  default is MashFlag = 1 enable 
        MashFlag        =       1
        
        %------------------------------------------------------
        % FBPrsFlag = 0 disable --rs switch in FBP recons
        % FBPrsFlag = 1 enable  --rs switch in FBP recons
        % (--rs is always enabled for iterative recons)
        % default is FBPrsFlag = 0 disable        
        FBPrsFlag        =       0
        
        %------------------------------------------------------
        % Set if you want JSRecon12 to print the filenames in  
        % the inventory. This is sometimes useful for debugging
        % or if you want to know which files are which data types.
        % Default is off. 1: Everything but umap files. 3: Everything.        
        PrintFilenames   =  0 % 0, 1, 3
        
        %------------------------------------------------------
        % These flags control which batch files are called in the
        % "Run-99-All" batch files. Clear all flags except the
        % ones you want to run.        
        doFBPRecon      =       0
        doAWRecon       =       0
        doOPRecon       =       0
        doPSFRecon      =       0
        doFBPTOFRecon   =       0
        doAWTOFRecon    =       0
        doOPTOFRecon    =       1
        doPSFTOFRecon   =       0
        doIF2Dicom      =       0
        doIF2MIP        =       0
        
        %------------------------------------------------------
        % Set if call to e7_recon should contain "-d ." flag        
        Debug           =       0
        
        %------------------------------------------------------
        % Set to force rendering of sino & list numbers with 
        % two digits rather than one  ("-01-" instead of "-1-")
        % This is now the default & is recommended.        
        TwoDigitFlag    =       1
        
        %--------------------------------------------------------
        % Set to use BedRemoval algorithm (version VG40 & higher)        
        BedRemoval      =       1
        
        %---------------------------------------------
        % Set to enable absolute scatter 
        % Works for mCT VG50 & above, mMR VA20 & above        
        AbsFlag         =       1
        
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
        % for version VR10. (Not fully implemented.)        
        LargeListmode   =       0
        
        %------------------------------------------------------
        % Gating Options
        % Works for Truepoint 6.7, mCT, Vision, and maybe Quadra. Not mMR.
        %
        %-----------
        % EnableResp        = If respiratory physio file present, JSRecon12 creates
        %                     -EQ- folder for equal counts gating
        %                     -EA- folder for equal amplitude gating
        %                     -OG- folder for optimal gating -- (use this folder instead of -RG-)
        %                     -RG- folder for optimal gating -- (same as -OG-, for backwards compatibility)
        % Parameters are,
        %   OptimalGate     = % events retained in optimal gate. Usually 35%
        %   RGates          = % gates for equal counts gating and equal amplitude gating
        %   AdaptiveGating  = enable adaptive gating (disabled outside Siemens)
        %   AdaptiveWindow  = AdaptiveWindow half-width in seconds (disabled outside Siemens)
        %	RespType        = Type of respiratory data to use in PhysioGates (ANZ, DDG, or MFL)
        %
        % Preprocessing options are,
        %   BaselineRestore = If enabled, do baseline restoration
        %   RMSScale        = If enabled, do RMS scaling
        %
        %--------------
        % EnableCardiac     = If cardiac physio file present, JSRecon12 creates
        %                     -CG- folder for cardiac gating
        % Parameters are,
        %   NCardiacGates   = Number of cardiac gates. Usually 8 or 16
        %
        %-----------
        % EnableDual        = If both physio files present, JSRecon12 will someday create
        %                     -DEQ- folder for "dual, equal counts gating"
        %                     -DEA- folder for "dual, equal amplitude gating"
        %                     -DOG- folder for "dual, optimal gated"
        %                     -DEQ- foldar for "dual, equal counts gated"
        %                      (uses same gating parameters as above)
        % Parameters are,
        %   Same as above.
        %
        %--------------
        % MotionCorrect  	= If MotionCorrect is set, then elastic motion
        %                     correction is applied in reconstruction of gated images.
        %					  (Not yet implemented.)
        %
        %----------
        % BedLimits         = This is not a user-adjustable parameter. JSrecon12 uses
        %                     it to send arguments to PhysioGates. Ignore it.
        %------
        % NOTE: Enable Dual currently not implemented.
        % NOTE: You cannot do gating and dynamic (below) at the same time.
        %       If you're doing dynamic, select "EnableResp = 0" & "EnableCardiac = 0"
        % NOTE: The JSRecon12 implementation of respiratory, cardiac, and dual gating is
        %       distinct from what's on the scanner. See C:\JSRecon12\PhysioGates.js
        
        % Cardiac        
        EnableCardiac = 0
        NCardiacGates    =   8
        
        % Respiratory
        EnableResp = 0
        OptimalGate      =  35
        RGates           =   6
        AdaptiveGating = 0
        AdaptiveWindow = 45
        RespType         = "ANZ"
        BaselineRestore = 0
        RMSScale         =   0
        
        % Dual (not implemented)
        EnableDual       =   0
        MotionCorrect    =   0
        BedLimits = -1
        
        %---------------
        % Beat Rejection
        %
        % BREnable    0 for disable, 1 for enable
        %
        % RRShortest  shortest accepted RR interval in ms (e.g. 400 for 150 bpm)
        % RRLongest  - longest  accepted RR interval in ms (e.g. 2000 for 30 bpm)         
        BREnable   = 0
        RRShortest = 400
        RRLongest  = 2000

        %------------------------------------------------------
        % Sinogram Compression
        %
        % If this flag is set, e7_histogramming or HistogramReplay will
        % create compressed sinograms, saving space & a little time. By
        % default, this flag is set.        
        CompressFlag    = 1
        
        %------------------------------------------------------
        % Set to use the GPU for reconstruction 
        % Values are equivalent to the possible parameters given 
        % in the e7_recon help file. -1 means do not use the GPU 
        % This is the safest option. (JSRecon12 does not support GPUs.)        
        usegpu          = -1
        
        %------------------------------------------------------
        % Default for handling CBM chunks in e7_recon is to call
        % e7_recon once for each chunk. ChunkString = 1 overrides 
        % the default and processes all the chunks in one call.
        % This has no effect on speed, efficiency, or results. It is
        % only used in rare testing applications. Don't worry about it.        
        ChunkString		= 0	
        
        %------------------------------------------------------
        % Various mappings & other flags 
        % It is preferable to use "UseVersion" below.
        %
        % MapV18toV20: if set, mMR V18 data will be processed with V20 e7_tools
        % MapV40toV50: if set, mCT VG40 data will be processed with VG50 e7_tools
        % MapV6toV66:  if set, mCT version 6 data will be processed with e7_tools version 6.6
        % MapV6toV67:  if set, mCT version 6 data will be processed with e7_tools version 6.7
        % ExMapFlag:   if set, calls to e7_ct2umap will have the --exfov switch enabled (version 6.7 only)
        % e7ScatFlag:  if set, calls to e7_recon will be replaced by calls to C:\JSRecon12\iScat\e7_scat (VG40 & VG50 only)
        % ForceForce:  if set, e7_recon batch files always include the --force flag        
        MapV18toV20     =       1
        MapV40toV50     =       0
        MapV6toV66      =       0
        MapV6toV67      =       0
        ExMapFlag       =       0
        e7ScatFlag      =       0
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
        mlaaparams      = "--is 3,21 --isaa 20,9 --gf -R 2,4 -w 344 --pthr 0.2,0.2 --fov 0.094681,0.933983,0.252103,220,220,190 --beta 0.1,0.001,0.1 --gamma 0.001,0.001 --msw 0,1,1,0.0885,1,1,0.113,1,1,0.0277,1,1 --prior GEMAN_3D"
        % The following parameters are used in e7_mlaa for VE11P
        mlaaVE11P       = "--is 1,1  --isaa 20,9 --gf -R 2,4 -w 344 --pthr 0.2,0.2 --fov 0,0,0,215,230,272                      --beta 0.1,0.001,0.1 --gamma 0.001,0.001 --msw 0,1,1,0.0885,1,1,0.0963,1,1,0.03,1,1  --prior GEMAN_3D --rs"
        
        %-------------------------------------------------------
        % The following parameters control mMR motion correction
        %
        % mMReMCLMstart / stop in the parameter file are used to define the
        % fraction of the PET listmode to be used. The values must be provided
        % in seconds or set to -1 indicating that the full file should be used.
        %
        % The refgate parameter controls the reference motion state, i.e. to 
        % which of the 0-4 motion states the umap fits. Usually 0 should work 
        % but in some cases the respiratory signal is flipped and hence motion 
        % state 4 fits to the umap. If a value other than 0 is provided, the umap 
        % is warped to motion state 0 and the reconstruction is performed afterwards.
        %
        % The other parameters are already known from the other reconstruction types. 
        % I simply copied them and created a separate set for the emoco reconstruction.
        % 
        % Please let me know in case there are more questions!
        
        % [TV] start
        mMReMCdoOPRecon   =     1
        mMReMCdoPSFRecon  =     1
        mMReMCiter        =     3
        mMReMCsubsets	  =    21
        mMReMCoimagesize  =   172  
        mMReMCrefgate     =     0  
        mMReMCLMstart     =    -1  
        mMReMCLMstop      =    -1
        mMReMCfiltertype  = "GAUSS"
        mMReMCfilterxy    =   2.0 
        mMReMCfilterz     =   2.0
        % [TV] end
        
        %------------------------------------------------------
        % umapsize: If this keyword is omitted, the default 
        % will be 400 for mCT models (1103 & 1104), 344 for
        % mMR model 2008, 336 for software version 6.7, 360
        % for mCT models 1113 & 1114, and 256 for all others. 
        % This should not ordinarily be changed.
        %
        % umapsize      =     256
        % umapsize      =     336
        % umapsize      =     344
        % umapsize      =     360
        % umapsize      =     400
        %
        % 03-May-2016: umapsize always 400 for 1103 & 1104.
        % Cannot be changed. umapsize always 336 for software
        % version 6.7 and bed removal enabled. Cannot be changed.
        % For 6.7, we never test the case bed removal disabled.
        
        %------------------------------------------------------
        % umapfilter: GAUSS and 4.0 are our standard and should
        % not ordinarily be changed 
        %
        % umapfiltertype  =   GAUSS
        % umapfilterxy    =     4.0
        % umapfilterz     =     4.0
        
        %------------------------------------------------------
        % UseVersion (Use with caution! You're on your own!)
        %
        % Sometimes, it's necessary to use a particular version of e7_tools, 
        % regardless of what the data say. If you need to do that, uncomment 
        % *one* of the lines below. JSRecon12 will ignore what the data say,
        % and generate batch files appropriate for your assertion.
        %
        % WARNING %1: The interfile headers in your data MAY OR MAY NOT be 
        % compatible with your selected version of e7_tools. If e7_tools throws
        % lots of errors, it's your problem to deal with them.
        %
        % WARNING %2: UseVersion is most frequently used by Siemens engineers 
        % in the development process. With rare exceptions, if you're not a 
        % Siemens engineer, you probably don't want to tinker with this.
        %
        %-------------------
        %-------------------
        % TruePoint 1093/1094/1080
        %-------------------
        % UseVersion = V67
        %-------------------
        %-------------------
        % mCT 1103/1104
        %-------------------
        % UseVersion = VG40
        % UseVersion = VG50
        % UseVersion = VG60
        % UseVersion = VG70
        % UseVersion = VG80
        %-------------------
        % Vision 1206/1208
        %-------------------
        % UseVersion = VG75
        % UseVersion = VG76
        % UseVersion = VG80
        %-------------------
        % Quadra 1232
        %-------------------
        % UseVersion = VR10
        % UseVersion = VR20
        %-------------------
        % Horizon 1113/1114
        %-------------------
        % UseVersion = VJ10
        % UseVersion = VJ20
        % UseVersion = VJ30
        %-------------------
        % mMR 2008
        %-------------------
        % UseVersion = VA18
        % UseVersion = VA20
        % UseVersion = VE11P
        %-------------------
    end

    properties (Dependent)
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

        % LMFrames       = 0:15,15,15,15,15,15,15,15,60,60,60,120,120,120,120,120
        % LMFrames       = 0:30,10,10,10,10,10,10,10,10,10,10,10,10,30,30,30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,300,300,300
        % LMFrames        = 0:1800
        % LMFrames        = 0:200,200,200
        % LMFrames        = 0:30,30,30,30
        % LMFrames        = all
        LMFrames

        % ------------------------------------------------------
        %  Default output image resolution (outimagesize)
        %  If this keyword is omitted, the default will be
        %  200 for mCT models 1103 & 1104,
        %  180 for Horizon models 1113 & 1114,
        %  220 for Vision models 12xx
        %  344 for mMR model 2008, and
        %  168 for all others (1080/1093/1094).
        % 
        %  -- use for 1080/1093/1094 --  (Truepoint)
        %  outimagesize  =     168
        %  outimagesize  =     336
        %  -- use for 1103/1104 --       (mCT)
        %  outimagesize  =     200
        %  outimagesize  =     400
        %  -- use for 1113/1114 --       (Horizon)
        %  outimagesize  =     180
        %  outimagesize  =     360
        %  -- use for 12xx --            (Vision & Quadra)
        %  outimagesize  =     220
        %  outimagesize  =     440
        %  -- use for mMR 2008 --        (mMR)
        %  outimagesize  =     172
        %  outimagesize  =     344
        outimagesize        
    end

    methods %% GET, SET
        function g = get.LMFrames(this)
            g = this.LMFrames_;
        end
        function this = set.LMFrames(this, s)
            assert(istext(s))
            this.LMFrames_ = s;
        end
        function g = get.outimagesize(this)
            switch this.model_
                case "Vision"
                    g = 440;
                case "mMR"
                    g = 344;
                case "mCT"
                    g = 400;
                otherwise
                    error('mlsiemens:ValueError', ...
                        'JSReconParams.get.outimagesize.this.model_ -> %s', this.model_);
            end
        end

        %%

        function this = JSReconParams(opts)
            %% Args:
            %  opts.model {mustBeTextScalar} = "Vision"
            %  opts.LMFrames {mustBeTextScalar} = "all"
            
            arguments
                opts.Skip {mustBeInteger} = 0
                opts.LMFrames {mustBeTextScalar} = "0:120"
                opts.model {mustBeTextScalar} = "Vision"
                opts.tracer {mustBeTextScalar} = "oo"
                opts.filepath {mustBeFolder} = pwd
                opts.tag {mustBeTextScalar} = ""
                opts.is_dyn logical = false
            end
            this.LMFrames_ = convertCharsToStrings(opts.LMFrames);
            this.model_ = convertCharsToStrings(opts.model);
            this.tracer_ = convertCharsToStrings(opts.tracer);
            this.filepath_ = convertCharsToStrings(opts.filepath);

            if contains(opts.tag, "start0")
                this.doIF2Dicom = 1;
                this.doIF2MIP = 1;
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
                this mlsiemens.JSReconParams
                fqfn {mustBeTextScalar} = this.fqfilename()
            end

            lines = ...
                ["#----------------------------------------#"; ...
                 "#           JSRecon12 parameters         #"; ...
                 "#                03-May-2023             #"; ...
                 "#----------------------------------------#"];
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
