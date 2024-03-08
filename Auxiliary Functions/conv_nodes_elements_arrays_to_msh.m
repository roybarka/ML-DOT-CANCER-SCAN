function conv_nodes_elements_arrays_to_msh(nodes, elements, filePath, elementType)
    % nodes: Nx4 matrix [NodeID, x, y, z]
    % elements: Mx4 matrix [NodeID1, NodeID2, NodeID3, NodeID4]
    % filePath: String with the path to save the .msh file
    % elementType: Scalar defining the Gmsh element type (e.g., 3 for quadrilaterals, 4 for tetrahedra)

    % Open the file for writing
    fileID = fopen(filePath, 'w');

    % Write the mesh format header
    fprintf(fileID, '$MeshFormat\n');
    fprintf(fileID, '2.2 0 8\n'); % Version 2.2, file-type (0 for ASCII), data-size
    fprintf(fileID, '$EndMeshFormat\n');

    % Write nodes section
    fprintf(fileID, '$Nodes\n');
    fprintf(fileID, '%d\n', size(nodes, 1)); % Number of nodes
    for i = 1:size(nodes, 1)
        fprintf(fileID, '%d %f %f %f\n',i,nodes(i, :)); % NodeID and coordinates
    end
    fprintf(fileID, '$EndNodes\n');

    % Write elements section
    fprintf(fileID, '$Elements\n');
    fprintf(fileID, '%d\n', size(elements, 1)); % Number of elements
    for i = 1:size(elements, 1)
        % Since there are no explicit element IDs, use the loop index (i) as the element ID
        fprintf(fileID, '%d %d 2 0 0 ', i, elementType); % Implicit ElementID, ElementType, number of tags, tags (assuming no physical or geometrical tags)
        fprintf(fileID, '%d %d %d %d\n', elements(i, :)); % Node IDs
    end
    fprintf(fileID, '$EndElements\n');

    % Close the file
    fclose(fileID);
end
