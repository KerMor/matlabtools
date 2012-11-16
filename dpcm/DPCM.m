classdef DPCM
% DPCM: Default property change monitoring for MatLab class properties
%
% This class collection allows to automatically supervise changes to properties' default
% settings and create reports of different detail and level for them.
%
% The purpose of this tool is to improve the reliability and quality of small software tools or
% even frameworks by ensuring that any end-users of the software get appropriate warnings when
% NOT changing default values, whose values have been chosen to the best knowledge of the
% programmers/developers but still might be critical or of great importance for the outcome of
% the computation.
%
% Target group is any MatLab programmer who develops classes and functionalities (e.g.
% simulation- or discretization tools, solvers etc) that are used by different people who might
% lack the domain knowledge of the program at hand.
%
% Roughly, the idea is to register any publicly changeable property after setting the default
% values and process any changes made to the properties at a later stage (by using the
% SetObservable flag for MatLab classes)
%
% Example:
% Create a DPCMDemoClass instance and run the demo!
% dc = DPCMDemoClass;
% dc.demo; % Watch out, there are pauses included! :-)
%
% The monitoring system distinguishes between several classes of properties that allow for a
% more precise categorization.
%
% DPCM property classes:
% - \c Critical A critical property is vital for the algorithm performance and result. This
% might be a given accuracy level or the consistency order for a discretization scheme. Any
% critical properties should have been set or at least validated by the end-user before
% simulations are started, otherwise a well-noticeable warning is issued.
% - \c Important Important properties are next in the order after the critical level. The
% difference is that those properties have an influence on the overall result, but will not
% lead to a totally different quality of the algorithm result. This might be an explicit
% jacobian matrix which would otherwise be computed by finite differences, a number of
% different samples to take or the simulation end time which is of course important for the
% computational time needed but does not affect the simulation quality. If any important
% properties have not been changed from their default value, a notice appears before the
% simulation.
% - \c alglimit Algorithm limit properties are of fail-safe nature. Sometimes algorithms have
% stopping conditions that are checked for within iterations which usually stop when some
% prescribed accuracy is gained. However, if an algorithm does not reach such states a maximum
% number of iterations can be put in place to force abortion of the iterations. As those
% properties are supposed to have appropriate (=high enough) default values simulations can be
% started without changing them. However, presence of those properties almost always implies
% the presence of a critical property like an accuracy level which is the first algorithm
% stopping condition.
% - \c scaling Scaling properties are used to perform numerical scaling of time, space or
% states within a numerical simulation. They are of an optional nature and thus are not
% elemental for simulations to produce accuracte results. However, for this special level it
% might very well be important if \e some scaling properties are set and some others are not.
% This might lead to wrong computational results and thus a warning is issued if not all or
% none of those properties are changed.
% - \c optional Optional properties are, well, optional. They can refer to whole components of
% a simulation that can be plugged in or not, specify a custom behaviour which will otherwise
% be computed in a correct but possibly more ineffective way or simply set the name of a
% component.
% - \c data Data properties circumfence all properties that must be set (or even will be set by
% the framework) at some stage, but their values are clear and necessary for the component.
% This can be plain data publicly accessible by other classes like function coefficients,
% trajectory samples or training data. Those properties are not kept track of, but enabling to
% register them within the surveillance system avoids messages that they are candidates for
% monitoring but have not been registered.
% - \c Experimental Experimental properties are settings whose effect on simulations have not
% been investigated completely or that might soon disappear. Properties of this level should
% not appear in production software, and any result produced with experimental properties
% should be questioned.
%
% @note This program makes use of the cprintf-function (File-Exchange #24093), if available.
% This way a more expressive colored summary can be printed. If not present, the standard
% output and error output streams (FileIDs 1 & 2) are used.
%
% @author Daniel Wirtz @date 2011-11-18
%
% @todo
% - Check if it makes sense to "link" properties with other known properties that
% helps to emphasize dependencies. maybe even a callback that validates a connected pair?
% - include a disable propchange listening flag for use during simulations.
% - maybe move the Text and Short property extractions to the getDPCMReport
% method? -> speedup
% - include DefaultConfirmed flag into output!
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
    
    properties(Constant)
        % The known property classes.
        %
        % Extend them at your need, however, the only restriction is to leave "critical" as
        % first entry.
        %
        % @type cell
        PropClasses = {'critical','important','alglimit','scaling','optional','data','experimental'};
        
        % Change this value to a more expressive one, i.e. a link to your software
        % documentation which includes the DPCM part.
        %
        % @type char
        PropClassesLink = 'matlab:help DPCM';
    end
    
    methods(Static)
        
        function getDPCMReport(DPCMobj, levels)
            % Prints a detailed report about the properties at each level which have not been
            % changed from their default setting.
            %
            % Call this method after any calls to models.BaseModel.simulate or
            % models.BaseModel.getTrajectory
            %
            % Parameters:
            % DPCMobj: The object to get the report for.
            % levels: [Optional] The property levels to print reports for. A list of admissible
            % values can be obtained by DPCM.PropClasses. Default is to print ''all''
            % data.
            %
            % See also: getDPCMSummary criticalsCheck
            if nargin < 2
                levels = DPCM.PropClasses;
            elseif ischar(levels)
                levels = {levels};
            end
            msg = DPCM.runDPCM(DPCMobj, levels);
            DPCM.printReport(msg, levels);
        end
        
        function getDPCMSummary(DPCMobj, levels)
            % Prints a summary about the properties of different levels which have not been changed
            % from their default setting.
            %
            % Parameters:
            % DPCMobj: The object to get the summary for.
            % levels: [Optional] The property levels to print reports for. A list of admissible
            % values can be obtained by DPCM.PropClasses. Default is to print ''all''
            % data.
            %
            % See also: getDPCMReport criticalsCheck
            if nargin < 2
                levels = DPCM.PropClasses;
            elseif ischar(levels)
                levels = {levels};
            end
            [~, stats] = DPCM.runDPCM(DPCMobj, levels);
            DPCM.printSummary(stats, levels);
        end
        
        function criticalsCheck(DPCMobj)
            % This is a shorthand method that runs the DPCM but only for critical properties.
            %
            % Use this method e.g. in front of your higher-level simulate/solve/etc methods.
            levels = DPCM.PropClasses(1);
            [msg, stats] = DPCM.runDPCM(DPCMobj, levels);
            if stats(1,1) > 0
                if ~isempty(DPCMobj.WorkspaceVariableName)
                    link = sprintf('<a href="matlab:DPCM.getDPCMReport(%s,''critical'')">critical properties</a>',DPCMobj.WorkspaceVariableName);
                else
                    link = 'critical properties';
                    DPCM.printReport(msg, levels);
                end
                DPCM.print('red',['RESULTS QUESTIONABLE: %d of %d ' link ' are still at their default value.\n'],...
                    stats(1,1),stats(2,1));
            end
        end
    end
    
    methods(Static, Access=private)
        
        function printSummary(stats, levels)
            % Internal summary printing method
            total = sum(stats,2);
            total(3) = total(1)/total(2)*100;

            col = [total(3)/100 1-total(3)/100 0];
            DPCM.print(col,'Total unchanged properties: %d of %d (%2.2f%%%%)\n',total);
            for lidx = 1:length(levels)
                col = [stats(3,lidx)/100 1-stats(3,lidx)/100 0];
                lvidx = find(strcmp(levels{lidx},DPCM.PropClasses),1);
                DPCM.print(col, 'Unchanged ''%s'': %d of %d (%2.2f%%%%)\n',levels{lidx},stats(:,lvidx));
            end
        end
        
        function printReport(msg, levels)
            % Internal report printing method
            for idx = 1:length(levels)
                m = msg.(levels{idx});
                if ~isempty(m)
                    DPCM.print([.5 .5 0],'Messages for property class %s:\n',levels{idx});
                    fprintf('%s\n',m{:});
                    fprintf('\n');
                end
            end
        end
        
        function print(varargin)
            % Print method that uses cprintf if available.
            if ~isempty(which('cprintf'))
                cprintf(varargin{:});
            else
                fprintf(2,varargin{2:end});
            end
        end
        
        function [msg, pstats] = runDPCM(DPCMobj, levels)
            % Checks all the model's properties recursively for unchanged default settings
            counts = struct;
            notchanged = struct;
            messages = struct;
            for lidx=1:length(levels)
                counts.(levels{lidx}) = 0;
                messages.(levels{lidx}) = {};
            end
            notchanged = counts;
            
            %% Run recursive check
            if isfield(DPCMobj,'Name') || isprop(DPCMobj,'Name')
                n = DPCMobj.Name;
            else
                tmp = metaclass(DPCMobj);
                n = tmp.Name;
            end
            recurCheck(DPCMobj, general.collections.Dictionary, n);
            
            % Store collected messages
            msg = messages;
            
            % Some total stats now
            %c = [struct2array(notchanged); struct2array(counts)];
            c = cell2mat([struct2cell(notchanged) struct2cell(counts)])';
            c(3,:) = round(10000 * c(1,:) ./ c(2,:))/100;
            c(3,isnan(c(3,:))) = 0;
            pstats = c;
                        
            function recurCheck(DPCMobj, done, lvl)
                mc = metaclass(DPCMobj);
                done(DPCMobj.ID) = true;
                
                %% Link name preparations
                objlink = editLink(mc.Name);
                
                %% Check the local properties
                pc = DPCMobj.PropertiesChanged;
                for pidx = 1:length(mc.Properties)
                    p = mc.Properties{pidx};
                    if strcmp(p.GetAccess,'public') && ~p.Constant && ~p.Transient && strcmp(p.SetAccess,'public') %~strcmp(p.SetAccess,'private')
                        key = [p.DefiningClass.Name '.' p.Name];
                        if pc.containsKey(key)
                            p = pc(key);
                            % Ignore if property level is not wanted
                            if any(strcmp(p.Level,levels))
                                counts.(p.Level) = counts.(p.Level) + 1;
                                if ~p.Changed
                                    notchanged.(p.Level) = notchanged.(p.Level) + 1;
                                    if ~any(strcmp(p.Level,'data'))
                                        hlp = messages.(p.Level);
                                        %if strcmp(mc.Name,p.)
                                        hlp{end+1} = sprintf('%s is still unchanged!\nProperty brief: %s\nPropclass tag description:\n%s\n',...
                                            [lvl '[' objlink '] -> ' p.Name],p.Short,p.Text);%#ok
                                        messages.(p.Level) = hlp;
                                    end
                                end
                            end
                        elseif ~p.SetObservable && ~pc.containsKey([p.DefiningClass.Name '.' p.Name])
%                             link2 = editLink(p.DefiningClass.Name);
%                             fprintf('Attention: Property %s of class %s is not <a href="matlab:docsearch SetObservable">SetObservable</a> but a candidate for a user-definable public property!\nFor more details see <a href="%s">Property classes and levels</a>\n\n',p.Name,link2,DPCM.PropClassesLink);
                        end
                        pobj = DPCMobj.(p.Name);
                        % Recursively register subobject's properties
                        if isa(pobj, 'DPCMObject') && isempty(done(pobj.ID))
                            recurCheck(pobj, done, [lvl '[' objlink '] -> ' p.Name]);
                        end
                    end
                end
            end
            
            function l = editLink(classname)
                dotpos = strfind(classname,'.');
                if ~isempty(dotpos)
                    lname = classname(dotpos(end)+1:end);
                else
                    lname = classname;
                end
                l = sprintf('<a href="matlab:edit %s">%s</a>',classname,lname);
            end
        end
    end
    
    
    
end