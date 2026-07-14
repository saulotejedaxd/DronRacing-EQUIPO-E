%% STARTUP - Configuración de rutas del proyecto

projectRoot = fileparts(mfilename("fullpath"));

addpath(projectRoot);
addpath(genpath(projectRoot));

fprintf("Rutas del proyecto cargadas correctamente.\n");
fprintf("Carpeta raíz: %s\n", projectRoot);