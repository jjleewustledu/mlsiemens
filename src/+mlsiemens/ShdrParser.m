classdef ShdrParser < mlio.AbstractParser
	%% HDRPARSER  

	%  $Revision$
 	%  was created 19-Jun-2017 22:30:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	methods (Static)
        function this = load(fn)
            assert(lexist(fn, 'file'));
            [pth, fp, fext] = fileparts(fn); 
            if (lstrfind(fext, mlsiemens.ShdrParser.FILETYPE_EXT) || ...
                isempty(fext))
                this = mlsiemens.ShdrParser.loadText(fn); 
                this.filepath_   = pth;
                this.fileprefix_ = fp;
                this.filesuffix_ = fext;
                return 
            end
            error('mlsiemens:unsupportedParam', 'ShdrParser.load does not support file-extension .%s', fext);
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
            this = mlsiemens.ShdrParser.loadText(fn);
            this.filepath_   = pth;
            this.fileprefix_ = fp;
            this.filesuffix_ = fext;
        end
    end
    
	methods 		  
        function sv = parseAssignedString(this, fieldName)
            line = this.findFirstCell(fieldName);
            names = regexp(line, sprintf('%s\\s*:=\\s*(?<valueName>.+$)', fieldName), 'names');
            sv = strtrim(names.valueName);
        end
        function nv = parseAssignedNumeric(this, fieldName)
            line = this.findFirstCell(fieldName);
            names = regexp(line, sprintf('%s\\s:*=\\s*(?<valueName>%s)', fieldName, this.ENG_PATT_UP), 'names');
            nv = str2num(strtrim(names.valueName)); %#ok<ST2NM>
        end    
    end 
    
    %% PROTECTED
    
    methods (Static, Access = 'protected')
        function this = loadText(fn)
            import mlsiemens.*;
            this = ShdrParser;
            this.cellContents_ = ShdrParser.textfileToCell(fn);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

