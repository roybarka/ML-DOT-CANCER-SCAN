function updatepath()
    fullpath = mfilename('fullpath');
    [projectDirectory, ~, ~] = fileparts(fullpath);
    addpath(projectDirectory)
    fprintf('Added %s to path successfuly\n', projectDirectory)
    toastdir = fullfile(projectDirectory,'Toast_app\toastpp-2.0.2\mtoast2_install.m');
    run(toastdir)
end