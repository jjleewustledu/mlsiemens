classdef Packet2 < mlsiemens.Packet
	%% PACKET2  (buffered packets)

	%  $Revision$
 	%  was created 11-Aug-2017 02:50:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties        
        syncCache
        timeStampIndices
        gateONIndices
        gateOFFIndices
        allGateIndices
 	end

	methods		
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
                        sino.singlesRatesPlusPlus(b, s);
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
        
 		function this = Packet2(varargin)
 			%% PACKET2
 			%  Usage:  this = Packet2()

 			this = this@mlsiemens.Packet(varargin{:});
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

