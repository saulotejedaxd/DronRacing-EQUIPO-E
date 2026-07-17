function comando = leer_comando_teclado(figura)
%LEER_COMANDO_TECLADO Convierte las teclas en comandos normalizados.
%
% Convenciones de entrada:
%
%   throttle:
%       0.00 a 1.00
%
%   roll:
%       -1 = izquierda
%        0 = neutro
%       +1 = derecha
%
%   pitch:
%       -1 = atrás
%        0 = neutro
%       +1 = adelante
%
%   yaw:
%       -1 = izquierda
%        0 = neutro
%       +1 = derecha

    %% Validar figura

    if ~isgraphics(figura, 'figure')

        error( ...
            'leer_comando_teclado:FiguraInvalida', ...
            'La entrada debe ser una figura válida.' ...
        );

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

    %% Comandos normalizados

    comando.throttle = estado.throttle;

    comando.roll = ...
        double(estado.rollDerecha) - ...
        double(estado.rollIzquierda);

    % Ahora flecha arriba aparece como +1.
    comando.pitch = ...
        double(estado.pitchAdelante) - ...
        double(estado.pitchAtras);

    comando.yaw = ...
        double(estado.yawDerecha) - ...
        double(estado.yawIzquierda);

    %% Teclas del throttle

    comando.subirThrottle = estado.subirThrottle;
    comando.bajarThrottle = estado.bajarThrottle;

    %% Estados generales

    comando.armado = estado.armado;
    comando.reset = estado.resetSolicitado;
    comando.salir = estado.salirSolicitado;

    comando.origen = 'TECLADO';

end