classdef PlotManager < handle
% PlotManager: Small class that allows the same plots generated by some
% script to be either organized as subplots or single figures.
%
% The key feature of this is that you can call your plotting methods with differently
% configured PlotManagers, so one time you have it plotting to subplots (=development time) and
% the next you create single plots with specific export settings (=publication/report time).
%
% This class needs a working 'export_fig' tool that is available at
% http://www.mathworks.com/matlabcentral/fileexchange/23629
%
% Any openend figure using nextPlot can be exported to a directory using a
% specified format (any allowed by export_fig).
%
% Examples:
% % Run with subplots:
% PlotManager.demo_Subplots
%
% % Run with single figures:
% PlotManager.demo_SinglePlots
%
% % Saving plots:
% PlotManager.demo_SavePlots
% PlotManager.demo_SavePlots_Details
%
% % Zooms:
% PlotManager.demo_Zoom
%
% @change{0,7,dw,2014-01-15} Changed the property "SingleSize" to
% "FigureSize". The sizes are now used whenever a new figure is created,
% independently of being in single or subplot mode.
%
% @new{0,7,dw,2013-07-05}
% - Compatibility with newest export_fig (June 2013) checked
% - Rewrote the savePlots routine to pass all desired formats to export_fig on the fly
% - New optional parameter "XArgs" that are passed to export_fig as-is
% - New property "WhiteBackground" for white figure background on export (default true)
%
% @new{0,6,dw,2012-09-25}
% - Now can set Figure names explicitly
% - New property DoubleSaveJPG as sometimes on Linux machines the output is useless on one save
% iteration (has probably to do with multiple monitors?)
% - MinYTickMarks property, that manually adds more Y tick marks if somehow matlab does not add
% enough. Output is not really pretty, but when it comes down to it its useful.
%
% @new{0,6,dw,2012-07-26}
% - Added a new function 'createZoom' to easily copy a Figure (only in ''Single''-mode) and
% zoom into a specified area.
% - Now the savePlots method optionally takes an argument 'separate_legends', that specifies
% for which selected figure to save the legend should be created as extra file (made for too
% large legends)
%
% @new{0,6,dw,2012-06-22} Added a new property NoTitlesOnSave, which
% enables to suppress any axes titles when savePlots is used.
%
% @new{0,6,dw,2012-06-16} Added a new property UseFileTypeFolders that
% causes the PlotManager to create subfolders for each file type inside the
% target directory when using savePlots.
%
% @change{0,6,dw,2012-05-07} 
% - PlotManager.savePlots now takes a cell array with file extensions,
% allowing to call the function once and generate all desired output types.
% Updated info string.
% - New default values (fig + pdf for savePlots, rows=cols=2 for subplots)
% - Only setting 'axes tight' if no manual changes have been made to the
% axis limits
%
% @new{0,6,dw,2012-04-27} Added support to optionally pass title, x- and
% ylabels for upcoming plots. If those values are given they will overwrite
% any manually set values. This is done by storing the given values and
% applying them upon 'nextPlot'/'done'.
%
% @new{0,6,dw,2012-04-12} Added this class.
%
% @author Daniel Wirtz @date 2012-04-12
%
% Copyright (c) 2012, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
%
% @todo register onFigureClose callback to remove figure from handles list
    
    properties
        % Flag if single plots shall be used for subsequent calls to
        % nextPlot.
        %
        % @type logical @default true
        Single = true;
        
        % Controls the maximum number of simultaneously opened figures.
        %
        % Set to a finite number to make the PlotManager re-use currently
        % openend figures. Has NO effect if Single is set to true.
        %
        % @type integer @default Inf
        MaxFigures = Inf;
        
        % The figure size for each newly created figure. Set to [] to use
        % system default.
        %
        % Is a two dimensional row vector with width and height
        %
        % @type rowvec<double> @default []
        FigureSize = [];
        
        % A prefix that has to be put before each file name for exported
        % plots.
        %
        % @type char @default ''
        FilePrefix = '';
        
        % DPI used for export. See export_fig settings.
        %
        % Defaults to the current pixels per inch resolution of the screen.
        %
        % @type integer @default get(0,'ScreenPixelsPerInch')
        ExportDPI = get(0,'ScreenPixelsPerInch');
        
        % JPEG quality used for export. See export_fig settings.
        %
        % @type char @default '95'
        JPEGQuality = '95';
       
        % Affects the savePlots behaviour.
        % This flag lets the PlotManager create subfolders in the target
        % folder according to the specified file extensions and places any
        % images of that type inside it.
        %
        % This is especially useful for use with LaTeX, as during
        % production simple and fast jpeg-versions of plots can be used and
        % later a single path change includes pdf or eps files.
        %
        % This setting is only used if more than one file type have been
        % specified.
        %
        % @type logical @default true
        UseFileTypeFolders = true;
        
        % Flag that determines if any figures title's are removed when
        % using savePlots.
        %
        % @type logical @default false
        NoTitlesOnSave = false;
        
        %
        SaveFont = struct('FontWeight','bold','FontSize',16);
        
        % Flag indicating if the plots should be left open once the PlotManager is deleted (as
        % variable)
        %
        % @type logical @default false
        LeaveOpen = false;
        
        % The image formats to use when savePlots is called.
        %
        % @type cell<char> @default {'jpg'}
        SaveFormats = {'jpg'};
        
        % An integer number to enforce a minimum number of tickmarks on the respective axes.
        % 
        % Set this property to a three element vector containing the numbers of how many tick
        % marks are desired for the X,Y and Z axis.
        %
        % When a plot is finished (i.e. nextPlot or done is called), it is checked if enough
        % tickmarks are present. If not, the given number of tickmarks is inserted, according
        % to the current -Lim and -Scale property.
        % Set to zero to let MatLab control how many tickmarks are used for the respective axis.
        %
        % @type rowvec<integer> @default [0 0 0]
%         MinTickMarks = [0 0 0];

        AutoTickMarks = true;
        
        % For some reason on unix machines export_fig sometimes uses the last image saved to
        % as the next one.
        %
        % As a workaround, images to be stored as jpg are saved twice in a row to avoid that.
        %
        % @type logical @default true
        DoubleSaveJPG = true;
        
        % Flag that determines if a white ''figure'' background should be used instead of any
        % set or default (grey) one
        %
        % @type logical @default true
        WhiteBackground = true;
    end
    
    properties(Access=private)
        rows = 0;
        cols = 0;
    end
    
    properties(SetAccess=private, Transient)
        % Provides access to all figure handles created using
        % nextPlot.
        %
        % @type rowvec<double>
        Figures;
    end
    
    properties(Access=private, Transient)
        curax = [];
        fignr;
        cnt;
        ss;
        % caption/labels for next plots
        ncap = [];
        nxl = [];
        nyl = [];
        nleg = [];
        donelast = false;
    end
    
    methods
        function this = PlotManager(single, rows, cols)
            % Creates a new PlotManager
            %
            % Parameters:
            % single: If to create single figures for each call to
            % nextPlot. @type logical @default true
            % rows: If on non-single mode, the number of rows to pass to
            % subplot. @type integer @default 2
            % cols: If on non-single mode, the number of columns to pass to
            % subplot. @type integer @default 2
            if nargin > 0
                this.Single = single;
                if nargin > 1
                    this.rows = rows;
                    this.cols = cols;    
                elseif ~this.Single
                    this.rows = 2;
                    this.cols = 2;
                end
            end
            this.cnt = 0;
            this.fignr = 0;
            this.Figures = [];
            s = get(0,'MonitorPositions');
            this.ss = s(1,3:4);
        end
        
        function ax_handle = nextPlot(this, tag, caption, xlab, ylab, leg_str, numsubplots)
            % Creates a new axis to plot in. Depending on the property
            % tools.PlotMananger.Single this will either advance to the
            % next subplot or open up a new figure window of size
            % FigureSize in the center of the main screen.
            %
            % If you specify a tag it will be used upon exporting created
            % plots to the file system as filename of the plot.
            %
            % Parameters:
            % tag: The tag to use for the axes. @type char @default ''
            % caption: The caption for the axes. @type char @default []
            % xlab: The xlabel for the axes. @type char @default []
            % ylab: The ylabel for the axes. @type char @default []
            % leg_str: The legend entry strings for the axes. @type cell<char> @default {}
            % numsubplots: The number of subplots to use up for this next
            % plot. Works only if the number of subplots is contained in
            % the current subplot row (i.e. there are sufficient columns
            % left over to use up the required number of subplots.) @type
            % integer @default 1
            %
            % Return values:
            % ax_handle: The handle to the new axes object. @type axes
            if nargin < 6
                leg_str = {};
                if nargin < 5
                    ylab = [];
                    if nargin < 4
                        xlab =[];
                        if nargin < 3
                            caption = [];
                            if nargin < 2
                                tag = '';
                            end
                        end
                    end
                end
            end
            % Finish current plot
            this.finishCurrent;
            % Store caption etc for upcoming plot
            this.ncap = caption;
            this.nxl = xlab;
            this.nyl = ylab;
            this.nleg = leg_str;
            
            if ~isempty(this.FigureSize)
                fpos = [(this.ss - this.FigureSize)/2 this.FigureSize];
            else
                fpos = get(0,'DefaultFigurePosition');
            end
            if this.Single
                this.Figures(end+1) = figure('Position',fpos,'Tag',tag);
                ax_handle = gca;
            else
                if nargin < 7
                    numsubplots = 1;
                end
                this.cnt = this.cnt + numsubplots;
                if isempty(this.Figures) || this.cnt > this.rows*this.cols
                    this.nextFigure(numsubplots,'Position',fpos,'Tag',tag);
                else
                    % Re-Focus on last figure to always correctly continue
                    % filling in plots
                    if gcf ~= this.Figures(end)
                        figure(get(this.curax,'Parent'));
                    end
                end
                ax_handle = subplot(this.rows, this.cols, ...
                    (this.cnt-numsubplots+1):this.cnt, 'Tag', tag);
            end
            this.curax = ax_handle;
            this.donelast = false;
        end
        
        function h = copyFigure(this, nr, newtag)
            % Copies the plot with the given number and returns the handle
            % to its axis.
            %
            if isempty(this.Figures)
                fprintf(2,'No figures exist yet within the PlotManager. Nothing to copy.\n');
                return;
            elseif ~this.Single
                error('copyFigure works only in single plot mode.');
            elseif isempty(nr) || ~isposintscalar(nr) || nr > length(this.Figures)
                error('nr must not be empty and within the range 1 to %d',length(this.Figures));
            end
            s = this.Figures(nr);
            if nargin < 3
                newtag = [get(s,'Tag') '_copy'];
            end
            f = figure('Position',get(s,'Position'),'Tag',newtag);
            this.Figures(end+1) = f;
            % Copy stuff over
            h = copyobj(get(s,'Children'),f);
            h = findobj(h,'Tag','','Type','axes');
        end
        
        function h = createZoom(this, nr, area, tagextra, withlegend)
            if nargin < 5
                withlegend = false;
                if nargin < 4
                    tagextra = '';
                end
            end
            if ~isempty(tagextra)
                tagextra = ['_' tagextra];
            end
            if numel(area) == 2
                area = [reshape(area,1,2) NaN NaN];
            end
            
            if ~this.Single
                error('Zooming only possible for Single mode yet.');
            elseif isempty(nr) || ~isposintscalar(nr) || nr > length(this.Figures)
                error('nr must not be empty and within the range 1 to %d',length(this.Figures));
            end
            % Creates a new figure and returns the axes handle
            h = this.copyFigure(nr,[get(this.Figures(nr),'Tag') '_zoom' tagextra]);
            % Set to desired area
            useold = isnan(area);
            area(useold) = 0; % set NaNs to values (otherwise 0*NaN = NaN)
            oldarea = [get(h,'XLim') get(h,'YLim')];
            area = useold.*oldarea + (~useold).*area;
            axis(h, area);
            if ~withlegend
                delete(findobj(get(this.Figures(end),'Children'),'Tag','legend'));
            end
            % Check correct Y tickmarks
            this.checkTickMarks(h);
        end
        
        function done(this)
            % Finishes the current plotting process.
            %
            % Important to call afterwards as the last plot might not get
            % finished off (currently, only "axis tight" is invoked
            % automatically)
            this.finishCurrent;
            this.cnt = 0;
        end
        
        function savePlots(this, folder, varargin)
            % Saves all plots that have been created thus far to a given
            % folder with given format.
            %
            % Parameters:
            % folder: The folder to save the current plots to. @type char @default pwd
            % varargin: Different options for saving.
            % Format: A cell with different formats than given in the PlotManager.SaveFormats
            % property. @type cell<char> @default {'jpg'}
            % Close: Set to true to close all saved figures. @type logical
            % Selection: A vector of indices of current figures that should be saved. @type
            % rowvec<integer> @default Save all figures
            % SeparateLegends: A vector of indices of current figures that should be saved.
            % @type rowvec<logical> @default All legends stay in-plot
            % XArgs: Any extra arguments that should be passed to export_fig. @type cell<char>
            % @default {}
            
            ip = inputParser;
            ip.addParamValue('Format',this.SaveFormats,@(arg)(ischar(arg) || iscellstr(arg)) && ~isempty(arg));
            ip.addParamValue('Close',false,@islogical);
            ip.addParamValue('Selection',1:length(this.Figures),@isvector);
            ip.addParamValue('SeparateLegends',false,@(arg)islogical(arg) && isvector(arg));
            ip.addParamValue('XArgs',{},@iscellstr);
            if nargin < 2
                folder = pwd;
            end
            if exist(folder,'file') ~= 7
                mkdir(folder);
            end
            ip.parse(varargin{:});
            res = ip.Results;
            selection = res.Selection;
            separate_legends = res.SeparateLegends;
            if isscalar(separate_legends)
                separate_legends = repmat(separate_legends,1,length(selection));
            elseif ~all(size(selection) == size(separate_legends))
                error('If a separate legends parameter is passed, it must match the selection parameter size.');
            end
            format = res.Format;
            if ischar(format)
                format = {format};
            end
            
            % Make sure the last plot has been finished off before saving
            % it.
            this.finishCurrent;
            
            n = length(selection);
            fmtstr = format{1};
            if length(format) > 1
                fmtstr = [sprintf('%s, ',format{1:end-1}) format{end}];
            end
            fprintf('Saving %d current figures as "%s" in %s...', n, fmtstr, folder);
            for idx=1:n
                h = this.Figures(selection(idx));%#ok<*PROP>
                if ishandle(h)
                    fname = get(h,'Tag');
                    % check for empty tags here as people may have changed
                    % the tag some place else in between
                    if isempty(fname)
                        fname = sprintf('figure_%d',idx);
                    end
                    [oldtitles, oldfonts] = this.preSave(h);
                    % Separate legend saving
                    legends = [];
                    if separate_legends(idx)
                        legends = findobj(h,'tag','legend');
                        lfh = zeros(1,length(legends));
                        for lidx = 1:length(legends)
                            lfh(lidx) = figure('Visible','off','MenuBar','none');
                            newlh = copyobj(legends(lidx),lfh(lidx));
                            set(newlh,'Box','off');
                            set(legends(lidx),'Visible','off');
                        end
                        if isempty(legends)
                            warning('PlotManager:savePlots',...
                                'No legends found for Figure %d.',selection(idx));
                        end
                    end
                    
                    % Add prefix if set
                    if ~isempty(this.FilePrefix)
                        fname = [this.FilePrefix '_' fname];
                    end
                    this.saveFigure(h, fullfile(folder, fname), format, res.XArgs);
                    % Save extra legends (if given)
                    for lidx = 1:length(legends)
                        this.saveFigure(lfh(lidx), ...
                            fullfile(folder, sprintf('%s_legend%d',fname, lidx)),...
                            format, res.XArgs);
                    end
                    
                    % Move created images to own folders if wanted
                    if this.UseFileTypeFolders
                        for fmt = 1:length(format)
                            if exist(fullfile(folder,format{fmt}),'file') ~= 7
                                mkdir(fullfile(folder,format{fmt}));
                            end
                            fn = [fname '.' format{fmt}];
                            % Move to format-specific folder
                            movefile(fullfile(folder, fn), fullfile(folder,format{fmt},fn));
                            % Move extra legends (if given)
                            for lidx = 1:length(legends)
                                fn = sprintf('%s_legend%d.%s', fname, lidx, format{fmt});
                                movefile(fullfile(folder, fn), fullfile(folder,format{fmt},fn));
                            end
                        end
                    end
                        
                        
%                         % Quick fix: Repeat save process for JPG figures if desired
%                         if this.DoubleSaveJPG && strcmp(format{fmt},'jpg')
%                             % Save actual figure
%                             this.saveFigure(h, ...
%                                 fullfile(eff_folder, eff_name), ...
%                                 format{fmt});
%                             % Save extra legends (if given)
%                             for lidx = 1:length(legends)
%                                 this.saveFigure(lfh(lidx), ...
%                                     fullfile(eff_folder, ...
%                                         sprintf('%s_legend%d',eff_name,lidx)), ...
%                                         format{fmt});
%                             end
%                         end

                    % Restore visibility of perhaps hidden legends and close temporary figures
                    for lidx = 1:length(legends)
                        set(legends(lidx),'Visible','on');
                        close(lfh(lidx));
                    end
                    this.postSave(h, oldtitles, oldfonts);
                else
                    fprintf(2,'Warning: figure handle %d is invalid. Did you close it?',...
                        selection(idx));
                end
            end
            fprintf('done!\n');
            if res.Close
                this.closeAll(selection);
            end
        end
        
        function closeAll(this, selection)
            % Closes all currently openend plots and resets the Handles
            % property.
            if nargin < 2
                selection = 1:length(this.Figures);
            end
            for i=1:length(selection)
                h = this.Figures(selection(i));
                if ishandle(h) && strcmp(get(h,'Type'),'figure')
                    close(h);
                end
            end
            if ~isempty(this.curax) && ishandle(this.curax) && strcmp(get(this.curax,'Type'),'figure')
                close(this.curax);
                this.curax = [];
            end
            this.Figures(selection) = [];
            this.fignr = 0;
            this.cnt = 0;
        end
        
        function resetCount(this)
            % Resets the current axes handle count so that subsequent calls to "nextPlot" will
            % result re-returning the current subplot's axes
            this.finishCurrent;
            this.cnt = 0;
        end
        
        function delete(this)
            if ~this.LeaveOpen
                this.closeAll;
            end
        end
        
        function setFigureNames(this, name)
            for i=1:length(this.Figures)
                h = this.Figures(i);
                if ishandle(h) && strcmp(get(h,'Type'),'figure')
                    set(h,'Name',name);
                end
            end
        end
        
        function matchPlotAxes(~, ax_handles, varargin)
            ip = inputParser;
            ip.addParamValue('Axis','YLim',@(arg)(ischar(arg)) && any(strcmp(arg,{'XLim','YLim','ZLim'})));
            %ip.addParamValue('Selection',1:length(this.Figures),@isvector);
            ip.parse(varargin{:});
            res = ip.Results;
            lim = get(ax_handles(1),res.Axis);
            for k = 2:numel(ax_handles)
                tmp = get(ax_handles(k),res.Axis);
                lim(1) = min(lim(1),tmp(1));
                lim(2) = max(lim(2),tmp(2));
            end
            for k = 1:numel(ax_handles)
                set(ax_handles, res.Axis, lim);
            end
        end
    end
    
    %% Getter & Setter
    methods
        function set.SaveFormats(this, value)
            if ~iscellstr(value)
                if ischar(value)
                    value = {value};
                else
                    error('SaveFormats must be a cell of strings.');
                end
            end
            this.SaveFormats = value;
        end
        
        function set.ExportDPI(this, value)
            if ~isposintscalar(value)
                error('ExportDPI must be a positive integer.');
            end
            this.ExportDPI = value;
        end
        
%         function set.MinTickMarks(this, value)
%             if numel(value) ~= 3 || ~isnumeric(value) || any(value < 0)
%                 error('MinTickMarks must be a three element positive numeric vector for X,Y and Z tick marks.');
%             end
%             this.MinTickMarks = value;
%         end
    end
    
    methods(Access=private)
        
        function fh = nextFigure(this, numsubplots, varargin)
            if this.fignr+1 > this.MaxFigures
                this.fignr = 1;
                fh = figure(this.Figures(1));
            else
                this.fignr = this.fignr + 1;
                fh = figure(varargin{:});
                this.Figures(this.fignr) = fh;
            end
            this.cnt = numsubplots;
        end
        
        function finishCurrent(this)
            % Finishes processing of the current plot, e.g. sets the labels
            % and tight axis.
            if ~this.donelast
                h = this.curax;
                if ishandle(h)
                    % Set title and labels if given 
                    if ~isempty(this.ncap)
                        title(h,this.ncap);
                    end
                    if ~isempty(this.nxl)
                        xlabel(h, this.nxl);
                    end
                    if ~isempty(this.nyl)
                        ylabel(h, this.nyl);
                    end
                    if ~isempty(this.nleg)
                        legend(h, this.nleg{:});
                    end
                    % Make axis tight if no manual values have been set
                    if ~any(strcmp(get(h,{'XLimMode','YLimMode','ZLimMode'}),'manual'))
                        axis(h,'tight');
                    end
                    % Check correct Y tickmarks
                    this.checkTickMarks(h);
                end
                this.donelast = true;
            end
        end
        
        function checkTickMarks(this, h)
            if this.AutoTickMarks
                dims = {'X','Y'}; %,'Z'
                fields = {'Tick','Scale','TickLabel','Data','Lim'};
                valign = {'top', 'middle'};
                halign = {'center', 'right'};
                f = struct;
                codim = [2 1];
                for dim=1:length(dims)
                    for fidx = 1:length(fields)
                        f(dim).(fields{fidx}) = [dims{dim} fields{fidx}];
                    end
                    
                    if strcmp(get(h,f(dim).Scale),'log')
                        % Get current effective limits
                        [ymin, ymax] = getLimits(h, f(dim));
                        
                        if ~isempty(ymin) && ~isempty(ymax)
                            % Delete old labels
                            set(h,f(dim).TickLabel,{});

                            ylmi = ceil(log10(ymin));
                            ylma = floor(log10(ymax));
                            % Usually: plot log scale in steps of one
                            step = 1;
                            if ylma-ylmi < 3
                                % Too few ticks: Double them
                                step = .5;
                                ylmi = ylmi-step;
                                ylma = ylma+step;
                            elseif ylma-ylmi > 5
                                % Too many ticks: Halfen them
                                step = ceil((ylma-ylmi) / 4);
                            end
                            % Determine tick steps
                            expo = ylmi:step:ylma;
                            tick = 10.^(expo);

                            % Remove outliers
                            valid = tick >= ymin & tick <= ymax;
                            tick(~valid) = [];
                            expo(~valid) = [];

                            ticklbl = arrayfun(@(arg)sprintf('\\textbf{$10^{%g}$}',arg),expo,'UniformOutput',false);
                            colim = get(h,f(codim(dim)).Lim);
                            offset = 0.02;
                            text(ones(size(tick))*(colim(1)-offset*(colim(2)-colim(1))),...
                                tick,ticklbl,'VerticalAlignment',valign{dim},...
                                'HorizontalAlignment',halign{dim},'interpreter','LaTex');
                        end
                    end
                end
            end
            
            function [minlim, maxlim] = getLimits(h, f)
                minlim = Inf; maxlim = -Inf;
                lines = findobj(get(h,'Children'),'Type','line');
                for k=1:length(lines)
                    d = get(lines(k),f.Data);
                    minlim = min(minlim, min(d(d~=0 & isfinite(d))));
                    maxlim = max(maxlim, max(d(d~=0 & isfinite(d))));
                end
                lim = get(h,f.Lim);
                if lim(1) ~= 0 && isfinite(lim(1))
                    minlim = min(minlim, lim(1));
                end
                if lim(2) ~= 0 && isfinite(lim(2))
                    maxlim = max(maxlim, lim(2));
                end
            end
        end
        
        function [oldtitles, oldfonts] = preSave(this, fig)
            allax = findobj(get(fig,'Children'),'Type','axes');
            % Get title strings 
            oldtitles = {}; %#ok<*AGROW>
            childs = {'XLabel','YLabel','ZLabel'};
            if this.NoTitlesOnSave
                th = get(allax,'Title');
                if numel(th) == 1, th = {th}; end
                oldtitles = cellfun(@(th)get(th,'String'),th,...
                    'UniformOutput',false);
                cellfun(@(th)set(th,'String',[]),th);
            else
                childs = [childs 'Title'];
            end
            oldfonts = {};
            if ~isempty(this.SaveFont)
                for k = 1:length(allax)
                    ax = allax(k);
                    items = [ax cell2mat(get(ax,childs)) findobj(ax,'Type','text')'];
                    oldfonts{k} = get(items,fieldnames(this.SaveFont));
                    set(items,fieldnames(this.SaveFont),...
                        repmat(struct2cell(this.SaveFont)',numel(items),1));
                end
            end
        end
        
        function postSave(this, fig, oldtitles, oldfonts)
            allax = findobj(get(fig,'Children'),'Type','axes');
            % Restore title strings
            childs = {'XLabel','YLabel','ZLabel'};
            if this.NoTitlesOnSave
                th = get(allax,'Title');
                if numel(th) == 1, th = {th}; end
                for k=1:length(th)
                    set(th{k},'String',oldtitles{k});
                end
            else
                childs = [childs 'Title'];
            end
            if ~isempty(this.SaveFont)
                for k = 1:length(allax)
                    ax = allax(k); 
                    items = [ax cell2mat(get(ax,childs)) findobj(ax,'Type','text')'];
                    set(items,fieldnames(this.SaveFont),oldfonts{k});
                end
            end
        end
        
        function saveFigure(this, fig, rawfilename, extlist, xargs)
            % Supported formats: eps, jpg, fig, png, tif, pdf
            %
            % This is a scrap function from a differen class i didnt want
            % to include completely.
                        
            exts = {'fig','pdf','eps','jpg','png','tif','bmp'};
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            formats = cell2mat(cellfun(@(arg)strcmp(exts,arg)',extlist,...
                'UniformOutput',false));
            err = find(sum(formats)==0);
            if ~isempty(err)
                fprintf(2,'Invalid extension(s): %s\n',sprintf('%s ',extlist{err}));
                extlist(err) = [];
            end
            formats = sum(formats,2)';
            
            if ~isempty(rawfilename) && ~isempty(extlist)
                % check if directory exists and resolve relative paths (export_fig subfunctions
                % somehow tend to break)
                seppos = strfind(rawfilename,filesep);
                thedir = rawfilename(1:seppos(end)-1);
                thefile = rawfilename(seppos(end)+1:end);
                % Does not work if filename contains dots!
                %[thedir, thefile] = fileparts(rawfilename);
                
                % Special treatment for home directory, as the file name is wrapped into ""
                % inside export_fig's commands. this prevents ~ from being resolved and thus
                % the pdf/eps export fails.
                if isunix && thedir(1) == '~'
                    [~, homedir] = system('echo ~'); %contains a linebreak, too
                    thedir = [homedir(1:end-1) thedir(2:end)];
                end
                % Fix for mangled file paths
                jdir = java.io.File(thedir);
                thedir = char(jdir.getCanonicalPath);
                file = fullfile(thedir, thefile);
                figpos = strcmp(extlist,'fig');
                if any(figpos) % fig
                    saveas(fig, [file '.fig'], 'fig');
                    extlist(figpos) = [];
                end
                if ~isempty(extlist)
                    extlist = cellfun(@(e)sprintf('-%s',e),extlist,'UniformOutput',false);
                    args = {file, extlist{:}, sprintf('-r%d',this.ExportDPI)};
                    if this.ExportDPI > 100
                        args{end+1} = '-a2';
                    end
                    if any(formats & logical([0 1 1 0 1 0 0])) %pdf, eps, png
                        args{end+1} = '-transparent';
                    elseif any(formats & logical([0 1 1 1 0 0 0])) % jpg, eps, pdf
                        args{end+1} = ['-q' this.JPEGQuality];
                    end
                    args(end+1:end+length(xargs)) = xargs;
                    args{end+1} = fig;

                    if this.WhiteBackground
                        pos = get(fig, 'Position');
                        oldcol = get(fig, 'Color');
                        set(fig, 'Color', 'w', 'Position', pos);
                    end
                    
                    drawnow;
                    export_fig(args{:});
                    
                    if this.WhiteBackground
                        set(fig, 'Color', oldcol, 'Position', pos);
                    end
                end
            else
                fprintf(2,'No file specified. Aborting\n');
            end
        end
    end 
    
    methods(Static)
        function pm = demo_SinglePlots
            % Create a new PlotManager
            pm = PlotManager;
            pm.LeaveOpen = true;
            pm.FilePrefix = 'my_pm_single';
            
            % Here: Run your matlab script/code, do computations, etc
            % At some stage: Plotting is needed. Now call your plotting function/script with
            % the PlotManager argument. The big advantage of this is, that you can call your
            % plotting method with whatever setting to the PlotManager, so one time you have it
            % plotting to subplots (=development time) and the next you create single plots
            % with specific export settings (=publication/report time)
            
            % Inside your plotting method, create new axes using the nextPlot command.
            
            h = pm.nextPlot('plot1','Title of plot 1, look it has axes labels','xlabel','ylabel');
            % [.. do whatever plotting here using the axes handle h]
            PlotManager.doPlot(h);
            
            h = pm.nextPlot('plot2','Only title given');
            % [.. do whatever plotting here using the axes handle h]
            PlotManager.doPlot(h);
            
            % Finish off the current plot, which will add labels etc to it.
            pm.done;
        end
        
        function pm = demo_Subplots
            pm = PlotManager(false,2,2);
            pm.LeaveOpen = true;
            pm.FilePrefix = 'my_pm_subplots';
            % [.. your plot function called with argument pm ..]
            h = pm.nextPlot('tag_of_subplot1','Title of subplot 1','xlabel','ylabel');
            PlotManager.doPlot(h);
            h = pm.nextPlot('tag_of_subplot2','Only title given');
            PlotManager.doPlot(h);
            h = pm.nextPlot('tag_of_subplot3','title of subplot 3, no y label','xlabel',[],{'legend!'});
            PlotManager.doPlot(h);
            pm.done;
        end
        
        function pm = demo_SavePlots
            pm = PlotManager.demo_SinglePlots;
            pm.SaveFormats = {'jpg','png'};
            pm.UseFileTypeFolders = false;
            pm.savePlots(pwd);
            pm.FilePrefix = 'sameplots_withseparate_dir';
            pm.UseFileTypeFolders = true;
            % Disable saving of titles!
            pm.NoTitlesOnSave = true;
            pm.savePlots(pwd,'Close','true');
        end
        
        function pm = demo_SavePlots_Details
            % You can also override some settings or specify what should be saved
            pm = PlotManager.demo_SinglePlots;
            pm.UseFileTypeFolders = false;
            % Add extra legend plot
            h = pm.nextPlot('withlegend','Some plot with a legend!','x','y',{'line 1', 'line 2', 'line 3'});
            x = -10:10;
            plot(h,x,[cos(x).*sin(x); cos(x); cosh(x)]);
            
            % Save with specific format and separate legend
            pm.savePlots(pwd,'Format',{'png'},'SeparateLegends',[false false true]);
            
            % Save under different file type, only a couple, and close ONLY THEM afterwards.
            pm.savePlots(pwd,'Format',{'jpg'},'Selection',[1 3],'Close',true);
        end
        
        function pm = demo_Zoom
            pm = PlotManager.demo_SinglePlots;
            % Add extra legend plot
            h = pm.nextPlot('withlegend','Some plot with a legend!','x','y',{'line 1', 'line 2', 'line 3'});
            x = -10:.01:10;
            plot(h,x,[cos(x).*sin(x); cos(x); tanh(x)]);
            % The latest figure number is three (so far got to know which is which)
            pm.createZoom(3, [5 10], 'zoom');
            pm.createZoom(3, [-3 2], 'zoom_nolegend', false);
            pm.done;
        end
    end
    
    methods(Static, Access=private)
        function doPlot(h)
            % Creates some pretty random plots!
            r = RandStream('mt19937ar','Seed',round(cputime*1000));
            fr = r.rand;
            x = linspace(-r.rand*5,r.rand*5,100);
            if fr < .3
                f = @(x,y)sin(y.*x/(3*r.rand*pi));
            elseif fr < .6
                f = @(x,y)log10(2*cosh(abs(x-y)).^(sin(x/r.rand*3)));
            else
                f = @(x,y)[r.rand*cos(x).*sin(y); pi*sin(x)];
            end
            if fr < .6 && r.rand < .5
                [X,Y] = meshgrid(x);
                surf(h,X,Y,f(X,Y),'EdgeColor','None');
            else
                plot(h,x,f(x,x.^2));
            end
        end
    end
end