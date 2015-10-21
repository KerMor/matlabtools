classdef PCPool < handle
    % Manage the parpool/matlabpool handling independent of the
    % current MatLab release.
    %   This has been introduced to maximize backwards compatibility of
    %   KerMor. PCPool = "Parallel Computing Pool".
    
    properties(Constant)
        % For versions older than 8.3 (R2014a) we still have the
        % matlabpool syntax available. (could be a different one, but
        % doesnt really matter)
        OldSyntax = verLessThan('matlab','8.3.0');
    end
    
    methods(Static)
        
        function res = isAvailable
            if PCPool.OldSyntax
                res = exist('matlabpool','file') == 2;
            else
                res = exist('parpool','file') == 2;
            end
        end
        
        function res = isOpen
            % Checks if the parpool is open and active.
            if PCPool.OldSyntax
                res = matlabpool('size') > 0;%#ok
            else
                res = ~isempty(gcp('nocreate'));
            end
        end
        
        function res = size
            % Returns the size of the current pool, zero if inactive
            res = 0;
            poolobj = gcp('nocreate');
            if ~isempty(poolobj)
                poolobj.NumWorkers;
            end
        end
        
        function created = open(varargin)
            % Opens a new pool using the specified arguments.
            % No arguments use the default pool.
            created = false;
            if ~PCPool.isOpen
                if PCPool.OldSyntax
                    matlabpool('open',varargin{:});%#ok
                else
                    parpool(varargin{:});
                end
                created = true;
            end
        end
        
        function close(force)
            % Closes any currently open pool.
            %
            % If force argument only applies for
            % the old matlabpool syntax.
            if nargin < 1
                force = false;
            end
            if PCPool.OldSyntax
                if force
                    matlabpool close force;%#ok
                elseif ~PCPool.isopen
                    matlabpool close;%#ok
                end
            else
                poolobj = gcp('nocreate');
                if ~isempty(poolobj)
                    delete(poolobj);
                end
            end
        end
    end
    
end

