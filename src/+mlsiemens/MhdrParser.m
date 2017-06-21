classdef MhdrParser < mlsiemens.AbstractHdrParser
	%% MHDRPARSER  

	%  $Revision$
 	%  was created 19-Jun-2017 17:49:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	

	methods (Static)
        function this = load(fn)
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = fileparts(fn); 
            if (lstrfind(fext, mlsiemens.MhdrParser.FILETYPE_EXT) || ...
                isempty(fext))
                this = mlsiemens.MhdrParser.loadText(fn); 
                this.filepath_   = pth;
                this.fileprefix_ = fp;
                this.filesuffix_ = fext;
                return 
            end
            error('mlsiemens:unsupportedParam', 'MhdrParser.load does not support file-extension .%s', fext);
        end
        function this = loadx(fn, ext)
            if (~lstrfind(fn, ext))
                if (~strcmp('.', ext(1)))
                    ext = ['.' ext];
                end
                fn = [fn ext];
            end
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = filepartsx(fn, ext); 
            this = mlsiemens.MhdrParser.loadText(fn);
            this.filepath_   = pth;
            this.fileprefix_ = fp;
            this.filesuffix_ = fext;
        end
    end
    
	methods 
        
        function this = MhdrParser(varargin)
 			ip = inputParser;
            addParameter(ip, 'filepath', pwd, @isdir)
            addParameter(ip, 'fileprefix', '', @ischar);
            parse(ip, varargin{:});
            
            this.filepath = ip.Results.filepath;
            this.fileprefix = ip.Results.fileprefix;
            this.filesuffix = '.mhdr';
            if (lexist(this.fqfilename, 'file'))
                this.cellContents_ = mlsiemens.MhdrParser.textfileToCell(this.fqfilename);
            end
        end
    end 
    
    %% PROTECTED
    
    methods (Static, Access = 'protected')
        function this = loadText(fn)
            import mlsiemens.*;
            this = MhdrParser;
            this.cellContents_ = MhdrParser.textfileToCell(fn);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

