function tecla_liberada(figura, evento)
%TECLA_LIBERADA Registra cuándo una tecla deja de presionarse.

    %% Validar estado

    if ~isgraphics(figura, 'figure')
        return;
    end

    if ~isappdata(figura, 'estadoTeclado')
        return;
    end

    estado = getappdata(figura, 'estadoTeclado');

    %% Obtener tecla

    tecla = lower(char(evento.Key));

    %% Procesar liberación

    switch tecla

        %% Throttle

        case 'w'

            estado.subirThrottle = false;

        case 's'

            estado.bajarThrottle = false;

        %% Roll

        case 'leftarrow'

            estado.rollIzquierda = false;

        case 'rightarrow'

            estado.rollDerecha = false;

        %% Movimiento frontal

        case 'uparrow'

            estado.pitchAdelante = false;

        case 'downarrow'

            estado.pitchAtras = false;

        %% Yaw

        case 'a'

            estado.yawIzquierda = false;

        case 'd'

            estado.yawDerecha = false;

        %% Espacio

        case 'space'

            estado.bloqueoEspacio = false;

        %% Reinicio

        case 'r'

            estado.bloqueoR = false;

    end

    %% Guardar cambios

    setappdata(figura, 'estadoTeclado', estado);

end