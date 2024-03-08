clear all
close all

fullpath = mfilename('fullpath');
[AuxiliaryDirectory, ~, ~] = fileparts(fullpath);
[ProjectFolderPath, ~, ~] = fileparts(AuxiliaryDirectory);
mesh = open(fullfile(ProjectFolderPath,'Auxiliary Variables\Base_Mesh_struct.mat'));

randRowIndex = randi(size(mesh.ForwardMesh.node, 1)); % Generate a random row index
centroid = mesh.ForwardMesh.node(randRowIndex, :); % Select the random row
radius = randi([5,15]);
[mesh_refined, tumor_nodes_idx] = project_meshrefine(mesh.ForwardMesh,[1.884580000000000e+02,41.196800000000000,15],10,0.1);
% dt = datetime('now');
% dtString = dt.Format('yyyy_MM_dd_HH_mm_ss');
% filename = [dtString '.msh'];
filename = 'new_func_test';
msh_path = fullfile('C:\Users\Orens\OneDrive\Documents\EE\Project\MESH',filename);
conv_nodes_elements_arrays_to_msh(mesh_refined.node,mesh_refined.elem,msh_path,4);

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

mua(tumor_nodes_idx) = 0.07;
mus(tumor_nodes_idx) = 1.3;


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
sphere_rad = 25;
placement_rad = 10;
nq = 12;

% Source & Detector positions above the sphere
for i = 1:nq
    for j = 1:nq
        Q((i-1)*nq + j,:) = [(sphere_rad - 2*sphere_rad*j*1/nq), (sphere_rad - 2*sphere_rad*i*1/nq), sphere_rad + placement_rad];
        M((i-1)*nq + j,:) = [(sphere_rad - 2*sphere_rad*j*1/nq),(sphere_rad - 2*sphere_rad*i*1/nq), -(sphere_rad + placement_rad)]; 
    end
end

mesh.SetQM(Q, M);

hold on
plot3(Q(:,1), Q(:,2), Q(:,3),'ro','MarkerFaceColor','r');
plot3(M(:,1), M(:,2), M(:,3),'bs','MarkerFaceColor','b');

% Create the source and boundary projection vectors
qvec = mesh.Qvec('Neumann', 'Gaussian', 2);
mvec = mesh.Mvec('Gaussian', 2, 0);

% Solve the FEM linear system (Simulate DOT Scan)
K = dotSysmat(mesh,mua,mus,ref,0);
Phi = K\qvec;
Y = mvec.' * Phi;

% Display sinogram
figure;
imagesc(log(Y));
xlabel('source index q');
ylabel('detector index m');
axis equal tight;
colorbar;
