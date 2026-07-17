%% DIAGNOSTICO_ESTRUCTURA_MODELO
% Encuentra las funciones reales de parámetros y dinámica del proyecto.

clearvars;
clc;

%% Encontrar carpeta raíz del proyecto

rutaEsteArchivo = mfilename('fullpath');

if isempty(rutaEsteArchivo)
    carpetaRaiz = pwd;
else
    carpetaTests = fileparts(rutaEsteArchivo);
    carpetaRaiz = fileparts(carpetaTests);
end

fprintf('\n');
fprintf('============================================================\n');
fprintf(' DIAGNOSTICO DEL MODELO DEL DRON\n');
fprintf('============================================================\n\n');

fprintf('Carpeta raíz detectada:\n%s\n\n', carpetaRaiz);

%% Mostrar contenido de los archivos de parámetros

archivosParametros = { ...
    fullfile(carpetaRaiz, 'config', 'parametros_fisicos.m'), ...
    fullfile(carpetaRaiz, 'config', 'parametros_diseno.m') ...
};

fprintf('============================================================\n');
fprintf(' ARCHIVOS DE PARAMETROS\n');
fprintf('============================================================\n\n');

for k = 1:numel(archivosParametros)

    rutaArchivo = archivosParametros{k};

    if ~isfile(rutaArchivo)

        fprintf('NO ENCONTRADO:\n%s\n\n', rutaArchivo);
        continue;

    end

    fprintf('------------------------------------------------------------\n');
    fprintf('ARCHIVO: %s\n', rutaArchivo);
    fprintf('------------------------------------------------------------\n');

    contenido = fileread(rutaArchivo);

    firmaFuncion = regexp( ...
        contenido, ...
        '(?m)^\s*function[^\r\n]*', ...
        'match', ...
        'once' ...
    );

    if isempty(firmaFuncion)
        fprintf('TIPO: SCRIPT, no función.\n\n');
    else
        fprintf('FIRMA: %s\n\n', strtrim(firmaFuncion));
    end

    lineas = splitlines(string(contenido));

    cantidadMostrar = min(numel(lineas), 80);

    fprintf('PRIMERAS %d LINEAS:\n\n', cantidadMostrar);

    for numeroLinea = 1:cantidadMostrar

        fprintf( ...
            '%3d | %s\n', ...
            numeroLinea, ...
            char(lineas(numeroLinea)) ...
        );

    end

    fprintf('\n');

end

%% Buscar candidatos a función dinámica

fprintf('============================================================\n');
fprintf(' POSIBLES FUNCIONES DEL MODELO DINAMICO\n');
fprintf('============================================================\n\n');

archivosM = dir(fullfile(carpetaRaiz, '**', '*.m'));

palabrasClave = [ ...
    "dinam", ...
    "modelo", ...
    "ecuacion", ...
    "estado", ...
    "deriv", ...
    "fuerza", ...
    "momento", ...
    "traslacion", ...
    "rotacion", ...
    "6dof", ...
    "12_estados" ...
];

cantidadCandidatos = 0;

for k = 1:numel(archivosM)

    rutaArchivo = fullfile( ...
        archivosM(k).folder, ...
        archivosM(k).name ...
    );

    contenido = fileread(rutaArchivo);

    firmaFuncion = regexp( ...
        contenido, ...
        '(?m)^\s*function[^\r\n]*', ...
        'match', ...
        'once' ...
    );

    if isempty(firmaFuncion)
        firmaMostrar = '[SCRIPT]';
    else
        firmaMostrar = strtrim(firmaFuncion);
    end

    rutaRelativa = erase( ...
        string(rutaArchivo), ...
        string(carpetaRaiz) + filesep ...
    );

    textoBusqueda = lower( ...
        rutaRelativa + " " + string(firmaMostrar) ...
    );

    esCandidato = any( ...
        contains(textoBusqueda, palabrasClave) ...
    );

    % Mostrar siempre lo que esté dentro de dynamics.
    estaEnDynamics = contains( ...
        lower(rutaRelativa), ...
        "dynamics" ...
    );

    if esCandidato || estaEnDynamics

        cantidadCandidatos = cantidadCandidatos + 1;

        fprintf('%02d. %s\n', ...
            cantidadCandidatos, ...
            char(rutaRelativa));

        fprintf('    %s\n\n', firmaMostrar);

    end

end

if cantidadCandidatos == 0

    fprintf('No se encontraron candidatos automáticamente.\n\n');

end

%% Listar todas las carpetas principales

fprintf('============================================================\n');
fprintf(' CARPETAS PRINCIPALES DEL PROYECTO\n');
fprintf('============================================================\n\n');

elementosRaiz = dir(carpetaRaiz);

for k = 1:numel(elementosRaiz)

    if elementosRaiz(k).isdir && ...
            ~strcmp(elementosRaiz(k).name, '.') && ...
            ~strcmp(elementosRaiz(k).name, '..')

        fprintf('[CARPETA] %s\n', elementosRaiz(k).name);

    end

end

fprintf('\n');
fprintf('============================================================\n');
fprintf(' FIN DEL DIAGNOSTICO\n');
fprintf('============================================================\n\n');