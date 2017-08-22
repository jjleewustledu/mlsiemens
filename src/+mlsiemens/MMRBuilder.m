classdef MMRBuilder
	%% MMRBUILDER  

	%  $Revision$
 	%  was created 01-Nov-2016 19:09:02
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
    properties 
        firstCrop = 0.5
    end
    
    properties (Dependent)
        inverseCrop
        product
        sessionData
    end
    
    methods (Static)
        function moveConvertedToConvertedNAC
            import mlsystem.* mlfourdfp.*;
            studyd = mlraichle.StudyData;            
            eSess = DirTool(studyd.subjectsDir);
            for iSess = 1:length(eSess.fqdns)

                eVisit = DirTool(eSess.fqdns{iSess});
                for iVisit = 1:length(eVisit.fqdns)
                        
                    eTracer = DirTool(eVisit.fqdns{iVisit});
                    for iTracer = 1:length(eTracer.fqdns)

                        try
                            nacFold = [eTracer.fqdns{iTracer} '-NAC'];
                            if (~isempty(regexp(eTracer.dns{iTracer}, '\w+-Converted$', 'once')) && ~isdir(nacFold))
                                movefile(eTracer.fqdns{iTracer}, nacFold);
                            end
                        catch ME
                            handwarning(ME);
                        end
                    end
                end                
            end
        end
        function incomplete = scanForIncompleteE7tools
            pthPPG0 = pushd(mlraichle.RaichleRegistry.instance.subjectsDir);
            incomplete = {};
            
            import mlsystem.* mlfourdfp.* mlsiemens.*;
            dtSess = DirTool('HYGLY*');
            for eSess = 1:length(dtSess.dns)
                cd(dtSess.fqdns{eSess});
                dtVisit = DirTool('V*');
                for eVisit = 1:length(dtVisit.dns)
                    cd(dtVisit.fqdns{eVisit});
                    
                    dtTracer = DirTool(['*_' dtVisit.dns{eVisit}]);
                    for eTracer = 1:length(dtTracer.dns)
                        dnTracer = dtTracer.dns{eTracer};
                        fqdnTracer = dtTracer.fqdns{eTracer};
                        prefixTracer = strtok(dnTracer, '-'); 
                        if ( lstrfind(dnTracer, 'FDG') && ...
                            ~lexist(sprintf('%s-Converted-Frame63/%s-LM-00-OP_000_000.v', ...
                                            fqdnTracer, prefixTracer)))
                            incomplete = [incomplete [fqdnTracer '-Converted-Frame63']]; %#ok<AGROW>
                        end
                        if ( lstrfind(dnTracer, 'HO') && ...
                            ~MMRBuilder.isConverted(fqdnTracer))
                            incomplete = [incomplete [fqdnTracer '-Converted']]; %#ok<AGROW>
                        end
                        if ( lstrfind(dnTracer, 'OO') && ...
                            ~MMRBuilder.isConvertedAbs(fqdnTracer))
                            incomplete = [incomplete [fqdnTracer '-Converted-Abs']]; %#ok<AGROW>
                        end
                        if ( lstrfind(dnTracer, 'OC') && ...
                            ~lexist(sprintf('%s-Converted-NAC/%s-LM-00-OP_009_000.v', ...
                                            fqdnTracer, prefixTracer)))
                            incomplete = [incomplete [fqdnTracer '-Converted-NAC']]; %#ok<AGROW>
                        end
                    end
                    
                    dtTracer = DirTools('*-Converted', '*-Converted-Abs');
                    for eTracer = 1:length(dtTracer.dns)
                        dnTracer = dtTracer.dns{eTracer};
                        fqdnTracer = dtTracer.fqdns{eTracer};
                        prefixTracer = strtok(dtTracer.dns{eTracer}, '-');  
                        if ( lstrfind(dnTracer, 'HO') && ...
                            ~lexist(sprintf('%s/%s-LM-00/%s-LM-00-OP_057_000.v', ...
                                            fqdnTracer, prefixTracer, prefixTracer)))
                            incomplete = [incomplete fqdnTracer]; %#ok<AGROW>
                        end                        
                        if ( lstrfind(dnTracer, 'OO') && ...
                            ~lexist(sprintf('%s/%s-LM-00/%s-LM-00-OP_057_000.v', ...
                                            fqdnTracer, prefixTracer, prefixTracer)))
                            incomplete = [incomplete fqdnTracer]; %#ok<AGROW>
                        end
                    end
                end
            end
            popd(pthPPG0);
            
            incomplete = incomplete';
        end
        function tf = hasAbsInLog(fqfn)
            log = mlio.TextParser.load(fqfn);
            MARKER = 'command line: C:\Siemens\PET\bin.win64-VA20\e7_recon --abs';
            str = log.findFirstCell(MARKER);
            tf = lstrfind(str, '--abs');
        end
        function tf = isConverted(trpath)
            cpath  = sprintf('%s-Converted', trpath);
            tf1    = isdir(cpath);            
            lmpath = fullfile(cpath, [basename(trpath) '-LM-00'], '');
            try
                dt  = mlsystem.DirTool(fullfile(lmpath, 'log_e7_recon_*.txt'));
                tf2 = ~mlsiemens.MMRBuilder.hasAbsInLog(dt.fqfns{end});
            catch
                tf2 = false;
            end
            
            tf = tf1 && tf2;
        end
        function tf = isConvertedAbs(trpath)
            cpath  = sprintf('%s-Converted-Abs', trpath);
            tf1    = isdir(cpath);            
            lmpath = fullfile(cpath, [basename(trpath) '-LM-00'], '');
            try
                dt  = mlsystem.DirTool(fullfile(lmpath, 'log_e7_recon_*.txt'));
                tf2 = mlsiemens.MMRBuilder.hasAbsInLog(dt.fqfns{end});
            catch
                tf2 = false;
            end
            
            tf = tf1 && tf2;
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.inverseCrop(this)
            inv = round(1/this.firstCrop);
            g = [inv inv 1];
        end
        function g = get.product(this)
            g = this.product_;
        end
        function g = get.sessionData(this)
            assert(~isempty(this.sessionData_));
            g = this.sessionData_;
        end
        
        %%
        
 		function this = MMRBuilder(varargin)
 			%% MMRBUILDER
 			%  @param named sessionData is an mlpipeline.SessionData.

 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;
            this.buildVisitor_ = mlfourdfp.FourdfpVisitor;
        end        
         
        function fqfp = cropfrac(this, varargin)
            %% CROPFRAC
            %  @param fqfp0 with default this.sessionData.tracerListmodeSif that must exist on filesystem.
            %  @return fqfp := cropped this.sessionData.tracerRevision.
            
            sd = this.sessionData;
            ip = inputParser;
            addOptional(ip, 'fqfp0', sd.tracerListmodeSif('typ', 'fqfp'), @mlfourdfp.FourdfpVisitor.lexist_4dfp);
            parse(ip, varargin{:});
            
            fqfp = sd.tracerRevision('typ', 'fqfp');
            if (lexist([fqfp '.4dfp.ifh']))
                return
            end            
            bv = this.buildVisitor_;
            bv.cropfrac_4dfp(this.firstCrop, ip.Results.fqfp0, fqfp);
        end
        function        ensureTracerLocation(this)
            %% ENSURETRACERLOCATION 
            %  @return creates this.sessionData.tracerLocation as needed.
            
            sd = this.sessionData;
            if (isdir(sd.tracerLocation))
                return
            end
            mkdir(sd.tracerLocation);
        end         
        function        ensureTracerSymlinks(this)
            %% ENSURETRACERSYMLINKS operates in this.sessionData.tracerLocation, 
            %  @return ensures valid links to mpr, mpr_to_atlas_t4, T1, t2, tof, ct.
            
            sd = this.sessionData;
            bv = this.buildVisitor_;

            assertLexist(sd.mpr('typ', 'fqfn'));
            if (~lexist(sd.mpr('typ', 'fn')))
                bv.lns_4dfp(sd.mpr('typ', 'fqfp'));
            end
            
            mprAtlT4 = [sd.mpr('typ', 'fp') '_to_' sd.atlas('typ', 'fp') '_t4'];
            fqMprAtlT4 = fullfile(sd.mpr('typ', 'path'), mprAtlT4);            
            assertLexist(fqMprAtlT4);
            if (~lexist(mprAtlT4))
                bv.lns(fqMprAtlT4);
            end
            
            this.ensureTracerLocation;
            pwd0 = pushd(sd.tracerLocation);
            if (~lexist(sd.T1('typ', 'fn')))
                assert(bv.lexist_4dfp(sd.T1( 'typ', 'fqfp')));
                bv.lns_4dfp(sd.T1('typ', 'fqfp'));
            end
            if (~lexist(sd.t2('typ', 'fn')))
                assert(bv.lexist_4dfp(sd.t2( 'typ', 'fqfp')));
                bv.lns_4dfp(sd.t2('typ', 'fqfp'));
            end
            if (~lexist(sd.tof('typ', 'fn')))
                assert(bv.lexist_4dfp(sd.tof('typ', 'fqfp')));
                bv.lns_4dfp(sd.tof('typ', 'fqfp'));
            end
            if (~lexist(sd.ct('typ', 'fn')))
                assert(bv.lexist_4dfp(sd.ct( 'typ', 'fqfp')));
                bv.lns_4dfp(sd.ct('typ', 'fqfp'));
            end
            popd(pwd0);
        end     
        function fqfp = sif(this)
            %% SIF ensures 4dfp data generated by sif_4dfp are in the locations:
            %  this.sessionData.tracerSif('typ', 'fqfp'),
            %  this.sessionData.tracerListmodeSif('typ', 'fqfp').
            %  @return fqfp := this.sessionData.tracerSif('typ', 'fqfp').
            
            sd = this.sessionData;
            bv = this.buildVisitor_;
            
            assertLexist(sd.tracerListmodeMhdr('typ', 'fqfn'));
            if (~lexist(  sd.tracerListmodeSif( 'typ', 'fqfn'), 'file'))
                pwd0 = pushd(sd.tracerListmodeMhdr('typ', 'path'));
                bv.sif_4dfp(sd.tracerListmodeMhdr( 'typ', 'fp'));
                popd(pwd0);                    
            end
            if (~isdir(sd.tracerSif('typ', 'path')))
                mkdir( sd.tracerSif('typ', 'path'));
            end
            if (~lexist(sd.tracerSif('typ', 'fqfn'), 'file'))
                pwd0 = pushd(sd.tracerSif('typ', 'path'));
                bv.lns_4dfp(sd.tracerListmodeMhdr('typ', 'fqfp'));
                popd(pwd0);
            end
            fqfp = sd.tracerSif('typ', 'fqfp');
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        buildVisitor_
        product_
        sessionData_
    end
    
    methods (Static, Access = private)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

