classdef BinTreeNode < handle
% BinTreeNode: 
%
% Attempt to write a tree for ModifiedNewton precomputation in offline phase. Unfortunately the
% lookup of the next bigger value is not as easy as thought in a tree, so work is postponed on this
% for now.
%
% @author Daniel Wirtz @date 2011-05-16
%
% @new{0,4,dw,2011-05-16} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.morepas.org/software/index.html
% - \c Documentation http://www.morepas.org/software/kermor/index.html
% - \c License @ref licensing
    
    properties
        Key = NaN;
        Value = NaN;
        left = [];
        right = [];
        height = 0;
    end
    
    methods        
        function this = BinTreeNode(key, value)
            if nargin == 2
                this.Key = key;
                this.Value = value;
            end
        end
        
        function set.left(this, value)
            if ~isempty(value) && ~isa(value,'BinTreeNode')
                error('Left property must be a BinTreeNode');
            end
            this.left = value;
        end
        
        function set.right(this, value)
            if ~isempty(value) && ~isa(value,'BinTreeNode')
                error('Right property must be a BinTreeNode');
            end
            this.right = value;
        end
    end
    
end