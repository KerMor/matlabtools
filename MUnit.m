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
    % See also: TestFunctionPrefix
    %
    % @author Daniel Wirtz @date 12.03.2010
    %
    % @change{0,3,dw,2011-04-26} Added linebreaks after each message to avoid loss of lines when
    % using cprintf.
    %
    % @todo 08.10.10: extend test method signature by a verbose flag; v=0 means
    % quiet, v=1 means text output and v=2 means with plots
    % @todo 08.10.10: apply changes of extended test method signature to all already
    % implemented test cases where applicable!
    % @todo 08.10.10: Extend MUnit to also be able to deal with folders &
    % function files named according to MUnit convention
    
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
        function RunClassTests(dir)
            % Runs class tests recursively within the specified path.
            %
            % If no path is given, the current directory (cd) is used.
            %
            % Within the path any static methods from classes beginning
            % with the 'TestFunctionPrefix' are detected and executed.
            %
            % After running all tests a summary is provided.
            
            % Check for no specified path
            if nargin == 0
                dir = cd;
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
            [s,f] = MUnit.recursiveRun(dir,curPackage);
            
            a.UseDPCM = old;
            
            % Summary
            fprintf('\n\n All Class Tests finished.\n');
            cprintf(MUnit.GreenCol,'Successful:%d\n',s);
            cprintf('Red','Failed:%d\n',f);
        end
    end
    
    methods(Static, Access=private)
        function [s,f] = recursiveRun(dir,currentPackage)
            % Internal private recursion function.
            %
            % Parameters:
            % dir: The directory to recurse, as full absolute path
            % currentPackage: The current package name
            %
            % Return values:
            % s: The number of successful tests
            % f: The number of failed tests
            w = what(dir);
            
            % Some weird afs stuff goin on!
            w=w(1);
            
            s = 0; f = 0;
            % Descend into any package
            for idx = 1:length(w.packages)
                subdir = fullfile(w.path,['+' w.packages{idx}]);
                %disp(['Descending into ' subdir]);
                [sa,fa] = MUnit.recursiveRun(subdir, [currentPackage w.packages{idx} '.']);
                s = s + sa;
                f = f + fa;
            end
            
            pref = MUnit.TestFunctionPrefix;
            pl = length(pref);
            
            targets = [w.m; w.classes];
            
            % Run tests in current directory
            for idx = 1:length(targets)
                [p,n] = fileparts(targets{idx});
                
                %disp(['Checking ' n '...']);
                
                mc = meta.class.fromName([currentPackage n]);
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
                                lines = '-----------------------------';
                                %MUnit.BlueCol
                                fprintf(2,[lines ' running '...
                                    mc.Name ' -> <a href="matlab:run(' mc.Name '.' m.Name ')">' m.Name(6:end) '</a>... ' lines '\n']);
                                try
                                    eval(['outargs = nargout(@' mc.Name '.' m.Name ');']);
                                    if outargs > 0
                                        command = ['succ = ' mc.Name '.' m.Name ';'];
                                    else
                                        command = [mc.Name '.' m.Name ';'];
                                    end
                                    eval(command);
                                    if outargs == 0 || succ
                                        cprintf(MUnit.GreenCol,['Test ' mc.Name ' -> ' m.Name(6:end) ' succeeded!\n']);
                                        s = s+1;
                                    elseif ~succ
                                        cprintf('Red','Failure!\n');
                                        f = f+1;
                                    end
                                catch ME
                                    f = f+1;
                                    cprintf(MUnit.WarnCol,['Test ' mc.Name ' -> ' m.Name(6:end) ' failed!\nExeption information:\n']);
                                    disp(getReport(ME));
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
        end
    end
end

