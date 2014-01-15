classdef DPCMObject < handle
% DPCMObject: Base object for any class participating in the DPCM system.
%
% Inherit any class from this superclass and use the DPCMObject.registerProps method in your
% object constructor after assigning any default values.
% Make sure to explicitly call the superclass constructor from your subclass constructor (see
% demo class)
%
% @author Daniel Wirtz @date 2011-11-18
%
% @attention Subclasses that explicitly implement the static loadobj-method for custom class
% loading MUST call the loadobj method of DPCMObject in order for the DPCM system to continue
% working after a save/load process.
%
% See also: loadobj
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php

    properties(SetObservable)
        % The workspace variable name of this class. Optional.
        %
        % Must be set manually as the name is not available inside the class.
        %
        % @propclass{optional} This property can be set by any methods that perform
        % computations that use the DPCM system a-priori. Setting this value increases the
        % readability of the DPCM output.
        %
        % See also: inputname
        WorkspaceVariableName = '';
    end
    
    properties(SetAccess=private)
        % An ID that allows to uniquely identify this DPCMObject (at least within the current
        % MatLab session/context).
        %
        % This value is assigned automatically during construction.
        ID = [];
        
        % The Dictionary containing all the property settings as key/value pairs.
        %
        % This dictionary is created in the constructor of the DPCMObject.
        PropertiesChanged = [];
    end
    
    methods
        function this = DPCMObject
            % Creates a new DPCM object.
            %
            % @attention Due to possible multiple inheritance any object's constructor should
            % check if any custom properties that are assigned during construction are already
            % present / different from the default value given at property declaration.
            % If so, chances are that the constructor is called again for the same object; in
            % this case, assigning a new ID and property changed dictionary caused any
            % old registered properties to be overwritten!
            
            % Check if this constructor has already been called; if yes, dont assign a new ID
            % as this might lead to errors in subclasses or with properties (see above)
            if isempty(this.ID)
                this.PropertiesChanged = Dictionary;
                this.ID = DPCMObject.generateID;
            end
        end
    end
    
    methods(Access=protected)
        function registerProps(this, varargin)
            % Call this method at any class that defines DPCM observed properties.
            %
            % Parameters:
            % varargin: A list of char arrays, denoting the names of the properties to
            % register.
            
            if ~KerMor.App.UseDPCM
                return;
            end
            
            mc = metaclass(this);
            if isempty(varargin)
                for idx = 1:length(mc.Properties)
                end
            end
            
            % Iterate over all properties that are to be registered
            for pidx = 1:length(varargin)
                if ~ischar(varargin{pidx})
                    error('All input arguments must be strings.');
                end
                found = false;
                for idx = 1:length(mc.Properties)
                    if strcmp(mc.Properties{idx}.Name,varargin{pidx})
                        p = mc.Properties{idx};
                        found = true;
                        break;
                    end
                end
                % Validity checks
                if ~found
                    error('Property %s does not exists in class %s.',varargin{pidx},mc.Name);
                elseif ~strcmp(p.GetAccess,'public')
                    error('Property %s has GetAccess=%s, ''public'' is required for registering.',p.Name,p.GetAccess);
                elseif p.Constant
                    error('Property %s is marked Constant.',p.Name,p.GetAccess);
                elseif p.Transient
                    error('Transient property %s is not admissible.',p.Name,p.GetAccess);
                elseif strcmp(p.SetAccess,'private')
                    error('Property %s has SetAccess=private, at least ''protected'' is required for registering.',p.Name,p.GetAccess);
                end
                
                key = [p.DefiningClass.Name '.' p.Name];
                hlp = strtrim(help(key)); %key matches the help search path! see doc help
                n = regexp(hlp, '@propclass{(?<level>\w*)}\s*(?<text>[^@]*)','names');
                % Check if property has @propclass tag set
                if ~isempty(n)
                    % Check validity
                    if ~any(strcmp(n.level,DPCM.PropClasses))
                        error('Invalid property class: %s',n.level);
                    end
                    % Add the listener
                    if ~any(strcmp(n.level,'data'))
                        if ~p.SetObservable
                            error('Non-passive registered property %s must have the SetObservable flag.',p.Name);
                        end
                        addlistener(this,p.Name,'PostSet',@(src,evd)this.PropPostSetCallback(src,evd));
                    end
                    % Only overwrite if not present -> save/load process!
                    if ~this.PropertiesChanged.containsKey(key)
                        % Initialize Changed flag to false
                        ps.Changed = false;
                        
                        % Get current value and save as default
                        ps.Default = this.(p.Name);
                        ps.Name = p.Name;
                        
                        % Add misc help texts and classification
                        ps.Short = DPCMObject.getHelpShort(hlp);
                        ps.Level = n.level;
                        ps.Text = strtrim(n.text);
                        
                        this.PropertiesChanged(key) = ps;
                    end
                elseif ~isempty(hlp)
                    error('When registering a property you must define the @propclass{<level>} tag in the properties help text.');
                end
            end
        end
    end
    
    methods(Access=private)
        function PropPostSetCallback(this, ~, evd)
            p = evd.Source;
            key = [p.DefiningClass.Name '.' p.Name];
            ps = this.PropertiesChanged(key);
            if isempty(ps)
                warning('DPCMObject:warning','PostSet called on property %s but dict does not contain key',key);
            else
                if ~ps.Changed
                    this.PropertiesChanged(key).Changed = true;
                    this.PropertiesChanged(key).DefaultConfirmed = isequal(ps.Default,evd.AffectedObject.(p.Name));
                    % Save some space!
                    this.PropertiesChanged(key).Default = [];
                    this.PropertiesChanged(key).Text = [];
                end
            end
        end
    end
    
    methods(Static, Access=protected)
        function obj = loadobj(obj, from)
            % Re-register any registered change listeners!
            %
            % @change{0,6,dw,2012-01-17} Checking if any properties registered in the
            % PropertiesChanged dictionary are not present anymore (due to updates etc) and
            % removing them from the dictionary if that is the case.
            if nargin > 1
                obj.ID = from.ID;
                obj.WorkspaceVariableName = from.WorkspaceVariableName;
                if isfield(from,'PropertiesChanged') && ~isempty(from.PropertiesChanged)
                    obj.PropertiesChanged = from.PropertiesChanged;
                    keys = obj.PropertiesChanged.Keys;
                    for idx = 1:obj.PropertiesChanged.Count
                        ps = obj.PropertiesChanged(keys{idx});
                        if ~ps.Changed && ~any(strcmp(ps.Level,'data'))
                            if isprop(obj,ps.Name)
                                addlistener(obj,ps.Name,'PostSet',@(src,evd)obj.PropPostSetCallback(src,evd));
                            else
                                warning('DPCMObject:load','Property %s of DPCMObject #%s (class %s) does not exist anymore.\nRemoving it from ProperitesChanged dictionary.',ps.Name,obj.ID,class(obj));
                                obj.PropertiesChanged.clear(keys{idx});
                            end
                        end
                    end
                end
            elseif ~isa(obj,'DPCMObject')
                warning('DPCM:loadobj','Argument "obj" not a DPCMObject instance but no argument to initialize from given!');
            end
        end
    end
    
    methods(Static, Access=private)
        function id = generateID
            % Generates an ID that is unique at least within the scope of the current MatLab
            % session.
            persistent cnt;
            if isempty(cnt)
                cnt = round((sum(clock)+cputime)*1000);
            end
            id = sprintf('%d',cnt);
            cnt = cnt+1;
        end
        
        function short = getHelpShort(txt)
            % Extracts the help short subtext from a given text.
            %
            % Gets the first block of a text that goes until the first
            % blank line.
            %
            % Parameters:
            % txt: The text to use. @type char
            %
            % Return values:
            % short: The subtext. @type char
            pos = regexp(txt,sprintf('\n[ ]*\n'));
            short = '';
            if ~isempty(pos)
                short = txt(1:pos(1)-1);
            else
                % Maybe only one line?
                pos = strfind(txt,char(10));
                if ~isempty(pos)
                    short = txt(1:pos(1)-1);
                end
            end
            short = strtrim(short);
        end
    end
end