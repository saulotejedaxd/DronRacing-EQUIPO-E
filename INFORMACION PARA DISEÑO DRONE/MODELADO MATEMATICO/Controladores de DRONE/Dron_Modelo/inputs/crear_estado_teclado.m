function estado = crear_estado_teclado()
%CREAR_ESTADO_TECLADO Inicializa todos los controles del teclado.

    %% Throttle persistente

    % 0.50 será el punto neutro provisional.
    estado.throttle = 0.50;

    estado.subirThrottle = false;
    estado.bajarThrottle = false;

    %% Roll

    estado.rollIzquierda = false;
    estado.rollDerecha = false;

    %% Pitch o movimiento frontal

    estado.pitchAdelante = false;
    estado.pitchAtras = false;

    %% Yaw

    estado.yawIzquierda = false;
    estado.yawDerecha = false;

    %% Estados generales

    estado.armado = false;

    estado.resetSolicitado = false;
    estado.salirSolicitado = false;

    %% Bloqueos contra repetición automática

    estado.bloqueoEspacio = false;
    estado.bloqueoR = false;

end