%% SIMULACION_INTERACTIVA_FISICA
% Gemelo virtual interactivo con:
%
% Teclado -> controlador -> mezclador -> modelo 12 estados
%          -> RK4 -> visualizacion 3D
%
% Controles:
%   W / S              Subir / bajar
%   Flechas laterales  Roll
%   Flechas verticales Pitch
%   A / D              Yaw
%   Espacio            Armar / desarmar
%   R                  Reiniciar
%   Escape             Salir

clearvars;
clc;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' SIMULACION INTERACTIVA FISICA DEL DRON\n');
fprintf('============================================================\n\n');

%% ================================================================
% PREPARAR MODELO
% ================================================================

modelo = definicion_modelo();

P = parametros_fisicos();
R = reglas_competencia();
Dproyecto = requisitos_proyecto(R);
Cdiseno = parametros_diseno();

[P, Cdiseno, ~] = caso_base_teorico( ...
    P, ...
    Cdiseno, ...
    R ...
);

G = configuracion_motores_x( ...
    R, ...
    Dproyecto, ...
    Cdiseno.geometria.distanciaCentroMotor, ...
    Cdiseno.geometria.zMotor_B ...
);

P = aplicar_configuracion_motores(P, G);

%% Controlador de actitud

Ccontrol = parametros_control_actitud(P);

estadoControl = [];

%% Perturbaciones externas

E = perturbacion_nula();

%% ================================================================
% VISUALIZACION
% ================================================================

visual = crear_visualizacion_dron();

title( ...
    visual.ejes, ...
    'Gemelo virtual con dinámica física y control' ...
);

% Evitar que el panel capture el teclado.
set( ...
    visual.texto, ...
    'Enable', 'inactive', ...
    'HitTest', 'off' ...
);

% Callbacks de teclado.
set( ...
    visual.figura, ...
    'WindowKeyPressFcn', @tecla_presionada, ...
    'WindowKeyReleaseFcn', @tecla_liberada, ...
    'Interruptible', 'on', ...
    'BusyAction', 'queue' ...
);

%% Estado inicial del teclado

estadoTeclado = crear_estado_teclado();

estadoTeclado.armado = true;
estadoTeclado.throttle = 0.50;

setappdata( ...
    visual.figura, ...
    'estadoTeclado', ...
    estadoTeclado ...
);

%% ================================================================
% ESTADO INICIAL DEL DRON
% ================================================================

x = zeros(modelo.numeroEstados, 1);

% Un metro arriba del suelo.
x(modelo.idx.zD) = -1.0;

%% ================================================================
% CONFIGURACION TEMPORAL
% ================================================================

% Modelo físico a 100 Hz.
dt = 0.01;

% Dibujo aproximadamente a 30 FPS.
periodoVisualizacion = 1 / 30;

% Máximo de pasos para recuperar retrasos.
maximoPasosPorCiclo = 5;

tiempoSimulado = 0.0;

relojReal = tic;
tiempoRealAnterior = 0.0;
ultimoTiempoVisualizado = -inf;
acumuladorTiempo = 0.0;

%% ================================================================
% CONTROL VERTICAL PROVISIONAL
% ================================================================

% Velocidades positivas en NED apuntan hacia abajo.
%
% W:
%   velocidad Down negativa -> subir.
%
% S:
%   velocidad Down positiva -> bajar.

velocidadSubida_D_m_s = -1.20;
velocidadHover_D_m_s = 0.0;
velocidadBajada_D_m_s = 1.00;

% Ganancia del controlador de velocidad vertical.
gananciaVelocidadVertical = 2.5;

% Limita la aceleración vertical solicitada.
aceleracionVerticalMaxima = 4.0;

%% Información

fprintf('Masa:                 %.4f kg\n', ...
    P.cuerpo.masa);

fprintf('Empuje de hover:      %.4f N\n', ...
    P.cuerpo.masa * P.entorno.g);

fprintf('Empuje por motor:     %.4f N\n\n', ...
    P.cuerpo.masa * P.entorno.g / P.motores.numero);

fprintf('La simulacion comienza ARMADA.\n');
fprintf('Haz clic dentro de la figura antes de usar el teclado.\n\n');

fprintf('W / S:      subir y bajar\n');
fprintf('Flechas:    roll y pitch\n');
fprintf('A / D:      yaw\n');
fprintf('Espacio:    armar o desarmar\n');
fprintf('R:          reiniciar\n');
fprintf('Escape:     salir\n\n');

%% Mostrar figura y darle prioridad

figure(visual.figura);
drawnow;

%% Entrada inicial

U = crear_entrada_actuadores(P);

momentoDeseado_B_Nm = zeros(3, 1);

%% ================================================================
% BUCLE PRINCIPAL
% ================================================================

while isgraphics(visual.figura)

    %% Procesar inmediatamente callbacks

    drawnow;

    if ~isgraphics(visual.figura)
        break;
    end

    %% Tiempo real

    tiempoRealActual = toc(relojReal);

    deltaTiempoReal = ...
        tiempoRealActual - tiempoRealAnterior;

    tiempoRealAnterior = tiempoRealActual;

    % Evitar saltos grandes.
    deltaTiempoReal = max( ...
        0.0, ...
        min(deltaTiempoReal, 0.05) ...
    );

    acumuladorTiempo = ...
        acumuladorTiempo + deltaTiempoReal;

    %% Leer teclado

    estadoTeclado = getappdata( ...
        visual.figura, ...
        'estadoTeclado' ...
    );

    % Valores utilizados solamente para el dashboard.
    if estadoTeclado.subirThrottle && ...
            ~estadoTeclado.bajarThrottle

        estadoTeclado.throttle = 0.75;

    elseif estadoTeclado.bajarThrottle && ...
            ~estadoTeclado.subirThrottle

        estadoTeclado.throttle = 0.25;

    else

        estadoTeclado.throttle = 0.50;

    end

    setappdata( ...
        visual.figura, ...
        'estadoTeclado', ...
        estadoTeclado ...
    );

    comando = leer_comando_teclado( ...
        visual.figura ...
    );

    comando.origen = ...
        'TECLADO + PID + MODELO FISICO';

    %% Salir

    if comando.salir

        delete(visual.figura);
        break;

    end

    %% Reiniciar

    if comando.reset

        x = zeros(modelo.numeroEstados, 1);

        x(modelo.idx.zD) = -1.0;

        tiempoSimulado = 0.0;
        acumuladorTiempo = 0.0;

        estadoControl = [];

        E = perturbacion_nula();

        U = crear_entrada_actuadores(P);

        momentoDeseado_B_Nm = zeros(3, 1);

        estadoTeclado = crear_estado_teclado();

        estadoTeclado.armado = true;
        estadoTeclado.throttle = 0.50;

        % Evita múltiples reinicios mientras R sigue presionada.
        estadoTeclado.bloqueoR = true;
        estadoTeclado.resetSolicitado = false;

        setappdata( ...
            visual.figura, ...
            'estadoTeclado', ...
            estadoTeclado ...
        );

        set( ...
            visual.trayectoria, ...
            'XData', NaN, ...
            'YData', NaN, ...
            'ZData', NaN ...
        );

        comando = leer_comando_teclado( ...
            visual.figura ...
        );

        comando.origen = ...
            'TECLADO + PID + MODELO FISICO';

    end

    %% ============================================================
    % INTEGRACION FISICA
    % =============================================================

    pasosEjecutados = 0;

    while acumuladorTiempo >= dt && ...
            pasosEjecutados < maximoPasosPorCiclo

        %% Control de actitud

        [ ...
            momentoDeseado_B_Nm, ...
            estadoControl, ...
            ~ ...
        ] = controlador_actitud( ...
            comando, ...
            x, ...
            dt, ...
            Ccontrol, ...
            estadoControl, ...
            modelo ...
        );

        %% Motores armados

        if comando.armado

            masa = P.cuerpo.masa;
            g = P.entorno.g;

            phi = x(modelo.idx.phi);
            theta = x(modelo.idx.theta);

            %% Velocidad vertical real en el marco NED

            K = cinematica_6dof( ...
                x, ...
                modelo ...
            );

            velocidadDownActual_m_s = ...
                K.posicionDot_N(3);

            %% Referencia de velocidad vertical

            if comando.subirThrottle && ...
                    ~comando.bajarThrottle

                velocidadDownReferencia_m_s = ...
                    velocidadSubida_D_m_s;

            elseif comando.bajarThrottle && ...
                    ~comando.subirThrottle

                velocidadDownReferencia_m_s = ...
                    velocidadBajada_D_m_s;

            else

                velocidadDownReferencia_m_s = ...
                    velocidadHover_D_m_s;

            end

            %% Control de velocidad vertical

            errorVelocidadDown = ...
                velocidadDownReferencia_m_s - ...
                velocidadDownActual_m_s;

            aceleracionDownDeseada_m_s2 = ...
                gananciaVelocidadVertical * ...
                errorVelocidadDown;

            aceleracionDownDeseada_m_s2 = max( ...
                -aceleracionVerticalMaxima, ...
                min( ...
                    aceleracionVerticalMaxima, ...
                    aceleracionDownDeseada_m_s2 ...
                ) ...
            );

            %% Componente vertical del empuje

            % En NED:
            %
            % a_D = g - T_vertical / m
            %
            % Por tanto:
            %
            % T_vertical = m * (g - a_D_deseada)

            empujeVerticalDeseado_N = ...
                masa * ...
                (g - aceleracionDownDeseada_m_s2);

            empujeVerticalDeseado_N = max( ...
                0.0, ...
                empujeVerticalDeseado_N ...
            );

            %% Compensar inclinación

            factorVertical = ...
                cos(phi) * cos(theta);

            factorVertical = max( ...
                factorVertical, ...
                0.50 ...
            );

            empujeTotal_N = ...
                empujeVerticalDeseado_N / ...
                factorVertical;

            %% Mezclador

            [U, ~] = mezclador_motores_x( ...
                empujeTotal_N, ...
                momentoDeseado_B_Nm, ...
                P ...
            );

        else

            %% Motores apagados

            U = crear_entrada_actuadores(P);

            estadoControl = [];

        end

        %% Integrar las doce ecuaciones

        x = paso_rk4( ...
            @modelo_no_lineal_12_estados, ...
            tiempoSimulado, ...
            x, ...
            dt, ...
            U, ...
            E, ...
            P, ...
            modelo ...
        );

        tiempoSimulado = ...
            tiempoSimulado + dt;

        %% Limitar yaw a -pi y pi

        x(modelo.idx.psi) = atan2( ...
            sin(x(modelo.idx.psi)), ...
            cos(x(modelo.idx.psi)) ...
        );

        %% Colisión sencilla con el piso

        if x(modelo.idx.zD) > 0.0

            x(modelo.idx.zD) = 0.0;

            x([
                modelo.idx.u
                modelo.idx.v
                modelo.idx.w
            ]) = 0.0;

            x([
                modelo.idx.p
                modelo.idx.q
                modelo.idx.r
            ]) = 0.0;

            x(modelo.idx.phi) = 0.0;
            x(modelo.idx.theta) = 0.0;

            estadoControl = [];

        end

        %% Validación numérica

        if any(~isfinite(x))

            error( ...
                'simulacion_interactiva_fisica:EstadoNoFinito', ...
                'El modelo produjo NaN o valores infinitos.' ...
            );

        end

        acumuladorTiempo = ...
            acumuladorTiempo - dt;

        pasosEjecutados = ...
            pasosEjecutados + 1;

    end

    %% Evitar acumular retraso indefinidamente

    if pasosEjecutados >= maximoPasosPorCiclo && ...
            acumuladorTiempo >= dt

        acumuladorTiempo = ...
            mod(acumuladorTiempo, dt);

    end

    %% Actualizar dibujo

    if tiempoRealActual - ultimoTiempoVisualizado >= ...
            periodoVisualizacion

        actualizar_visualizacion_dron( ...
            visual, ...
            x, ...
            comando, ...
            tiempoSimulado ...
        );

        ultimoTiempoVisualizado = ...
            tiempoRealActual;

    end

    pause(0.001);

end

fprintf('\nSimulacion finalizada.\n');