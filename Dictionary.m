classdef Dictionary < handle
% A basic dictionary of key/value pairs for small to medium amounts of data
%
% This simple dictionary basically wraps a nice interface around a matlab cell with the
% corresponding values. Due to the linear search for keys it is only suited for small to medium
% sized amounts of data.
%
% @note Despite the standard set/get methods one can also use the matlab-like subscripted
% notation to set and get values.
%
% Example:
% @code
% d = general.collections.Dictionary;
% d('somekey') = 'somevalue';
% d('nr') = 2346;
% d('myclass') = 'some object instance';
% disp(d('nr'));
% disp(d('myclass'));
% disp(d('nonexistent'));
% @endcode
% 
% @author Daniel Wirtz @date 2011-04-06
%
% See also: The dict class at http://www.mathworks.com/matlabcentral/fileexchange/19647
%
% @change{0,6,dw,2012-01-17} Changed the clear method so that optionally a specific key can be
% passed in order to only remove one entry.
%
% @change{0,3,dw,2011-04-20} - Improved the subsref and subsasgn methods to forward eventual
% further sub-assignments to the respective underlying values. Now i.e. assignments of the type
% @code d('t').Somefield @endcode natively creates a struct at @code d('t') @endcode.
% - Added a method general.collections.Dictionary.containsKey
% - Added two properties general.collections.Dictionary.Keys and
% general.collections.Dictionary.Values
%
% @new{0,3,dw,2011-04-06} Added this class.
%
% @todo connect to/backup with tree structure for speedup.
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
    
    properties(Access=private)
        % The internal List structure
        List;
    end
    
    properties(Dependent)
        % The keys used in the dictionary. Readonly.
        %
        % @type cell
        Keys;
        
        % The values used in the dictionary. Readonly.
        %
        % @type cell
        Values;
        
        % The size of the dictionary. Readonly.
        %
        % @type integer
        Count;
    end
    
    methods
        function this = Dictionary
            % Creates a new empty dictionary
            this.List = struct('Key',{},'Value',{});
        end
        
        function set(this, key, value)
            % Sets the dictionary entry for key 'key' to value 'value'
            % The keys are unique, so if a key already exists the value is overwritten.
            %
            % Parameters:
            % key: The key for the value. @type char
            % value: The value for the key. :-) @type any MatLab variable
            this.set_(key, value);
        end
        
        function value = get(this, key)
            % Returns the value for a given key, [] is the key does not exists inside the
            % dictionary.
            %
            % Parameters:
            % key: The key whose value is to be returned @type char
            value = this.get_(key);
        end
        
        function clear(this, key)
            % Clears the dictionary or the contents for a specific key, if given.
            %
            % Pass no argument in order to clear the whole dictionary.
            %
            % Parameters:
            % key: A key whose key/value pair is to be removed from the dictionary. @default []
            if nargin ==  2
                cidx = [];
                for i=1:length(this.List)
                    if strcmp(this.List(i).Key,key)
                        cidx = i;
                    end
                end
                if ~isempty(cidx)
                    this.List(cidx) = [];
                end
            else
                this.List = struct('Key',{},'Value',{});
            end
        end
        
        function bool = containsKey(this, key)
            % Checks if the dictionary contains the key 'key'.
            %
            % Parameters:
            % key: The key whose existence is to check @type char
            if ~isa(key,'char')
                error('Key must be a string.');
            end
            bool = false;
            for i=1:length(this.List)
                if strcmp(this.List(i).Key,key)
                    bool = true;
                    return;
                end
            end
        end
        
        function varargout = subsref(this, key)
            % Implements subscripted value retrieval.
            %
            % See also: subsref
            if (isequal(key(1).type,'()'))
                varargout{1} = this.get_(key(1).subs{1});
                if length(key) > 1
                    [varargout{1:nargout}] = builtin('subsref', varargout, key(2:end));
                end
            else
                [varargout{1:nargout}] = builtin('subsref', this, key);
            end
        end
        
        function this = subsasgn(this, key, value)
            % Implements subscripted assignment.
            %
            % See also: subsasgn
            if (isequal(key(1).type,'()'))
                if length(key) > 1
                    value = builtin('subsasgn', this.get_(key(1).subs{1}), key(2:end), value);
                end
                this.set_(key(1).subs{1}, value);
            else
                builtin('subsasgn', this, key, value);
            end
        end
        
        function c = get.Count(this)
            c = length(this.List);
        end
        
        function k = get.Keys(this)
            k = {this.List(:).Key};
        end
        
        function k = get.Values(this)
            k = {this.List(:).Value};
        end
        
        function display(this)
            % Overrides the default display method in MatLab and prints a list of keys and
            % values inside the dictionary.
            fprintf('general.collections.Dictionary with %d elements.\n',this.Count);
            arrayfun(@(kv)(disp({'Key:' kv.Key 'Value:' kv.Value})),this.List);
        end
    end
        
    methods(Access=private)
        function value = get_(this, key)
            % Default: []
            value = [];
            if isempty(key)
                return;    
            end
            if isa(key, 'char')
                for i=1:length(this.List)
                    if isequal(this.List(i).Key,key)
                        % Return found value
                        value = this.List(i).Value;
                        break;
                    end
                end
                return;
            elseif isposintscalar(key)
                if key < 1 || key > this.Count
                    error('Key index exceeds dictionary.');
                end
                value = this.List(key).Value;
                return;
            end
            error('The key must be a string or integer');
        end
        
        function set_(this, key, value)
            %cl = class(value);
            %fprintf('Set class %s for key %s\n',cl,key);
            if isa(key, 'char')
                for i=1:length(this.List)
                    if isequal(this.List(i).Key,key)
                        % Set value if already in list
                        this.List(i).Value = value;
                        return;
                    end
                end
                % Otherwise: Extend!
                this.List(end+1).Key = key;
                this.List(end).Value = value;
            elseif isposintscalar(key)
                if key < 1 || key > this.Count
                    error('Setting per numerical index only allowed within existing items; use a char key for automatic insertions.');
                end
                this.List(key).Value = value;
                return;
            end   
        end
    end
    
end

