function updatepath()
    fullpath = mfilename('fullpath');
    [Projectdir, ~, ~] = fileparts(fullpath);
    addpath(Projectdir);
    fprintf('Added %s to path successfuly\n', Projectdir);
    Directory = fullfile(Projectdir,'Auxiliary_Functions');
    addpath(Directory);
    fprintf('Added %s to path successfuly\n', Directory);
    Directory = fullfile(Projectdir,'Auxiliary_Variables');
    addpath(Directory);
    fprintf('Added %s to path successfuly\n', Directory);
    Directory = fullfile(Projectdir,'MESH');
    addpath(Directory);
    fprintf('Added %s to path successfuly\n', Directory);
    toastdir = fullfile(Projectdir,'Toast_app\toastpp-2.0.2\mtoast2_install.m');
    run(toastdir)
end