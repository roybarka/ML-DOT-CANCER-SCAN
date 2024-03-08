function stretch_mesh(inputFilePath, outputFilePath, scaleX, scaleY, scaleZ)
    % Open the input mesh file
    fileID = fopen(inputFilePath, 'r');
    
    % Initialize containers for nodes and elements
    currentNodeIndex = 0;
    currentElementIndex = 0;

    % Flags to track what part of the file we are reading
    readingNodes = false;
    readingElements = false;
    
    % Read file line by line
    while ~feof(fileID)
        line = fgetl(fileID);
        
        % Check what section we are in
        if contains(line, '$Nodes')
            readingNodes = true;
            nodes_count = str2num(fgetl(fileID));
            nodes = zeros(nodes_count,4);
            continue; % Skip to next line
        elseif contains(line, '$EndNodes')
            readingNodes = false;
        elseif contains(line, '$Elements')
            readingElements = true;
            elements_count = str2num(fgetl(fileID));
            elements = cell(elements_count, 1);
            continue;
        elseif contains(line, '$EndElements')
            readingElements = false;
        end
        
        % Read and store node data
        if readingNodes
            % Split the line by spaces and convert to numeric data
            nodeData = str2num(line);
            if ~isempty(nodeData)
                % Increment the current node index
                currentNodeIndex = currentNodeIndex + 1;
                
                % Apply scaling factors directly in the pre-allocated array
                nodes(currentNodeIndex, 1) = nodeData(1); % Node ID
                nodes(currentNodeIndex, 2) = nodeData(2) * scaleX; % x-coordinate
                nodes(currentNodeIndex, 3) = nodeData(3) * scaleY; % y-coordinate
                nodes(currentNodeIndex, 4) = nodeData(4) * scaleZ; % z-coordinate
            end 
        elseif readingElements
            % Directly store element data; no modification needed
            currentElementIndex = currentElementIndex +1;
            elements{currentElementIndex} = str2num(line); % Append to the cell array
            
        end
    end
    
    % Close the input file
    fclose(fileID);
    
    % Write the modified mesh to a new file
    fileID = fopen(outputFilePath, 'w');
    fprintf(fileID,'$MeshFormat\n2.2 0 8\n$EndMeshFormat\n');

    % Write nodes to the file
    fprintf(fileID, '$Nodes\n');
    fprintf(fileID, '%d\n', currentNodeIndex); % Number of nodes processed and stored
    for i = 1:currentNodeIndex
        fprintf(fileID, '%d %f %f %f\n', nodes(i, :));
    end
    fprintf(fileID, '$EndNodes\n');
    
    % Write elements to the file (unmodified)
    fprintf(fileID, '$Elements\n');
    fprintf(fileID, '%d\n', currentElementIndex); % Number of elements
    for i = 1:length(elements)
        element = elements{i}; % Access the element data from the cell
        % Use fprintf to write the element data
        % Since element is a vector, loop through each value for printing
        for j = 1:length(element)
            if j == length(element)
                fprintf(fileID, '%d\n', element(j)); % Print the last value with a newline
            else
                fprintf(fileID, '%d ', element(j)); % Print the value with a trailing space
            end
        end
    end
    fprintf(fileID, '$EndElements\n');
    
    % Close the output file
    fclose(fileID);
end
