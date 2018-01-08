classdef FUMOT < handle
% Fluoresecence Ultrasound Modulated Optical Tomography
    
    properties (Access = public)
        cache
        measurement
        source
        load
        parameter
        model
        reg
    end
    
    methods
        function obj = FUMOT(opt)
            assert(isfield(opt, 'femm_opt'));
            
            obj.cache = struct('s',[], 'm', [], 'n', [], 'dof', [], 'ndof',[],...
                'sx', [], 'mx', [], 'sm', [], 'mm', []); % cached variables
            obj.parameter = struct('dX', [], 'aX', [], 'dM', [], 'aM', [], 'aF', [], 'eta', []);
            obj.source = struct('ex',[], 'em',[]); % emission source for auxillary function use
            obj.load = struct('ex', [], 'em',[]); 
            
            obj.model = femm(opt.femm_opt);
            
            obj.cache.s = obj.model.build('s', 1);
            obj.cache.m = obj.model.build('m', 1);
            
            obj.cache.n = size(obj.model.space.nodes, 2);
            obj.cache.ndof = unique(obj.model.space.edges);
            obj.cache.dof = setdiff(1:obj.cache.n, obj.cache.ndof);
            
            obj.reg = opt.reg;
            
            obj.parameter.dX = diffusionFX(obj.model.space.nodes)';
            obj.parameter.dM = diffusionFM(obj.model.space.nodes)';
            obj.parameter.aX = absorptionFX(obj.model.space.nodes)';
            obj.parameter.aM = absorptionFM(obj.model.space.nodes)';
            
            qdX = obj.mapping(obj.parameter.dX, obj.model.space.elems, obj.model.facet.ref');
            qdM = obj.mapping(obj.parameter.dM, obj.model.space.elems, obj.model.facet.ref');
            qaX = obj.mapping(obj.parameter.aX, obj.model.space.elems, obj.model.facet.ref');
            qaM = obj.mapping(obj.parameter.aM, obj.model.space.elems, obj.model.facet.ref');
            
            obj.cache.sx = obj.model.build('s', qdX);
            obj.cache.sm = obj.model.build('s', qdM);
            obj.cache.mx = obj.model.build('m', qaX);
            obj.cache.mm = obj.model.build('m', qaM);
           
            obj.parameter.aF = absorptionFF(obj.model.space.nodes)'; % to be recovered.
            obj.parameter.eta = quantumF(obj.model.space.nodes)'; % to be recovered.
            
            obj.source.ex = ex_source(obj.model.space.nodes); % full information
            obj.source.em = em_source(obj.model.space.nodes); % full information
            
            obj.load.ex = zeros(obj.cache.n, 1); % init
            obj.load.em = zeros(obj.cache.n, 1); % init
            
            obj.load.ex(obj.cache.ndof) = obj.source.ex(obj.cache.ndof); % boundary
            obj.load.em(obj.cache.ndof) = obj.source.em(obj.cache.ndof); % boundary
            
        end
        
        function [ m ] = forward_ex(obj, p, noise)
            if nargin == 2
                noise = 0;
            end
            
            qaF = obj.mapping(p.aF,  obj.model.space.elems, obj.model.facet.ref');
%             qeta= obj.mapping(p.eta, obj.model.space.elems, obj.model.facet.ref');
            
            A = obj.cache.sx + obj.cache.mx + obj.model.build('m', qaF);
            % requires a gradient solver here. todo
            
        end
    end
    
    methods(Static)
        function [interpolate] = mapping(func, elems, trans_ref)
            numberofqnodes = size(trans_ref, 1);
            interpolate = zeros(numberofqnodes, size(elems, 2));
            for i = 1: size(elems, 2)
                interpolate(:, i) = trans_ref * func(elems(:, i));
            end
        end
        function r = normsq(v)
            r = sum(v.^2);
        end

end
    
end
