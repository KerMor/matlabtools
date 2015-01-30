classdef ProcessIndicator < handle
% ProcessIndicator: A simple class that indicates process either via waitbar or text output
%
% The flag UseWaitbar determines if a waitbar is used or text output is produced. The text
% output restrains itself to only report progress at about each 10% to keep verbosity at an
% acceptable level.
%
% @author Daniel Wirtz @date 2012-03-20
%
% @change{0,6,dw,2012-05-07} The constructor takes varargin arguments that
% are forwarded to a sprintf of the title string, if given.
%
% @change{0,6,dw,2012-04-16} Fixed misinterpreted use of "step" method. Now
% have a step method which takes an increase value and a set method which
% takes the new absolute progress to show
%
% @new{0,6,dw,2012-03-20} Added this class.
%
% @todo process indicator for arbitrary (percentage/integer) values!
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing

    properties
        % Flag that indicates if a waitbar should be used.
        %
        % @default false @type logical
        UseWaitbar = false;
    end
    
    properties(Access=private)
        total;
        p;
        wb;
        title;
        cur;
    end

    methods
        function this = ProcessIndicator(title, total, wb, varargin)
            % Creates a new ProcessIndicator.
            %
            % If a total argument is given, the indicator is initialized via @code start(total)
            % @endcode directly.
            %
            % Parameters:
            % title: A title @type char @default 'Process running'
            % total: The total process amount. Must be positive. @type double @default []
            % wb: Flag that indicates how to initialize the UseWaitbar flag. @type logical
            % @default false
            % varargin: Any further parameters are passed to a sprintf call
            % for the title string.
            %
            % Return values:
            % this: The new ProcessIndicator @type ProcessIndicator
            if nargin < 3
                wb = false;
            end
            if ~isempty(varargin)
                this.title = sprintf(title,varargin{:});
            else
                this.title = sprintf('%s (%d total)',title,total);
            end
            this.UseWaitbar = wb;
            if nargin > 1
                this.start(total);
            end
        end
        
        function start(this, total)
            % Starts the process indicator with the given total process amount.
            %
            % Parameters:
            % total: The total process amount. Must be positive. @type double
            if isempty(total) || ~isscalar(total) || total <= 0
                error('Total must be a positve scalar value');
            end
            this.total = total;
            this.cur = 0;
            this.p = 0;
            if this.UseWaitbar
                this.wb = waitbar(0,this.title,'Visible','off');
                % Place at main monitor middle
                mpos = get(0,'MonitorPositions');
                if size(mpos,1) > 1
                    npos = get(this.wb,'Position');
                    npos(1) = (mpos(1,3)/2-npos(3));
                    set(this.wb,'Position',npos);
                end
                set(this.wb,'Visible','on');
            else
                fprintf('%s: ',this.title);
            end
        end
        
        function set(this, value)
            % Directly sets the current process value.
            %
            % Value is always restricted to `[0, total]`, and if no argument is given, value=1
            % is assumed.
            if nargin == 1
                error('Set requires a value to set.');
            end
            if value > this.total
                value = this.total;
            elseif value < 0
                value = 0;
            end
            this.cur = value;
            this.update;
        end
        
        function step(this, value)
            % Reports process to the indicator and triggers waitbar or text output.
            %
            % Increases the current process by the given value. If no value
            % is specified, one is assumed.
            %
            % Parameters:
            % value: The process value. @type double @default 1
            if nargin == 1
                value = 1;
            end
            if value + this.cur > this.total
                value = this.total - this.cur;
            elseif value < -this.cur
                value = -this.cur;
            end
            this.cur = this.cur + value;
            this.update;
        end
        
        function stop(this)
            % Stops the process indication and closes the waitbar, if any.
            if this.UseWaitbar
                if ~isempty(this.wb) && ishandle(this.wb)
                    close(this.wb);
                end
            else
                fprintf('done!\n');
            end
        end
        
        function set.UseWaitbar(this, value)
            if ~islogical(value) || ~isscalar(value)
                error('UseWaitbar must be a logical scalar');
            end
            this.UseWaitbar = value;
        end
    end
    
    methods(Access=private)
        function update(this)
            perc = this.cur/this.total;
            pstr = sprintf('%2.0f%% ',round(perc*100));
            if this.UseWaitbar
                waitbar(perc,this.wb,sprintf('%s: %s',this.title,pstr));
            else
                if perc > this.p
                    fprintf('%s',pstr);
                    this.p = ceil(perc*10)/10;
                end
            end
        end
    end
    
end