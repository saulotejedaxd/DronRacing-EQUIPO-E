function CAD = cargar_modelo_dron_cad(forzarRegeneracion)
%CARGAR_MODELO_DRON_CAD Carga y prepara el STL real del dron.
%
% USO:
%
%   CAD = cargar_modelo_dron_cad();
%
%   CAD = cargar_modelo_dron_cad(true);
%
% El argumento TRUE obliga a volver a procesar el STL y regenerar
% el archivo de caché.
%
% ARCHIVO DE ENTRADA:
%
%   Dron_Modelo/cad/Dron.stl
%
% ARCHIVO DE CACHÉ:
%
%   Dron_Modelo/cad/Dron_cache.mat
%
% SALIDA:
%
%   CAD.caras
%   CAD.vertices_m
%   CAD.dimensiones_m
%   CAD.numeroCaras
%   CAD.numeroVertices
%   CAD.colorSugerido
%
% La geometría final queda:
%
%   - Expresada en metros.
%   - Centrada en el origen.
%   - Orientada para la simulación.
%   - Reducida para mantener fluidez.
%
% EJES LOCALES:
%
%   +X = frente del dron
%   +Y = derecha del dron
%   +Z = parte superior del dron

    %% ============================================================
    % ARGUMENTO OPCIONAL
    % =============================================================

    if nargin < 1 || isempty(forzarRegeneracion)

        forzarRegeneracion = false;

    end

    if ~isscalar(forzarRegeneracion)

        error( ...
            'cargar_modelo_dron_cad:ArgumentoInvalido', ...
            'forzarRegeneracion debe ser un valor lógico escalar.' ...
        );

    end

    forzarRegeneracion = ...
        logical(forzarRegeneracion);

    %% ============================================================
    % CONFIGURACIÓN
    % =============================================================

    % Cambiar esta versión obliga a regenerar cachés anteriores.

    versionCache = ...
        2;

    % El STL debe exportarse desde SolidWorks en milímetros.

    escalaMilimetrosAMetros = ...
        1e-3;

    % Número máximo aproximado de triángulos para la animación.
    %
    % Un valor muy alto mejora el detalle, pero puede hacer menos
    % fluida la simulación.

    maximoCarasAnimacion = ...
        18000;

    % Tolerancia para unir vértices prácticamente iguales.

    toleranciaVertices_m = ...
        1e-8;

    %% ============================================================
    % ORIENTACIÓN DEL STL
    % =============================================================

    % Conversión aproximada de los ejes exportados por SolidWorks:
    %
    %   X final = -Z del STL
    %   Y final =  X del STL
    %   Z final =  Y del STL
    %
    % La salida debe quedar:
    %
    %   X positivo hacia el frente.
    %   Y positivo hacia la derecha.
    %   Z positivo hacia arriba.

    matrizSTLaGrafica = [
         0,  0, -1
         1,  0,  0
         0,  1,  0
    ];

    %% ============================================================
    % RUTAS DEL PROYECTO
    % =============================================================

    rutaFuncion = ...
        mfilename('fullpath');

    carpetaAnalysis = ...
        fileparts(rutaFuncion);

    raizProyecto = ...
        fileparts(carpetaAnalysis);

    carpetaCAD = fullfile( ...
        raizProyecto, ...
        'cad' ...
    );

    if ~isfolder(carpetaCAD)

        mkdir(carpetaCAD);

    end

    rutaSTL = localizar_archivo_stl( ...
        carpetaCAD ...
    );

    rutaCache = fullfile( ...
        carpetaCAD, ...
        'Dron_cache.mat' ...
    );

    if strlength(rutaSTL) == 0

        error( ...
            'cargar_modelo_dron_cad:STLNoEncontrado', ...
            [ ...
                'No se encontró el archivo STL del dron.' ...
                newline ...
                newline ...
                'Exporta el ensamble desde SolidWorks y colócalo en:' ...
                newline ...
                fullfile(carpetaCAD, 'Dron.stl') ...
            ] ...
        );

    end

    rutaSTL = ...
        char(rutaSTL);

    %% ============================================================
    % CARGAR CACHÉ EXISTENTE
    % =============================================================

    if ~forzarRegeneracion && ...
            cache_vigente( ...
                rutaSTL, ...
                rutaCache, ...
                versionCache ...
            )

        datosCache = load( ...
            rutaCache, ...
            'CAD' ...
        );

        CAD = ...
            datosCache.CAD;

        CAD.cargadoDesdeCache = ...
            true;

        fprintf('\n');
        fprintf('CAD cargado desde caché.\n');
        fprintf('  Archivo:   %s\n', ...
            rutaCache);

        fprintf('  Caras:     %d\n', ...
            CAD.numeroCaras);

        fprintf('  Vértices:  %d\n\n', ...
            CAD.numeroVertices);

        return;

    end

    %% ============================================================
    % COMPROBAR STLREAD
    % =============================================================

    if exist('stlread', 'file') ~= 2

        error( ...
            'cargar_modelo_dron_cad:STLReadNoDisponible', ...
            [ ...
                'MATLAB no encontró la función stlread.' ...
                newline ...
                'Verifica que estés usando MATLAB R2018b o posterior.' ...
            ] ...
        );

    end

    %% ============================================================
    % CARGAR STL
    % =============================================================

    fprintf('\n');
    fprintf('Cargando el STL real del dron...\n');
    fprintf('  Archivo: %s\n\n', ...
        rutaSTL);

    mallaSTL = ...
        stlread(rutaSTL);

    %% ============================================================
    % EXTRAER CARAS Y VÉRTICES
    % =============================================================

    [caras, verticesSTL] = extraer_datos_stl( ...
        mallaSTL ...
    );

    if isempty(caras) || ...
            isempty(verticesSTL)

        error( ...
            'cargar_modelo_dron_cad:MallaVacia', ...
            'El archivo STL no contiene una malla utilizable.' ...
        );

    end

    %% ============================================================
    % LIMPIAR MALLA ORIGINAL
    % =============================================================

    [caras, verticesSTL] = limpiar_malla( ...
        caras, ...
        verticesSTL ...
    );

    if isempty(caras) || ...
            isempty(verticesSTL)

        error( ...
            'cargar_modelo_dron_cad:MallaInvalida', ...
            'La malla STL no contiene triángulos válidos.' ...
        );

    end

    %% ============================================================
    % CONVERTIR MILÍMETROS A METROS
    % =============================================================

    vertices_m = ...
        verticesSTL * ...
        escalaMilimetrosAMetros;

    %% ============================================================
    % ORIENTAR EL DRON
    % =============================================================

    vertices_m = ...
        (matrizSTLaGrafica * vertices_m.').';

    %% ============================================================
    % CENTRAR EN EL ORIGEN
    % =============================================================

    limiteMinimoOriginal_m = ...
        min(vertices_m, [], 1);

    limiteMaximoOriginal_m = ...
        max(vertices_m, [], 1);

    centroCajaOriginal_m = ...
        0.5 * ...
        (limiteMinimoOriginal_m + ...
         limiteMaximoOriginal_m);

    vertices_m = ...
        vertices_m - ...
        centroCajaOriginal_m;

    %% ============================================================
    % FUSIONAR VÉRTICES REPETIDOS
    % =============================================================

    [caras, vertices_m] = fusionar_vertices( ...
        caras, ...
        vertices_m, ...
        toleranciaVertices_m ...
    );

    %% ============================================================
    % ELIMINAR TRIÁNGULOS DUPLICADOS
    % =============================================================

    carasOrdenadas = ...
        sort(caras, 2);

    [~, indicesCarasUnicas] = unique( ...
        carasOrdenadas, ...
        'rows' ...
    );

    indicesCarasUnicas = ...
        sort(indicesCarasUnicas);

    caras = ...
        caras(indicesCarasUnicas, :);

    %% ============================================================
    % REDUCIR MALLA PARA ANIMACIÓN
    % =============================================================

    numeroCarasOriginal = ...
        size(caras, 1);

    reduccionAplicada = ...
        false;

    if numeroCarasOriginal > ...
            maximoCarasAnimacion

        fprintf( ...
            ['Reduciendo la malla de %d a aproximadamente ' ...
             '%d caras...\n'], ...
            numeroCarasOriginal, ...
            maximoCarasAnimacion ...
        );

        [carasReducidas, verticesReducidos] = reducepatch( ...
            caras, ...
            vertices_m, ...
            maximoCarasAnimacion, ...
            'fast' ...
        );

        caras = ...
            double(carasReducidas);

        vertices_m = ...
            double(verticesReducidos);

        reduccionAplicada = ...
            true;

        [caras, vertices_m] = limpiar_malla( ...
            caras, ...
            vertices_m ...
        );

    end

    %% ============================================================
    % VOLVER A CENTRAR DESPUÉS DE LA REDUCCIÓN
    % =============================================================

    limiteMinimoReducido_m = ...
        min(vertices_m, [], 1);

    limiteMaximoReducido_m = ...
        max(vertices_m, [], 1);

    centroReducido_m = ...
        0.5 * ...
        (limiteMinimoReducido_m + ...
         limiteMaximoReducido_m);

    vertices_m = ...
        vertices_m - ...
        centroReducido_m;

    %% ============================================================
    % DIMENSIONES FINALES
    % =============================================================

    limiteMinimoFinal_m = ...
        min(vertices_m, [], 1);

    limiteMaximoFinal_m = ...
        max(vertices_m, [], 1);

    dimensiones_m = ...
        limiteMaximoFinal_m - ...
        limiteMinimoFinal_m;

    %% ============================================================
    % REVISIÓN BÁSICA DE ESCALA
    % =============================================================

    dimensionMayor_m = ...
        max(dimensiones_m);

    if dimensionMayor_m > 1.0

        warning( ...
            'cargar_modelo_dron_cad:ModeloDemasiadoGrande', ...
            [ ...
                'El dron mide %.3f m en su dimensión mayor. ' ...
                'Verifica que el STL haya sido exportado en milímetros.' ...
            ], ...
            dimensionMayor_m ...
        );

    elseif dimensionMayor_m < 0.03

        warning( ...
            'cargar_modelo_dron_cad:ModeloDemasiadoPequeno', ...
            [ ...
                'El dron mide %.4f m en su dimensión mayor. ' ...
                'La escala del STL podría ser incorrecta.' ...
            ], ...
            dimensionMayor_m ...
        );

    end

    %% ============================================================
    % CONSTRUIR SALIDA
    % =============================================================

    CAD = struct();

    CAD.meta = struct();

    CAD.meta.nombre = ...
        "CAD real del dron";

    CAD.meta.formatoOriginal = ...
        "STL";

    CAD.meta.versionCache = ...
        versionCache;

    CAD.meta.fechaGeneracion = ...
        string(datetime('now'));

    CAD.meta.unidadesOriginales = ...
        "milímetros";

    CAD.meta.unidadesSalida = ...
        "metros";

    CAD.caras = ...
        double(caras);

    CAD.vertices_m = ...
        double(vertices_m);

    % Alias para usarlo directamente con PATCH.

    CAD.vertices = ...
        CAD.vertices_m;

    CAD.dimensiones_m = ...
        double(dimensiones_m);

    CAD.limiteMinimo_m = ...
        double(limiteMinimoFinal_m);

    CAD.limiteMaximo_m = ...
        double(limiteMaximoFinal_m);

    CAD.centroCajaOriginal_m = ...
        double(centroCajaOriginal_m);

    CAD.matrizSTLaGrafica = ...
        double(matrizSTLaGrafica);

    CAD.escalaMilimetrosAMetros = ...
        escalaMilimetrosAMetros;

    CAD.numeroCarasOriginal = ...
        numeroCarasOriginal;

    CAD.numeroCaras = ...
        size(CAD.caras, 1);

    CAD.numeroVertices = ...
        size(CAD.vertices_m, 1);

    CAD.reduccionAplicada = ...
        reduccionAplicada;

    CAD.maximoCarasAnimacion = ...
        maximoCarasAnimacion;

    CAD.rutaSTL = ...
        string(rutaSTL);

    CAD.rutaCache = ...
        string(rutaCache);

    CAD.cargadoDesdeCache = ...
        false;

    %% ============================================================
    % APARIENCIA SUGERIDA
    % =============================================================

    CAD.colorSugerido = ...
        [0.18, 0.20, 0.24];

    CAD.colorBordeSugerido = ...
        'none';

    CAD.transparenciaSugerida = ...
        1.0;

    %% ============================================================
    % GUARDAR CACHÉ
    % =============================================================

    save( ...
        rutaCache, ...
        'CAD', ...
        '-v7' ...
    );

    %% ============================================================
    % REPORTE
    % =============================================================

    fprintf('\n');
    fprintf('CAD preparado correctamente.\n');

    fprintf('  Dimensión X: %.4f m\n', ...
        CAD.dimensiones_m(1));

    fprintf('  Dimensión Y: %.4f m\n', ...
        CAD.dimensiones_m(2));

    fprintf('  Dimensión Z: %.4f m\n', ...
        CAD.dimensiones_m(3));

    fprintf('  Caras originales: %d\n', ...
        CAD.numeroCarasOriginal);

    fprintf('  Caras finales:    %d\n', ...
        CAD.numeroCaras);

    fprintf('  Vértices finales: %d\n', ...
        CAD.numeroVertices);

    if CAD.reduccionAplicada

        fprintf('  Reducción:         SÍ\n');

    else

        fprintf('  Reducción:         NO\n');

    end

    fprintf('  Caché creada en:\n');
    fprintf('    %s\n\n', ...
        rutaCache);

end


function rutaSTL = localizar_archivo_stl(carpetaCAD)
%LOCALIZAR_ARCHIVO_STL Busca diferentes variantes del nombre.

    candidatos = string({
        fullfile(carpetaCAD, 'Dron.stl')
        fullfile(carpetaCAD, 'Dron.STL')
        fullfile(carpetaCAD, 'dron.stl')
        fullfile(carpetaCAD, 'DRON.STL')
    });

    rutaSTL = ...
        "";

    for indice = 1:numel(candidatos)

        if isfile(candidatos(indice))

            rutaSTL = ...
                candidatos(indice);

            return;

        end

    end

    archivosSTL = [
        dir(fullfile(carpetaCAD, '*.stl'))
        dir(fullfile(carpetaCAD, '*.STL'))
    ];

    if ~isempty(archivosSTL)

        rutaSTL = string( ...
            fullfile( ...
                archivosSTL(1).folder, ...
                archivosSTL(1).name ...
            ) ...
        );

    end

end


function vigente = cache_vigente( ...
    rutaSTL, ...
    rutaCache, ...
    versionCache ...
)
%CACHE_VIGENTE Comprueba que la caché sea válida.

    vigente = ...
        false;

    if ~isfile(rutaCache)

        return;

    end

    informacionSTL = ...
        dir(rutaSTL);

    informacionCache = ...
        dir(rutaCache);

    if isempty(informacionSTL) || ...
            isempty(informacionCache)

        return;

    end

    % Regenerar si el STL es más reciente que la caché.

    if informacionCache.datenum < ...
            informacionSTL.datenum

        return;

    end

    try

        variablesCache = whos( ...
            '-file', ...
            rutaCache ...
        );

        nombresVariables = string( ...
            {variablesCache.name} ...
        );

        if ~any(nombresVariables == "CAD")

            return;

        end

        datosCache = load( ...
            rutaCache, ...
            'CAD' ...
        );

        CADCache = ...
            datosCache.CAD;

        camposObligatorios = {
            'meta'
            'caras'
            'vertices_m'
            'numeroCaras'
            'numeroVertices'
        };

        for indiceCampo = 1:numel(camposObligatorios)

            if ~isfield( ...
                    CADCache, ...
                    camposObligatorios{indiceCampo} ...
                )

                return;

            end

        end

        if ~isfield(CADCache.meta, 'versionCache') || ...
                CADCache.meta.versionCache ~= versionCache

            return;

        end

        if isempty(CADCache.caras) || ...
                isempty(CADCache.vertices_m)

            return;

        end

        vigente = ...
            true;

    catch

        vigente = ...
            false;

    end

end


function [caras, vertices] = extraer_datos_stl(mallaSTL)
%EXTRAER_DATOS_STL Extrae caras y vértices de la salida de STLREAD.
%
% Compatible con:
%
%   - Objetos triangulation.
%   - Estructuras con ConnectivityList y Points.
%   - Estructuras antiguas con faces y vertices.
%   - Estructuras con Faces y Vertices.

    %% Salida moderna de STLREAD

    if isa(mallaSTL, 'triangulation')

        caras = double( ...
            mallaSTL.ConnectivityList ...
        );

        vertices = double( ...
            mallaSTL.Points ...
        );

        return;

    end

    %% Salidas almacenadas como estructura

    if isstruct(mallaSTL)

        if isfield(mallaSTL, 'ConnectivityList') && ...
                isfield(mallaSTL, 'Points')

            caras = double( ...
                mallaSTL.ConnectivityList ...
            );

            vertices = double( ...
                mallaSTL.Points ...
            );

            return;

        end

        if isfield(mallaSTL, 'faces') && ...
                isfield(mallaSTL, 'vertices')

            caras = double( ...
                mallaSTL.faces ...
            );

            vertices = double( ...
                mallaSTL.vertices ...
            );

            return;

        end

        if isfield(mallaSTL, 'Faces') && ...
                isfield(mallaSTL, 'Vertices')

            caras = double( ...
                mallaSTL.Faces ...
            );

            vertices = double( ...
                mallaSTL.Vertices ...
            );

            return;

        end

    end

    %% Formato desconocido

    error( ...
        'cargar_modelo_dron_cad:FormatoSTLNoReconocido', ...
        [ ...
            'No fue posible interpretar la salida de STLREAD. ' ...
            'La salida recibida es de tipo: %s.' ...
        ], ...
        class(mallaSTL) ...
    );

end


function [caras, vertices] = limpiar_malla( ...
    caras, ...
    vertices ...
)
%LIMPIAR_MALLA Elimina triángulos y vértices inválidos.

    caras = ...
        double(caras);

    vertices = ...
        double(vertices);

    if isempty(caras) || ...
            isempty(vertices)

        caras = ...
            zeros(0, 3);

        vertices = ...
            zeros(0, 3);

        return;

    end

    if size(vertices, 2) == 2

        vertices(:, 3) = ...
            0;

    end

    if size(vertices, 2) ~= 3

        error( ...
            'cargar_modelo_dron_cad:VerticesInvalidos', ...
            'Los vértices deben tener tres coordenadas.' ...
        );

    end

    if size(caras, 2) ~= 3

        error( ...
            'cargar_modelo_dron_cad:CarasInvalidas', ...
            'El STL debe contener caras triangulares.' ...
        );

    end

    caras = ...
        round(caras);

    %% Eliminar caras con índices inválidos

    carasValidas = ...
        all(isfinite(caras), 2) & ...
        all(caras >= 1, 2) & ...
        all(caras <= size(vertices, 1), 2);

    caras = ...
        caras(carasValidas, :);

    %% Eliminar vértices con NaN o infinito

    verticesValidos = ...
        all(isfinite(vertices), 2);

    if ~all(verticesValidos)

        mapaVertices = ...
            zeros(size(vertices, 1), 1);

        indicesValidos = ...
            find(verticesValidos);

        mapaVertices(indicesValidos) = ...
            1:numel(indicesValidos);

        carasConVerticesValidos = ...
            all(verticesValidos(caras), 2);

        caras = ...
            caras(carasConVerticesValidos, :);

        caras = ...
            mapaVertices(caras);

        vertices = ...
            vertices(verticesValidos, :);

    end

    %% Eliminar caras con índices repetidos

    carasNoDegeneradas = ...
        caras(:, 1) ~= caras(:, 2) & ...
        caras(:, 1) ~= caras(:, 3) & ...
        caras(:, 2) ~= caras(:, 3);

    caras = ...
        caras(carasNoDegeneradas, :);

    if isempty(caras)

        vertices = ...
            zeros(0, 3);

        return;

    end

    %% Eliminar caras con área prácticamente cero

    vertice1 = ...
        vertices(caras(:, 1), :);

    vertice2 = ...
        vertices(caras(:, 2), :);

    vertice3 = ...
        vertices(caras(:, 3), :);

    areaDoble = vecnorm( ...
        cross( ...
            vertice2 - vertice1, ...
            vertice3 - vertice1, ...
            2 ...
        ), ...
        2, ...
        2 ...
    );

    toleranciaArea = ...
        1e-12;

    caras = ...
        caras(areaDoble > toleranciaArea, :);

    if isempty(caras)

        vertices = ...
            zeros(0, 3);

        return;

    end

    %% Eliminar vértices que ya no utiliza ninguna cara

    indicesUsados = ...
        unique(caras(:));

    mapaCompacto = ...
        zeros(size(vertices, 1), 1);

    mapaCompacto(indicesUsados) = ...
        1:numel(indicesUsados);

    vertices = ...
        vertices(indicesUsados, :);

    caras = ...
        mapaCompacto(caras);

end


function [caras, vertices] = fusionar_vertices( ...
    caras, ...
    vertices, ...
    tolerancia ...
)
%FUSIONAR_VERTICES Une vértices con posiciones casi idénticas.

    if isempty(vertices) || ...
            tolerancia <= 0

        return;

    end

    verticesCuantizados = round( ...
        vertices / tolerancia ...
    );

    [ ...
        ~, ...
        indicesRepresentantes, ...
        mapaVertices ...
    ] = unique( ...
        verticesCuantizados, ...
        'rows' ...
    );

    vertices = ...
        vertices(indicesRepresentantes, :);

    caras = reshape( ...
        mapaVertices(caras), ...
        size(caras) ...
    );

    [caras, vertices] = limpiar_malla( ...
        caras, ...
        vertices ...
    );

end