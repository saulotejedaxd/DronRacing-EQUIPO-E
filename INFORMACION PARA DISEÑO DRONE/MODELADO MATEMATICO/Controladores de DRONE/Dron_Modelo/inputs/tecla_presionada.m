function tecla_presionada(figura, evento)
%TECLA_PRESIONADA Registra una tecla mientras permanece presionada.
%
% Controles:
%   W / S              Aumentar / disminuir throttle
%   Flecha izquierda   Roll izquierda
%   Flecha derecha     Roll derecha
%   Flecha arriba      Avanzar
%   Flecha abajo       Retroceder
%   A / D              Yaw izquierda / derecha
%   Espacio            Armar / desarmar
%   R                  Reiniciar
%   Escape             Salir

    %% Validar figura

    if ~isgraphics(figura, 'figure')
        return;
    end

    %% Crear estado si no existe

    if ~isappdata(figura, 'estadoTeclado')

        setappdata( ...
            figura, ...
            'estadoTeclado', ...
            crear_estado_teclado() ...
        );

    end

    estado = getappdata(figura, 'estadoTeclado');

    %% Obtener tecla

    tecla = lower(char(evento.Key));

    %% Procesar tecla

    switch tecla

        %% Throttle

        case 'w'

            estado.subirThrottle = true;

        case 's'

            estado.bajarThrottle = true;

        %% Roll

        case 'leftarrow'

            estado.rollIzquierda = true;

        case 'rightarrow'

            estado.rollDerecha = true;

        %% Movimiento frontal

        case 'uparrow'

            estado.pitchAdelante = true;

        case 'downarrow'

            estado.pitchAtras = true;

        %% Yaw

        case 'a'

            estado.yawIzquierda = true;

        case 'd'

            estado.yawDerecha = true;

        %% Armar o desarmar

        case 'space'

            if ~estado.bloqueoEspacio

                estado.armado = ~estado.armado;
                estado.bloqueoEspacio = true;

            end

        %% Reiniciar

        case 'r'

            if ~estado.bloqueoR

                estado.resetSolicitado = true;
                estado.bloqueoR = true;

            end

        %% Salir

        case 'escape'

            estado.salirSolicitado = true;

    end

    %% Guardar cambios

    setappdata(figura, 'estadoTeclado', estado);

end