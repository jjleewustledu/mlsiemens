classdef AbstractHdrParser < mlio.AbstractParser
	%% ABSTRACTHDRPARSER  

	%  $Revision$
 	%  was created 20-Jun-2017 18:11:00 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods
        function sv = parseSplitString(this, fieldName)  
            line = this.findFirstCell(fieldName);          
            tokens = strsplit(line, ":=");
            if (length(tokens) < 2)
                sv = []; 
                return
            end
            sv = strtrim(tokens{2});            
        end
        function nv = parseSplitNumeric(this, fieldName)
            nv = str2num(this.parseSplitString(fieldName)); %#ok<ST2NM>
        end
        
        function sv = parseAssignedString(this, fieldName)
            line = this.findFirstCell(fieldName);
            fieldName = this.strrep2(fieldName);
            line = this.strrep2(line);
            names = regexp(line, this.strrep(sprintf('%s\\s*:=\\s*(?<valueName>.+$)', fieldName)), 'names');
            sv = strtrim(names.valueName);
        end
        function nv = parseAssignedNumeric(this, fieldName)
            line = this.findFirstCell(fieldName);
            fieldName = this.strrep2(fieldName);
            line = this.strrep2(line);
            names = regexp(line, this.strrep(sprintf('%s\\s*:=\\s*(?<valueName>%s)', fieldName, this.ENG_PATT)), 'names');
            nv = str2num(strtrim(names.valueName)); %#ok<ST2NM>
        end  
        function s = strrep(~, s)
            s = strrep(s, ']', '\]');
            s = strrep(s, '[', '\[');
        end
        function s = strrep2(~, s)            
            s = strrep(s, ')', '_');
            s = strrep(s, '(', '_');
            s = strrep(s, '+', '');
            s = strrep(s, '%', '%%');
        end
        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

