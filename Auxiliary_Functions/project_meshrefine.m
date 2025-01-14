function [mesh_refined, nodeIndicesWithinRegion] = project_meshrefine(mesh, centroid, radius, height, maxvol, shapeType)
% Refine the input mesh within a spherical or cylindrical region centered at centroid.
% 
% Input:
%   mesh: a struct with at least two fields "node" and "elem"
%   centroid: [x, y, z] coordinates of the center of the desired refined region (in length unit)
%   radius: radius of the spherical or cylindrical refined region (in length unit)
%   height: height of the cylindrical refined region (ignored if shapeType is 'sphere')
%   maxvol: maximum element volume for the refinement
%   shapeType: 'sphere' or 'cylinder' to choose the region type
%
% Output:
%   mesh_refined: a struct with refined "node" and "elem" lists
%   nodeIndicesWithinRegion: indices of nodes within the refined region


if nargin < 5
    error('You must provide at least five inputs: mesh, centroid, radius, height, and maxvol.');
end

if nargin < 6
    shapeType = 'sphere'; % Default to sphere
end

if ~isstruct(mesh) || ~isfield(mesh, 'node') || ~isfield(mesh, 'elem')
    error('The mesh input must be a struct with node and elem fields');
end

% Calculate centroids of elements
c0 = meshcentroid(mesh.node, mesh.elem);

% Initialize sizing field
sz = zeros(size(mesh.elem, 1), 1);

% Select region type using switch-case
switch lower(shapeType)
    case 'sphere'
        % Calculate distances from element centroids to the sphere center
        dist = sqrt(sum((c0 - centroid).^2, 2));
        % Set sizing field for elements within the spherical region
        sz(dist < radius) = maxvol;

    case 'cylinder'
        if nargin < 4
            error('Height is required for cylindrical refinement.');
        end
        % Calculate radial distances (in the XY-plane) and axial distances (along Z)
        dist_radial = sqrt((c0(:, 1) - centroid(1)).^2 + (c0(:, 2) - centroid(2)).^2);
        dist_axial = abs(c0(:, 3) - centroid(3));
        % Set sizing field for elements within the cylindrical region
        sz(dist_radial < radius & dist_axial < height / 2) = maxvol;

    otherwise
        error('Invalid shapeType. Use ''sphere'' or ''cylinder''.');
end

% Refine the mesh
[node_refine, elem_refine] = meshrefine(mesh.node, mesh.elem, sz);

% Recalculate centroids of the refined mesh
c0 = meshcentroid(node_refine, elem_refine);

% Determine the region again for refined elements
switch lower(shapeType)
    case 'sphere'
        dist = sqrt(sum((c0 - centroid).^2, 2));
        elementsWithinRegion = find(dist < radius);

    case 'cylinder'
        dist_radial = sqrt((c0(:, 1) - centroid(1)).^2 + (c0(:, 2) - centroid(2)).^2);
        dist_axial = abs(c0(:, 3) - centroid(3));
        elementsWithinRegion = find(dist_radial < radius & dist_axial < height / 2);
end

% Get node indices for the elements within the specified region
nodeIndicesWithinRegion = unique(elem_refine(elementsWithinRegion, :));

% Return the refined mesh
mesh_refined.node = node_refine;
mesh_refined.elem = elem_refine;
end