classdef SiemensDicom 
	%% SIEMENSDICOM  

	%  $Revision$
 	%  was created 05-Aug-2018 22:34:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        OVERWRITE = true
        INFO_FIELD = 'SeriesDescription' % unique identifier for imaging series
    end
    
    properties
        cachedDcminfosFilename = 'DicomSorter_dcminfos_infos.mat'
        dicomExtension = '.dcm'
    end
    
    methods (Static)
        function copyUmaps
        end
        function copyConsoleACs
        end
        function niih = dcm2niixOuterFrames(trStr, vStr, attStr)
            %% across *-Converted-Frame*
            %  @param tracer is char
            %  @param visit is char
            %  @param attenuation is char
            %  @return niih is mlfourd.ImagingFormatContext
            
            assert(ischar(trStr));
            assert(ischar(vStr));
            assert(ischar(attStr));
            
            targ = sprintf('%s_%s-Converted-Frames-%s', trStr, vStr, attStr);
            targNiigz = [targ '.nii.gz'];
            if (SiemensDicom.finished(targNiigz))
                niih = ImagingFormatContext(targNiigz);
                return
            end
            
            import mlsiemens.*;
            framDirs = mlsystem.DirTool(sprintf('%s_%s-Converted-Frame*-%s', trStr, vStr, attStr));
            niihs = cell(1, length(framDirs.dns));
            for d = 1:length(framDirs.dns)
                targd = fullfile(sprintf('%s_%s-Converted-Frame%i-%s', trStr, vStr, d-1, attStr), ...
                                 sprintf('%s_%s-LM-00', trStr, vStr), '');
                try
                    pwd0 = pushd(targd);
                    niihs{d} = SiemensDicom.dcm2niixInnerFrames(trStr, vStr);
                    popd(pwd0);
                catch ME
                    dispexcept(ME, 'mlsiemens:pushdFailed', ...
                        'SiemensDicom.dcm2niixOuterFrames failed to pushd(%s)', targd)
                end
            end
            niih = SiemensDicom.mergeFrames(targNiigz, niihs);
            niih.saveas(targNiigz);
        end
        function niih = dcm2niixInnerFrames(trStr, vStr)
            %% within *-Converted-Frame*
            %  @param tracer is char
            %  @param visit is char
            %  @return niih is mlfourd.ImagingFormatContext
            
            assert(ischar(trStr));
            assert(ischar(vStr)); 
            
            import mlfourd.* mlsiemens.*;
            targ = sprintf('%s_%s-LM-00-OP', trStr, vStr);
            targNiigz = [targ '.nii.gz'];
            if (SiemensDicom.finished(targNiigz))
                niih = ImagingFormatContext(targNiigz);
                return
            end
            
            intfiles = mlsystem.DirTool(sprintf('%s_00*_000.v', targ));
            niihs = cell(1, length(intfiles.fns));
            for f = 1:length(intfiles.fns)
                fv = intfiles.fns{f};
                fp = myfileprefix(fv);
                deleteExisting([fp '*.nii.gz']);
                deleteExisting([fp '.json']);
                mlbash(sprintf('dcm2niix -o %s -f %s %s-DICOM', pwd, fp, fv));
                %%mlbash(sprintf('fslroi %s %s %i %i %i %i 0 -1', fp, fp, xmin, xsize, xmin, xsize)); 
                % clobbers scl_slope, scl_inter
                niih_ = ImagingFormatContext([fp '.nii.gz']);
                niih_ = niih_.applyScl;
                niih_.addLog(['mlsiemens.SiemensDicom.dcm2niixInnerFrames:  finished work in ' pwd]);
                niihs{f} = niih_;
            end
            niih = SiemensDicom.mergeFrames(targNiigz, niihs);
        end
        function niih = mergeFrames(fn, niihs)
            assert(iscell(niihs));
            niih = niihs{1};
            niih.filename = fn;
            for n = 2:length(niihs)
                niih.img = cat(4, niih.img, niihs{n}.img);
                niih = niih.append_descrip(niihs{n}.descrip);
            end            
        end
    end
    
    methods
        function infos = dcminfos(this, varargin)
            %% DCMINFOS
            %  @param scansPth points to SCANS; has the pwd as default.
            %  @returns infos, a cell array containing struct results of dcminfo acting in scansPth.
            
            ip = inputParser;
            addOptional(ip, 'scansPth', pwd, @isdir);
            parse(ip, varargin{:});
            
            import mlsystem.* mlio.*;
            pwd0 = pushd(ip.Results.scansPth);
            if (lexist(this.cachedDcminfosFilename, 'file'))
                load(this.cachedDcminfosFilename, 'infos');
                return
            end 

            dtseries = DirTool('*');
            fqdns    = dtseries.fqdns;
            infos    = cell(1, length(fqdns));
            for iser = 1:length(fqdns)
                try
                    dcms = DirTool(fullfile(fqdns{iser}, 'DICOM', ['*.' this.dicomExtension]));
                    if (~isempty(dcms.fqfns))
                        infos{iser} = dicominfo(dcms.fqfns{1});
                    end
                catch ME
                    handwarning(ME);
                end
            end 
            save(this.cachedDcminfosFilename, 'infos');
            popd(pwd0);
        end 
        
        function this = SiemensDicom(varargin)
            ip = inputParser;
            addParameter(ip, 'scansPth', pwd, @isdir);
            parse(ip, varargin{:});
            
            this.infos_ = this.dcminfos(ip.Results.scansPth);
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        infos_
    end
    
    methods (Static, Access = private)
        function tf = finished(targNiigz)
            tf = lexist(targNiigz, 'file') && ~mlsiemens.SiemensDicom.OVERWRITE;
        end
    end
    
    methods (Access = private)      
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

