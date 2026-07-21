function estado = crear_estado_teclado()
%CREAR_ESTADO_TECLADO Inicializa el estado completo del teclado.
%
% CONTROLES CONTINUOS
%
%   W / S
%       Modificación manual continua de la referencia de altura.
%
%   Flecha arriba / abajo
%       Movimiento hacia adelante / atrás.
%
%   Flecha izquierda / derecha
%       Movimiento lateral.
%
%   A / D
%       Rotación yaw.
%
% COMANDOS DISCRETOS
%
%   Shift
%       Solicitar ascenso automático de 1 metro.
%
%   Espacio
%       Solicitar descenso automático de 1 metro.
%
%   X
%       Apagar o desarmar los motores.
%
%   Enter
%       Armar los motores.
%
%   R
%       Reiniciar la simulación.
%
%   Escape
%       Cerrar la simulación.
%
% Las solicitudes discretas se generan una sola vez por pulsación.
% Los bloqueos evitan que el sistema operativo repita automáticamente
% una acción mientras la tecla continúa presionada.

    %% ============================================================
    % CONTROL MANUAL CONTINUO DE ALTURA
    % =============================================================

    % Se conservan estos nombres por compatibilidad con la
    % simulación interactiva anterior.

    estado.subirThrottle = false;
    estado.bajarThrottle = false;

    % Valor informativo para visualizaciones anteriores.
    %
    % El nuevo controlador de altura no utilizará este valor
    % directamente para controlar los motores.

    estado.throttle = 0.50;

    %% ============================================================
    % MOVIMIENTO HORIZONTAL
    % =============================================================

    % Movimiento lateral:
    %
    %   izquierda = -1
    %   derecha   = +1

    estado.rollIzquierda = false;
    estado.rollDerecha = false;

    % Movimiento longitudinal:
    %
    %   adelante = +1
    %   atrás    = -1

    estado.pitchAdelante = false;
    estado.pitchAtras = false;

    %% ============================================================
    % ROTACIÓN YAW
    % =============================================================

    estado.yawIzquierda = false;
    estado.yawDerecha = false;

    %% ============================================================
    % ESTADO DE ARMADO
    % =============================================================

    % Se inicializa desarmado por seguridad.
    %
    % La nueva simulación podrá cambiarlo a true al comenzar.

    estado.armado = false;

    %% ============================================================
    % MANIOBRAS AUTOMÁTICAS DE UN METRO
    % =============================================================

    % Estas banderas representan solicitudes de un solo ciclo.
    %
    % Shift:
    %   solicitudSubirUnMetro = true
    %
    % Espacio:
    %   solicitudBajarUnMetro = true
    %
    % leer_comando_teclado será responsable de consumirlas y
    % volverlas a poner en false.

    estado.solicitudSubirUnMetro = false;
    estado.solicitudBajarUnMetro = false;

    %% ============================================================
    % SOLICITUDES GENERALES
    % =============================================================

    estado.resetSolicitado = false;
    estado.salirSolicitado = false;

    %% ============================================================
    % BLOQUEOS DE TECLAS DISCRETAS
    % =============================================================

    % Evitan que una tecla sostenida genere varias órdenes.

    estado.bloqueoShift = false;
    estado.bloqueoEspacio = false;

    estado.bloqueoX = false;
    estado.bloqueoEnter = false;

    estado.bloqueoR = false;

end