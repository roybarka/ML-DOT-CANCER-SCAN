function compare_reconstruction()
    % Ask user to select the folder
    folder_path = uigetdir('', 'Select Folder');
    
    if folder_path == 0
        disp('No folder selected.');
        return;
    end
    
    % Get all subfolders
    subfolders = genpath(folder_path);
    subfolders = strsplit(subfolders, ';');
    
    for i = 1:length(subfolders)
        subfolder = subfolders{i};
        if isempty(subfolder)
            continue;
        end
        
        % Look for the required files in the current subfolder
        mesh_file = fullfile(subfolder, 'mesh_refined.msh');        
        config_file = fullfile(subfolder, 'simulation_config_and_results.mat');
        reconstructed_mus_file = fullfile(subfolder, 'reconstructed_mus.mat');
        reconstructed_mua_file = fullfile(subfolder, 'reconstructed_mua.mat');
        
        if exist(mesh_file, 'file') && exist(config_file, 'file') && exist(reconstructed_mus_file, 'file') && exist(reconstructed_mua_file, 'file')
            % Load the data
            config_data = load(config_file);
            reconstructed_mus = load(reconstructed_mus_file);
            reconstructed_mua = load(reconstructed_mua_file);
            [nodes, elements] = conv_msh_to_nodes_elements_arrays(mesh_file);

            % Check for the required variables
            if isfield(config_data, 'mus') && isfield(config_data, 'mua')
                
                reconstructed_mus = reconstructed_mus.reconstructed_mus';
                reconstructed_mua = reconstructed_mua.reconstructed_mua';
                original_mus = config_data.mus;
                original_mua = config_data.mua;
                
                % Display the figures
                figure;
                subplot(2, 2, 1);
                display_3d_mesh(nodes, elements, original_mus, 'Original mus');
                subplot(2, 2, 2);
                display_3d_mesh(nodes, elements, reconstructed_mus(1:length(original_mus)), 'Reconstructed mus');
                subplot(2, 2, 3);
                display_3d_mesh(nodes, elements, original_mua, 'Original mua');
                subplot(2, 2, 4);
                display_3d_mesh(nodes, elements, reconstructed_mua(1:length(original_mua)), 'Reconstructed mua');

                pause(2);
                input("press enter to continue");
                close all;
            end
        end
    end

    function display_3d_mesh(nodes, elements, values, title_str)        
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
    end
end
