classdef PlotManager < handle
% PlotManager: Small class that allows the same plots generated by some
% script to be either organized as subplots or single figures.
%
% This class needs a working 'export_fig' tool that is available at
% http://www.mathworks.com/matlabcentral/fileexchange/23629
%
% Any openend figure using nextPlot can be exported to a directory using a
% specified format (any allowed by export_fig).
%
% Examples:
% % Run with subplots:
% pm = PlotManager(false,2,1);
% pm.FilePrefix = 'my_pm';
% % [.. your plot function called with argument pm ..]
% pm.nextPlot('fig_in_subplot1','Title of subplot 1','xlabel','ylabel',{'sin','cos'});
% plot(1:10,[sin(1:10); cos(1:10)]');
% pm.nextPlot('fig_in_subplot2','Only title given');
% plot(-10:10,cos(pi*(-10:10)));
% pm.nextPlot('fig_in_new_subplot1','Yeay! a new figure has popped up.');
% plot(-10:10,exp((-10:10) / 5));
% pm.done;
% pm.savePlots('.','fig');
% pm.savePlots('.','png',true);
%
% % Run with single figures:
% % Run with subplots:
% pm = PlotManager;
% pm.FilePrefix = 'my_pm_single';
% % [.. your plot function called with argument pm ..]
% pm.nextPlot('fig_in_subplot1','Title of subplot 1','xlabel','ylabel');
% plot(1:10,sin(1:10));
% pm.nextPlot('fig_in_subplot2','Only title given');
% plot(-10:10,cos(pi*(-10:10)));
% pm.nextPlot('fig_in_new_subplot1','Yeay! a new figure has popped up.');
% plot(-10:10,exp((-10:10) / 5));
% pm.done;
% pm.savePlots('.','fig');
% pm.savePlots('.','png',true);
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
        
        % The figure size for each newly created figure when on single
        % mode.
        %
        % Is a two dimensional row vector with width and height
        %
        % @type rowvec<double> @default [600 480]
        SingleSize = [800 600];
        
        % A prefix that has to be put before each file name for exported
        % plots.
        %
        % @type char @default ''
        FilePrefix = '';
        
        % DPI used for export. See export_fig settings.
        %
        % @type char @default '150'
        ExportDPI = '150';
        
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
        
        % An integer number to enforce a minimum number of tickmarks on the y axis.
        % 
        % When a plot is finished (i.e. nextPlot or done is called), it is checked if enough
        % tickmarks are present. If not, the given number of tickmarks is inserted, according
        % to the current YLim and YScale property.
        % Set to [] to let MatLab control how many tickmarks are used.
        %
        % [x,y axis not needed yet]
        %
        % @type integer @default []
        MinYTickMarks = [];
        
        % For some reason on unix machines export_fig sometimes uses the last image saved to
        % as the next one.
        %
        % As a workaround, images to be stored as jpg are saved twice in a row to avoid that.
        %
        % @type logical @default true
        DoubleSaveJPG = true;
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
            this.Figures = [];
            s = get(0,'MonitorPositions');
            this.ss = s(1,3:4);
        end
        
        function ax_handle = nextPlot(this, tag, caption, xlab, ylab, leg_str, numsubplots)
            % Creates a new axis to plot in. Depending on the property
            % tools.PlotMananger.Single this will either advance to the
            % next subplot or open up a new figure window of size
            % SingleSize in the center of the main screen.
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
            
            if this.Single
                this.Figures(end+1) = figure('Position',[(this.ss - this.SingleSize)/2 this.SingleSize],'Tag',tag);
                ax_handle = gca;
            else
                if nargin < 7
                    numsubplots = 1;
                end
                this.cnt = this.cnt + numsubplots;
                if isempty(this.Figures) || this.cnt > this.rows*this.cols
                    this.Figures(end+1) = figure('Tag',tag);
                    this.cnt = numsubplots;
                else
                    if gcf ~= this.Figures(end)
                        figure(this.curax);
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
            
            ip = inputParser;
            ip.addParamValue('Format',this.SaveFormats,@(arg)(ischar(arg) || iscellstr(arg)) && ~isempty(arg));
            ip.addParamValue('Close',false,@islogical);
            ip.addParamValue('Selection',1:length(this.Figures),@isvector);
            ip.addParamValue('SeparateLegends',false,@(arg)islogical(arg) && isvector(arg));
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
            fprintf('Saving %d current figures as "%s"...', n, fmtstr);
            eff_folder = folder;
            fmts = length(format);
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
                    % Save with all formats
                    for fmt = 1:fmts
                        % Add format-named folder if enabled
                        if this.UseFileTypeFolders
                            eff_folder = fullfile(folder,format{fmt});
                        end
                        % Save actual figure
                        this.saveFigure(h, ...
                            fullfile(eff_folder, [this.FilePrefix '_' fname]), ...
                            format{fmt});
                        % Save extra legends (if given)
                        for lidx = 1:length(legends)
                            this.saveFigure(lfh(lidx), ...
                                fullfile(eff_folder, ...
                                    sprintf('%s_%s_legend%d',this.FilePrefix,fname,lidx)), ...
                                    format{fmt});
                        end
                        % Quick fix: Repeat save process for JPG figures if desired
                        if this.DoubleSaveJPG && strcmp(format{fmt},'jpg')
                            % Save actual figure
                            this.saveFigure(h, ...
                                fullfile(eff_folder, [this.FilePrefix '_' fname]), ...
                                format{fmt});
                            % Save extra legends (if given)
                            for lidx = 1:length(legends)
                                this.saveFigure(lfh(lidx), ...
                                    fullfile(eff_folder, ...
                                        sprintf('%s_%s_legend%d',this.FilePrefix,fname,lidx)), ...
                                        format{fmt});
                            end
                        end
                    end
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
    end
    
    %% Getter & Setter
    methods
        function set.SaveFormats(this, value)
            if ~iscellstr(value)
                error('SaveFormats must be a cell of strings.');
            end
            this.SaveFormats = value;
        end
    end
    
    methods(Access=private)
        
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
            if ~isempty(this.MinYTickMarks) && length(get(h,'YTick')) < this.MinYTickMarks
                lim = get(h,'YLim');
                if strcmp(get(h,'YScale'),'linear')
                    sfun = @linspace;
                    fmt = '%2.2g';
                else
                    sfun = @logspace;
                    lim = log10(lim);
                    fmt = '%1.1e';
                end
                % Move the labels 5% into the plot range interior
                range = lim(2)-lim(1);
                lim(1) = lim(1) + .05*range;
                lim(2) = lim(2) - .05*range;
                newticks = sfun(lim(1),lim(2),this.MinYTickMarks);
                lbl = arrayfun(@(e)sprintf(fmt,e),newticks,'Unif',false);
                set(h,'YTick',newticks,'YTickLabel',lbl);
            end
        end
        
        function [oldtitles, oldfonts] = preSave(this, fig)
            ax = findobj(get(fig,'Children'),'Type','axes');
            % Get title strings
            oldtitles = [];
            childs = {'XLabel','YLabel','ZLabel'};
            if this.NoTitlesOnSave
                th = get(ax,'Title');
                if numel(th) == 1, th = {th}; end
                oldtitles = cellfun(@(th)get(th,'String'),th,...
                    'UniformOutput',false);
                cellfun(@(th)set(th,'String',[]),th);
            else
                childs = [childs 'Title'];
            end
            if ~isempty(this.SaveFont)
                items = [ax cell2mat(get(ax,childs))];
                oldfonts = get(items,fieldnames(this.SaveFont));
                set(items,fieldnames(this.SaveFont),...
                    repmat(struct2cell(this.SaveFont)',numel(items),1));
%                 this.ensureLegendColumns(fig);
            end
        end
        
        function postSave(this, fig, oldtitles, oldfonts)
            ax = findobj(get(fig,'Children'),'Type','axes');
            % Restore title strings
            childs = {'XLabel','YLabel','ZLabel'};
            if this.NoTitlesOnSave
                th = get(findobj(get(fig,'Children'),...
                    'Type','axes'),'Title');
                if numel(th) == 1, th = {th}; end
                for k=1:length(th)
                    set(th{k},'String',oldtitles{k});
                end
            else
                childs = [childs 'Title'];
            end
            if ~isempty(this.SaveFont)
                items = [ax cell2mat(get(ax,childs))];
                set(items,fieldnames(this.SaveFont),oldfonts);
%                 this.ensureLegendColumns(fig);
            end
        end
        
        function saveFigure(this, fig, filename, ext)
            % Supported formats: eps, jpg, fig, png, tif, pdf
            %
            % This is a scrap function from a differen class i didnt want
            % to include completely.
                        
            exts = {'fig','pdf','eps','jpg','png','tif'};
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            extidx = find(strcmp(ext,exts),1);
            if isempty(extidx)
                warning('ohno:invalidExtension','Invalid extension: %s, using eps',ext);
                extidx = 3;
            end
            
            if ~isempty(filename)
                % check if directory exists and resolve relative paths (export_fig subfunctions
                % somehow tend to break)
                [thedir, thefile] = fileparts(filename);
                if exist(thedir,'dir') ~= 7
                    mkdir(thedir);
                end
                % Special treatment for home directory, as the file name is wrapped into ""
                % inside export_fig's commands. this prevents ~ from being resolved and thus
                % the pdf/eps export fails.
                if isunix && thedir(1) == '~'
                    [~, homedir] = system('echo ~'); %contains a linebreak, too
                    thedir = [homedir(1:end-1) thedir(2:end)];
                end
                jdir = java.io.File(thedir);
                thedir = char(jdir.getCanonicalPath);
                file = [fullfile(thedir, thefile) '.' exts{extidx}];
                if extidx == 1 % fig
                    saveas(fig, file, 'fig');
                else
                    args = {file, ['-' exts{extidx}],['-r' this.ExportDPI]};
                    if any(extidx == [2 3]) %pdf, eps
                        %args{end+1} = '-painters';
                        args{end+1} = '-transparent';
                    elseif extidx == 4 % jpg
                        args{end+1} = ['-q' this.JPEGQuality];
                        %args{end+1} = '-opengl';
                    elseif extidx == 5 % png
                        args{end+1} = '-transparent';
                    end

                    args{end+1} = fig;

                    % export_fig ignores -transparent somehow on my machine..
                    c = get(fig,'Color');
                    set(fig,'Color','white');

                    export_fig(args{:});

                    set(fig,'Color',c);
                end
            else
                fprintf(2,'No file specified. Aborting\n');
            end
        end
    end 
end