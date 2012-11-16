classdef BinTree < handle
% BinTree: A weighted binary tree.
%
% The BinTreeNode have a key and value property. The key values used only must
% implement the lt/gt/eq methods, so either be native data-types or objects. Strings cannot be used
% as indices for this data structure.
%
% @author Daniel Wirtz @date 2011-05-16
%
% @change{0,5,dw,2011-07-07} Bugfix in FindClosest: If the root key was already lower or bigger than
% all following nodes, an empty node instead of the root node was returned, leading to an error. Now
% the lower and upper closest nodes are always initialized to the root node.
%
% @new{0,4,dw,2011-05-16} Added this class.
%
% This class is part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
% - \c License @ref licensing
    
    properties(Access=private)
        root = [];
    end
    
    properties(Dependent)
        Height;
        Values;
    end
    
    methods        
        
        function h = get.Height(this)
            h = this.height(this.root);
        end
        
        function v = get.Values(this)
            v = this.getvalues(this.root);
        end
        
        function clear(this)
            if ~isempty(this.root)
                this.root.delete;
                this.root = [];
            end
        end
        
        function Insert(this, key, value)
            if nargin < 3
                value = key;
            end
            if numel(key) ~= numel(value)
                error('If key and value arguments are given they must have the same number of elements.');
            end
            if KerMor.App.Verbose > 2
                cnt = 0; cp = 0;
                m = numel(value);
                fprintf('Filling tree (%d values).. ',m); 
                for idx=1:m
                    this.root = this.insert(this.root, key(idx), value(idx));
                    p = round(idx*100/m);
                    if p >= cp
                       fprintf('%d%% ',p); 
                       cp = cp+10;
                    end
                end
                fprintf('\n'); 
            else
                for idx=1:numel(value)
                    this.root = this.insert(this.root, key(idx), value(idx));
                end
            end
        end
        
        function values = Find(this, keys)
%             if numel(keys) > 1
%                 values = this.findMulti(repmat(this.root,1,length(keys)), keys);
%             else
                values = this.find(this.root, keys);
%             end
        end
        
        function [l, u] = FindClosest(this, keys)
            n = numel(keys);
            if n == 1
                [l, u] = this.findclosest(this.root, keys);
            elseif n < 15
                l = zeros(1:n);
                u = zeros(1:n);
                for idx=1:n
                    [l(idx), u(idx)] = this.findclosest(this.root, keys(idx));
                end
            else
                [l, u] = this.findclosestmulti(repmat(this.root,1,length(keys)), keys);
            end
        end
        
        function display(this)
            this.printTree(this.root,0);
        end
    end
        
    methods(Access=private)
        
        function value = find(this, n, key)%#ok (not needed as nonrecursive)
            % Performs an in-place search for the value associated with the given key.
            value = [];
            while ~isempty(n)
                if lt(key,n.Key)
                    n = n.left;
                elseif gt(key,n.Key)
                    n = n.right;
                else
                    value = n.Value;
                    return;
                end
            end
        end
        
        function [l,u] = findclosest(this, n, key)%#ok (not needed as nonrecursive)
            % Performs an in-place search for the value associated with the given key.
            u = []; l = [];
%             minu = [];
%             maxl = [];
            % Initialize with this node n, as it might be the smallest/largest
            minu = n;
            maxl = n;
            while ~isempty(n)
                if lt(key,n.Key)
                    minu = n;
                    n = n.left;
                elseif gt(key,n.Key)
                    maxl = n;
                    n = n.right;
                else
                    l = n.Value;
                    u = l;
                    return;
                end
            end
            if ~isempty(minu)
               u = minu.Value;
            end
            if ~isempty(maxl)
               l = maxl.Value;
            end
        end
        
        function [l,u] = findclosestmulti(this, n, keys)%#ok (not needed as nonrecursive)
            % Performs an in-place search for the value associated with the given key.
            u = inf(size(keys));
            l = -u;
            minu = BinTreeNode.empty(0,1);
            maxl = minu;
            while true
                lempt = cellfun('isempty',{n.left});
                rempt = cellfun('isempty',{n.right});

                low = lt(keys,[n.Key]);
                gre = gt(keys,[n.Key]);
                
                minu(low) = n(low);
                maxl(gre) = n(gre);
                
                golow = low & ~lempt;
                if any(golow)
                    n(golow) = [n(golow).left];
                end
                goup = gre & ~rempt;
                if any(goup)
                    n(goup) = [n(goup).right];
                end
                eq = ~low & ~gre;
                if any(eq)
                    u(eq) = [n(eq).Value];
                    l(eq) = [n(eq).Value];
                end
                if all(~golow & ~goup)
                    break;
                end
            end
            hasu = ~isnan([minu.Key]);
            u(hasu) = [minu(hasu).Value];
            hasl = ~isnan([maxl.Key]);
            l(hasl) = [maxl(hasl).Value];
        end
        
        function v = getvalues(this, n)
            v = [];
            if ~isempty(n)
                v = [this.getvalues(n.left) n.Value this.getvalues(n.right)];
            end
        end
        
%         function values = findMulti(this, n, keys)%#ok (not needed as nonrecursive)
%             % Performs an in-place search for the value associated with the given key.
%             values = nan(size(keys));
%             while ~isempty(n)
%                 low = lt(keys,[n(:).Key]);
%                 if any(low)
%                     n(low) = n(low).left;
%                 end
%                 gre = gt(keys,[n(:).Key]);
%                 if any(gre)
%                     n(gre) = n(gre).right;
%                 end
%                 eq = ~low & ~gre;
%                 if any(eq)
%                     values(eq) = [n(eq).Value];
%                 end
%                 if all(eq)
%                     return
%                 end
%             end
%         end
        
        function n = insert(this, n, key, value)
            if isempty(n)
                n = BinTreeNode(key, value);
            elseif lt(key,n.Key)
                n.left = this.insert(n.left, key, value);
                if n.left.height - this.height(n.right)== 2
                    if lt(key, n.left.Key)
                        n = this.rotateWithLeftChild(n);
                    else
                        n = this.doubleWithLeftChild(n);
                    end
                end
            elseif gt(key, n.Key)
                n.right = this.insert(n.right, key, value);
                if  n.right.height - this.height(n.left) == 2
                    if gt(key, n.right.Key)
                        n = this.rotateWithRightChild(n);
                    else
                        n = this.doubleWithRightChild(n);
                    end
                end
            else
                error('Duplicate entry!');
            end
            n.height = max(this.height(n.left), this.height(n.right)) + 1;
        end
        
        function h = height(this, n)%#ok
            if isempty(n)
                h = -1;
            else
                h = n.height;
            end
        end
        
        function n = rotateWithLeftChild(this, n2)
            n = n2.left;
            n2.left = n.right;
            n.right = n2;
            n2.height = max(this.height(n2.left), this.height(n2.right)) + 1;
            n.height = max(this.height(n.left), n2.height) + 1;
        end

        function n = rotateWithRightChild(this, n2)
            n = n2.right;
            n2.right = n.left;
            n.left = n2;
            n2.height = max(this.height(n2.left), this.height(n2.right)) + 1;
            n.height = max(this.height(n.right), n2.height ) + 1;
        end

        function n = doubleWithLeftChild(this, n)
            n.left = this.rotateWithRightChild(n.left);
            n = this.rotateWithLeftChild(n);
        end

        function n = doubleWithRightChild(this, n)
            n.right = this.rotateWithLeftChild(n.right);
            n = this.rotateWithRightChild(n);
        end
        
        function printTree(this, n, ntabs)
            if ~isempty(n)
                this.printTree(n.left,ntabs+1);
                fprintf([repmat('\t',1,ntabs) '%f => %f\n'], n.Key, n.Value);
                this.printTree(n.right,ntabs+1);
            end
        end
    end
    
    methods(Static)
        function res = test_BinTree
            res = true;
            
            %% Init
            t = BinTree;
            n = 2^4;
            
            %% Test usage as Key-Value BinaryTree
            k = randperm(n);
            v = randperm(n);
            t.Insert(k,v);
            
            % Find all values for keys
            for idx = 1:length(k)
                res = res && v(idx) == t.Find(k(idx));
            end
            % Test nonexistent key
            res = res && isempty(t.Find(2*n));
            
            % Test multi-find
%             vs = t.Find([k n+1]);
%             res = res && all(v == vs(1:end-1)) && isnan(vs(end));
            
            %% Test usage as simple BinaryTree
            t.clear;
            v = randperm(n);
            t.Insert(v);
            
            % Check for correct ordering
            res = res && all(sort(v) == t.Values);
            
            % Find all values
            for value=v
                res = res && ~isempty(t.Find(value));
            end
            
            % Height check
            h = t.Height;
            hlp = n / (2^(h+1));
            res = res && hlp <= 1;
            
            % Closeness check - select some random positions and check
            ex = randperm(n-1)+1;
            ex = ex(1:round(n/2));
            ks = sort(k);
            for i=1:length(ex)
                ru = ks(ex(i));
                rl = ru-1;
                [l,u] = t.FindClosest((rl+ru)/2);
                res = res && l == rl && u == ru;
            end
            
            M = [2, 10, 100, 1000, 10000];
            R = [100, 60, 40, 20, 10]; 
            for j = 1:length(R)
                m = M(j);
                r = R(j);
                k = linspace(0,n+1,m);
                tmp = tic;
                for idx = 1:length(k)
                    [l,u] = t.FindClosest(k(idx)); %#ok<*NASGU>
                end
                ti(1,j) = toc(tmp); %#ok<*AGROW>

                tmp = tic;
                [l,u] = t.FindClosest(k);
                ti(2,j) = toc(tmp);
                ti = sum(ti,2)/r;
                fprintf('Speed test of multi-find-closest of %d values (averaged over %d runs): %fs loop to %fs multi (factor %f faster).\n',m,r,ti(1),ti(2),ti(1)/ti(2));
            end
                
            fprintf('BinTree test finished with n=%d, h=%d, n/2^(h+1)=%f <! 1\n',n,h,hlp);
        end
    end
end