classdef (Abstract) SessionData < handle & mlpipeline.SessionData
    %% SESSIONDATA implements mlpipeline.ISessionData.
    %  It is suited for data collected from Siemens PET scanners designed since 2023.
    %  It considers Siemens e7 tools and JSRecon12.
    %  It considers OMEGA, https://github.com/villekf/OMEGA .
    %  It considers OpenGATE/GEANT4, http://www.opengatecollaboration.org .
    %  
    %  Created 02-Feb-2023 00:59:27 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlsiemens/src/+mlsiemens.
    %  Developed on Matlab 9.13.0.2126072 (R2022b) Update 3 for MACI64.  Copyright 2023 John J. Lee.
    
    methods
        function this = SessionData(varargin)
            this = this@mlpipeline.SessionData(varargin{:});
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
