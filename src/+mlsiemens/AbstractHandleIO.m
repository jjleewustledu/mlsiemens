classdef AbstractIOHandle < handle
	%% ABSTRACTIO provides thin, minimalist methods for I/O.  Agnostic to all other object characteristics.
    
	%  $Revision$
 	%  was created $Date$
 	%  by $Author$, 
 	%  last modified $LastChangedDate$
 	%  and checked into repository $URL$, 
 	%  developed on Matlab 8.1.0.604 (R2013a)
 	%  $Id$

    properties (Constant)
        DEBUGGING = true
    end
    
	properties (Dependent)
        filename
        filepath
        fileprefix 
        filesuffix
        fqfilename
        fqfileprefix
        fqfn
        fqfp
        noclobber
    end
    
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
            if (~mlan.AbstractIO.DEBUGGING)
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
    
    methods 
        
        %% SET/GET
        
        function        set.filename(this, fn)
            assert(ischar(fn));
            [this.filepath,this.fileprefix,this.filesuffix] = myfileparts(fn);
        end
        function fn   = get.filename(this)
            fn = [this.fileprefix this.filesuffix];
        end
        function        set.filepath(this, pth)
            assert(ischar(pth));
            this.filepath_ = pth;
        end
        function pth  = get.filepath(this)
            if (isempty(this.filepath_))
                this.filepath_ = pwd; 
            end
            pth = this.filepath_;
        end
        function        set.fileprefix(this, fp)
            assert(ischar(fp));
            assert(~isempty(fp));
            this.fileprefix_ = fp;
        end
        function fp   = get.fileprefix(this)
            fp = this.fileprefix_;
        end
        function        set.filesuffix(this, fs)
            assert(ischar(fs));
            if (~isempty(fs) && ~strcmp('.', fs(1)))
                fs = ['.' fs];
            end
            [~,~,this.filesuffix_] = myfileparts(fs);
        end
        function fs   = get.filesuffix(this)
            if (isempty(this.filesuffix_))
                fs = ''; return; end
            if (~strcmp('.', this.filesuffix_(1)))
                this.filesuffix_ = ['.' this.filesuffix_]; end
            fs = this.filesuffix_;
        end
        function        set.fqfilename(this, fqfn)
            assert(ischar(fqfn));
            [p,f,e] = myfileparts(fqfn);
            if (~isempty(p))
                this.filepath = p;
            end
            if (~isempty(f))
                this.fileprefix = f;
            end
            if (~isempty(e))
                this.filesuffix = e;
            end        
        end
        function fqfn = get.fqfilename(this)
            fqfn = [this.fqfileprefix this.filesuffix];
        end
        function        set.fqfileprefix(this, fqfp)
            assert(ischar(fqfp));
            [p,f] = fileprefixparts(fqfp);            
            if (~isempty(p))
                this.filepath = p;
            end
            if (~isempty(f))
                this.fileprefix = f;
            end
        end
        function fqfp = get.fqfileprefix(this)
            fqfp = fullfile(this.filepath, this.fileprefix);
        end
        function        set.fqfn(this, f)
            this.fqfilename = f;
        end
        function f    = get.fqfn(this)
            f = this.fqfilename;
        end
        function        set.fqfp(this, f)
            this.fqfileprefix = f;
        end
        function f    = get.fqfp(this)
            f = this.fqfileprefix;
        end
        function        set.noclobber(this, nc)
            assert(islogical(nc));
            this.noclobber_ = nc;
        end
        function tf   = get.noclobber(this) 
            tf = this.noclobber_;
        end
        
        %%
        
        function c    = char(this)
            c = this.fqfilename;
        end
        function this = saveas(this, fqfn)
            this.fqfilename = fqfn;
            this.save;
        end
        function this = saveasx(this, fqfn, x)
            this.fqfileprefix = fqfn(1:strfind(fqfn, x)-1);
            this.filesuffix_ = x;
            this.save;
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)        
        filepath_   = '';
        fileprefix_ = '';
        filesuffix_ = '';
        noclobber_  = false;
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

