function [mesh_refined, nodeIndicesWithinRadius] = project_meshrefine(mesh,centroid,radius,maxvol)
%
% Based on DigiBreast Meshrefine function
%
% Refine the input mesh within a spherical region centered at centroid.
%
% Original Authors: Bin Deng (bdeng1 <at> nmr.mgh.harvard.edu)
%                   Qianqian Fang (fangq <at> nmr.mgh.harvard.edu)
%
% input:
%   mesh: a struct with at least two fields "node" and "elem"
%         mesh.node: existing tetrahedral mesh node list (N x 3 array, in length unit)
%         mesh.elem: existing tetrahedral element list (M x 4 array)
%         mesh.value: (optional) value list, one node can associate with K values (N x K array, K>=1)
%   centroid: [x,y,z] coordinates of the center of desired refine region (in length unit)
%   radius: radius of the sperical refined mesh region (in length unit)
%   maxvol: maximum element volume
%           For the DigiBreast phantom, the applied value is 0.1 (mm^3) for
%           forward mesh and 1 (mm^3) for reconstruction mesh.
%
% output:
%    mesh_refined: a struct with two fields containing the refined "node" (in length unit) and "elem" lists
%                  if the optional field "value" is defined in the input,
%                  then mesh_refined will also have the cooresponding field "value".                      
%
% dependency:
%    this function requires "meshrefine" and "meshcentroid" from iso2mesh toolbox.


if(nargin<2)
    error('you must provide at least two inputs - mesh and centroid');
end

if(nargin<3)
    radius=10;
end

if(nargin<4)
    maxvol=0.1;
end

if(~isstruct(mesh) || ~isfield(mesh,'node') || ~isfield(mesh,'elem'))
    error('the mesh input must be a struct with node and elem fields')
end

% look for all tetrahedral elements whos centers are within the radius from the centroid
% set the desired maximum volume to a maxvol for those elements
% Calculate the centroid of each element

c0 = meshcentroid(mesh.node, mesh.elem(:,1:4));

% Calculate distance from each element's centroid to the given centroid
dist = c0 - repmat(centroid, [size(mesh.elem,1), 1]);
dist = sqrt(sum(dist.*dist, 2));

% Initialize sizing field
sz = zeros(size(mesh.elem,1), 1); % sizing field
% Set sizing field for elements within specified radius
sz(dist < radius) = maxvol;

% refine the mesh
[node_refine,elem_refine]=meshrefine(mesh.node,mesh.elem,sz);

c0 = meshcentroid(node_refine, elem_refine(:,1:4));

% Calculate distance from each element's centroid to the given centroid
dist = c0 - repmat(centroid, [size(elem_refine,1), 1]);
dist = sqrt(sum(dist.*dist, 2));

% Find elements within the specified radius
elementsWithinRadius = find(dist < radius);

% Get node indices for these elements
nodeIndicesWithinRadius = unique(elem_refine(elementsWithinRadius, 1:4));

mesh_refined.node=node_refine;
mesh_refined.elem=elem_refine;

if(isfield(mesh,'value'))
    if(size(mesh.value,1)~=size(mesh.node,1))
        error('the value list must match the rows of the node list');
    end
    isoriginal=ismember(round(mesh_refined.node*1e10)*1e-10,round(mesh.node*1e10)*1e-10,'rows');
    newnodeidx=find(isoriginal==0); % find newly inserted nodes
    if(length(newnodeidx))
        [eid,weight]=tsearchn(mesh.node,mesh.elem,mesh_refined.node(newnodeidx,:));
    end
    mesh_refined.value=zeros(size(mesh_refined.node,1),size(mesh.value,2));
    mesh_refined.value(find(isoriginal==1),:)=mesh.value;
    for i=1:size(mesh.value,2)
        mesh_refined.value(newnodeidx,i)=sum(reshape(mesh.value(mesh.elem(eid,:),i),size(weight,1),size(weight,2)).*weight,2);
    end
end
