function [nodes, elements] = conv_msh_to_nodes_elements_arrays(input_path,output_path)
    % Read the .msh file and extract nodes and elements into arrays
    % filePath: String with the path to the .msh file

    % Open the file for reading
    fileID = fopen(input_path, 'r');
    if fileID == -1
        error('Could not open file %s', input_path);
    end

    nodes = [];
    elements = [];

    while ~feof(fileID)
        line = fgetl(fileID);
        if contains(line, '$Nodes')
            % Read the number of nodes
            numNodes = str2double(fgetl(fileID));
            nodes = zeros(numNodes, 3);
            for i = 1:numNodes
                data = str2num(fgetl(fileID)); %#ok<ST2NM>
                nodes(i, :) = data(2:end); % Exclude the node index
            end
        elseif contains(line, '$Elements')
            % Read the number of elements
            numElements = str2double(fgetl(fileID));
            elements = zeros(numElements, 4);
            for i = 1:numElements
                data = str2num(fgetl(fileID)); %#ok<ST2NM>
                elements(i, :) = data(end-3:end); % Only keep the node IDs
            end
        end
    end

    % Close the file
    fclose(fileID);

    ForwardMesh.node = nodes;
    ForwardMesh.elem = elements;
    save(output_path,"ForwardMesh");
end
