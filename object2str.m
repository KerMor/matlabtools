function str = object2str(obj, maxdepth)
% object2str: Generic matlab object to string converter.
%
% This small function recursively displays the complete hierarchy of any object and nested
% objects therein as a string, intended by tabs equal to the sublevel and sorted alphabetically.
%
% Parameters:
% obj: The object to convert to a string @type handle
% maxdepth: The maximum recursion depth. @type integer @default Inf
%
% Return values:
% str: The string representation of the object's state.
%
% See also:
% http://www.mathworks.com/matlabcentral/fileexchange/26947
% http://www.mathworks.com/matlabcentral/fileexchange/17935
%
% @author Daniel Wirtz @date 2011-11-23
%
% @change{0,6,dw,2011-11-23} Export as standalone object2str function.
%
% @change{0,3,dw,2011-04-05} The order of the properties listed
% is now alphabetically, fixed no-tabs-bug.
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
%
% @todo enable argument that omits any properties of a given name

if ~isobject(obj)
    error('The obj argument has to be a matlab object.');
end
if nargin < 2
    maxdepth = Inf; % Default: Inf depth
elseif ~isnumeric(maxdepth) || ~isreal(maxdepth)
    error('maxdepth has to be a real value/integer.');
end
str = recursive2str(obj, maxdepth, 0, {});

    function str = recursive2str(obj, depth, numtabs, done)
        % Internal recursion.
        str = '';
        if depth == 0
            return;
        end
        done{end+1} = obj;
        mc = metaclass(obj);
        if isfield(obj,'Name')
            name = obj.Name;
        else
            name = mc.Name;
        end
        if ~isempty(str)
            str = [str ': ' name '\n'];
        else
            str = [name ':\n'];
        end
        % get string cell of names and sort alphabetically
        names = cellfun(@(mp)mp.Name,mc.Properties,'UniformOutput',false);
        [~, sortedidx] = sort(names);
        for n = 1:length(sortedidx)
            idx = sortedidx(n);
            p = mc.Properties{idx};
            if strcmp(p.GetAccess,'public')
                str = [str repmat('\t',1,numtabs) '.']; %#ok<*AGROW>
                pobj = obj.(p.Name);
                if ~isempty(pobj) && ~any(cellfun(@(el)isequal(pobj,el),done))
                    if isobject(pobj)
                        str = [str p.Name ' - ' recursive2str(pobj, depth-1, numtabs+1, done)];
                    elseif isnumeric(pobj)
                        if numel(pobj) > 20
                            str = [str p.Name ': [' num2str(size(pobj)) '] ' class(pobj)];
                        else
                            pobj = reshape(pobj,1,[]);
                            str = [str p.Name ': ' num2str(pobj)];
                        end
                    elseif isstruct(pobj)
                        if any(size(pobj) > 1)
                            str = [str p.Name ' (struct, [' num2str(size(pobj)) ']), fields: '];
                        else
                            str = [str p.Name ' (struct), fields: '];
                        end
                        fn = fieldnames(pobj);
                        for fnidx = 1:length(fn)
                            str = [str fn{fnidx} ','];
                        end
                        str = str(1:end-1);
                    elseif isa(pobj,'function_handle')
                        str = [str p.Name ' (f-handle): ' func2str(pobj)];
                    elseif ischar(pobj)
                        str = [str p.Name ': ' pobj];
                    elseif islogical(pobj)
                        if pobj
                            str = [str p.Name ': true'];
                        else
                            str = [str p.Name ': false'];
                        end
                    elseif iscell(pobj)
                        str = [str sprintf('%s: %dx%d cell<%s>', p.Name, size(pobj,1),size(pobj,2),class(pobj{1}))];
                    else
                        str = [str p.Name ': ATTENTION. Display for type "' class(pobj) '" not implemented yet.'];
                    end
                else
                    if isequal(obj,pobj)
                        str = [str p.Name ': [self-reference]'];
                    else
                        str = [str p.Name ': empty'];
                    end
                end
                str = [str '\n'];
            end
        end
        % Take away the last \n for inner recursive calls
        if depth < maxdepth
            str = str(1:end-2);
        end

        % Format!
        str = sprintf(str);
    end
end