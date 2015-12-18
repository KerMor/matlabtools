classdef LineSpecIterator < handle
% LinSpecIterator: Small helper class to automatically iterate through different line
% styles/markers/colors
%
% @author Daniel Wirtz @date 2012-06-08
%
% @new{0,6,dw,2012-07-26} Can now also iterate through colors with the option of excluding
% some.
%
% @new{0,6,dw,2012-06-08} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing

    properties
        MarkerStyles = {'s','d','o','*','p','x','+','^','v','<','>','.','h'};
        
        LineStyles = {'-',':','-.','--'};
        
        Colors = [  0       0       1.0000;
                    0       0.5000  0;
                    1.0000  0       0;
                    0       0.7500  0.7500;
                    0.7500  0       0.7500;
                    0.7500  0.7500  0;
                    0.2500  0.2500  0.2500;
                    0   1   0;
                    .75 .75 .75;
                    .9  .6  0;
                    .2  1  .2;
                    .5  .5  1]; % start of custom colors
        
        ShortColors = {'r','g','b','c','m','y','k'};
    end
    
    properties(Access=private)
        curl = 0;
        curm = 0;
        curc = 0;
        cursc = 0;
        excluded_cols = [];
    end
    
    methods
        function this = LineSpecIterator(ncolors, seed)
            predef = [  0       0       1.0000;
                        0       0.5000  0;
                        1.0000  0       0;
                        0       0.7500  0.7500;
                        0.7500  0       0.7500;
                        0.7500  0.7500  0;
                        0.2500  0.2500  0.2500];
            if nargin < 2
                seed = round(100*cputime);
                if nargin < 1
                    ncolors = size(predef,1);
                end
            end
            maxintensity = .7;
            np = size(predef,1);
            if ncolors > np
                num = ncolors - np;
                colors = zeros(ncolors,3);
                colors(1:np,:) = predef;
                r = RandStream('mt19937ar','Seed',seed);
                mindiff = .3;
                for n=1:num
                    color = r.rand(1,3)*maxintensity;
                    cnt = 1;
                    while any(sum(abs(repmat(color,np+n-1,1)-colors(1:np+n-1,:)),2) < mindiff)
                        color = r.rand(1,3)*maxintensity;
                        cnt = cnt+1;
                        if cnt > 1000
                            mindiff = mindiff*.8;
                            fprintf('LinSpecIterator: Couldn''t find any new sufficiently distant color. Choosing new mindiff=%g\n',mindiff);
                            cnt = 1;
                        end
                    end
                    colors(np+n,:) = color;
                end
                this.Colors = colors;
            else
                this.Colors = predef(1:ncolors,:);
            end
        end
        
        function markerstyle = nextMarkerStyle(this)
            markerstyle = this.MarkerStyles{this.curm+1};
            this.curm = mod(this.curm+1,length(this.MarkerStyles));
        end
        
        function linestyle = nextLineStyle(this)
            linestyle = this.LineStyles{this.curl+1};
            this.curl = mod(this.curl+1,length(this.LineStyles));
        end
        
        function ls = nextColorLineStyle(this)
            ls = [this.ShortColors{this.cursc+1} this.nextLineStyle];
            this.cursc = mod(this.cursc+1,length(this.ShortColors));
        end
        
        function ls = nextColorMarkerStyle(this)
            ls = [this.ShortColors{this.cursc+1} this.nextMarkerStyle];
            this.cursc = mod(this.cursc+1,length(this.ShortColors));
        end
        
        function c = nextShortColor(this, linestyle)
            if nargin < 2
                linestyle = '-';
            end
            c = [this.ShortColors{this.cursc+1} linestyle];
            this.cursc = mod(this.cursc+1,length(this.ShortColors));
        end
        
        function color = nextColor(this)
            color = this.Colors(this.curc+1,:);
            this.curc = mod(this.curc+1,size(this.Colors,1));
            if ~isempty(this.excluded_cols)
                cnt = 1;
                while any(sum(abs(repmat(color,size(this.excluded_cols,1),1)-this.excluded_cols),2) < .3)
                    % Pick next one
                    color = this.Colors(this.curc+1,:);
                    this.curc = mod(this.curc+1,size(this.Colors,1));

                    cnt = cnt+1;
                    if cnt == size(this.Colors,1)
                        warning('KerMor:LineSpecInterator',...
                            'Out of pre-defined colors (all excluded). Using random color.');
                        color = rand(1,3);
                        this.Colors = [this.Colors; color];
                        break;
                    end
                end
            end
            %fprintf('New color: [%g %g %g]\n',color);
        end
        
        function excludeColor(this, data)
            if size(data,2) == 3
                color = data;
            elseif ishandle(data)
                color = [];
                for i=1:length(data)
                    color = [color; get(data(i),'Color')];%#ok
                end
            end
            this.excluded_cols = [this.excluded_cols; color];
        end
    end
    
end