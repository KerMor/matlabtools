classdef RangeSplitter < handle
% RangeSplitter: 
%
% @docupdate
%
% @author Daniel Wirtz @date 2014-01-15
%
% @new{0,7,dw,2014-01-15} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing
    
    properties
        Total;
    end
    
    properties(Access=private)
        % Num Parts
        np;
        % Positions of the parts
        partpos = [];
    end
    
    methods
        function this = RangeSplitter(total, varargin)
            if isempty(total)
                error('Total range value must be specified.');
            end
            this.Total = total;
            ip = inputParser;
            ip.addParamValue('Max',[]);
            ip.addParamValue('Num',[]);
            ip.parse(varargin{:});
            res = ip.Results;
            if ~isempty(res.Max)
                pos = 0:res.Max:total;
                if (pos(end) < total)
                    pos = [pos total];
                end
                this.np = length(pos)-1;
                this.partpos = pos;
            elseif ~isempty(res.Num)
                if res.Num > total
                    error('Cannot have more parts than total elements');
                end
                this.np = res.Num;
                sizes = ones(1,this.np)*floor(total/res.Num);
                rest = mod(total,res.Num);
                if rest > 0
                    sizes(1:rest) = sizes(1:rest)+1;
                end
                this.partpos = [0 cumsum(sizes)];
            else
                error('You must specify either a maximum part size or the number of parts.');
            end
            
        end
        
        function np = getNumParts(this)
            np = this.np;
        end
        
        function pt = getPart(this, nr)
            if nr > this.np
                error('Only %d parts present.',this.np);
            end
            pt = this.partpos(nr)+1:this.partpos(nr+1);
        end
    end
    
    methods(Static)
        function res = test_RangeSplitter
            res = true;
            rs = RangeSplitter(1000,'Num',1);
            res = res && rs.getNumParts == 1;
            res = res && isequal(1:1000,rs.getPart(1));
            
            rs = RangeSplitter(1000,'Num',4);
            res = res && rs.getNumParts == 4;
            res = res && isequal(1:250,rs.getPart(1));
            res = res && isequal(751:1000,rs.getPart(4));
            
            rs = RangeSplitter(1001,'Max',250);
            res = res && rs.getNumParts == 5;
            res = res && isequal(1:250,rs.getPart(1));
            res = res && isequal(751:1000,rs.getPart(4));
            res = res && isequal(1001:1001,rs.getPart(5));
            
            rs = RangeSplitter(100,'Max',19);
            res = res && rs.getNumParts == 6;
            
            rs = RangeSplitter(100,'Max',20);
            res = res && rs.getNumParts == 5;
            
            rs = RangeSplitter(100,'Max',21);
            res = res && rs.getNumParts == 5;
            res = res && isequal(1:21,rs.getPart(1));
            res = res && isequal(22:42,rs.getPart(2));
            res = res && isequal(43:63,rs.getPart(3));
            res = res && isequal(64:84,rs.getPart(4));
            res = res && isequal(85:100,rs.getPart(5));
            
            rs = RangeSplitter(6,'Num',4);
            res = res && isequal(1:2,rs.getPart(1));
            res = res && isequal(3:4,rs.getPart(2));
            res = res && isequal(5,rs.getPart(3));
            res = res && isequal(6,rs.getPart(4));
            
            rs = RangeSplitter(9,'Num',4);
            res = res && isequal(1:3,rs.getPart(1));
            res = res && isequal(4:5,rs.getPart(2));
            res = res && isequal(6:7,rs.getPart(3));
            res = res && isequal(8:9,rs.getPart(4));
            
            try
                rs = RangeSplitter(10);%#ok
                res = false;
            catch ME%#ok
                res = res && true;
            end
            
            try
                rs = RangeSplitter(10,'Num',14);%#ok
                res = false;
            catch ME%#ok
                res = res && true;
            end
        end
    end
    
end