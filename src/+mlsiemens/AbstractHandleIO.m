classdef AbstractHandleIO < handle & mlio.AbstractHandleIO
	%% ABSTRACTIO provides thin, minimalist methods for I/O.  Agnostic to all other object characteristics.
    
	%  $Revision$
 	%  was created $Date$
 	%  by $Author$, 
 	%  last modified $LastChangedDate$
 	%  and checked into repository $URL$, 
 	%  developed on Matlab 8.1.0.604 (R2013a)
 	%  $Id$
    
    methods (Static)        
        function obj  = long(obj)
            %% LONG always returns 4-byte integers (int32)
            
            if (ischar(obj))
                obj = uint32(str2double(obj));
            end
            if (isfloat(obj))
                obj = uint32(obj);
            end
        end
        function obj  = hex2long(obj)
            obj = uint32(hex2dec(obj));
        end
        function str  = num2SiemensHdrStr(num)
            str = num2str(num(1));
            for inum = 2:length(num)
                str = [str ', ' num2str(num(inum))]; %#ok<AGROW>
            end            
            str = sprintf('{%s}', str);
        end
        
        function fn   = appendFileprefix(fn, suff)
            assert(2 == exist(fn, 'file'));
            assert(ischar(suff));
            [pth,fp,x] = fileparts(fn);
            fn = fullfile(pth, [fp suff x]);
        end
        function bn   = basename(fn)
            [~,fp,ext] = fileparts(fn);
            bn = [fp ext];
        end
        function        dprintf(meth, obj, varargin)
            if isempty(getenv('DEBUG'))
                return
            end
            assert(ischar(meth));
            if (ischar(obj))
                if (~isempty(varargin))
                    obj = sprintf(obj, varargin{:});
                end
                fprintf(sprintf('%s:  %s\n', meth, obj));
            elseif (isnumeric(obj))
                if (numel(obj) < 100)
                    fprintf(sprintf('%s:  %s\n', meth, mat2str(obj)));
                else
                    obj = reshape(obj, 1, []);                    
                    fprintf(sprintf('%s:  %s\n', meth, mat2str(obj(1:100))));
                end
            else
                try
                    fprintf(sprintf('%s:  %s\n', meth, char(obj)));
                catch ME
                    error('mlan:unsupportedTypeclass', 'class(SortLMMotionMatlab.dprintf.obj) -> %s', class(obj));
                end
            end
        end
        function t    = total(arr)
            t = sum(reshape(arr, 1, []));
        end       
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

