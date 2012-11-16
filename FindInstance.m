function [t, matches, parents, locations] = FindInstance(obj, type, varargin)
% FindInstance: Locate instances of certain classes within a class or a struct.
%
% Parameters:
% obj: The object in which to search. @type [handle|struct]
% type: The type of the instances to find. @type char
% varargin: Any more arguments are assumed to be character arrays and denote existing
% properties of the instances to find.
%
% Return values:
% t: A PrintTable instance containing information about the matches and their location within
% the passed object. @type PrintTable
% matches: A cell array of all instances that have been found in obj. @type
% cell
% parents: A cell array of all the parent objects/structs whose immediate property is of the
% specified type.
% locations: A cell array of the according locations/paths within the object hierarchy. @type
% cell
%
% Examples:
% s.someclass1 = RandStream('mt19937ar','Seed',1);
% s.foo = 'bar';
% s.nested.one = RandStream('mt19937ar','Seed',56);
% s.nested.two = RandStream('mrg32k3a');
% s.nested.matrix = rand(4,5);
% FindInstance(s,'RandStream');
%
% % You can also automatically select specific properties of the instances as extra parameters:
% FindInstance(s,'RandStream','Seed')
% FindInstance(s,'RandStream','Seed','NormalTransform')
%
% % If you want to obtain references to the found objects:
% [t, m] = FindInstance(s,'RandStream','Seed','NormalTransform');
% disp(m);
%
% @new{0,6,dw,2012-09-25} Added a cell array of the according locations/paths within the object
% hierarchy as optional return value
%
% @change{0,6,dw,2012-07-20) No longer running into an error if an extra specified property
% could not be found
%
% @author Daniel Wirtz @date 2012-06-11
% This class has originally been developed as part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php

    if ~isa(obj, 'handle') && ~isstruct(obj) 
        error('The argument must either be a handle class or a struct.');
    end
    
    matches = {};
    visited = {};
    parents = {};
    locations = {};
    t = PrintTable('Instances of "%s" in %s (%s)',...
        type,inputname(1),class(obj));
    t.HasHeader = true;
    t.addRow('Location','Class','ID','Parent',varargin{:});
    
    warning('off','MATLAB:structOnObject');
    findinst_recur(obj, inputname(1), true);
    warning('on','MATLAB:structOnObject');
    
    function findinst_recur(obj, lvl, checkloop)
        if checkloop && any(cellfun(@(o)isequal(o,obj),visited))
            return;
        end
        
        if numel(obj) > 1
            if iscell(obj)
                for l = 1:length(obj)
                    findinst_recur(obj{l}, sprintf('%s{%d}',lvl,l), false);
                end
            else
                for l = 1:length(obj)
                    findinst_recur(obj(l), sprintf('%s(%d)',lvl,l), false);
                end
            end
        else
            if isa(obj,'handle')
                os = struct(obj);
            elseif isstruct(obj)
                os = obj;
            end
            fn = fieldnames(os);
            for idx = 1:length(fn)
                if ~isempty(os.(fn{idx}))
                    prop = os.(fn{idx});
                    thislvl = [lvl '.' fn{idx}];
                    if isa(prop,type)
                        matches{end+1} = prop;%#ok
                        parents{end+1} = obj;%#ok
                        locations{end+1} = thislvl;%#ok
                        st = 'none';
                        if any(cellfun(@(o)isequal(o,'ID'),fieldnames(prop)))
                            st = prop.ID;
                        end
                        props = cell(1,length(varargin));
                        for k = 1:length(varargin)
                            if isprop(prop,varargin{k}) || isfield(prop,varargin{k})
                                props{k} = prop.(varargin{k});
                            else
                                props{k} = 'doesn''t exist';
                            end
                        end
                        t.addRow(thislvl,class(prop),st,class(obj),props{:});
                    end    
                    if isa(prop, 'handle') || isstruct(prop)
                        visited{end+1} = obj;%#ok
                        findinst_recur(prop, thislvl, true);
                    end
                end
            end
        end
    end
    
    
end