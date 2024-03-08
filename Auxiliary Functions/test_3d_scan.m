clear all
close all

fullpath = mfilename('fullpath');
[AuxiliaryDirectory, ~, ~] = fileparts(fullpath);
[ProjectFolderPath, ~, ~] = fileparts(AuxiliaryDirectory);
mesh = open(fullfile(ProjectFolderPath,'Auxiliary Variables\Base_Mesh_struct.mat'));
randRowIndex = randi(size(mesh.ForwardMesh.node, 1)); % Generate a random row index
centroid = mesh.ForwardMesh.node(randRowIndex, :); % Select the random row
radius = randi([8,15]);
[mesh_refined, tumor_nodes_idx] = project_meshrefine(mesh.ForwardMesh,centroid,radius,0.1);

current_datetime = now;
formattedDateTime = datestr(current_datetime, 'yyyy-mm-dd_HH-MM-SS');
formattedDateTime = strrep(formattedDateTime, '-', '_');
filename = strcat(formattedDateTime,'.msh');
msh_path = fullfile(ProjectFolderPath,'MESH');
msh_path = fullfile(msh_path,filename);

conv_nodes_elements_arrays_to_msh(mesh_refined.node,mesh_refined.elem,msh_path,4);

% Calculate the min and max of X, Y, Z in the mesh nodes
minX = min(mesh_refined.node(:,1));
maxX = max(mesh_refined.node(:,1));
minY = min(mesh_refined.node(:,2));
maxY = max(mesh_refined.node(:,2));
minZ = min(mesh_refined.node(:,3));
maxZ = max(mesh_refined.node(:,3));

% % Open mesh
mesh = toastMesh(msh_path,'gmsh');

% Create the background parameters
mua_bkg = 0.01;
mus_bkg = 1.0;
ref_bkg = 1.4;
nnd = mesh.NodeCount;
mua = ones(nnd,1)*mua_bkg;
mus = ones(nnd,1)*mus_bkg;
ref = ones(nnd,1) * ref_bkg;

mua(tumor_nodes_idx) = 0.05;
mus(tumor_nodes_idx) = 2;

figure
mesh.Display(mua);
title('mua display')
figure
mesh.Display(mus);
title('mus display')
figure
mesh.Display;
title('mesh and source-detector display')

% Create the source and detector positions
z_delta = 0;
Q_z_pos = maxZ + z_delta; % Z position above the mesh
M_z_pos = minZ - z_delta; % Z position below the mesh
nqm = 12; % Number of sources and detectors in one dimension

Q = zeros(nqm^2, 3); % Initialize source positions
M = zeros(nqm^2, 3); % Initialize detector positions

% Source & Detector positions above and below the centered sphere
for i = 1:nqm
    for j = 1:nqm
        x = minX + (maxX - minX)*j/nqm;
        y = minY + (maxY - minY)*i/nqm;
        temp = Q_z_pos;
        Q_z_pos = M_z_pos;
        M_z_pos = temp;

        Q((i-1)*nqm + j,:) = [x, y, Q_z_pos];
        M((i-1)*nqm + j,:) = [x, y, M_z_pos];
    end
end

mesh.SetQM(Q, M);

hold on; % Ensure that new plots are added to the existing figure

% Plot the source positions in red with marker 'o'
plot3(Q(:,1), Q(:,2), Q(:,3), 'ro', 'MarkerFaceColor', 'r');

% Label each source position with its index number
for idx = 1:size(Q, 1)
    text(Q(idx,1), Q(idx,2), Q(idx,3), num2str(idx), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'red');
end

% Plot the detector positions in blue with marker 's'
plot3(M(:,1), M(:,2), M(:,3), 'bs', 'MarkerFaceColor', 'b');

% Label each detector position with its index number
for idx = 1:size(M, 1)
    text(M(idx,1), M(idx,2), M(idx,3), num2str(idx), 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'Color', 'blue');
end

% Create the source and boundary projection vectors
qvec = real(mesh.Qvec('Neumann', 'Gaussian', 5));
mvec = real(mesh.Mvec('Gaussian', 2, ref_bkg));

% Solve the FEM linear system (Simulate DOT Scan)
K = dotSysmat(mesh,mua,mus,ref);
Phi = K\qvec;
Y = mvec.' * Phi;

mua(tumor_nodes_idx) = mua_bkg;
mus(tumor_nodes_idx) = mus_bkg;
K = dotSysmat(mesh,mua,mus,ref);
Phi = K\qvec;
Y_homogeneous = mvec.' * Phi;

% Display sinogram
figure;
imagesc(log(Y) - log(Y_homogeneous));
xlabel('source index q');
ylabel('detector index m');
axis equal tight;
colorbar;