classdef DPCMDemoClass < DPCMObject
% DPCMDemoClass: Demo class for the DPCM System.
%
% @note The DPCM methods work on nested properties, too.
%
% @author Daniel Wirtz @date 2011-11-21
%
% @new{0,6,dw,2011-11-21} Added this class.
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
    
    properties(SetObservable)
        % Brief description of property one.
        %
        % @propclass{critical} This is a very critical property!
        Prop1;
        
        % Brief for property two.
        %
        % @propclass{important} Another property, but "only" important.
        % This comment is extracted to the end of the comment section or until the next tag.
        % @type double
        Prop2;
        
        % This is a subclass of type DPCMObject
        %
        % @propclass{important} This description is about the importance of the SubClass
        % property.
        %
        % @type DPCMObject
        SubClass;
        
        % This is a property of type "data".
        %
        % The specialty for this
        % @propclass{data}
        SupervisedDataProperty = 'somedata';
    end
    
    properties
        % This is a property that intentionally has been "forgotten" to be added to the DPCM
        % system. Note how the system detects this and suggests inclusion.
        DPCMCandidate = true;
    end
    
    properties(SetAccess=private)
        % Methods with private set access are not considered for DPCM.
        % Candidates are with set access protected and public.
        notObserved = 'somevalue';
    end
    
    methods
        function this = DPCMDemoClass
            % Call superclass constructor
            this = this@DPCMObject;
            
            % Assign any class instances as default values.      
            this.SubClass = DPCMObject;
            
            % Register properties that are to be supervised
            this.registerProps('Prop1','Prop2','SubClass');
            
            % If you change any property after registering them, the whole point of the system
            % fails because at this stage the DPCM is already active. 
            % As a consequence, Prop2 will always be seen as already changed.
            this.Prop2 = 'changed after registering ..';
        end
        
        function demo(this)
            % Perform some fake computations
            this.doSomeComputation;
            
            % Change some variables
            disp('<<<<<<<<<<<<<<<<<<<<<<<< DPCMDemo: Changing some variables... >>>>>>>>>>>>>>>>>>>>>>>');
            this.Prop1 = 45;
            this.SubClass.WorkspaceVariableName = 'some value for a property';
            
            this.doSomeComputation;
        end
        
        function doSomeComputation(this)
            
            %% Perform the DPCM check before computations
            % Critical properties only (recommended):
            DPCM.criticalsCheck(this);
            
            %% More details
            % Optional: Print a summary
            disp('<<<<<<<<<<<<<<<<<<<<<<<< DPCMDemo: summary >>>>>>>>>>>>>>>>>>>>>>>');
            pause;
            DPCM.getDPCMSummary(this);
            
            % Optional: Detailed report
            disp('<<<<<<<<<<<<<<<<<<<<<<<< DPCMDemo: report >>>>>>>>>>>>>>>>>>>>>>>');
            pause;
            DPCM.getDPCMReport(this);
            
            
            %% Put your computation/method calls here
            % [...]
        end
        
        function set.Prop1(this, value)
            % Setters for DPCM properties are compatibel
            
            this.Prop1 = value;
        end
    end
    
end