classdef Listmode < mlsiemens.AbstractHandleIO
	%% LISTMODE supports listmode data from the Siemens Biograph mMR. 

	%  $Revision$
 	%  was created 20-Jun-2017 12:18:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Constant)
        xdim = 344
        ydim = 252
        zdim = 4084
        NLOOK = 2^20 % 4-byte words read at a time from listmode
    end
    
    properties (Dependent)
        DEBUGGING
        lhdrParser
        max_ring_difference
        mhdrParser
        nbuckets
        NBufferBlocks
        NLook
        nlook
        nsegments
        number_of_rings
        remainderBufferBlock
        segtable
        studyDate
        studyTime
        totalRead
        wordCounts % listmode bytes / 4
        xsize
        zsize
    end
    
	methods 
        
        %% GET/SET
        
        function g = get.DEBUGGING(this)
            g = ~isempty(getenv('DEBUG'));
        end
        function g = get.lhdrParser(this)
            g = this.lhdrParser_;
        end
        function g = get.max_ring_difference(this)
            g = this.max_ring_difference_;
        end
        function g = get.mhdrParser(this)
            g = this.mhdrParser_;
        end
        function g = get.nbuckets(this)
            g = this.nbuckets_;
        end
        function g = get.NBufferBlocks(this)
            g = fix(this.wordCounts/this.nlook_); % ~1375 for 5 min PET
        end
        function g = get.NLook(this)
            g = min(this.nlook_, this.wordCounts - this.totalRead); % min(NLOOK, 90087245 - this.totalRead)
        end
        function g = get.nlook(this)
            g = this.nlook_;
        end
        function g = get.nsegments(this)
            g = this.nsegments_;
        end
        function g = get.number_of_rings(this)
            g = this.number_of_rings_;
        end
        function g = get.remainderBufferBlock(this)
            g = mod(this.wordCounts, this.nlook_);
        end
        function g = get.segtable(this)
            g = this.segtable_;
        end
        function g = get.studyDate(this)
            g = this.studyDate_;
        end
        function g = get.studyTime(this)
            g = this.studyTime_;
        end
        function g = get.totalRead(this)
            g = this.totalRead_;
        end
        function g = get.wordCounts(this)
            g = this.wordCounts_;
        end
        function g = get.xsize(this)
            g = this.xsize_;
        end
        function g = get.zsize(this)
            g = this.zsize_;
        end
        
        function this = set.nlook(this, s)
            assert(isnumeric(s));
            this.nlook_ = s;
        end
            
        %%
		          
        function s    = curlyString2numeric(~, s)
            s = strrep(s, '{', '[');
            s = strrep(s, '}', ']');
            s = str2num(s); %#ok<ST2NM>
        end
        function        fopen(this)
            this.fid_ = fopen(this.fqfilename);
        end
        function        fclose(this)
            assert(~isempty(this.fid_));
            fclose(this.fid_);
        end
        function pack = freadPacket(this)
            pack = mlsiemens.Packet( ...
                freadPacketArg(this.fid_, this.NLook), 'Nbin', this.Nbin_);
        end
        function pack = freadPacket2(this)
            pack = mlsiemens.Packet2( ...
                freadPacketArg2(this.fid_, this.NLook), 'Nbin', this.Nbin_);
        end
        function n    = numel(this)
            %% NUMEL seeks speed over safety.
            
            n = this.numelCache_;
        end
        function        incrTotalRead(this, word)
            this.totalRead_ = this.totalRead_ + word;
        end
        
 		function this = Listmode(varargin)
 			%% LISTMODE
            %  @param 'filepath', pwd, @isdir
            %  @param 'fileprefix', 'Motion-LM-00', @ischar
            %  @param 'Nbin', 1, @isnumeric);

 			ip = inputParser;
            addParameter(ip, 'filepath', pwd, @isfolder);
            addParameter(ip, 'fileprefix', '', @ischar);
            addParameter(ip, 'Nbin', 1, @isnumeric);
            addParameter(ip, 'nlook', this.NLOOK, @isnumeric);
            addParameter(ip, 'legacy', false, @islogical);
            parse(ip, varargin{:});
            
            this.filepath = ip.Results.filepath;
            this.fileprefix_ = ip.Results.fileprefix;
            this.filesuffix = '.hdr';
            this.Nbin_ = ip.Results.Nbin;
            
            import mlsiemens.*;
            if (ip.Results.legacy)
                this.lhdrParser_ = LhdrParser('filepath', ip.Results.filepath, 'fileprefix',  ip.Results.fileprefix, 'legacy', ip.Results.legacy);
            else
                this.lhdrParser_ = LhdrParser('filepath', ip.Results.filepath, 'fileprefix',  ip.Results.fileprefix);
            end
            this.mhdrParser_ = MhdrParser('filepath', ip.Results.filepath, 'fileprefix', [ip.Results.fileprefix '-OP']);
            
            this.max_ring_difference_ = ...
                               this.lhdrParser_.parseSplitNumeric('%maximum ring difference');
            this.nbuckets_   = this.lhdrParser_.parseSplitNumeric('%total number of singles blocks');
            this.nsegments_  = this.lhdrParser_.parseSplitNumeric('%number of segments');
            this.number_of_rings_ = ...
                               this.lhdrParser_.parseSplitNumeric('number of rings');
            this.segtable_   = this.curlyString2numeric( ...
                               this.lhdrParser_.parseSplitString('%segment table'));
            this.studyDate_  = this.lhdrParser_.parseSplitString('%study date (yyyy:mm:dd)');
            this.studyTime_  = this.lhdrParser_.parseSplitString('%study time (hh:mm:ss GMT+00:00)');
            this.wordCounts_ = this.lhdrParser_.parseSplitNumeric('%total listmode word counts'); 
            this.xsize_      = this.lhdrParser.parseSplitNumeric('bin size (cm)');
            this.zsize_      = this.lhdrParser.parseSplitNumeric('distance between rings (cm)')/2;  
            
            this.totalRead_  = 0;
            this.nlook_      = max(ip.Results.nlook, this.NLOOK);
            this.numelCache_ = this.xdim*this.ydim*this.zdim;
            
            this.dprintf('Listmode', 'Scan Time and Day  %s on %s', this.studyTime, this.studyDate);            
            this.dprintf('Listmode', 'Sinogram data = %g %g %g %g %g %g %g %g', ...
                this.xdim, this.ydim, this.zdim, this.xsize, this.zsize, ...
                this.nsegments, this.number_of_rings, this.max_ring_difference);
            this.dprintf('Listmode', 'Segtable = %s', num2str(this.segtable));            
            this.dprintf('Listmode', 'numel(listmode) = %i bytes', numel(this));
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        Nbin_
        fid_
        lhdrParser_
        max_ring_difference_
        mhdrParser_
        nbuckets_
        nlook_
        nsegments_
        number_of_rings_
        numelCache_
        segtable_
        studyDate_
        studyTime_
        totalRead_
        wordCounts_
        xsize_
        zsize_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

