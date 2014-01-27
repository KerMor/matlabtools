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
        % Max part size
        ms;
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
                this.np = ceil(total / res.Max);
                this.ms = res.Max;
            elseif ~isempty(res.Num)
                this.np = res.Num;
                this.ms = ceil(total/res.Num);
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
            pt = ((nr-1)*this.ms+1):min((nr*this.ms),this.Total);
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
            
            try
                rs = RangeSplitter(10);%#ok
                res = false;
            catch ME%#ok
                res = res && true;
            end
        end
    end
    
end