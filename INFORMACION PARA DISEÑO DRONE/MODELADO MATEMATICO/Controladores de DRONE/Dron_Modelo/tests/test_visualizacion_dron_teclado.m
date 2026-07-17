%% TEST_VISUALIZACION_DRON_TECLADO
% Prueba interactiva del dibujo tridimensional del dron.
%
% Esta prueba todavía NO utiliza:
%   - PID
%   - Dinámica real
%   - Fuerzas físicas
%
% Su objetivo es validar:
%   - Teclado
%   - Movimiento visual
%   - Orientación
%   - Trayectoria
%   - Dashboard

clearvars;
clc;
close all;

%% Crear visualización

visual = crear_visualizacion_dron();

%% Evitar que el panel de texto tome el foco

set(visual.texto, 'Enable', 'inactive');

%% Asignar callbacks del teclado

set( ...
    visual.figura, ...
    'WindowKeyPressFcn', @tecla_presionada, ...
    'WindowKeyReleaseFcn', @tecla_liberada ...
);

%% Crear estado inicial del teclado

estadoTeclado = crear_estado_teclado();

% Para esta prueba inicia armado.
estadoTeclado.armado = true;

% 0.50 es el throttle neutro.
estadoTeclado.throttle = 0.50;

setappdata( ...
    visual.figura, ...
    'estadoTeclado', ...
    estadoTeclado ...
);

%% Vector de doce estados

estado = zeros(12, 1);

% Iniciar a un metro de altura.
% En NED, un metro arriba equivale a zD = -1.
estado(3) = -1.0;

%% Parámetros de movimiento visual

anguloMaximo = deg2rad(25);

velocidadYawMaxima = deg2rad(80);

velocidadHorizontalMaxima = 2.0;

velocidadVerticalMaxima = 3.0;

% Suavizado visual de roll y pitch.
constanteSuavizado = 0.12;

%% Tiempo

tiempoSimulado = 0;

relojPaso = tic;

%% Mostrar ventana al frente

figure(visual.figura);

drawnow;

%% Bucle principal

while isgraphics(visual.figura)

    %% Calcular tiempo transcurrido

    dt = toc(relojPaso);
    relojPaso = tic;

    % Limitar el paso para evitar saltos grandes.
    dt = max(dt, 0.001);
    dt = min(dt, 0.05);

    tiempoSimulado = tiempoSimulado + dt;

    %% Leer estado interno del teclado

    estadoTeclado = getappdata( ...
        visual.figura, ...
        'estadoTeclado' ...
    );

%% Actualizar throttle momentáneo

if estadoTeclado.subirThrottle && ...
        ~estadoTeclado.bajarThrottle

    % Mientras se mantiene W, el dron sube.
    estadoTeclado.throttle = 0.80;

elseif estadoTeclado.bajarThrottle && ...
        ~estadoTeclado.subirThrottle

    % Mientras se mantiene S, el dron baja.
    estadoTeclado.throttle = 0.20;

else

    % Al soltar W o S, regresar inmediatamente al hover.
    estadoTeclado.throttle = 0.50;

end

setappdata( ...
    visual.figura, ...
    'estadoTeclado', ...
    estadoTeclado ...
);
    %% Crear comando normalizado

    comando = leer_comando_teclado(visual.figura);

    %% Salir

    if comando.salir

        delete(visual.figura);
        break;

    end

    %% Reiniciar simulación

    if comando.reset

        estado = zeros(12, 1);
        estado(3) = -1.0;

        tiempoSimulado = 0;

        estadoTeclado = getappdata( ...
            visual.figura, ...
            'estadoTeclado' ...
        );

        estadoTeclado.throttle = 0.50;

        estadoTeclado.subirThrottle = false;
        estadoTeclado.bajarThrottle = false;

        estadoTeclado.rollIzquierda = false;
        estadoTeclado.rollDerecha = false;

        estadoTeclado.pitchAdelante = false;
        estadoTeclado.pitchAtras = false;

        estadoTeclado.yawIzquierda = false;
        estadoTeclado.yawDerecha = false;

        estadoTeclado.resetSolicitado = false;

        % Mantener armado después del reinicio.
        estadoTeclado.armado = true;

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

        comando = leer_comando_teclado(visual.figura);

    end

    %% Guardar orientación anterior

    phiAnterior = estado(7);
    thetaAnterior = estado(8);

    %% Movimiento

    if comando.armado

        %% Referencias visuales

        % Roll positivo: inclinarse hacia la derecha.
        phiReferencia = ...
            comando.roll * anguloMaximo;

        % Comando positivo significa avanzar.
        % Físicamente avanzar requiere pitch negativo:
        % nariz hacia abajo.
        thetaReferencia = ...
            -comando.pitch * anguloMaximo;

        %% Suavizado de orientación

        factorSuavizado = ...
            1 - exp(-dt / constanteSuavizado);

        estado(7) = estado(7) + ...
            factorSuavizado * ...
            (phiReferencia - estado(7));

        estado(8) = estado(8) + ...
            factorSuavizado * ...
            (thetaReferencia - estado(8));

        %% Yaw

        estado(12) = ...
            comando.yaw * velocidadYawMaxima;

        estado(9) = estado(9) + ...
            estado(12) * dt;

        estado(9) = atan2( ...
            sin(estado(9)), ...
            cos(estado(9)) ...
        );

        %% Velocidades corporales visuales

        velocidadFrontal = ...
            comando.pitch * velocidadHorizontalMaxima;

        velocidadDerecha = ...
            comando.roll * velocidadHorizontalMaxima;

        velocidadDown = ...
            -(comando.throttle - 0.50) * ...
            velocidadVerticalMaxima;

        %% Convertir movimiento horizontal al mundo

        psi = estado(9);

        velocidadNorte = ...
            cos(psi) * velocidadFrontal - ...
            sin(psi) * velocidadDerecha;

        velocidadEste = ...
            sin(psi) * velocidadFrontal + ...
            cos(psi) * velocidadDerecha;

        %% Integrar posición

        estado(1) = estado(1) + ...
            velocidadNorte * dt;

        estado(2) = estado(2) + ...
            velocidadEste * dt;

        estado(3) = estado(3) + ...
            velocidadDown * dt;

        %% Guardar velocidades corporales aproximadas

        estado(4) = velocidadFrontal;
        estado(5) = velocidadDerecha;
        estado(6) = velocidadDown;

    else

        %% Cuando está desarmado no se desplaza

        factorSuavizado = ...
            1 - exp(-dt / constanteSuavizado);

        estado(7) = estado(7) + ...
            factorSuavizado * ...
            (0 - estado(7));

        estado(8) = estado(8) + ...
            factorSuavizado * ...
            (0 - estado(8));

        estado(4:6) = 0;
        estado(12) = 0;

    end

    %% Calcular velocidades angulares aproximadas

    estado(10) = ...
        (estado(7) - phiAnterior) / dt;

    estado(11) = ...
        (estado(8) - thetaAnterior) / dt;

    %% Colisión provisional con el piso

    % No permitir que el dron atraviese el suelo.
    % No existen límites horizontales ni altura máxima.
    estado(3) = min(estado(3), 0.0);
    %% Actualizar visualización

    actualizar_visualizacion_dron( ...
        visual, ...
        estado, ...
        comando, ...
        tiempoSimulado ...
    );

    %% Procesar teclado y gráficos

    drawnow;

    pause(0.01);

end