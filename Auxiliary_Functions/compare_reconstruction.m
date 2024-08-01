function compare_reconstruction()
    
    close all;

    % Ask user to select the folder
    folder_path = uigetdir('', 'Select Folder');
    
    if folder_path == 0
        disp('No folder selected.');
        return;
    end
    
    % Get all subfolders
    subfolders = genpath(folder_path);
    subfolders = strsplit(subfolders, ';');
    subfolders = subfolders(2:end);
    
    % Create a figure and subplots once
    hFig = figure;
    hAxes(1) = subplot(2, 2, 1);
    hAxes(2) = subplot(2, 2, 2);
    hAxes(3) = subplot(2, 2, 3);
    hAxes(4) = subplot(2, 2, 4);
    
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
                
                original_mus = config_data.mus;
                original_mua = config_data.mua;
                reconstructed_mus = reconstructed_mus.reconstructed_mus';
                reconstructed_mus = reconstructed_mus(1:length(original_mus));
                reconstructed_mua = reconstructed_mua.reconstructed_mua';
                reconstructed_mua = reconstructed_mua(1:length(original_mua));                
                
                % Determine color limits for mus
                mus_min = min(min(original_mus), min(reconstructed_mus));
                mus_max = max(max(original_mus), max(reconstructed_mus));
                
                % Determine color limits for mua
                mua_min = min(min(original_mua), min(reconstructed_mua));
                mua_max = max(max(original_mua), max(reconstructed_mua));
                
                % Update the figures with shared colorbars
                display_3d_mesh(hAxes(1), nodes, elements, original_mus, ['Original mus (Subfolder ' num2str(i) ')'], mus_min, mus_max);
                display_3d_mesh(hAxes(2), nodes, elements, reconstructed_mus, ['Reconstructed mus (Subfolder ' num2str(i) ')'], mus_min, mus_max);
                display_3d_mesh(hAxes(3), nodes, elements, original_mua, ['Original mua (Subfolder ' num2str(i) ')'], mua_min, mua_max);
                display_3d_mesh(hAxes(4), nodes, elements, reconstructed_mua, ['Reconstructed mua (Subfolder ' num2str(i) ')'], mua_min, mua_max);

                pause(0.2);
                input("Press enter to display the next subfolder");
            end
        end
    end

    function display_3d_mesh(hAx, nodes, elements, values, title_str, cmin, cmax)        
        % Plot the mesh using trisurf
        axes(hAx); % Make hAx the current axes
        trisurf(elements, nodes(:, 1), nodes(:, 2), nodes(:, 3), values, 'EdgeColor', 'none', 'FaceAlpha', 0.04);
        title(title_str);
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        colorbar;
        caxis([cmin cmax]);
        axis equal;
        view(3);
        camlight; 
        lighting gouraud;
    end
end
