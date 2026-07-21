%% SIMULACION_INTERACTIVA_FISICA
% Gemelo virtual optimizado del KIWO E88 real V1.
%
% ARQUITECTURA:
%
%   Teclado
%       ↓
%   Referencia universal
%       ↓
%   Controlador traslacional
%       ↓
%   Controlador de actitud
%       ↓
%   Mezclador de motores
%       ↓
%   Modelo no lineal de 12 estados
%       ↓
%   Integración RK4
%       ↓
%   Visualización optimizada
%
% CONTROLES:
%
%   Flechas:
%       Movimiento horizontal.
%
%   A / D:
%       Rotación yaw.
%
%   W / S:
%       Modificación manual continua de altura.
%
%   Shift:
%       Subir un metro.
%
%   Espacio:
%       Bajar un metro.
%
%   X:
%       Apagar y desarmar motores.
%
%   Enter:
%       Armar motores.
%
%   R:
%       Reiniciar.
%
%   Escape:
%       Salir.
%
% FRECUENCIAS:
%
%   Física y control:       100 Hz
%   Modelo 3D:               25 Hz
%   Cámara:                  12 Hz
%   Trayectoria:              8 Hz
%   Paneles de texto:         5 Hz
%
% La separación de frecuencias evita que el dibujo del dron bloquee
% el controlador y los eventos del teclado.

clearvars;
clc;
close all force;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' SIMULACIÓN INTERACTIVA OPTIMIZADA - KIWO E88 REAL V1\n');
fprintf('============================================================\n\n');

%% ================================================================
% MODELO Y PARÁMETROS
% ================================================================

modelo = definicion_modelo();

P = parametros_fisicos();

Cdiseno = parametros_diseno();

R = reglas_competencia();

[P, Cdiseno, casoReal] = caso_real_dron( ...
    P, ...
    Cdiseno, ...
    R ...
);

%% ================================================================
% VALIDAR PARÁMETROS FÍSICOS
% ================================================================

reporteFisico = validar_parametros_fisicos(P);

if ~reporteFisico.completo

    fprintf('PARÁMETROS FÍSICOS INVÁLIDOS:\n\n');

    for indice = 1:numel(reporteFisico.faltantes)

        fprintf( ...
            '  Faltante: %s\n', ...
            reporteFisico.faltantes(indice) ...
        );

    end

    for indice = 1:numel(reporteFisico.errores)

        fprintf( ...
            '  Error: %s\n', ...
            reporteFisico.errores(indice) ...
        );

    end

    error( ...
        'simulacion_interactiva_fisica:ParametrosInvalidos', ...
        'El caso real no superó la validación física.' ...
    );

end

%% ================================================================
% CONTROLADORES
% ================================================================

Cactitud = parametros_control_actitud(P);

Ctraslacional = parametros_control_traslacional( ...
    P, ...
    Cactitud ...
);

%% ================================================================
% AJUSTE VERTICAL RÁPIDO
% ================================================================

Ctraslacional.altura.posicion.Kp = ...
    2.00;

Ctraslacional.altura.velocidad.Kp = ...
    3.80;

Ctraslacional.altura.velocidad.Ki = ...
    1.40;

Ctraslacional.altura.limites.toleranciaAltura_m = ...
    0.015;

Ctraslacional.altura.limites.toleranciaVelocidad_m_s = ...
    0.030;

Ctraslacional.altura.limites.velocidadSubidaMax_m_s = ...
    1.60;

Ctraslacional.altura.limites.velocidadBajadaMax_m_s = ...
    1.30;

Ctraslacional.altura.limites.aceleracionSubidaMax_m_s2 = min( ...
    4.00, ...
    0.90 * ...
    Ctraslacional.diagnostico.aceleracionSubidaFisicaMax_m_s2 ...
);

Ctraslacional.altura.limites.aceleracionBajadaMax_m_s2 = min( ...
    3.50, ...
    0.90 * ...
    Ctraslacional.diagnostico.aceleracionBajadaFisicaMax_m_s2 ...
);

memoriaActitud = [];

memoriaTraslacional = [];

%% ================================================================
% PERTURBACIÓN ACTUAL
% ================================================================

% Se conserva la interfaz para conectar posteriormente las
% perturbaciones interactivas.

E = perturbacion_nula();

%% ================================================================
% ESTADO INICIAL
% ================================================================

alturaInicial_m = ...
    1.0;

x = zeros( ...
    modelo.numeroEstados, ...
    1 ...
);

% NED:
%
%   zD negativa = altura positiva.

x(modelo.idx.zD) = ...
    -alturaInicial_m;

%% ================================================================
% FRECUENCIA DE FÍSICA Y CONTROL
% ================================================================

frecuenciaControl_Hz = ...
    100;

dt = ...
    1 / frecuenciaControl_Hz;

%% ================================================================
% FRECUENCIAS DE VISUALIZACIÓN
% ================================================================

frecuenciaGeometria_Hz = ...
    25;

frecuenciaCamara_Hz = ...
    12;

frecuenciaTrayectoria_Hz = ...
    8;

frecuenciaTexto_Hz = ...
    5;

periodoGeometria_s = ...
    1 / frecuenciaGeometria_Hz;

periodoCamara_s = ...
    1 / frecuenciaCamara_Hz;

periodoTrayectoria_s = ...
    1 / frecuenciaTrayectoria_Hz;

periodoTexto_s = ...
    1 / frecuenciaTexto_Hz;

ultimoTiempoGeometria_s = ...
    -inf;

ultimoTiempoCamara_s = ...
    -inf;

ultimoTiempoTrayectoria_s = ...
    -inf;

ultimoTiempoTexto_s = ...
    -inf;

%% ================================================================
% ADMINISTRACIÓN DEL TIEMPO REAL
% ================================================================

tiempoSimulado_s = ...
    0.0;

relojReal = ...
    tic;

tiempoRealAnterior_s = ...
    0.0;

acumuladorTiempo_s = ...
    0.0;

% Permite recuperar un pequeño retraso sin congelar la interfaz.

maximoPasosPorCiclo = ...
    8;

% Cuando MATLAB se atrasa demasiado, el exceso se descarta para
% mantener responsiva la ventana.

retrasoMaximoPermitido_s = ...
    0.10;

%% ================================================================
% SUAVIZADO DE COMANDOS
% ================================================================

% El filtrado evita cambios instantáneos bruscos de -1 a +1 y hace
% que la respuesta visual sea más continua.

constanteTiempoHorizontal_s = ...
    0.055;

constanteTiempoYaw_s = ...
    0.070;

constanteTiempoAlturaManual_s = ...
    0.050;

mandoFiltrado.adelante = ...
    0;

mandoFiltrado.derecha = ...
    0;

mandoFiltrado.altura = ...
    0;

mandoFiltrado.yaw = ...
    0;

%% ================================================================
% MANIOBRAS AUTOMÁTICAS
% ================================================================

toleranciaAlcanceAltura_m = ...
    0.050;

toleranciaAlturaEstable_m = ...
    0.060;

toleranciaVelocidadVertical_m_s = ...
    0.150;

tiempoEstableRequerido_s = ...
    0.12;

tiempoMaximoManiobra_s = ...
    5.00;

resultadoAscenso = ...
    crear_resultado_vacio();

resultadoDescenso = ...
    crear_resultado_vacio();

maniobra = ...
    crear_maniobra_vacia();

ordenAlturaPendiente = ...
    false;

alturaOrdenPendiente_m = ...
    alturaInicial_m;

%% ================================================================
% PROTECCIÓN DE COMANDOS DISCRETOS
% ================================================================

% Ayuda cuando MATLAB pierde el evento de liberación de Shift o
% espacio por carga gráfica.

desbloqueoTeclasPendiente = ...
    false;

instanteDesbloqueoTeclas_s = ...
    inf;

retardoDesbloqueoAuxiliar_s = ...
    0.45;

ultimoComandoDiscreto_s = ...
    -inf;

tiempoAntirreboteDiscreto_s = ...
    0.25;

%% ================================================================
% VISUALIZACIÓN
% ================================================================

visual = crear_visualizacion_dron();

title( ...
    visual.ejes, ...
    'KIWO E88 real V1 — simulación optimizada' ...
);

%% Evitar que los paneles de texto capturen el teclado

camposTexto = {
    'textoEstado'
    'textoManiobra'
    'textoMotores'
    'texto'
};

for indiceTexto = 1:numel(camposTexto)

    nombreCampo = ...
        camposTexto{indiceTexto};

    if isfield(visual, nombreCampo) && ...
            isgraphics(visual.(nombreCampo))

        try

            set( ...
                visual.(nombreCampo), ...
                'Enable', ...
                'inactive' ...
            );

        catch
        end

        try

            set( ...
                visual.(nombreCampo), ...
                'HitTest', ...
                'off' ...
            );

        catch
        end

    end

end

%% Callbacks

set( ...
    visual.figura, ...
    'WindowKeyPressFcn', ...
    @tecla_presionada, ...
    'WindowKeyReleaseFcn', ...
    @tecla_liberada, ...
    'Interruptible', ...
    'on', ...
    'BusyAction', ...
    'queue' ...
);

%% ================================================================
% ESTADO INICIAL DEL TECLADO
% ================================================================

estadoTeclado = ...
    crear_estado_teclado();

estadoTeclado.armado = ...
    true;

estadoTeclado.throttle = ...
    0.50;

setappdata( ...
    visual.figura, ...
    'estadoTeclado', ...
    estadoTeclado ...
);

%% ================================================================
% ENTRADA INICIAL DE MOTORES
% ================================================================

empujeHoverTotal_N = ...
    P.cuerpo.masa * ...
    P.entorno.g;

[U, Dmezclador] = mezclador_motores_x( ...
    empujeHoverTotal_N, ...
    zeros(3, 1), ...
    P ...
);

momentoDeseado_B_Nm = ...
    zeros(3, 1);

%% ================================================================
% SALIDA INICIAL
% ================================================================

salidaTraslacional = struct();

salidaTraslacional.alturaObjetivo_m = ...
    alturaInicial_m;

salidaTraslacional.posicionObjetivo_NE_m = [
    0
    0
];

salidaTraslacional.modoHorizontal = ...
    "MANTENER POSICION";

%% ================================================================
% INFORMACIÓN EN CONSOLA
% ================================================================

fprintf('Caso físico:\n');
fprintf('  %s\n\n', ...
    casoReal.meta.nombre);

fprintf('Masa total:\n');
fprintf('  %.4f kg\n\n', ...
    P.cuerpo.masa);

fprintf('Frecuencias:\n');
fprintf('  Física y control:    %.0f Hz\n', ...
    frecuenciaControl_Hz);

fprintf('  Geometría 3D:        %.0f Hz\n', ...
    frecuenciaGeometria_Hz);

fprintf('  Cámara:              %.0f Hz\n', ...
    frecuenciaCamara_Hz);

fprintf('  Trayectoria:         %.0f Hz\n', ...
    frecuenciaTrayectoria_Hz);

fprintf('  Paneles de texto:    %.0f Hz\n\n', ...
    frecuenciaTexto_Hz);

fprintf('CONTROLES:\n\n');
fprintf('  Flechas: movimiento horizontal\n');
fprintf('  A / D:   yaw\n');
fprintf('  W / S:   altura manual\n');
fprintf('  Shift:   subir 1 metro\n');
fprintf('  Espacio: bajar 1 metro\n');
fprintf('  X:       apagar motores\n');
fprintf('  Enter:   armar motores\n');
fprintf('  R:       reiniciar\n');
fprintf('  Escape:  salir\n\n');

fprintf('Haz clic dentro de la figura.\n\n');

figure(visual.figura);

drawnow;

%% ================================================================
% BUCLE PRINCIPAL
% ================================================================

while isgraphics(visual.figura)

    %% ------------------------------------------------------------
    % PROCESAR EVENTOS UNA SOLA VEZ
    % -------------------------------------------------------------

    drawnow limitrate;

    if ~isgraphics(visual.figura)

        break;

    end

    %% ------------------------------------------------------------
    % RELOJ REAL
    % -------------------------------------------------------------

    tiempoRealActual_s = ...
        toc(relojReal);

    deltaTiempoReal_s = ...
        tiempoRealActual_s - ...
        tiempoRealAnterior_s;

    tiempoRealAnterior_s = ...
        tiempoRealActual_s;

    deltaTiempoReal_s = max( ...
        0, ...
        min(deltaTiempoReal_s, 0.05) ...
    );

    acumuladorTiempo_s = ...
        acumuladorTiempo_s + ...
        deltaTiempoReal_s;

    %% ------------------------------------------------------------
    % DESCARTAR RETRASO EXCESIVO
    % -------------------------------------------------------------

    if acumuladorTiempo_s > ...
            retrasoMaximoPermitido_s

        acumuladorTiempo_s = ...
            retrasoMaximoPermitido_s;

    end

    %% ------------------------------------------------------------
    % DESBLOQUEO AUXILIAR DE SHIFT Y ESPACIO
    % -------------------------------------------------------------

    if desbloqueoTeclasPendiente && ...
            tiempoRealActual_s >= ...
            instanteDesbloqueoTeclas_s

        liberar_bloqueos_altura( ...
            visual.figura ...
        );

        desbloqueoTeclasPendiente = ...
            false;

        instanteDesbloqueoTeclas_s = ...
            inf;

    end

    %% ------------------------------------------------------------
    % LEER TECLADO
    % -------------------------------------------------------------

    comando = leer_comando_teclado( ...
        visual.figura ...
    );

    comando.origen = ...
        "TECLADO + CONTROL EN CASCADA + MODELO REAL";

    %% ------------------------------------------------------------
    % SALIR
    % -------------------------------------------------------------

    if comando.salir

        delete(visual.figura);

        break;

    end

    %% ------------------------------------------------------------
    % REINICIAR
    % -------------------------------------------------------------

    if comando.reset

        x = zeros( ...
            modelo.numeroEstados, ...
            1 ...
        );

        x(modelo.idx.zD) = ...
            -alturaInicial_m;

        memoriaActitud = [];
        memoriaTraslacional = [];

        E = perturbacion_nula();

        tiempoSimulado_s = ...
            0;

        acumuladorTiempo_s = ...
            0;

        relojReal = ...
            tic;

        tiempoRealAnterior_s = ...
            0;

        ultimoTiempoGeometria_s = ...
            -inf;

        ultimoTiempoCamara_s = ...
            -inf;

        ultimoTiempoTrayectoria_s = ...
            -inf;

        ultimoTiempoTexto_s = ...
            -inf;

        mandoFiltrado.adelante = 0;
        mandoFiltrado.derecha = 0;
        mandoFiltrado.altura = 0;
        mandoFiltrado.yaw = 0;

        maniobra = ...
            crear_maniobra_vacia();

        resultadoAscenso = ...
            crear_resultado_vacio();

        resultadoDescenso = ...
            crear_resultado_vacio();

        ordenAlturaPendiente = ...
            false;

        alturaOrdenPendiente_m = ...
            alturaInicial_m;

        desbloqueoTeclasPendiente = ...
            false;

        instanteDesbloqueoTeclas_s = ...
            inf;

        ultimoComandoDiscreto_s = ...
            -inf;

        salidaTraslacional.alturaObjetivo_m = ...
            alturaInicial_m;

        salidaTraslacional.posicionObjetivo_NE_m = [
            0
            0
        ];

        salidaTraslacional.modoHorizontal = ...
            "MANTENER POSICION";

        [U, Dmezclador] = mezclador_motores_x( ...
            empujeHoverTotal_N, ...
            zeros(3, 1), ...
            P ...
        );

        estadoTeclado = ...
            crear_estado_teclado();

        estadoTeclado.armado = ...
            true;

        estadoTeclado.bloqueoR = ...
            true;

        setappdata( ...
            visual.figura, ...
            'estadoTeclado', ...
            estadoTeclado ...
        );

        limpiar_trayectoria( ...
            visual ...
        );

        fprintf('\nSimulación reiniciada.\n\n');

        continue;

    end

    %% ------------------------------------------------------------
    % CANCELAR MANIOBRA AL DESARMAR
    % -------------------------------------------------------------

    if maniobra.activa && ...
            ~comando.armado

        fprintf('\n');
        fprintf('MANIOBRA CANCELADA\n');
        fprintf('  Motivo: motores apagados.\n\n');

        maniobra = ...
            crear_maniobra_vacia();

        ordenAlturaPendiente = ...
            false;

        liberar_bloqueos_altura( ...
            visual.figura ...
        );

    end

    %% ------------------------------------------------------------
    % PROCESAR SHIFT Y ESPACIO
    % -------------------------------------------------------------

    solicitudAscenso = ...
        logical(comando.solicitudSubirUnMetro);

    solicitudDescenso = ...
        logical(comando.solicitudBajarUnMetro);

    existeSolicitudDiscreta = ...
        solicitudAscenso || ...
        solicitudDescenso;

    solicitudFueraDeRebote = ...
        tiempoRealActual_s - ...
        ultimoComandoDiscreto_s >= ...
        tiempoAntirreboteDiscreto_s;

    if existeSolicitudDiscreta && ...
            solicitudFueraDeRebote

        ultimoComandoDiscreto_s = ...
            tiempoRealActual_s;

        desbloqueoTeclasPendiente = ...
            true;

        instanteDesbloqueoTeclas_s = ...
            tiempoRealActual_s + ...
            retardoDesbloqueoAuxiliar_s;

        if solicitudAscenso && ...
                solicitudDescenso

            fprintf('\n');
            fprintf('Shift y espacio se detectaron simultáneamente.\n\n');

        elseif ~comando.armado

            fprintf('\n');
            fprintf('Orden ignorada: el dron está desarmado.\n\n');

        elseif maniobra.activa

            fprintf('\n');
            fprintf('Ya existe una maniobra automática en curso.\n\n');

        else

            alturaActual_m = ...
                -x(modelo.idx.zD);

            if solicitudAscenso

                alturaObjetivo_m = saturar_escalar( ...
                    alturaActual_m + 1.0, ...
                    Ctraslacional.altura.limites.alturaMinima_m, ...
                    Ctraslacional.altura.limites.alturaMaxima_m ...
                );

                cambioSolicitado_m = ...
                    alturaObjetivo_m - ...
                    alturaActual_m;

                if cambioSolicitado_m > 0.02

                    maniobra = iniciar_maniobra( ...
                        "ASCENSO 1 METRO", ...
                        +1, ...
                        tiempoSimulado_s, ...
                        alturaActual_m, ...
                        alturaObjetivo_m ...
                    );

                    ordenAlturaPendiente = ...
                        true;

                    alturaOrdenPendiente_m = ...
                        alturaObjetivo_m;

                    fprintf('\n');
                    fprintf('ASCENSO INICIADO\n');
                    fprintf('  Inicial:  %.3f m\n', ...
                        alturaActual_m);

                    fprintf('  Objetivo: %.3f m\n\n', ...
                        alturaObjetivo_m);

                else

                    fprintf('\n');
                    fprintf('Altura máxima alcanzada.\n\n');

                end

            elseif solicitudDescenso

                alturaObjetivo_m = saturar_escalar( ...
                    alturaActual_m - 1.0, ...
                    Ctraslacional.altura.limites.alturaMinima_m, ...
                    Ctraslacional.altura.limites.alturaMaxima_m ...
                );

                cambioSolicitado_m = ...
                    alturaActual_m - ...
                    alturaObjetivo_m;

                if cambioSolicitado_m > 0.02

                    maniobra = iniciar_maniobra( ...
                        "DESCENSO 1 METRO", ...
                        -1, ...
                        tiempoSimulado_s, ...
                        alturaActual_m, ...
                        alturaObjetivo_m ...
                    );

                    ordenAlturaPendiente = ...
                        true;

                    alturaOrdenPendiente_m = ...
                        alturaObjetivo_m;

                    fprintf('\n');
                    fprintf('DESCENSO INICIADO\n');
                    fprintf('  Inicial:  %.3f m\n', ...
                        alturaActual_m);

                    fprintf('  Objetivo: %.3f m\n\n', ...
                        alturaObjetivo_m);

                else

                    fprintf('\n');
                    fprintf('Altura mínima alcanzada.\n\n');

                end

            end

        end

    end

    %% ============================================================
    % PASOS FÍSICOS
    % ================================================================

    pasosEjecutados = ...
        0;

    while acumuladorTiempo_s >= dt && ...
            pasosEjecutados < maximoPasosPorCiclo

        %% --------------------------------------------------------
        % SUAVIZAR MANDOS
        % ---------------------------------------------------------

        mandoFiltrado.adelante = filtro_primer_orden( ...
            mandoFiltrado.adelante, ...
            comando.mandoAdelante, ...
            constanteTiempoHorizontal_s, ...
            dt ...
        );

        mandoFiltrado.derecha = filtro_primer_orden( ...
            mandoFiltrado.derecha, ...
            comando.mandoDerecha, ...
            constanteTiempoHorizontal_s, ...
            dt ...
        );

        mandoFiltrado.yaw = filtro_primer_orden( ...
            mandoFiltrado.yaw, ...
            comando.mandoYaw, ...
            constanteTiempoYaw_s, ...
            dt ...
        );

        mandoFiltrado.altura = filtro_primer_orden( ...
            mandoFiltrado.altura, ...
            comando.mandoAltura, ...
            constanteTiempoAlturaManual_s, ...
            dt ...
        );

        %% --------------------------------------------------------
        % REFERENCIA UNIVERSAL
        % ---------------------------------------------------------

        referencia = struct();

        referencia.armado = ...
            comando.armado;

        referencia.mandoAdelante = ...
            mandoFiltrado.adelante;

        referencia.mandoDerecha = ...
            mandoFiltrado.derecha;

        referencia.mandoAltura = ...
            mandoFiltrado.altura;

        referencia.mandoYaw = ...
            mandoFiltrado.yaw;

        referencia.fijarAltura = ...
            false;

        referencia.alturaObjetivo_m = ...
            NaN;

        referencia.fijarPosicion = ...
            false;

        referencia.xObjetivo_m = ...
            NaN;

        referencia.yObjetivo_m = ...
            NaN;

        referencia.origen = ...
            comando.origen;

        if maniobra.activa

            referencia.mandoAltura = ...
                0;

            mandoFiltrado.altura = ...
                0;

        end

        if ordenAlturaPendiente

            referencia.fijarAltura = ...
                true;

            referencia.alturaObjetivo_m = ...
                alturaOrdenPendiente_m;

            ordenAlturaPendiente = ...
                false;

        end

        %% --------------------------------------------------------
        % CONTROL TRASLACIONAL
        % ---------------------------------------------------------

        [ ...
            salidaTraslacional, ...
            memoriaTraslacional, ...
            ~ ...
        ] = controlador_traslacional( ...
            referencia, ...
            x, ...
            dt, ...
            P, ...
            Ctraslacional, ...
            Cactitud, ...
            memoriaTraslacional, ...
            modelo ...
        );

        %% --------------------------------------------------------
        % CONTROL DE ACTITUD
        % ---------------------------------------------------------

        [ ...
            momentoDeseado_B_Nm, ...
            memoriaActitud, ...
            ~ ...
        ] = controlador_actitud( ...
            salidaTraslacional.comandoActitud, ...
            x, ...
            dt, ...
            Cactitud, ...
            memoriaActitud, ...
            modelo ...
        );

        %% --------------------------------------------------------
        % MOTORES
        % ---------------------------------------------------------

        if comando.armado

            [U, Dmezclador] = mezclador_motores_x( ...
                salidaTraslacional.empujeTotal_N, ...
                momentoDeseado_B_Nm, ...
                P ...
            );

        else

            U = crear_entrada_actuadores(P);

            Dmezclador = struct();

            Dmezclador.huboSaturacion = ...
                false;

            Dmezclador.empujeReal_N = ...
                0;

            Dmezclador.momentoReal_B_Nm = ...
                zeros(3, 1);

        end

        %% --------------------------------------------------------
        % ESTADÍSTICAS DE MANIOBRA
        % ---------------------------------------------------------

        if maniobra.activa && ...
                comando.armado

            maniobra = acumular_empuje_maniobra( ...
                maniobra, ...
                sum(U.empujeMotores_N) ...
            );

        end

        %% --------------------------------------------------------
        % INTEGRACIÓN
        % ---------------------------------------------------------

        x = paso_rk4( ...
            @modelo_no_lineal_12_estados, ...
            tiempoSimulado_s, ...
            x, ...
            dt, ...
            U, ...
            E, ...
            P, ...
            modelo ...
        );

        tiempoSimulado_s = ...
            tiempoSimulado_s + dt;

        %% Normalizar yaw

        x(modelo.idx.psi) = atan2( ...
            sin(x(modelo.idx.psi)), ...
            cos(x(modelo.idx.psi)) ...
        );

        %% --------------------------------------------------------
        % COLISIÓN CON EL PISO
        % ---------------------------------------------------------

        if x(modelo.idx.zD) > 0

            x(modelo.idx.zD) = ...
                0;

            x([
                modelo.idx.u
                modelo.idx.v
                modelo.idx.w
            ]) = ...
                0;

            x([
                modelo.idx.p
                modelo.idx.q
                modelo.idx.r
            ]) = ...
                0;

            x(modelo.idx.phi) = ...
                0;

            x(modelo.idx.theta) = ...
                0;

            memoriaActitud = [];

        end

        %% --------------------------------------------------------
        % VALIDACIÓN NUMÉRICA
        % ---------------------------------------------------------

        if any(~isfinite(x))

            error( ...
                'simulacion_interactiva_fisica:EstadoNoFinito', ...
                'El modelo produjo NaN o valores infinitos.' ...
            );

        end

        %% --------------------------------------------------------
        % EVALUAR MANIOBRA
        % ---------------------------------------------------------

        if maniobra.activa && ...
                comando.armado

            alturaActual_m = ...
                -x(modelo.idx.zD);

            Kactual = cinematica_6dof( ...
                x, ...
                modelo ...
            );

            velocidadUpActual_m_s = ...
                -Kactual.posicionDot_N(3);

            errorAltura_m = ...
                maniobra.alturaObjetivo_m - ...
                alturaActual_m;

            dentroBandaAlcance = ...
                abs(errorAltura_m) <= ...
                toleranciaAlcanceAltura_m;

            if ~maniobra.objetivoAlcanzado && ...
                    dentroBandaAlcance

                maniobra.objetivoAlcanzado = ...
                    true;

                maniobra.tiempoAlcance_s = ...
                    tiempoSimulado_s - ...
                    maniobra.tiempoInicio_s;

            end

            dentroBandaAltura = ...
                abs(errorAltura_m) <= ...
                toleranciaAlturaEstable_m;

            dentroBandaVelocidad = ...
                abs(velocidadUpActual_m_s) <= ...
                toleranciaVelocidadVertical_m_s;

            if dentroBandaAltura && ...
                    dentroBandaVelocidad

                maniobra.tiempoEstable_s = ...
                    maniobra.tiempoEstable_s + dt;

            else

                maniobra.tiempoEstable_s = ...
                    0;

            end

            tiempoTotalManiobra_s = ...
                tiempoSimulado_s - ...
                maniobra.tiempoInicio_s;

            maniobraCompletada = ...
                maniobra.tiempoEstable_s >= ...
                tiempoEstableRequerido_s;

            maniobraExpirada = ...
                tiempoTotalManiobra_s >= ...
                tiempoMaximoManiobra_s;

            if maniobraCompletada

                resultadoManiobra = finalizar_maniobra( ...
                    maniobra, ...
                    tiempoSimulado_s, ...
                    alturaActual_m, ...
                    P.motores.numero ...
                );

                if maniobra.direccion > 0

                    resultadoAscenso = ...
                        resultadoManiobra;

                    imprimir_resultado_maniobra( ...
                        'ASCENSO COMPLETADO', ...
                        resultadoAscenso ...
                    );

                else

                    resultadoDescenso = ...
                        resultadoManiobra;

                    imprimir_resultado_maniobra( ...
                        'DESCENSO COMPLETADO', ...
                        resultadoDescenso ...
                    );

                end

                maniobra = ...
                    crear_maniobra_vacia();

                liberar_bloqueos_altura( ...
                    visual.figura ...
                );

                ultimoComandoDiscreto_s = ...
                    tiempoRealActual_s;

            elseif maniobraExpirada

                fprintf('\n');
                fprintf('MANIOBRA CANCELADA POR TIEMPO MÁXIMO\n');
                fprintf('  Tipo:      %s\n', ...
                    char(maniobra.tipo));

                fprintf('  Altura:    %.3f m\n', ...
                    alturaActual_m);

                fprintf('  Objetivo:  %.3f m\n', ...
                    maniobra.alturaObjetivo_m);

                fprintf('  Error:     %+.3f m\n\n', ...
                    errorAltura_m);

                maniobra = ...
                    crear_maniobra_vacia();

                liberar_bloqueos_altura( ...
                    visual.figura ...
                );

            end

        end

        %% --------------------------------------------------------
        % AVANZAR RELOJ FIJO
        % ---------------------------------------------------------

        acumuladorTiempo_s = ...
            acumuladorTiempo_s - dt;

        pasosEjecutados = ...
            pasosEjecutados + 1;

    end

    %% ============================================================
    % ACTUALIZACIÓN GRÁFICA MULTIRRITMO
    % ================================================================

    actualizarGeometriaAhora = ...
        tiempoRealActual_s - ...
        ultimoTiempoGeometria_s >= ...
        periodoGeometria_s;

    actualizarCamaraAhora = ...
        tiempoRealActual_s - ...
        ultimoTiempoCamara_s >= ...
        periodoCamara_s;

    actualizarTrayectoriaAhora = ...
        tiempoRealActual_s - ...
        ultimoTiempoTrayectoria_s >= ...
        periodoTrayectoria_s;

    actualizarTextoAhora = ...
        tiempoRealActual_s - ...
        ultimoTiempoTexto_s >= ...
        periodoTexto_s;

    actualizarAlgo = ...
        actualizarGeometriaAhora || ...
        actualizarCamaraAhora || ...
        actualizarTrayectoriaAhora || ...
        actualizarTextoAhora;

    if actualizarAlgo

        Kvisual = cinematica_6dof( ...
            x, ...
            modelo ...
        );

        datosVisuales = struct();

        datosVisuales.actualizarGeometria = ...
            actualizarGeometriaAhora;

        datosVisuales.actualizarCamara = ...
            actualizarCamaraAhora;

        datosVisuales.actualizarTrayectoria = ...
            actualizarTrayectoriaAhora;

        datosVisuales.actualizarPiso = ...
            false;

        datosVisuales.actualizarTexto = ...
            actualizarTextoAhora;

        datosVisuales.alturaObjetivo_m = ...
            salidaTraslacional.alturaObjetivo_m;

        datosVisuales.modoHorizontal = ...
            salidaTraslacional.modoHorizontal;

        datosVisuales.velocidadUp_m_s = ...
            -Kvisual.posicionDot_N(3);

        datosVisuales.empujeMotores_N = ...
            U.empujeMotores_N;

        datosVisuales.empujeTotal_N = ...
            sum(U.empujeMotores_N);

        datosVisuales.empujeHoverTotal_N = ...
            empujeHoverTotal_N;

        datosVisuales.saturacionMotores = ...
            Dmezclador.huboSaturacion;

        datosVisuales.maniobra.activa = ...
            maniobra.activa;

        datosVisuales.maniobra.tipo = ...
            maniobra.tipo;

        if maniobra.activa

            datosVisuales.maniobra.tiempoTranscurrido_s = ...
                tiempoSimulado_s - ...
                maniobra.tiempoInicio_s;

        else

            datosVisuales.maniobra.tiempoTranscurrido_s = ...
                0;

        end

        datosVisuales.maniobra.alturaInicial_m = ...
            maniobra.alturaInicial_m;

        datosVisuales.maniobra.alturaObjetivo_m = ...
            maniobra.alturaObjetivo_m;

        datosVisuales.resultadoAscenso = ...
            resultadoAscenso;

        datosVisuales.resultadoDescenso = ...
            resultadoDescenso;

        actualizar_visualizacion_dron( ...
            visual, ...
            x, ...
            comando, ...
            tiempoSimulado_s, ...
            datosVisuales ...
        );

        if actualizarGeometriaAhora

            ultimoTiempoGeometria_s = ...
                tiempoRealActual_s;

        end

        if actualizarCamaraAhora

            ultimoTiempoCamara_s = ...
                tiempoRealActual_s;

        end

        if actualizarTrayectoriaAhora

            ultimoTiempoTrayectoria_s = ...
                tiempoRealActual_s;

        end

        if actualizarTextoAhora

            ultimoTiempoTexto_s = ...
                tiempoRealActual_s;

        end

    end

    pause(0.001);

end

fprintf('\nSimulación finalizada.\n');


%% =================================================================
% FUNCIONES LOCALES
% =================================================================

function resultado = crear_resultado_vacio()

    resultado = struct();

    resultado.completado = false;
    resultado.tiempo_s = NaN;
    resultado.alturaInicial_m = NaN;
    resultado.alturaFinal_m = NaN;
    resultado.empujeTotalPromedio_N = NaN;
    resultado.empujePromedioMotor_N = NaN;
    resultado.empujeTotalMaximo_N = NaN;
    resultado.empujeTotalMinimo_N = NaN;

end


function maniobra = crear_maniobra_vacia()

    maniobra = struct();

    maniobra.activa = false;
    maniobra.tipo = "NINGUNA";
    maniobra.direccion = 0;
    maniobra.tiempoInicio_s = 0;
    maniobra.tiempoEstable_s = 0;
    maniobra.objetivoAlcanzado = false;
    maniobra.tiempoAlcance_s = NaN;
    maniobra.alturaInicial_m = 0;
    maniobra.alturaObjetivo_m = 0;
    maniobra.sumaEmpujeTotal_N = 0;
    maniobra.numeroMuestras = 0;
    maniobra.empujeTotalMaximo_N = -inf;
    maniobra.empujeTotalMinimo_N = inf;

end


function maniobra = iniciar_maniobra( ...
    tipo, ...
    direccion, ...
    tiempoInicio_s, ...
    alturaInicial_m, ...
    alturaObjetivo_m ...
)

    maniobra = ...
        crear_maniobra_vacia();

    maniobra.activa = true;
    maniobra.tipo = string(tipo);
    maniobra.direccion = direccion;
    maniobra.tiempoInicio_s = tiempoInicio_s;
    maniobra.alturaInicial_m = alturaInicial_m;
    maniobra.alturaObjetivo_m = alturaObjetivo_m;

end


function maniobra = acumular_empuje_maniobra( ...
    maniobra, ...
    empujeTotal_N ...
)

    if ~isscalar(empujeTotal_N) || ...
            ~isfinite(empujeTotal_N)

        return;

    end

    maniobra.sumaEmpujeTotal_N = ...
        maniobra.sumaEmpujeTotal_N + ...
        empujeTotal_N;

    maniobra.numeroMuestras = ...
        maniobra.numeroMuestras + 1;

    maniobra.empujeTotalMaximo_N = max( ...
        maniobra.empujeTotalMaximo_N, ...
        empujeTotal_N ...
    );

    maniobra.empujeTotalMinimo_N = min( ...
        maniobra.empujeTotalMinimo_N, ...
        empujeTotal_N ...
    );

end


function resultado = finalizar_maniobra( ...
    maniobra, ...
    tiempoFinal_s, ...
    alturaFinal_m, ...
    numeroMotores ...
)

    resultado = ...
        crear_resultado_vacio();

    resultado.completado = ...
        true;

    if isfinite(maniobra.tiempoAlcance_s)

        resultado.tiempo_s = ...
            max(0, maniobra.tiempoAlcance_s);

    else

        resultado.tiempo_s = max( ...
            0, ...
            tiempoFinal_s - ...
            maniobra.tiempoInicio_s ...
        );

    end

    resultado.alturaInicial_m = ...
        maniobra.alturaInicial_m;

    resultado.alturaFinal_m = ...
        alturaFinal_m;

    if maniobra.numeroMuestras > 0

        resultado.empujeTotalPromedio_N = ...
            maniobra.sumaEmpujeTotal_N / ...
            maniobra.numeroMuestras;

        resultado.empujePromedioMotor_N = ...
            resultado.empujeTotalPromedio_N / ...
            numeroMotores;

        resultado.empujeTotalMaximo_N = ...
            maniobra.empujeTotalMaximo_N;

        resultado.empujeTotalMinimo_N = ...
            maniobra.empujeTotalMinimo_N;

    else

        resultado.empujeTotalPromedio_N = 0;
        resultado.empujePromedioMotor_N = 0;
        resultado.empujeTotalMaximo_N = 0;
        resultado.empujeTotalMinimo_N = 0;

    end

end


function imprimir_resultado_maniobra( ...
    titulo, ...
    resultado ...
)

    fprintf('\n');
    fprintf('%s\n', titulo);

    fprintf('  Tiempo para alcanzar:  %.3f s\n', ...
        resultado.tiempo_s);

    fprintf('  Altura inicial:        %.3f m\n', ...
        resultado.alturaInicial_m);

    fprintf('  Altura final:          %.3f m\n', ...
        resultado.alturaFinal_m);

    fprintf('  Cambio real:           %+.3f m\n', ...
        resultado.alturaFinal_m - ...
        resultado.alturaInicial_m);

    fprintf('  Empuje promedio total: %.4f N\n', ...
        resultado.empujeTotalPromedio_N);

    fprintf('  Empuje promedio motor: %.4f N\n', ...
        resultado.empujePromedioMotor_N);

    fprintf('  Empuje máximo total:   %.4f N\n', ...
        resultado.empujeTotalMaximo_N);

    fprintf('  Empuje mínimo total:   %.4f N\n\n', ...
        resultado.empujeTotalMinimo_N);

end


function valorFiltrado = filtro_primer_orden( ...
    valorAnterior, ...
    valorObjetivo, ...
    constanteTiempo_s, ...
    dt ...
)

    if constanteTiempo_s <= 0

        valorFiltrado = ...
            valorObjetivo;

        return;

    end

    alpha = ...
        dt / ...
        (constanteTiempo_s + dt);

    valorFiltrado = ...
        valorAnterior + ...
        alpha * ...
        (valorObjetivo - valorAnterior);

end


function valorSaturado = saturar_escalar( ...
    valor, ...
    limiteInferior, ...
    limiteSuperior ...
)

    valorSaturado = max( ...
        limiteInferior, ...
        min(limiteSuperior, valor) ...
    );

end


function liberar_bloqueos_altura(figura)

    if ~isgraphics(figura, 'figure') || ...
            ~isappdata(figura, 'estadoTeclado')

        return;

    end

    estadoTeclado = getappdata( ...
        figura, ...
        'estadoTeclado' ...
    );

    if isfield(estadoTeclado, 'bloqueoShift')

        estadoTeclado.bloqueoShift = ...
            false;

    end

    if isfield(estadoTeclado, 'bloqueoEspacio')

        estadoTeclado.bloqueoEspacio = ...
            false;

    end

    estadoTeclado.solicitudSubirUnMetro = ...
        false;

    estadoTeclado.solicitudBajarUnMetro = ...
        false;

    setappdata( ...
        figura, ...
        'estadoTeclado', ...
        estadoTeclado ...
    );

end


function limpiar_trayectoria(visual)

    if ~isstruct(visual) || ...
            ~isfield(visual, 'figura') || ...
            ~isgraphics(visual.figura, 'figure')

        return;

    end

    if isfield(visual, 'trayectoria') && ...
            isgraphics(visual.trayectoria)

        set( ...
            visual.trayectoria, ...
            'XData', ...
            NaN, ...
            'YData', ...
            NaN, ...
            'ZData', ...
            NaN ...
        );

    end

    setappdata( ...
        visual.figura, ...
        'trayectoriaX', ...
        [] ...
    );

    setappdata( ...
        visual.figura, ...
        'trayectoriaY', ...
        [] ...
    );

    setappdata( ...
        visual.figura, ...
        'trayectoriaZ', ...
        [] ...
    );

    if isappdata(visual.figura, 'ultimaPosicionCamara')

        rmappdata( ...
            visual.figura, ...
            'ultimaPosicionCamara' ...
        );

    end

    if isappdata(visual.figura, 'ultimoCentroPiso')

        rmappdata( ...
            visual.figura, ...
            'ultimoCentroPiso' ...
        );

    end

end