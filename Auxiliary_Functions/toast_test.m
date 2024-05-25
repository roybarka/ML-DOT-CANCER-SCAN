clear all
close all

% % Open mesh
mesh = toastMesh('circle.msh','gmsh');

% Create the background parameters
mua_bkg = 0.01;
mus_bkg = 1.0;
ref_bkg = 1.4;
nnd = mesh.NodeCount;
mua = 0.099.*rand(nnd,1) + 10^-3;
mus = rand(nnd,1) + 1;
ref = ones(nnd,1) * ref_bkg;

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
rad = 25;
nq = 16;
for i=1:nq
  phi_q = 2*pi*(i-1)/nq;
  Q(i,:) = rad * [cos(phi_q) sin(phi_q)];
  phi_m = 2*pi*(i-0.5)/nq;
  M(i,:) = rad * [cos(phi_m) sin(phi_m)];
end
mesh.SetQM(Q,M);
hold on
plot(Q(:,1),Q(:,2),'ro','MarkerFaceColor','r');
plot(M(:,1),M(:,2),'bs','MarkerFaceColor','b');

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
colorbar

% Display boundary profile
figure;
hold on;
angle = [360/32:360/16:360];
for i=1:size(Y,2)
    ywrap = [Y(i:end,i); Y(1:i-1,i)];
    plot(angle,log(ywrap),'o-');
end
axis([0 360 -13 -2]);
xlabel('angular source-detector separation');
ylabel('log intensity');
