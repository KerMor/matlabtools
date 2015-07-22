classdef MUnit
    % Class Unit Testing Framework for Matlab
    %
    % This class allows to run tests within a OO-Based Matlab program
    % according to the conventions mentioned below:
    %
    % Any test method has to satisfy:
    % - The method's name begins with "TestFunctionPrefix"
    % - Static
    % - No input arguments
    % - One (optional) output argument indicating success or failure of the
    %   test
    % Possible exceptions do not have to be taken care of as they are
    % caught automatically by the system, resulting in a failure of the
    % test.
    %
    % The most convenient way of calling MUnit is to use
    % @code done = {};
    %  done = MUnit.RunClassTests(cd, done); @endcode
    % After testing, you can simply re-run the last command, and the
    % subsequently successful tests (after e.g. fixing) will automatically
    % be added to the done cell array.
    %
    % See also: TestFunctionPrefix
    %
    % @author Daniel Wirtz @date 12.03.2010
    %
    % @change{0,7,dw,2014-04-15} Added a convenience interface for easy
    % skipping of previously successful tests (via passing an "exclude"
    % cell array and retrieving a "successful" cell array)
    %
    % @change{0,3,dw,2011-04-26} Added linebreaks after each message to
    % avoid loss of lines when using cprintf
    
    properties(Constant)
        % The prefix for any function that will be detected in the MUnit
        % testing process.
        %
        % Defaults to 'test_'
        TestFunctionPrefix = 'test_';
        
        % Green color (the default is hardly readable)
        GreenCol = [0 .5 0];
        
        % Blue color
        BlueCol = '*[0 0 .8]';
        
        % Warning color
        WarnCol = '*[1 .4 0]';
    end
    
    methods(Static)
        function succeeded = RunClassTests(dir, returnonerror, exclude)
            % Runs class tests recursively within the specified path.
            %
            % If no path is given, the current directory (cd) is used.
            %
            % Within the path any static methods from classes beginning
            % with the 'TestFunctionPrefix' are detected and executed.
            %
            % After running all tests a summary is provided.
            
            % Check for no specified path
            if nargin < 3
                exclude = {};
                if nargin < 2
                    returnonerror = false;
                    if nargin < 1
                        dir = cd;
                    end
                end
            end
            
            % Check if the current directory path contains packages and
            % extract them if necessary
            curPackage = '';
            pckidx = strfind(dir,'+');
            if ~isempty(pckidx)
                curPackage = dir(pckidx(1)+1:end);
                curPackage = [strrep(strrep(curPackage,'+','.'),'/','') '.'];
            end
            
            a = KerMor.App;
            old = a.UseDPCM;
            a.UseDPCM = false;
            
            % Start recursive run
            [s,f,succeeded,abort] = MUnit.recursiveRun(dir, curPackage, returnonerror, exclude);
            
            a.UseDPCM = old;
            
            % Summary
            if abort
                fprintf('\n\n Test runs aborted.\n');
            else
                fprintf('\n\n All Class Tests finished.\n');
            end
            cprintf(MUnit.GreenCol,'Successful:%d\n',s);
            cprintf('Red','Failed:%d\n',f);
        end
    end
    
    methods(Static, Access=private)
        function [s,f,succeeded,abort] = recursiveRun(folder, currentPackage, returnonerror, exclude)
            % Internal private recursion function.
            %
            % Parameters:
            % dir: The directory to recurse, as full absolute path @type
            % char
            % currentPackage: The current package name @type char
            % exclude: A cell array of strings containing function names
            % (fully qualified) that should not be tested @type cell<char>
            % @default {}
            %
            % Return values:
            % s: The number of successful tests
            % f: The number of failed tests
            % succeeded: A cell array of strings containing the fully
            % qualified names of functions that have successfully run.
            % Contains all values of exclude, if set. @type cell<char>
            
            s = 0; f = 0; succeeded = exclude;
            
            % Descend into subfolders
            dinf = dir(folder);
            for idx = 1:length(dinf)
                if dinf(idx).isdir
                    subdir = dinf(idx).name;
                    if ~any(strcmp(subdir,{'.','..'}))
                        subdir = fullfile(folder,subdir);
                        %disp(['Descending into ' subdir]);
                        [sa,fa,succeeded,abort] = ...
                            MUnit.recursiveRun(subdir, currentPackage, returnonerror, succeeded);
                        s = s + sa;
                        f = f + fa;
                        if abort
                            return;
                        end
                    end
                end
            end
            
            % Descend into any package
            w = what(folder);
            w=w(1); % Some weird afs stuff goin on!
            for idx = 1:length(w.packages)
                subdir = fullfile(w.path,['+' w.packages{idx}]);
                %disp(['Descending into ' subdir]);
                [sa,fa,succeeded,abort] = MUnit.recursiveRun(subdir, [currentPackage w.packages{idx} '.'], returnonerror, succeeded);
                s = s + sa;
                f = f + fa;
                if abort
                    return;
                end
            end
            
            pref = MUnit.TestFunctionPrefix;
            pl = length(pref);
            
            targets = [w.m; w.classes];
            
            % Run tests in current directory
            for idx = 1:length(targets)
                [~,n] = fileparts(targets{idx});
                
                %disp(['Checking ' n '...']);
                
                try
                    mc = meta.class.fromName([currentPackage n]);
                catch ME
                    warning('Could not instantiate class %s: %s',[currentPackage n],ME.message);
                    abort = true;
                    return;
                end
                % mc is empty if m-file wasnt a class
                if ~isempty(mc)
                    
                    %disp(['Checking ' mc.Name '...']);
                    
                    for midx=1:length(mc.Methods)
                        m = mc.Methods{midx};
                        
                        %disp(['Method: ' mc.Name '.' m.Name]);
                        
                        % check for test function and if the method is
                        % actually declared within the current class
                        % (subclassing would otherwise lead to a repeated
                        % call to the test)
                        if length(m.Name) >= pl+1 ...
                                && strcmpi(m.Name(1:pl),pref) ...
                                && strcmp(m.DefiningClass.Name,mc.Name)
                            % check if the method is static [non-statics
                            % cant be run without instances.. :-)]
                            if m.Static
                                fullname = [mc.Name '.' m.Name];
                                if any(strcmp(fullname,exclude))
                                    continue;
                                end
                                lines = '-----------------------------';
                                fprintf(2,[lines ' running '...
                                    mc.Name ' -> <a href="matlab:run(' mc.Name '.' m.Name ')">' m.Name(6:end) '</a>... ' lines '\n']);
                                try
                                    eval(['outargs = nargout(@' fullname ');']);
                                    if outargs > 0
                                        command = ['succ = ' fullname ';'];
                                    else
                                        command = [fullname ';'];
                                    end
                                    eval(command);
                                    if outargs == 0 || succ
                                        cprintf(MUnit.GreenCol,['Test ' mc.Name ' -> ' m.Name(6:end) ' succeeded!\n']);
                                        succeeded{end+1} = fullname;%#ok
                                        s = s+1;
                                    elseif ~succ
                                        cprintf('Red','Failure!\n');
                                        f = f+1;
                                    end
                                catch ME
                                    f = f+1;
                                    cprintf(MUnit.WarnCol,['Test ' mc.Name ' -> ' m.Name(6:end) ' failed!\nExeption information:\n']);
                                    disp(getReport(ME));
                                    if returnonerror
                                        abort = true;
                                        return;
                                    end
                                end
                            else
                                cprintf(MUnit.WarnCol,['Non-static test "%s" in %s found.'...
                                    'Should this be static?\n'],...
                                    m.Name((length(MUnit.TestFunctionPrefix)+1):end),...
                                    mc.Name);
                            end
                        end
                    end
                end
            end
            abort = false;
        end
    end
end

