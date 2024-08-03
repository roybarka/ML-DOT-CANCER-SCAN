function simulation_3d(mat_path, mua_bkg, mus_bkg, ref_bkg, tumor_mua, tumor_mus, radius, nqm, multiple_flag)
    mesh = open(mat_path);
    randRowIndex = randi(size(mesh.ForwardMesh.node, 1)); % Generate a random row index
    centroid = mesh.ForwardMesh.node(randRowIndex, :); % Select the random row
    [mesh_refined, tumor_nodes_idx] = project_meshrefine(mesh.ForwardMesh, centroid, radius, 0.1);
    
    [simpath, ~, ~] = fileparts(mat_path);
    filename = 'mesh_refined.mat';
    msh_path = fullfile(simpath, filename);
    save(msh_path, 'mesh_refined');

    filename = 'mesh_refined.msh';
    msh_path = fullfile(simpath, filename);
    conv_nodes_elements_arrays_to_msh(mesh_refined.node, mesh_refined.elem, msh_path, 4);
    
    % Calculate the min and max of X, Y, Z in the mesh nodes
    minX = min(mesh_refined.node(:, 1));
    maxX = max(mesh_refined.node(:, 1));
    minY = min(mesh_refined.node(:, 2));
    maxY = max(mesh_refined.node(:, 2));
    minZ = min(mesh_refined.node(:, 3));
    maxZ = max(mesh_refined.node(:, 3));
    
    % Open mesh
    mesh = toastMesh(msh_path, 'gmsh');
    
    % Create the background parameters
    nnd = mesh.NodeCount;
    mua = ones(nnd, 1) * mua_bkg;
    mus = ones(nnd, 1) * mus_bkg;
    ref = ones(nnd, 1) * ref_bkg;
    
    mua(tumor_nodes_idx) = tumor_mua;
    mus(tumor_nodes_idx) = tumor_mus;    
    
    Q = []; % Initialize source positions
    M = []; % Initialize detector positions
    
    % Create a KD-tree for nearest neighbor search
    mesh_points = mesh_refined.node;    
    
    % Source & Detector positions above and below the centered sphere
    for i = 1:nqm
        for j = 1:nqm
            x = minX + (maxX - minX) * j / nqm;
            y = minY + (maxY - minY) * i / nqm;
            
            check = find(abs(mesh_refined.node(:, 1) - x) < 5 & abs(mesh_refined.node(:, 2) - y) < 5, 1);
            if ~isempty(check)
                % Find the closest point in the mesh for z_max
                [closest_idx_max, ~] = knnsearch(mesh_points, [x, y, maxZ]);
                Q = [Q; mesh_points(closest_idx_max, :)];
                
                % Find the closest point in the mesh for z_min
                [closest_idx_min, ~] = knnsearch(mesh_points, [x, y, minZ]);
                M = [M; mesh_points(closest_idx_min, :)];
            end
        end
    end
    
    mesh.SetQM(Q, M);
    
    if ~multiple_flag

        display_3d_mesh(mesh_refined.node, mesh_refined.elem, mua, 'mua', Q, M);
        display_3d_mesh(mesh_refined.node, mesh_refined.elem, mus, 'mus', Q, M);

    end
    
    % Create the source and boundary projection vectors
    qvec = real(mesh.Qvec('Neumann', 'Gaussian', 5));
    mvec = real(mesh.Mvec('Gaussian', 2, ref_bkg));
    
    % Solve the FEM linear system (Simulate DOT Scan)
    K = dotSysmat(mesh, mua, mus, ref);
    Phi = K \ qvec;
    Y = mvec.' * Phi;
    
    % Save simulation results and config
    save(fullfile(simpath, 'simulation_config_and_results.mat'), 'Y', 'Q', 'M', 'mus', 'mua', 'ref', 'centroid', 'radius', 'tumor_nodes_idx');

    mua(tumor_nodes_idx) = mua_bkg;
    mus(tumor_nodes_idx) = mus_bkg;
    K = dotSysmat(mesh, mua, mus, ref);
    Phi = K \ qvec;
    Y_homogeneous = mvec.' * Phi;
    
    if ~multiple_flag
        % Display sinogram
        figure;
        imagesc(real(log(Y) - log(Y_homogeneous)));
        xlabel('source index q');
        ylabel('detector index m');
        axis equal tight;
        colorbar;
    end
end

function display_3d_mesh(nodes, elements, values, title_str, Q, M)
    figure;
    % Plot the mesh using trisurf
    trisurf(elements, nodes(:, 1), nodes(:, 2), nodes(:, 3), values, 'EdgeColor', 'none', 'FaceAlpha', 0.025);
    title(title_str);
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    colorbar;
    axis equal;
    view(3);
    camlight; 
    lighting gouraud;

    hold on; % Ensure that new plots are added to the existing figure
    
    % Plot the source positions in red with marker 'o'
    plot3(Q(:, 1), Q(:, 2), Q(:, 3), 'ro', 'MarkerFaceColor', 'r');
    
    % Label each source position with its index number
    for idx = 1:size(Q, 1)
        text(Q(idx, 1), Q(idx, 2), Q(idx, 3), num2str(idx), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'red');
    end
    
    % Plot the detector positions in blue with marker 's'
    plot3(M(:, 1), M(:, 2), M(:, 3), 'bs', 'MarkerFaceColor', 'b');
    
    % Label each detector position with its index number
    for idx = 1:size(M, 1)
        text(M(idx, 1), M(idx, 2), M(idx, 3), num2str(idx), 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'Color', 'blue');
    end
end
