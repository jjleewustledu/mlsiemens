classdef Packet 
	%% PACKET (buffered packets) 

	%  $Revision$
 	%  was created 10-Aug-2017 23:42:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	properties (Dependent)
        Nbin
        p
    end    

    methods (Static)
        function obj  = hex2long(obj)
            obj = uint32(hex2dec(obj));
        end
    end
    
    methods
        
        %% GET
        
        function g = get.Nbin(this)
            g = this.Nbin_;
        end
        function g = get.p(this)
            g = this.p_;
        end
        
        %%
        
        function [mrBins,petBins] = parseTags(this, ipac, mrBins, petBins, lm, sino)
            
            sino.petBinsTime = petBins.time;
            
            if (0 == this.tagPacketBitL(ipac) && mrBins.hasTimeMarker)
                [mrBins,petBins] = this.parsePromptsAndRandoms(ipac, mrBins, petBins, lm, sino);
            end
            if (2 == this.tagTimeMarkerL(ipac))
                gantry = this.tagGantryL(ipac);
                if (4 == gantry)
                    [mrBins,petBins] = this.parseTimeTags(ipac, mrBins, petBins, lm, sino);
                end
                if (5 == gantry)
                    [b,s] = this.blockAndSingles(ipac);                    
                    if (b < lm.nbuckets)
                        sino.singlesRates(b+1) = s;
                    end
                end
            end
            if (14 == this.tagPhysioL(ipac))
                sino.monitorsPlusplus;
            end
            if (15 == this.tagPhysioL(ipac))
                sino.controlsPlusplus
            end
        end
        function [mrBins,petBins] = parsePromptsAndRandoms(this, ipac, mrBins, petBins, lm, sino)
            if (petBins.time < sino.tstart)
                return
            end            

            % lots of small local variables ...
            [prtL,addrL] = this.promptsAndRandoms(ipac);
            izpL  = addrL/(       lm.xdim*lm.ydim);
            ivwL  = (addrL - izpL*lm.xdim*lm.ydim)/ lm.xdim;
            iprL  = (addrL - izpL*lm.xdim*lm.ydim - ivwL*lm.xdim);
            indL  = iprL;  %(iprL-lm.xdim/2)*2+lm.xdim/2

            if (addrL <= numel(lm))
                if (prtL == 1 && mrBins.ibin <= this.Nbin_)
                    sino.promptsPlusplus(mrBins.ibin, addrL);

                    %% CUT in vertical position
                    if (abs(ivwL-120) <= 10)
                        petBins.avgpos = petBins.avgpos + single(indL);
                        petBins.nbpos  = petBins.nbpos + 1;
                    end
                end
                if (prtL == 0 && mrBins.ibin <= this.Nbin_)
                    sino.randomsPlusplus(mrBins.ibin, addrL);
                end
            else
                error('mlsiemens:arrayAddressErr', ...
                    'parsePromptsAndRandoms: Bad sino address at ipac->%12i, packet->%32.32bx, addrL->%12i', ...
                    ipac, this.p_(ipac), addrL);
            end
        end
        function [mrBins,petBins] = parseTimeTags(this, ipac, mrBins, petBins, ~, sino)
            petBins.time = this.timeValue(ipac);
            %petBins.time = timeValue_mex(this.p_(ipac));
            %if (petBins.time >= sino.tstart)
            %    fprintf('petBins.time->%g\n', petBins.time);
            %end
            sino.timemarksPlusplus;
            if (mrBins.hasTimeMarker && mrBins.ibin <= this.Nbin_)
                sino.tickPerBinPlusplus(mrBins.ibin);
            end            
            % skip to the first MR time marker
            if (petBins.frame_time >= petBins.tstart)
                mrBins = mrBins.resetIbin;
            end            
            if (petBins.frame_time >= petBins.tlast && ...
                petBins.frame_time <  mrBins.TFinal)
                [mrBins,petBins] = this.parseNormals(mrBins, petBins, sino);
            end            
            if (petBins.frame_time >= mrBins.TFinal)                
                throw(MException('mlsiemens:exitSortLMMotion', ...
                    'Packet.parseTimeTags.petBins.frame_time->', petBins.frame_time));
            end
        end
        function [mrBins,petBins] = parseNormals(this, mrBins, petBins, sino)
            if (petBins.time < sino.tstart)
                return
            end    
            if (mrBins.hasNext)
                mrBins = mrBins.next;
            else
                throw(MException('mlsiemens:exitSortLMMotion', 'Packet.parseNormals.mrBins.hasNext->false'));
            end
            if (~isnan(mrBins.ibin))
                if (mrBins.ibin > this.Nbin_)
                    error('mlsiemens:counterErr', 'bin number is too large!\n%g\n', mrBins.ibin);
                end
                mrBins = mrBins.setIbin0;
                petBins.timepos(petBins.timemarker) = single(petBins.avgpos)/petBins.nbpos;
                petBins.timemarker = petBins.timemarker + 1;
                
                %% PET only time increment
                petBins.tstart = petBins.tstart + petBins.tstep;
                petBins.tlast  = petBins.tlast  + petBins.tstep;
                %ibin = 1 % no PET sorting
                
                %% PET data driven bins
                %% use petBins.avgpos to provide the bin number
                amin = 153.5;    % 153.5
                amax = 157;
                astep = (amax-amin)/5;
                abin  = (single(petBins.avgpos)/petBins.nbpos - amin);
                ibinP = fix(abin/astep);
                if (ibinP <= 0); ibinP = 0; end
                if (ibinP >= 4); ibinP = 4; end
                mrBins = mrBins.setIbin0;
                petBins.avgpos = 0;
                petBins.nbpos = 0;
            end
            % ibin = ibinP
            mrBins = mrBins.setIbin0;
            % ibin = 1 % no PET sorting % should be removed
            petBins.fprintf('%13g %13g %13g %8i %8g\n', ...
                petBins.tstart, petBins.time, petBins.frame_time, mrBins.ibin-1, ibinP);
            mrBins.tvecMR(petBins.timemarker-1) = mrBins.ibin;
            petBins.tvecPET(petBins.timemarker-1) = ibinP;            
        end
        
        function [b,s] = blockAndSingles(this, idx)
            %[b,s] = blockAndSingles_mex(this.p_(idx));
            b = bitand(bitshift(this.p_(idx), -19, 'uint32'), 1023, 'uint32');
            s = bitand(this.p_(idx), 524287, 'uint32');
        end
        function len = length(this)
            len = length(this.p_);
        end
        function t = tagGantryL(this, idx)
            t = bitshift(this.p_(idx), -29, 'uint32');
        end
        function t = tagPacketBitL(this, idx)
            t = bitshift(this.p_(idx), -31, 'uint32');
        end
        function t = tagPhysioL(this, idx)
            t = bitshift(this.p_(idx), -28, 'uint32');
        end
        function t = tagTimeMarkerL(this, idx)
            t = bitshift(this.p_(idx), -30, 'uint32');
        end
        function t = timeValue(this, idx)
            %t = timeValue_mex(this.p_(idx));
            t = bitand(this.p_(idx), 536870911, 'uint32'); % this.hex2long('1FFFFFFF')
        end
        function [p,r] = promptsAndRandoms(this, idx)   
            %[p,r] = promptsAndRandoms_mex(this.p_(idx));
            p = bitshift(this.p_(idx), -30, 'uint32');
            r = bitand(this.p_(idx), 536870911, 'uint32'); % this.hex2long('1FFFFFFF')
        end
        
        function this = Packet(varargin)
            ip = inputParser;
            addRequired( ip, 'p', @isnumeric);
            addParameter(ip, 'Nbin', @isnumeric);
            parse(ip, varargin{:});
            
            this.p_ = ip.Results.p;
            this.Nbin_ = ip.Results.Nbin;
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        Nbin_
        p_
    end
    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

